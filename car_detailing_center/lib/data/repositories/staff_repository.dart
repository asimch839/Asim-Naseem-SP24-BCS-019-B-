import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/staff_model.dart';

class StaffRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  // 1. Staff List CRUD
  Future<List<StaffModel>> getStaffList({String? searchQuery, bool activeOnly = false}) async {
    final db = await _db;
    String whereClause = 'is_deleted = 0';
    final List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause += " AND status = 'Active'";
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      whereClause += ' AND (LOWER(name) LIKE ? OR LOWER(designation) LIKE ? OR phone LIKE ? OR cnic LIKE ?)';
      whereArgs.addAll([q, q, q, q]);
    }

    final maps = await db.query(
      'staff',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return maps.map((m) {
      return StaffModel(
        id: m['id'] as String,
        businessId: 'local',
        name: m['name'] as String,
        fatherName: m['father_name'] as String?,
        cnic: m['cnic'] as String?,
        phone: m['phone'] as String,
        address: m['address'] as String?,
        joiningDate: DateTime.tryParse(m['joining_date']?.toString() ?? '') ?? DateTime.now(),
        designation: m['designation'] as String,
        salaryType: m['salary_type'] as String,
        basicSalary: (m['basic_salary'] as num?)?.toDouble() ?? 0.0,
        commissionRate: (m['commission_rate'] as num?)?.toDouble() ?? 0.0,
        status: m['status'] as String? ?? 'Active',
        photoUrl: m['photo_path'] as String?,
        notes: m['notes'] as String?,
        isDeleted: (m['is_deleted'] as int? ?? 0) == 1,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<StaffModel?> getStaffById(String id) async {
    final db = await _db;
    final maps = await db.query('staff', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final m = maps.first;

    return StaffModel(
      id: m['id'] as String,
      businessId: 'local',
      name: m['name'] as String,
      fatherName: m['father_name'] as String?,
      cnic: m['cnic'] as String?,
      phone: m['phone'] as String,
      address: m['address'] as String?,
      joiningDate: DateTime.tryParse(m['joining_date']?.toString() ?? '') ?? DateTime.now(),
      designation: m['designation'] as String,
      salaryType: m['salary_type'] as String,
      basicSalary: (m['basic_salary'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (m['commission_rate'] as num?)?.toDouble() ?? 0.0,
      status: m['status'] as String? ?? 'Active',
      photoUrl: m['photo_path'] as String?,
      notes: m['notes'] as String?,
      isDeleted: (m['is_deleted'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<void> saveStaff(StaffModel staff) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'staff',
      {
        'id': staff.id,
        'name': staff.name,
        'father_name': staff.fatherName ?? '',
        'cnic': staff.cnic ?? '',
        'phone': staff.phone,
        'address': staff.address ?? '',
        'joining_date': staff.joiningDate.toIso8601String(),
        'designation': staff.designation,
        'salary_type': staff.salaryType,
        'basic_salary': staff.basicSalary,
        'commission_rate': staff.commissionRate,
        'status': staff.status,
        'photo_path': staff.photoUrl ?? '',
        'notes': staff.notes ?? '',
        'is_deleted': staff.isDeleted ? 1 : 0,
        'created_at': staff.createdAt.toIso8601String(),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteStaff(String id, {bool softDelete = true}) async {
    final db = await _db;
    if (softDelete) {
      await db.update('staff', {'is_deleted': 1, 'status': 'Terminated', 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    } else {
      await db.delete('staff', where: 'id = ?', whereArgs: [id]);
    }
  }

  // 2. Attendance with Duplicate Prevention
  Future<List<Map<String, dynamic>>> getDailyAttendance(String dateStr) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT s.id as staff_id, s.name as staff_name, s.designation, s.salary_type, s.photo_path,
             a.id as attendance_id, a.status as attendance_status, a.check_in_time, a.check_out_time, a.notes
      FROM staff s
      LEFT JOIN attendance a ON s.id = a.staff_id AND a.date = ?
      WHERE s.is_deleted = 0 AND s.status = 'Active'
      ORDER BY s.name ASC
    ''', [dateStr]);
  }

  Future<void> recordAttendance({
    required String staffId,
    required String dateStr,
    required String status,
    String? checkInTime,
    String? checkOutTime,
    String? notes,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final id = 'att_${const Uuid().v4().substring(0, 8)}';

    await db.insert(
      'attendance',
      {
        'id': id,
        'staff_id': staffId,
        'date': dateStr,
        'status': status,
        'check_in_time': checkInTime ?? '',
        'check_out_time': checkOutTime ?? '',
        'notes': notes ?? '',
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getStaffAttendanceHistory(String staffId, {String? startDate, String? endDate}) async {
    final db = await _db;
    String sql = 'SELECT * FROM attendance WHERE staff_id = ?';
    final List<dynamic> args = [staffId];

    if (startDate != null && endDate != null) {
      sql += ' AND date BETWEEN ? AND ?';
      args.addAll([startDate, endDate]);
    }
    sql += ' ORDER BY date DESC';
    return await db.rawQuery(sql, args);
  }

  // 3. Salaries Calculation & History
  Future<Map<String, dynamic>> calculateSalaryForStaff(String staffId, String payPeriod) async {
    final db = await _db;
    final staff = await getStaffById(staffId);
    if (staff == null) throw Exception('Staff member not found');

    // Parse pay period YYYY-MM
    final parts = payPeriod.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final startDate = DateFormat('yyyy-MM-dd').format(DateTime(year, month, 1));
    final endDate = DateFormat('yyyy-MM-dd').format(DateTime(year, month + 1, 0));

    // Get attendance counts in this period
    final attRecords = await db.query(
      'attendance',
      where: 'staff_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [staffId, startDate, endDate],
    );

    int presentDays = 0;
    int absentDays = 0;
    int halfDays = 0;
    int leaveDays = 0;

    for (final r in attRecords) {
      final st = r['status'] as String;
      if (st == 'Present') {
        presentDays++;
      } else if (st == 'Absent') {
        absentDays++;
      } else if (st == 'Half Day') {
        halfDays++;
      } else if (st == 'Leave') {
        leaveDays++;
      }
    }

    // Days in month
    final totalDaysInMonth = DateTime(year, month + 1, 0).day;

    double grossSalary = 0.0;
    final basic = staff.basicSalary;

    switch (staff.salaryType) {
      case 'Daily':
        grossSalary = (presentDays * basic) + (halfDays * (basic / 2));
        break;
      case 'Weekly':
        final weeks = (presentDays + (halfDays * 0.5)) / 6.0;
        grossSalary = weeks * basic;
        break;
      case 'Commission':
        // Commission calculated from completed jobs assigned to this staff
        final commissionRes = await db.rawQuery('''
          SELECT COALESCE(SUM(j.grand_total), 0.0) as job_total
          FROM jobs j
          INNER JOIN job_staff js ON j.id = js.job_id
          WHERE js.staff_id = ? AND j.status IN ('Completed', 'Delivered')
            AND j.receiving_date BETWEEN ? AND ?
        ''', [staffId, startDate, endDate]);
        final totalJobsAmount = (commissionRes.first['job_total'] as num?)?.toDouble() ?? 0.0;
        grossSalary = totalJobsAmount * (staff.commissionRate / 100.0);
        break;
      case 'Mixed':
        // Base monthly + commission
        final commissionRes = await db.rawQuery('''
          SELECT COALESCE(SUM(j.grand_total), 0.0) as job_total
          FROM jobs j
          INNER JOIN job_staff js ON j.id = js.job_id
          WHERE js.staff_id = ? AND j.status IN ('Completed', 'Delivered')
            AND j.receiving_date BETWEEN ? AND ?
        ''', [staffId, startDate, endDate]);
        final totalJobsAmount = (commissionRes.first['job_total'] as num?)?.toDouble() ?? 0.0;
        final commissionEarned = totalJobsAmount * (staff.commissionRate / 100.0);
        final dayRate = basic / totalDaysInMonth;
        final baseEarned = (presentDays * dayRate) + (halfDays * dayRate * 0.5);
        grossSalary = baseEarned + commissionEarned;
        break;
      case 'Monthly':
      default:
        // Deduct only for actual recorded unexcused absences
        final dayRate = basic / totalDaysInMonth;
        final deductions = (absentDays * dayRate) + (halfDays * dayRate * 0.5);
        grossSalary = basic - deductions;
        if (grossSalary < 0) grossSalary = 0;
        break;
    }

    // Check existing advance payments for this staff in this period
    final advanceRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as adv_total
      FROM salary_payments
      WHERE staff_id = ? AND is_advance = 1 AND payment_date BETWEEN ? AND ?
    ''', [staffId, startDate, endDate]);
    final advanceTotal = (advanceRes.first['adv_total'] as num?)?.toDouble() ?? 0.0;

    final netSalary = grossSalary - advanceTotal > 0 ? (grossSalary - advanceTotal) : 0.0;

    return {
      'staff_id': staffId,
      'staff_name': staff.name,
      'pay_period': payPeriod,
      'start_date': startDate,
      'end_date': endDate,
      'salary_type': staff.salaryType,
      'basic_salary': basic,
      'present_days': presentDays,
      'absent_days': absentDays,
      'half_days': halfDays,
      'leave_days': leaveDays,
      'gross_salary': grossSalary,
      'advance_deductions': advanceTotal,
      'net_salary': netSalary,
    };
  }

  Future<List<Map<String, dynamic>>> getSalaries({String? payPeriod, String? staffId}) async {
    final db = await _db;
    String sql = '''
      SELECT s.*, st.name as staff_name, st.designation, st.phone as staff_phone
      FROM salaries s
      INNER JOIN staff st ON s.staff_id = st.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (payPeriod != null && payPeriod.isNotEmpty) {
      sql += ' AND s.pay_period = ?';
      args.add(payPeriod);
    }
    if (staffId != null && staffId.isNotEmpty) {
      sql += ' AND s.staff_id = ?';
      args.add(staffId);
    }

    sql += ' ORDER BY s.created_at DESC';
    return await db.rawQuery(sql, args);
  }

  Future<void> saveSalaryRecord(Map<String, dynamic> data) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final salaryId = data['id'] ?? 'sal_${const Uuid().v4().substring(0, 8)}';

    final gross = (data['gross_salary'] as num?)?.toDouble() ?? 0.0;
    final deductions = (data['advance_deductions'] as num?)?.toDouble() ?? 0.0;
    final net = (data['net_salary'] as num?)?.toDouble() ?? (gross - deductions);
    final paid = (data['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final remaining = (net - paid) > 0 ? (net - paid) : 0.0;
    final status = remaining <= 0 ? 'Paid' : (paid > 0 ? 'Partially Paid' : 'Pending');

    await db.insert(
      'salaries',
      {
        'id': salaryId,
        'staff_id': data['staff_id'],
        'pay_period': data['pay_period'],
        'start_date': data['start_date'],
        'end_date': data['end_date'],
        'salary_type': data['salary_type'] ?? 'Monthly',
        'basic_salary': (data['basic_salary'] as num?)?.toDouble() ?? 0.0,
        'present_days': data['present_days'] ?? 0,
        'absent_days': data['absent_days'] ?? 0,
        'half_days': data['half_days'] ?? 0,
        'overtime_hours': (data['overtime_hours'] as num?)?.toDouble() ?? 0.0,
        'overtime_amount': (data['overtime_amount'] as num?)?.toDouble() ?? 0.0,
        'bonus': (data['bonus'] as num?)?.toDouble() ?? 0.0,
        'commission': (data['commission'] as num?)?.toDouble() ?? 0.0,
        'advance_deductions': deductions,
        'other_deductions': (data['other_deductions'] as num?)?.toDouble() ?? 0.0,
        'gross_salary': gross,
        'net_salary': net,
        'paid_amount': paid,
        'remaining_amount': remaining,
        'status': status,
        'notes': data['notes'] ?? '',
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> recordSalaryPayment({
    required String salaryId,
    required String staffId,
    required double amount,
    required String paymentMethod,
    bool isAdvance = false,
    String? reference,
    String? notes,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final paymentId = 'spay_${const Uuid().v4().substring(0, 8)}';

    await db.transaction((txn) async {
      await txn.insert('salary_payments', {
        'id': paymentId,
        'salary_id': salaryId,
        'staff_id': staffId,
        'amount': amount,
        'payment_date': now,
        'payment_method': paymentMethod,
        'is_advance': isAdvance ? 1 : 0,
        'reference': reference ?? '',
        'notes': notes ?? '',
        'created_at': now,
      });

      if (!isAdvance) {
        // Update salary paid & remaining amounts
        final salRes = await txn.query('salaries', where: 'id = ?', whereArgs: [salaryId]);
        if (salRes.isNotEmpty) {
          final sal = salRes.first;
          final currentPaid = (sal['paid_amount'] as num?)?.toDouble() ?? 0.0;
          final net = (sal['net_salary'] as num?)?.toDouble() ?? 0.0;
          final newPaid = currentPaid + amount;
          final newRemaining = (net - newPaid) > 0 ? (net - newPaid) : 0.0;
          final newStatus = newRemaining <= 0 ? 'Paid' : 'Partially Paid';

          await txn.update(
            'salaries',
            {
              'paid_amount': newPaid,
              'remaining_amount': newRemaining,
              'status': newStatus,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [salaryId],
          );
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getSalaryPayments(String salaryId) async {
    final db = await _db;
    return await db.query('salary_payments', where: 'salary_id = ?', whereArgs: [salaryId], orderBy: 'payment_date DESC');
  }

  // 4. Staff Expenses (User-typed category, inside Staff module)
  Future<List<Map<String, dynamic>>> getStaffExpenses({String? staffId, String? startDate, String? endDate}) async {
    final db = await _db;
    String sql = '''
      SELECT se.*, s.name as staff_name, s.designation
      FROM staff_expenses se
      INNER JOIN staff s ON se.staff_id = s.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (staffId != null && staffId.isNotEmpty) {
      sql += ' AND se.staff_id = ?';
      args.add(staffId);
    }
    if (startDate != null && endDate != null) {
      sql += ' AND se.date BETWEEN ? AND ?';
      args.addAll([startDate, endDate]);
    }

    sql += ' ORDER BY se.date DESC';
    return await db.rawQuery(sql, args);
  }

  Future<void> saveStaffExpense({
    String? id,
    required String staffId,
    required String category, // User typed
    required String description,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? vendorDetails,
    String? reference,
    String? receiptPath,
    String? notes,
  }) async {
    final db = await _db;
    final expId = id ?? 'stf_exp_${const Uuid().v4().substring(0, 8)}';

    await db.insert(
      'staff_expenses',
      {
        'id': expId,
        'staff_id': staffId,
        'category': category.trim(),
        'description': description.trim(),
        'amount': amount,
        'date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'vendor_details': vendorDetails ?? '',
        'reference': reference ?? '',
        'receipt_path': receiptPath ?? '',
        'notes': notes ?? '',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteStaffExpense(String id) async {
    final db = await _db;
    await db.delete('staff_expenses', where: 'id = ?', whereArgs: [id]);
  }
}
