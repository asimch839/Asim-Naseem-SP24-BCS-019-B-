import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../../core/services/audit_service.dart';
import '../../core/utils/date_formatter.dart';
import '../models/student_model.dart';
import '../models/room_allocation_model.dart';
import 'room_repository.dart';
import 'rent_repository.dart';

class StudentRepository {
  final DbHelper _dbHelper = DbHelper.instance;
  final RoomRepository _roomRepo = RoomRepository();
  final RentRepository _rentRepo = RentRepository();

  Future<List<StudentModel>> getAllStudents({
    String? search,
    String? statusFilter,
    int? roomId,
    bool autoSyncRent = true,
  }) async {
    if (autoSyncRent) {
      try {
        await _rentRepo.syncMonthlyBillsAndOverdue();
      } catch (_) {}
    }
    final db = await _dbHelper.database;
    final currentMonth = DateFormatter.toIsoMonth(DateTime.now());

    String query = '''
      SELECT s.*, r.room_number, b.bed_number,
             curr_rent.status as current_rent_status,
             curr_rent.remaining_amount as current_rent_remaining
      FROM ${DbTables.students} s
      LEFT JOIN ${DbTables.rooms} r ON s.current_room_id = r.id
      LEFT JOIN ${DbTables.beds} b ON s.current_bed_id = b.id
      LEFT JOIN ${DbTables.rentRecords} curr_rent
        ON curr_rent.student_id = s.id AND curr_rent.rent_month = '$currentMonth'
    ''';

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(s.full_name LIKE ? OR s.student_id_code LIKE ? OR s.phone LIKE ? OR s.cnic LIKE ? OR r.room_number LIKE ?)');
      whereArgs.addAll(['%$search%', '%$search%', '%$search%', '%$search%', '%$search%']);
    }

    if (statusFilter != null && statusFilter != 'All') {
      whereClauses.add('s.status = ?');
      whereArgs.add(statusFilter);
    }

    if (roomId != null) {
      whereClauses.add('s.current_room_id = ?');
      whereArgs.add(roomId);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY s.id DESC';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((m) => StudentModel.fromMap(m)).toList();
  }

  Future<StudentModel?> getStudentById(int id) async {
    final db = await _dbHelper.database;
    final currentMonth = DateFormatter.toIsoMonth(DateTime.now());
    final query = '''
      SELECT s.*, r.room_number, b.bed_number,
             curr_rent.status as current_rent_status,
             curr_rent.remaining_amount as current_rent_remaining
      FROM ${DbTables.students} s
      LEFT JOIN ${DbTables.rooms} r ON s.current_room_id = r.id
      LEFT JOIN ${DbTables.beds} b ON s.current_bed_id = b.id
      LEFT JOIN ${DbTables.rentRecords} curr_rent
        ON curr_rent.student_id = s.id AND curr_rent.rent_month = '$currentMonth'
      WHERE s.id = ?
    ''';
    final results = await db.rawQuery(query, [id]);
    if (results.isEmpty) return null;
    return StudentModel.fromMap(results.first);
  }

  /// Generate next Student Code like STU-001, STU-002, etc.
  Future<String> generateNextStudentCode() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('SELECT MAX(id) as max_id FROM ${DbTables.students}');
    final maxId = (results.first['max_id'] as int?) ?? 0;
    return 'STU-${(maxId + 1).toString().padLeft(3, '0')}';
  }

  /// Complete Admission Transaction
  Future<int> admitStudent({
    required StudentModel student,
    required int roomId,
    required int bedId,
    required double monthlyRent,
    required double securityDeposit,
    required String admissionDate,
    String? admissionNotes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // 1. Verify bed is available
      final bedCheck = await txn.query(
        DbTables.beds,
        where: "id = ? AND bed_status = 'Available' AND current_student_id IS NULL",
        whereArgs: [bedId],
      );
      if (bedCheck.isEmpty) {
        throw Exception('The selected bed is no longer available. Please select another bed.');
      }

      // 2. Insert Student Record
      final studentMap = student.toMap();
      studentMap.remove('id');
      studentMap['current_room_id'] = roomId;
      studentMap['current_bed_id'] = bedId;
      studentMap['monthly_rent'] = monthlyRent;
      studentMap['security_deposit'] = securityDeposit;
      studentMap['admission_date'] = admissionDate;
      studentMap['status'] = 'Active';
      studentMap['created_at'] = now;

      final studentId = await txn.insert(DbTables.students, studentMap);

      // 3. Mark Bed as Occupied
      await txn.update(
        DbTables.beds,
        {
          'bed_status': 'Occupied',
          'current_student_id': studentId,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [bedId],
      );

      // 4. Update Room Status
      await _roomRepo.syncRoomStatus(roomId, txn);

      // 5. Create Admission Record
      await txn.insert(DbTables.admissions, {
        'student_id': studentId,
        'room_id': roomId,
        'bed_id': bedId,
        'admission_date': admissionDate,
        'monthly_rent': monthlyRent,
        'security_deposit': securityDeposit,
        'notes': admissionNotes,
        'created_at': now,
      });

      // 6. Create First Room Allocation History
      await txn.insert(DbTables.roomAllocations, {
        'student_id': studentId,
        'room_id': roomId,
        'bed_id': bedId,
        'start_date': admissionDate,
        'end_date': null,
        'reason': 'Admission',
        'notes': 'Initial room allocation on admission.',
        'created_at': now,
      });

      // 7. Create Monthly Rent Record for Admission Month
      final parsedDate = DateTime.tryParse(admissionDate) ?? DateTime.now();
      final rentMonth = DateFormatter.toIsoMonth(parsedDate);
      final dueDate = DateFormatter.toIsoDate(DateTime(parsedDate.year, parsedDate.month, 5));

      await txn.insert(DbTables.rentRecords, {
        'student_id': studentId,
        'room_id': roomId,
        'bed_id': bedId,
        'rent_month': rentMonth,
        'rent_amount': monthlyRent,
        'paid_amount': 0.0,
        'remaining_amount': monthlyRent,
        'due_date': dueDate,
        'status': 'Pending',
        'notes': 'Initial rent on admission.',
        'created_at': now,
      });

      // 8. Audit Log
      await AuditService.log(
        activityType: 'Admission',
        description: 'Student "${student.fullName}" (${student.studentIdCode}) admitted to Room ID $roomId.',
        studentId: studentId,
        executor: txn,
      );

      return studentId;
    });
  }

  /// Change Student Room and Bed with Complete Historical Tracking
  Future<void> changeRoom({
    required int studentId,
    required int newRoomId,
    required int newBedId,
    required String transferDate,
    String? reason,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Get current student details
      final studentData = await txn.query(
        DbTables.students,
        where: 'id = ?',
        whereArgs: [studentId],
      );
      if (studentData.isEmpty) throw Exception('Student not found.');
      final student = StudentModel.fromMap(studentData.first);
      final oldRoomId = student.currentRoomId;
      final oldBedId = student.currentBedId;

      // 2. Verify new bed is available
      final bedCheck = await txn.query(
        DbTables.beds,
        where: "id = ? AND bed_status = 'Available' AND current_student_id IS NULL",
        whereArgs: [newBedId],
      );
      if (bedCheck.isEmpty) {
        throw Exception('The selected destination bed is not available.');
      }

      // 3. Close previous active allocation
      await txn.update(
        DbTables.roomAllocations,
        {
          'end_date': transferDate,
          'notes': reason ?? 'Transferred to another room.',
        },
        where: 'student_id = ? AND end_date IS NULL',
        whereArgs: [studentId],
      );

      // 4. Release old bed
      if (oldBedId != null) {
        await txn.update(
          DbTables.beds,
          {
            'bed_status': 'Available',
            'current_student_id': null,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [oldBedId],
        );
      }
      if (oldRoomId != null) {
        await _roomRepo.syncRoomStatus(oldRoomId, txn);
      }

      // 5. Occupy new bed
      await txn.update(
        DbTables.beds,
        {
          'bed_status': 'Occupied',
          'current_student_id': studentId,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [newBedId],
      );
      await _roomRepo.syncRoomStatus(newRoomId, txn);

      // 6. Create new Allocation Record
      await txn.insert(DbTables.roomAllocations, {
        'student_id': studentId,
        'room_id': newRoomId,
        'bed_id': newBedId,
        'start_date': transferDate,
        'end_date': null,
        'reason': 'Room Change',
        'notes': reason ?? 'Room changed by management.',
        'created_at': now,
      });

      // 7. Update Student record
      await txn.update(
        DbTables.students,
        {
          'current_room_id': newRoomId,
          'current_bed_id': newBedId,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );

      // 8. Audit Log
      await AuditService.log(
        activityType: 'Room Change',
        description: 'Student "${student.fullName}" moved to new Room ID $newRoomId.',
        studentId: studentId,
        executor: txn,
      );
    });
  }

  /// Get total remaining unpaid rent for a student
  Future<double> getStudentPendingRentTotal(int studentId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT COALESCE(SUM(remaining_amount), 0) as total FROM ${DbTables.rentRecords} WHERE student_id = ? AND remaining_amount > 0',
      [studentId],
    );
    return (results.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Mark Student as Left (Archive with Settlement & History Preserved)
  Future<void> markStudentAsLeft({
    required int studentId,
    required String leavingDate,
    String? reason,
    double adjustSecurityToRent = 0.0,
    double refundSecurityAmount = 0.0,
    String? settlementNotes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final studentData = await txn.query(
        DbTables.students,
        where: 'id = ?',
        whereArgs: [studentId],
      );
      if (studentData.isEmpty) throw Exception('Student not found.');
      final student = StudentModel.fromMap(studentData.first);
      final oldBedId = student.currentBedId;
      final oldRoomId = student.currentRoomId;

      // 1. If adjustSecurityToRent > 0, settle against pending rent bills
      if (adjustSecurityToRent > 0) {
        final pendingRecords = await txn.query(
          DbTables.rentRecords,
          where: "student_id = ? AND remaining_amount > 0",
          orderBy: "rent_month ASC",
          whereArgs: [studentId],
        );

        double remainingToAdjust = adjustSecurityToRent;
        for (final rMap in pendingRecords) {
          if (remainingToAdjust <= 0) break;
          final rId = rMap['id'] as int;
          final remAmount = (rMap['remaining_amount'] as num).toDouble();
          final currPaid = (rMap['paid_amount'] as num).toDouble();
          final rentAmount = (rMap['rent_amount'] as num).toDouble();
          final adjustAmount = remainingToAdjust >= remAmount ? remAmount : remainingToAdjust;

          final newPaid = currPaid + adjustAmount;
          final newRem = (rentAmount - newPaid).clamp(0.0, double.infinity);
          final newStatus = newRem <= 0 ? 'Paid' : 'Partial';

          await txn.update(
            DbTables.rentRecords,
            {
              'paid_amount': newPaid,
              'remaining_amount': newRem,
              'status': newStatus,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [rId],
          );

          // Generate payment and receipt
          final receiptNumber = await _rentRepo.generateUniqueReceiptNumber(txn);
          final paymentId = await txn.insert(DbTables.payments, {
            'rent_record_id': rId,
            'student_id': studentId,
            'receipt_number': receiptNumber,
            'amount': adjustAmount,
            'payment_date': leavingDate,
            'payment_method': 'Security Deposit',
            'notes': 'Adjusted from security deposit on hostel departure.',
            'created_at': now,
          });

          await txn.insert(DbTables.receipts, {
            'receipt_number': receiptNumber,
            'payment_id': paymentId,
            'student_id': studentId,
            'rent_month': rMap['rent_month'] as String,
            'amount_paid': adjustAmount,
            'remaining_amount': newRem,
            'payment_date': leavingDate,
            'payment_method': 'Security Deposit',
            'pdf_path': null,
            'created_at': now,
          });

          remainingToAdjust -= adjustAmount;
        }

        if (remainingToAdjust > 0) {
          final latestRecords = await txn.query(
            DbTables.rentRecords,
            where: "student_id = ?",
            orderBy: "id DESC",
            limit: 1,
            whereArgs: [studentId],
          );
          final targetRentRecordId = latestRecords.isNotEmpty ? (latestRecords.first['id'] as int) : 0;
          final targetRentMonth = latestRecords.isNotEmpty ? (latestRecords.first['rent_month'] as String) : DateFormatter.toIsoMonth(DateTime.tryParse(leavingDate) ?? DateTime.now());

          final receiptNumber = await _rentRepo.generateUniqueReceiptNumber(txn);
          final paymentId = await txn.insert(DbTables.payments, {
            'rent_record_id': targetRentRecordId,
            'student_id': studentId,
            'receipt_number': receiptNumber,
            'amount': remainingToAdjust,
            'payment_date': leavingDate,
            'payment_method': 'Security Deposit',
            'notes': 'Security deposit adjusted towards rent/dues on departure. ${settlementNotes ?? ""}'.trim(),
            'created_at': now,
          });

          await txn.insert(DbTables.receipts, {
            'receipt_number': receiptNumber,
            'payment_id': paymentId,
            'student_id': studentId,
            'rent_month': targetRentMonth,
            'amount_paid': remainingToAdjust,
            'remaining_amount': 0.0,
            'payment_date': leavingDate,
            'payment_method': 'Security Deposit',
            'pdf_path': null,
            'created_at': now,
          });
        }
      }

      // 1b. If refundSecurityAmount > 0, record refund transaction in payment ledger
      if (refundSecurityAmount > 0) {
        final latestRecords = await txn.query(
          DbTables.rentRecords,
          where: "student_id = ?",
          orderBy: "id DESC",
          limit: 1,
          whereArgs: [studentId],
        );
        final targetRentRecordId = latestRecords.isNotEmpty ? (latestRecords.first['id'] as int) : 0;
        final nowDT = DateTime.now();
        final refundReceiptNo = 'REF-${nowDT.year}${nowDT.month.toString().padLeft(2, '0')}-${studentId.toString().padLeft(4, '0')}';

        await txn.insert(DbTables.payments, {
          'rent_record_id': targetRentRecordId,
          'student_id': studentId,
          'receipt_number': refundReceiptNo,
          'amount': refundSecurityAmount,
          'payment_date': leavingDate,
          'payment_method': 'Security Refund',
          'notes': 'Security deposit refunded upon departure. ${settlementNotes ?? ""}'.trim(),
          'created_at': now,
        });
      }

      // 2. Close current allocation
      await txn.update(
        DbTables.roomAllocations,
        {
          'end_date': leavingDate,
          'reason': 'Left',
          'notes': reason ?? 'Student departed from hostel.',
        },
        where: 'student_id = ? AND end_date IS NULL',
        whereArgs: [studentId],
      );

      // 3. Release bed
      if (oldBedId != null) {
        await txn.update(
          DbTables.beds,
          {
            'bed_status': 'Available',
            'current_student_id': null,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [oldBedId],
        );
      }
      if (oldRoomId != null) {
        await _roomRepo.syncRoomStatus(oldRoomId, txn);
      }

      // 4. Calculate new security balance
      final finalSecurity = (student.securityDeposit - adjustSecurityToRent - refundSecurityAmount).clamp(0.0, double.infinity);
      final noteParts = <String>[];
      if (student.notes != null && student.notes!.isNotEmpty) noteParts.add(student.notes!);
      noteParts.add('Departure: ${reason ?? "Left"} on $leavingDate');
      if (adjustSecurityToRent > 0) noteParts.add('Security adjusted towards rent: Rs. ${adjustSecurityToRent.toStringAsFixed(0)}');
      if (refundSecurityAmount > 0) noteParts.add('Security refunded to student: Rs. ${refundSecurityAmount.toStringAsFixed(0)}');
      if (settlementNotes != null && settlementNotes.trim().isNotEmpty) noteParts.add('Settlement note: $settlementNotes');

      // 5. Mark Student as Left
      await txn.update(
        DbTables.students,
        {
          'status': 'Left',
          'leaving_date': leavingDate,
          'current_room_id': null,
          'current_bed_id': null,
          'security_deposit': finalSecurity,
          'notes': noteParts.join('\n'),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );

      // 6. Audit Log
      await AuditService.log(
        activityType: 'Student Left',
        description: 'Student "${student.fullName}" (${student.studentIdCode}) departed. Security adjusted: Rs. $adjustSecurityToRent, refunded: Rs. $refundSecurityAmount.',
        studentId: studentId,
        executor: txn,
      );
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final studentMap = student.toMap();
    studentMap['updated_at'] = now;

    await db.update(
      DbTables.students,
      studentMap,
      where: 'id = ?',
      whereArgs: [student.id],
    );

    await AuditService.log(
      activityType: 'Student Updated',
      description: 'Student "${student.fullName}" profile details updated.',
      studentId: student.id,
    );
  }

  /// Get student room allocation history
  Future<List<RoomAllocationModel>> getStudentAllocations(int studentId) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT a.*, r.room_number, b.bed_number, s.full_name as student_name, s.student_id_code
      FROM ${DbTables.roomAllocations} a
      INNER JOIN ${DbTables.rooms} r ON a.room_id = r.id
      INNER JOIN ${DbTables.beds} b ON a.bed_id = b.id
      INNER JOIN ${DbTables.students} s ON a.student_id = s.id
      WHERE a.student_id = ?
      ORDER BY a.start_date DESC
    ''';
    final results = await db.rawQuery(query, [studentId]);
    return results.map((m) => RoomAllocationModel.fromMap(m)).toList();
  }

  /// Permanently delete student record and release assigned bed
  Future<void> deleteStudent(int studentId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final studentData = await txn.query(
        DbTables.students,
        where: 'id = ?',
        whereArgs: [studentId],
      );
      if (studentData.isEmpty) return;
      final student = StudentModel.fromMap(studentData.first);

      // Release bed if currently occupied
      if (student.currentBedId != null) {
        await txn.update(
          DbTables.beds,
          {
            'bed_status': 'Available',
            'current_student_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [student.currentBedId],
        );
      }
      if (student.currentRoomId != null) {
        await _roomRepo.syncRoomStatus(student.currentRoomId!, txn);
      }

      // Clean up child tables
      await txn.delete(DbTables.roomAllocations, where: 'student_id = ?', whereArgs: [studentId]);
      await txn.delete(DbTables.admissions, where: 'student_id = ?', whereArgs: [studentId]);
      await txn.delete(DbTables.receipts, where: 'student_id = ?', whereArgs: [studentId]);
      await txn.delete(DbTables.payments, where: 'student_id = ?', whereArgs: [studentId]);
      await txn.delete(DbTables.rentRecords, where: 'student_id = ?', whereArgs: [studentId]);
      await txn.delete(DbTables.students, where: 'id = ?', whereArgs: [studentId]);

      await AuditService.log(
        activityType: 'Student Deleted',
        description: 'Student "${student.fullName}" (${student.studentIdCode}) record deleted.',
        recordId: studentId,
        executor: txn,
      );
    });
  }
}
