import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../../core/services/audit_service.dart';
import '../../core/utils/date_formatter.dart';
import '../models/rent_record_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';

class RentRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  /// Automatically syncs monthly bills for the current month and updates overdue statuses
  Future<int> syncMonthlyBillsAndOverdue({String? targetMonth}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final currentMonth = targetMonth ?? DateFormatter.toIsoMonth(now);
    final todayIso = DateFormatter.toIsoDate(now);

    // 1. Get due day from settings
    int dueDay = 5;
    try {
      final settings = await db.query(DbTables.hostelSettings, limit: 1);
      if (settings.isNotEmpty && settings.first['rent_due_day'] != null) {
        dueDay = settings.first['rent_due_day'] as int;
      }
    } catch (_) {}

    // 2. Generate bills for current month for all active students who don't have one
    final generatedCount = await generateMonthlyBills(currentMonth, dueDay: dueDay);

    // 3. Auto-update status to 'Overdue' for any Pending record past due date
    await db.update(
      DbTables.rentRecords,
      {
        'status': 'Overdue',
        'updated_at': now.toIso8601String(),
      },
      where: "(status = 'Pending' OR status = 'Partial') AND remaining_amount > 0 AND due_date < ?",
      whereArgs: [todayIso],
    );

    return generatedCount;
  }

  Future<List<RentRecordModel>> getRentRecords({
    String? search,
    String? monthFilter,
    String? statusFilter,
    int? studentId,
    bool autoSync = true,
  }) async {
    if (autoSync) {
      try {
        await syncMonthlyBillsAndOverdue();
      } catch (_) {}
    }
    final db = await _dbHelper.database;

    String query = '''
      SELECT rr.*, s.full_name as student_name, s.student_id_code, s.phone as student_phone,
             s.security_deposit as student_security_deposit,
             r.room_number, b.bed_number,
             COALESCE((
               SELECT SUM(p.amount)
               FROM ${DbTables.payments} p
               WHERE p.rent_record_id = rr.id
                 AND p.payment_method NOT IN ('Security Refund')
             ), rr.paid_amount) as total_payments_sum
      FROM ${DbTables.rentRecords} rr
      INNER JOIN ${DbTables.students} s ON rr.student_id = s.id
      LEFT JOIN ${DbTables.rooms} r ON rr.room_id = r.id
      LEFT JOIN ${DbTables.beds} b ON rr.bed_id = b.id
    ''';

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(s.full_name LIKE ? OR s.student_id_code LIKE ? OR r.room_number LIKE ?)');
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (monthFilter != null && monthFilter != 'All') {
      whereClauses.add('rr.rent_month = ?');
      whereArgs.add(monthFilter);
    }

    if (statusFilter != null && statusFilter != 'All') {
      whereClauses.add('rr.status = ?');
      whereArgs.add(statusFilter);
    }

    if (studentId != null) {
      whereClauses.add('rr.student_id = ?');
      whereArgs.add(studentId);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY rr.rent_month DESC, rr.id DESC';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((m) => RentRecordModel.fromMap(m)).toList();
  }

  /// Generate monthly rent bills for all currently active students
  Future<int> generateMonthlyBills(String targetMonthYear, {int dueDay = 5}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final todayIso = DateFormatter.toIsoDate(now);

    // 1. Get all active students with assigned rooms
    final activeStudents = await db.query(
      DbTables.students,
      where: "status = 'Active' AND current_room_id IS NOT NULL AND current_bed_id IS NOT NULL",
    );

    int generatedCount = 0;
    final parts = targetMonthYear.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final validDueDay = dueDay.clamp(1, daysInMonth);
    final dueDate = DateFormatter.toIsoDate(DateTime(year, month, validDueDay));
    final initialStatus = dueDate.compareTo(todayIso) < 0 ? 'Overdue' : 'Pending';

    await db.transaction((txn) async {
      for (final sMap in activeStudents) {
        final studentId = sMap['id'] as int;
        final roomId = sMap['current_room_id'] as int;
        final bedId = sMap['current_bed_id'] as int;
        final rentAmount = (sMap['monthly_rent'] as num).toDouble();

        // Check if bill already exists
        final existing = await txn.query(
          DbTables.rentRecords,
          where: 'student_id = ? AND rent_month = ?',
          whereArgs: [studentId, targetMonthYear],
        );

        if (existing.isEmpty) {
          await txn.insert(DbTables.rentRecords, {
            'student_id': studentId,
            'room_id': roomId,
            'bed_id': bedId,
            'rent_month': targetMonthYear,
            'rent_amount': rentAmount,
            'paid_amount': 0.0,
            'remaining_amount': rentAmount,
            'due_date': dueDate,
            'status': initialStatus,
            'notes': 'Monthly bill generated automatically.',
            'created_at': nowIso,
          });
          generatedCount++;
        }
      }

      if (generatedCount > 0) {
        await AuditService.log(
          activityType: 'Bills Generated',
          description: 'Generated $generatedCount monthly rent bills for period $targetMonthYear.',
          executor: txn,
        );
      }
    });

    return generatedCount;
  }

  /// Generate a unique sequential receipt number
  Future<String> generateUniqueReceiptNumber([DatabaseExecutor? executor]) async {
    final db = executor ?? await _dbHelper.database;
    final now = DateTime.now();
    final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}';

    final settings = await db.query(DbTables.hostelSettings, limit: 1);
    final prefix = (settings.isNotEmpty ? (settings.first['receipt_prefix'] as String?) : null) ?? 'REC-';

    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${DbTables.receipts}');
    final count = ((result.first['count'] as int?) ?? 0) + 1;

    return '$prefix$datePrefix-${count.toString().padLeft(4, '0')}';
  }

  /// Record Rent Payment & Issue Receipt
  Future<ReceiptModel> recordPayment({
    required int rentRecordId,
    required double paymentAmount,
    required String paymentDate,
    required String paymentMethod,
    double securityAmount = 0.0,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // 1. Fetch current rent record
      final recordResults = await txn.query(
        DbTables.rentRecords,
        where: 'id = ?',
        whereArgs: [rentRecordId],
      );
      if (recordResults.isEmpty) throw Exception('Rent record not found.');
      final rentRecord = RentRecordModel.fromMap(recordResults.first);

      if (paymentAmount <= 0 && securityAmount <= 0) {
        throw Exception('Payment amount must be greater than zero.');
      }
      if (paymentAmount > rentRecord.remainingAmount) {
        throw Exception('Payment amount exceeds remaining due of ${rentRecord.remainingAmount}.');
      }

      final totalPaidThisTxn = paymentAmount + securityAmount;
      final newPaidAmount = rentRecord.paidAmount + totalPaidThisTxn;
      final newRemaining = (rentRecord.rentAmount - (rentRecord.paidAmount + paymentAmount)).clamp(0.0, double.infinity);

      // Status rule
      String newStatus = 'Pending';
      if (newRemaining <= 0) {
        newStatus = 'Paid';
      } else if (newPaidAmount > 0) {
        newStatus = 'Partial';
      }

      // If paying using Security Deposit, verify sufficient balance & deduct
      if (paymentMethod == 'Security Deposit') {
        final studentData = await txn.query(
          DbTables.students,
          where: 'id = ?',
          whereArgs: [rentRecord.studentId],
        );
        if (studentData.isEmpty) throw Exception('Student record not found.');
        final currentDeposit = (studentData.first['security_deposit'] as num?)?.toDouble() ?? 0.0;
        if (paymentAmount > currentDeposit) {
          throw Exception('Payment amount (Rs. $paymentAmount) exceeds available security deposit of Rs. $currentDeposit.');
        }
        await txn.update(
          DbTables.students,
          {
            'security_deposit': currentDeposit - paymentAmount,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [rentRecord.studentId],
        );
      } else if (securityAmount > 0) {
        // If security deposit collected along with rent, ensure student record has it stored
        final studentData = await txn.query(
          DbTables.students,
          where: 'id = ?',
          whereArgs: [rentRecord.studentId],
        );
        if (studentData.isNotEmpty) {
          final currentDeposit = (studentData.first['security_deposit'] as num?)?.toDouble() ?? 0.0;
          if (currentDeposit < securityAmount) {
            await txn.update(
              DbTables.students,
              {
                'security_deposit': securityAmount,
                'updated_at': now,
              },
              where: 'id = ?',
              whereArgs: [rentRecord.studentId],
            );
          }
        }
      }

      // 2. Update Rent Record
      await txn.update(
        DbTables.rentRecords,
        {
          'paid_amount': newPaidAmount,
          'remaining_amount': newRemaining,
          'status': newStatus,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [rentRecordId],
      );

      // 3. Generate Receipt Number
      final receiptNumber = await generateUniqueReceiptNumber(txn);
      final totalPaid = paymentAmount + securityAmount;

      final formattedNotes = securityAmount > 0
          ? '${notes ?? ""}${notes != null && notes.isNotEmpty ? " • " : ""}Includes Rs. ${securityAmount.toStringAsFixed(0)} security deposit'.trim()
          : notes;

      // 4. Insert Payment Record
      final paymentId = await txn.insert(DbTables.payments, {
        'rent_record_id': rentRecordId,
        'student_id': rentRecord.studentId,
        'receipt_number': receiptNumber,
        'amount': totalPaid,
        'payment_date': paymentDate,
        'payment_method': paymentMethod,
        'notes': formattedNotes,
        'created_at': now,
      });

      // 5. Insert Receipt Record
      final receiptId = await txn.insert(DbTables.receipts, {
        'receipt_number': receiptNumber,
        'payment_id': paymentId,
        'student_id': rentRecord.studentId,
        'rent_month': rentRecord.rentMonth,
        'amount_paid': totalPaid,
        'remaining_amount': newRemaining,
        'payment_date': paymentDate,
        'payment_method': paymentMethod,
        'pdf_path': null,
        'created_at': now,
      });

      // 6. Audit Log
      await AuditService.log(
        activityType: 'Payment',
        description: 'Recorded payment of Rs. $totalPaid (Rent: Rs. $paymentAmount, Security: Rs. $securityAmount, Receipt: $receiptNumber) for student ID ${rentRecord.studentId}.',
        studentId: rentRecord.studentId,
        recordId: paymentId,
        executor: txn,
      );

      // 7. Return Full Joined Receipt Model
      final fullReceipt = await getReceiptById(receiptId, txn);
      final effectiveSecurity = securityAmount > 0 ? securityAmount : (rentRecord.studentSecurityDeposit ?? 0.0);
      return fullReceipt?.copyWith(securityDeposit: effectiveSecurity) ?? ReceiptModel(
        id: receiptId,
        receiptNumber: receiptNumber,
        paymentId: paymentId,
        studentId: rentRecord.studentId,
        rentMonth: rentRecord.rentMonth,
        amountPaid: totalPaid,
        remainingAmount: newRemaining,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        createdAt: now,
        studentName: rentRecord.studentName,
        studentPhone: rentRecord.studentPhone,
        studentIdCode: rentRecord.studentIdCode,
        roomNumber: rentRecord.roomNumber,
        bedNumber: rentRecord.bedNumber,
        rentAmount: paymentAmount,
        securityDeposit: effectiveSecurity,
      );
    });
  }

  Future<ReceiptModel?> getReceiptById(int id, [DatabaseExecutor? executor]) async {
    final db = executor ?? await _dbHelper.database;
    final query = '''
      SELECT rc.*, s.full_name as student_name, s.student_id_code, s.phone as student_phone,
             s.security_deposit as student_security_deposit,
             r.room_number, b.bed_number, rr.rent_amount
      FROM ${DbTables.receipts} rc
      INNER JOIN ${DbTables.payments} p ON rc.payment_id = p.id
      INNER JOIN ${DbTables.rentRecords} rr ON p.rent_record_id = rr.id
      INNER JOIN ${DbTables.students} s ON rc.student_id = s.id
      LEFT JOIN ${DbTables.rooms} r ON rr.room_id = r.id
      LEFT JOIN ${DbTables.beds} b ON rr.bed_id = b.id
      WHERE rc.id = ?
    ''';
    final results = await db.rawQuery(query, [id]);
    if (results.isEmpty) return null;
    return ReceiptModel.fromMap(results.first);
  }

  Future<List<ReceiptModel>> getAllReceipts({String? search, String? monthFilter}) async {
    final db = await _dbHelper.database;
    String query = '''
      SELECT rc.*, s.full_name as student_name, s.student_id_code, s.phone as student_phone,
             s.security_deposit as student_security_deposit,
             r.room_number, b.bed_number, rr.rent_amount
      FROM ${DbTables.receipts} rc
      INNER JOIN ${DbTables.payments} p ON rc.payment_id = p.id
      INNER JOIN ${DbTables.rentRecords} rr ON p.rent_record_id = rr.id
      INNER JOIN ${DbTables.students} s ON rc.student_id = s.id
      LEFT JOIN ${DbTables.rooms} r ON rr.room_id = r.id
      LEFT JOIN ${DbTables.beds} b ON rr.bed_id = b.id
    ''';

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(rc.receipt_number LIKE ? OR s.full_name LIKE ? OR s.student_id_code LIKE ?)');
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (monthFilter != null && monthFilter != 'All') {
      whereClauses.add('rc.rent_month = ?');
      whereArgs.add(monthFilter);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY rc.id DESC';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((m) => ReceiptModel.fromMap(m)).toList();
  }

  Future<List<PaymentModel>> getStudentPaymentHistory(int studentId) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT p.*, s.full_name as student_name, s.student_id_code,
             r.room_number, b.bed_number, rr.rent_month
      FROM ${DbTables.payments} p
      INNER JOIN ${DbTables.students} s ON p.student_id = s.id
      LEFT JOIN ${DbTables.rentRecords} rr ON p.rent_record_id = rr.id
      LEFT JOIN ${DbTables.rooms} r ON rr.room_id = r.id
      LEFT JOIN ${DbTables.beds} b ON rr.bed_id = b.id
      WHERE p.student_id = ?
      ORDER BY p.payment_date DESC, p.id DESC
    ''';
    final results = await db.rawQuery(query, [studentId]);
    return results.map((m) => PaymentModel.fromMap(m)).toList();
  }

  Future<List<RentRecordModel>> getStudentRentRecords(int studentId) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT rr.*, s.full_name as student_name, s.student_id_code, s.phone as student_phone,
             s.security_deposit as student_security_deposit,
             r.room_number, b.bed_number,
             COALESCE((
               SELECT SUM(p.amount)
               FROM ${DbTables.payments} p
               WHERE p.rent_record_id = rr.id
                 AND p.payment_method NOT IN ('Security Refund')
             ), rr.paid_amount) as total_payments_sum
      FROM ${DbTables.rentRecords} rr
      INNER JOIN ${DbTables.students} s ON rr.student_id = s.id
      INNER JOIN ${DbTables.rooms} r ON rr.room_id = r.id
      INNER JOIN ${DbTables.beds} b ON rr.bed_id = b.id
      WHERE rr.student_id = ?
      ORDER BY rr.rent_month DESC, rr.id DESC
    ''';
    final results = await db.rawQuery(query, [studentId]);
    return results.map((m) => RentRecordModel.fromMap(m)).toList();
  }

  Future<ReceiptModel?> getReceiptByPaymentId(int paymentId) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT rc.*, s.full_name as student_name, s.student_id_code, s.phone as student_phone,
             r.room_number, b.bed_number, rr.rent_amount
      FROM ${DbTables.receipts} rc
      INNER JOIN ${DbTables.payments} p ON rc.payment_id = p.id
      INNER JOIN ${DbTables.rentRecords} rr ON p.rent_record_id = rr.id
      INNER JOIN ${DbTables.students} s ON rc.student_id = s.id
      INNER JOIN ${DbTables.rooms} r ON rr.room_id = r.id
      INNER JOIN ${DbTables.beds} b ON rr.bed_id = b.id
      WHERE rc.payment_id = ?
      LIMIT 1
    ''';
    final results = await db.rawQuery(query, [paymentId]);
    if (results.isEmpty) return null;
    return ReceiptModel.fromMap(results.first);
  }
}
