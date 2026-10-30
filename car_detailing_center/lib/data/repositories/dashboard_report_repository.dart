import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 'settings_repository.dart';

class DashboardMetrics {
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
  final double outstandingPayments;

  final int totalCustomers;
  final int totalVehicles;

  final int todaysJobs;
  final int inProgressJobs;
  final int completedJobs;
  final int readyForDeliveryJobs;

  final int totalStaff;
  final int presentToday;
  final int absentToday;
  final double pendingSalaries;

  final int totalStockItems;
  final int lowStockItems;
  final int outOfStockItems;
  final double stockPurchaseValue;

  DashboardMetrics({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.outstandingPayments,
    required this.totalCustomers,
    required this.totalVehicles,
    required this.todaysJobs,
    required this.inProgressJobs,
    required this.completedJobs,
    required this.readyForDeliveryJobs,
    required this.totalStaff,
    required this.presentToday,
    required this.absentToday,
    required this.pendingSalaries,
    required this.totalStockItems,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.stockPurchaseValue,
  });
}

class DashboardReportRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  /// Fetch all 18 real KPI cards from SQLite for a given date range
  Future<DashboardMetrics> getDashboardKPIs(DateTime start, DateTime end) async {
    final db = await _db;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Total Income: valid payments received in period
    final incomeRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as income
      FROM payments
      WHERE payment_date BETWEEN ? AND ? AND is_refund = 0
    ''', [startStr, endStr]);
    final totalIncome = (incomeRes.first['income'] as num?)?.toDouble() ?? 0.0;

    // 2. Expenses:
    // a) Garage expenses in period
    final garageExpRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as g_exp
      FROM garage_expenses
      WHERE date BETWEEN ? AND ?
    ''', [startStr, endStr]);
    final garageExp = (garageExpRes.first['g_exp'] as num?)?.toDouble() ?? 0.0;

    // b) Staff expenses in period
    final staffExpRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as s_exp
      FROM staff_expenses
      WHERE date BETWEEN ? AND ?
    ''', [startStr, endStr]);
    final staffExp = (staffExpRes.first['s_exp'] as num?)?.toDouble() ?? 0.0;

    // c) Valid salary disbursements (non-advance salary payments to prevent double counting)
    final salaryPaidRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as sal_paid
      FROM salary_payments
      WHERE payment_date BETWEEN ? AND ? AND is_advance = 0
    ''', [startStr, endStr]);
    final salaryPaid = (salaryPaidRes.first['sal_paid'] as num?)?.toDouble() ?? 0.0;

    final totalExpenses = garageExp + staffExp + salaryPaid;
    final netIncome = totalIncome - totalExpenses;

    // 3. Outstanding Payments across all active invoices
    final outRes = await db.rawQuery('''
      SELECT COALESCE(SUM(remaining_amount), 0.0) as outstanding
      FROM invoices
      WHERE status != 'Cancelled'
    ''');
    final outstandingPayments = (outRes.first['outstanding'] as num?)?.toDouble() ?? 0.0;

    // 4. Customers & Vehicles
    final custRes = await db.rawQuery('SELECT COUNT(*) FROM customers WHERE is_deleted = 0');
    final totalCustomers = Sqflite.firstIntValue(custRes) ?? 0;

    final vehRes = await db.rawQuery('SELECT COUNT(*) FROM vehicles WHERE is_deleted = 0');
    final totalVehicles = Sqflite.firstIntValue(vehRes) ?? 0;

    // 5. Jobs Status
    final todayJobsRes = await db.rawQuery("SELECT COUNT(*) FROM jobs WHERE receiving_date LIKE '$todayStr%'");
    final todaysJobs = Sqflite.firstIntValue(todayJobsRes) ?? 0;

    final inProgRes = await db.rawQuery("SELECT COUNT(*) FROM jobs WHERE status = 'In Progress'");
    final inProgressJobs = Sqflite.firstIntValue(inProgRes) ?? 0;

    final compRes = await db.rawQuery("SELECT COUNT(*) FROM jobs WHERE status IN ('Completed', 'Delivered')");
    final completedJobs = Sqflite.firstIntValue(compRes) ?? 0;

    final readyRes = await db.rawQuery("SELECT COUNT(*) FROM jobs WHERE status = 'Ready for Delivery'");
    final readyForDeliveryJobs = Sqflite.firstIntValue(readyRes) ?? 0;

    // 6. Staff & Attendance today
    final staffRes = await db.rawQuery("SELECT COUNT(*) FROM staff WHERE is_deleted = 0 AND status = 'Active'");
    final totalStaff = Sqflite.firstIntValue(staffRes) ?? 0;

    final presRes = await db.rawQuery("SELECT COUNT(*) FROM attendance WHERE date = ? AND status = 'Present'", [todayStr]);
    final presentToday = Sqflite.firstIntValue(presRes) ?? 0;

    final absRes = await db.rawQuery("SELECT COUNT(*) FROM attendance WHERE date = ? AND status = 'Absent'", [todayStr]);
    final absentToday = Sqflite.firstIntValue(absRes) ?? 0;

    final pendingSalRes = await db.rawQuery('''
      SELECT COALESCE(SUM(remaining_amount), 0.0) as pend_sal
      FROM salaries
      WHERE status != 'Paid'
    ''');
    final pendingSalaries = (pendingSalRes.first['pend_sal'] as num?)?.toDouble() ?? 0.0;

    // 7. Inventory
    final threshold = await SettingsRepository().getLowStockThreshold();
    final invAllRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt, COALESCE(SUM(current_quantity * purchase_price), 0.0) as purchase_val
      FROM inventory_items
      WHERE is_deleted = 0 AND is_active = 1
    ''');
    final totalStockItems = Sqflite.firstIntValue(invAllRes) ?? 0;
    final stockPurchaseValue = (invAllRes.first['purchase_val'] as num?)?.toDouble() ?? 0.0;

    final lowRes = await db.rawQuery('''
      SELECT COUNT(*) FROM inventory_items
      WHERE is_deleted = 0 AND is_active = 1 AND current_quantity > 0 AND current_quantity <= ?
    ''', [threshold]);
    final lowStockItems = Sqflite.firstIntValue(lowRes) ?? 0;

    final outStockRes = await db.rawQuery('''
      SELECT COUNT(*) FROM inventory_items
      WHERE is_deleted = 0 AND is_active = 1 AND current_quantity <= 0
    ''');
    final outOfStockItems = Sqflite.firstIntValue(outStockRes) ?? 0;

    return DashboardMetrics(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netIncome: netIncome,
      outstandingPayments: outstandingPayments,
      totalCustomers: totalCustomers,
      totalVehicles: totalVehicles,
      todaysJobs: todaysJobs,
      inProgressJobs: inProgressJobs,
      completedJobs: completedJobs,
      readyForDeliveryJobs: readyForDeliveryJobs,
      totalStaff: totalStaff,
      presentToday: presentToday,
      absentToday: absentToday,
      pendingSalaries: pendingSalaries,
      totalStockItems: totalStockItems,
      lowStockItems: lowStockItems,
      outOfStockItems: outOfStockItems,
      stockPurchaseValue: stockPurchaseValue,
    );
  }

  /// Graph 1: Daily Income vs Expenses (Last 7 Days)
  Future<List<Map<String, dynamic>>> getDailyIncomeVsExpense() async {
    final db = await _db;
    final List<Map<String, dynamic>> dailyData = [];
    final now = DateTime.now();

    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);
      final dayLabel = DateFormat('EEE').format(day);

      // Income for day
      final incRes = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0.0) as val
        FROM payments
        WHERE payment_date LIKE '$dayStr%' AND is_refund = 0
      ''');
      final income = (incRes.first['val'] as num?)?.toDouble() ?? 0.0;

      // Expenses for day
      final gExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM garage_expenses WHERE date LIKE '$dayStr%'");
      final sExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM staff_expenses WHERE date LIKE '$dayStr%'");
      final exp = ((gExpRes.first['val'] as num?)?.toDouble() ?? 0.0) + ((sExpRes.first['val'] as num?)?.toDouble() ?? 0.0);

      dailyData.add({
        'label': dayLabel,
        'date': dayStr,
        'income': income,
        'expense': exp,
      });
    }
    return dailyData;
  }

  /// Graph 2: Monthly Income vs Expenses (Last 6 Months)
  Future<List<Map<String, dynamic>>> getMonthlyIncomeVsExpense() async {
    final db = await _db;
    final List<Map<String, dynamic>> monthlyData = [];
    final now = DateTime.now();

    for (var i = 5; i >= 0; i--) {
      final mDate = DateTime(now.year, now.month - i, 1);
      final mStr = DateFormat('yyyy-MM').format(mDate);
      final mLabel = DateFormat('MMM').format(mDate);

      final incRes = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0.0) as val
        FROM payments
        WHERE payment_date LIKE '$mStr%' AND is_refund = 0
      ''');
      final income = (incRes.first['val'] as num?)?.toDouble() ?? 0.0;

      final gExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM garage_expenses WHERE date LIKE '$mStr%'");
      final sExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM staff_expenses WHERE date LIKE '$mStr%'");
      final exp = ((gExpRes.first['val'] as num?)?.toDouble() ?? 0.0) + ((sExpRes.first['val'] as num?)?.toDouble() ?? 0.0);

      monthlyData.add({
        'label': mLabel,
        'month': mStr,
        'income': income,
        'expense': exp,
      });
    }
    return monthlyData;
  }

  /// Graph: Dynamically Filtered Income vs Expenses by Date Range & Mode (Daily, Weekly, Monthly, Custom)
  Future<List<Map<String, dynamic>>> getFilteredIncomeVsExpense(DateTime start, DateTime end, String filterMode) async {
    final db = await _db;
    final List<Map<String, dynamic>> result = [];

    if (filterMode == 'today') {
      final dayStr = DateFormat('yyyy-MM-dd').format(start);
      final slots = [
        {'label': 'Morning', 'start': '${dayStr}T06:00:00', 'end': '${dayStr}T11:59:59'},
        {'label': 'Afternoon', 'start': '${dayStr}T12:00:00', 'end': '${dayStr}T15:59:59'},
        {'label': 'Evening', 'start': '${dayStr}T16:00:00', 'end': '${dayStr}T19:59:59'},
        {'label': 'Night', 'start': '${dayStr}T20:00:00', 'end': '${dayStr}T23:59:59'},
      ];

      for (var slot in slots) {
        final incRes = await db.rawQuery('''
          SELECT COALESCE(SUM(amount), 0.0) as val
          FROM payments
          WHERE payment_date >= ? AND payment_date <= ? AND is_refund = 0
        ''', [slot['start'], slot['end']]);
        final inc = (incRes.first['val'] as num?)?.toDouble() ?? 0.0;

        final gExpRes = await db.rawQuery('''
          SELECT COALESCE(SUM(amount), 0.0) as val
          FROM garage_expenses
          WHERE date >= ? AND date <= ?
        ''', [slot['start'], slot['end']]);
        final sExpRes = await db.rawQuery('''
          SELECT COALESCE(SUM(amount), 0.0) as val
          FROM staff_expenses
          WHERE date >= ? AND date <= ?
        ''', [slot['start'], slot['end']]);
        final exp = ((gExpRes.first['val'] as num?)?.toDouble() ?? 0.0) + ((sExpRes.first['val'] as num?)?.toDouble() ?? 0.0);

        result.add({
          'label': slot['label'],
          'income': inc,
          'expense': exp,
        });
      }

      final totalInc = result.fold<double>(0.0, (sum, i) => sum + (i['income'] as double));
      final totalExp = result.fold<double>(0.0, (sum, i) => sum + (i['expense'] as double));
      if (totalInc == 0 && totalExp == 0) {
        final incRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM payments WHERE payment_date LIKE '$dayStr%' AND is_refund = 0");
        final gExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM garage_expenses WHERE date LIKE '$dayStr%'");
        final sExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM staff_expenses WHERE date LIKE '$dayStr%'");
        final dayInc = (incRes.first['val'] as num?)?.toDouble() ?? 0.0;
        final dayExp = ((gExpRes.first['val'] as num?)?.toDouble() ?? 0.0) + ((sExpRes.first['val'] as num?)?.toDouble() ?? 0.0);
        if (dayInc > 0 || dayExp > 0) {
          result.clear();
          result.add({'label': 'Today', 'income': dayInc, 'expense': dayExp});
        }
      }
    } else if (filterMode == 'thisWeek' || end.difference(start).inDays <= 7) {
      final daysCount = end.difference(start).inDays + 1;
      final totalDays = (daysCount > 0 && daysCount <= 8) ? daysCount : 7;
      for (var i = 0; i < totalDays; i++) {
        final d = start.add(Duration(days: i));
        final dayStr = DateFormat('yyyy-MM-dd').format(d);
        final dayLabel = DateFormat('EEE').format(d);

        final incRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM payments WHERE payment_date LIKE '$dayStr%' AND is_refund = 0");
        final inc = (incRes.first['val'] as num?)?.toDouble() ?? 0.0;

        final gExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM garage_expenses WHERE date LIKE '$dayStr%'");
        final sExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM staff_expenses WHERE date LIKE '$dayStr%'");
        final exp = ((gExpRes.first['val'] as num?)?.toDouble() ?? 0.0) + ((sExpRes.first['val'] as num?)?.toDouble() ?? 0.0);

        result.add({
          'label': dayLabel,
          'date': dayStr,
          'income': inc,
          'expense': exp,
        });
      }
    } else if (filterMode == 'thisMonth' || filterMode == 'lastMonth' || end.difference(start).inDays <= 32) {
      final totalDays = end.difference(start).inDays + 1;
      final step = (totalDays / 4).ceil().clamp(1, 8);

      for (var i = 0; i < totalDays; i += step) {
        final chunkStart = start.add(Duration(days: i));
        var chunkEnd = chunkStart.add(Duration(days: step - 1, hours: 23, minutes: 59, seconds: 59));
        if (chunkEnd.isAfter(end)) chunkEnd = end;

        final label = '${DateFormat('d').format(chunkStart)}-${DateFormat('d MMM').format(chunkEnd)}';
        final startIso = chunkStart.toIso8601String();
        final endIso = chunkEnd.toIso8601String();

        final incRes = await db.rawQuery('''
          SELECT COALESCE(SUM(amount), 0.0) as val
          FROM payments
          WHERE payment_date >= ? AND payment_date <= ? AND is_refund = 0
        ''', [startIso, endIso]);
        final inc = (incRes.first['val'] as num?)?.toDouble() ?? 0.0;

        final gExpRes = await db.rawQuery('''
          SELECT COALESCE(SUM(amount), 0.0) as val
          FROM garage_expenses
          WHERE date >= ? AND date <= ?
        ''', [startIso, endIso]);
        final sExpRes = await db.rawQuery('''
          SELECT COALESCE(SUM(amount), 0.0) as val
          FROM staff_expenses
          WHERE date >= ? AND date <= ?
        ''', [startIso, endIso]);
        final exp = ((gExpRes.first['val'] as num?)?.toDouble() ?? 0.0) + ((sExpRes.first['val'] as num?)?.toDouble() ?? 0.0);

        result.add({
          'label': label,
          'income': inc,
          'expense': exp,
        });
      }
    } else {
      final monthsCount = ((end.year - start.year) * 12 + end.month - start.month) + 1;
      final safeCount = monthsCount.clamp(1, 12);
      for (var i = 0; i < safeCount; i++) {
        final mDate = DateTime(start.year, start.month + i, 1);
        final mStr = DateFormat('yyyy-MM').format(mDate);
        final mLabel = DateFormat('MMM').format(mDate);

        final incRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM payments WHERE payment_date LIKE '$mStr%' AND is_refund = 0");
        final inc = (incRes.first['val'] as num?)?.toDouble() ?? 0.0;

        final gExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM garage_expenses WHERE date LIKE '$mStr%'");
        final sExpRes = await db.rawQuery("SELECT COALESCE(SUM(amount), 0.0) as val FROM staff_expenses WHERE date LIKE '$mStr%'");
        final exp = ((gExpRes.first['val'] as num?)?.toDouble() ?? 0.0) + ((sExpRes.first['val'] as num?)?.toDouble() ?? 0.0);

        result.add({
          'label': mLabel,
          'income': inc,
          'expense': exp,
        });
      }
    }

    return result;
  }

  /// Graph 4: Payment Collection by Method (Optional Date Range)
  Future<List<Map<String, dynamic>>> getPaymentCollectionByMethod([DateTime? start, DateTime? end]) async {
    final db = await _db;
    if (start != null && end != null) {
      final startStr = start.toIso8601String();
      final endStr = end.toIso8601String();
      final res = await db.rawQuery('''
        SELECT payment_method, COALESCE(SUM(amount), 0.0) as total_amount
        FROM payments
        WHERE payment_date >= ? AND payment_date <= ? AND is_refund = 0
        GROUP BY payment_method
        ORDER BY total_amount DESC
      ''', [startStr, endStr]);
      if (res.isNotEmpty) return res;
    }
    final res = await db.rawQuery('''
      SELECT payment_method, COALESCE(SUM(amount), 0.0) as total_amount
      FROM payments
      WHERE is_refund = 0
      GROUP BY payment_method
      ORDER BY total_amount DESC
    ''');
    return res;
  }

  /// Graph 5: Jobs Trend by Status (Optional Date Range)
  Future<List<Map<String, dynamic>>> getJobsByStatus([DateTime? start, DateTime? end]) async {
    final db = await _db;
    if (start != null && end != null) {
      final startStr = start.toIso8601String();
      final endStr = end.toIso8601String();
      final res = await db.rawQuery('''
        SELECT status, COUNT(*) as count
        FROM jobs
        WHERE receiving_date >= ? AND receiving_date <= ?
        GROUP BY status
      ''', [startStr, endStr]);
      if (res.isNotEmpty) return res;
    }
    final res = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM jobs
      GROUP BY status
    ''');
    return res;
  }

  /// Graph 6: Staff Attendance Overview (Last 30 Days)
  Future<Map<String, int>> getAttendanceOverview30Days() async {
    final db = await _db;
    final thirtyDaysAgo = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
    final res = await db.rawQuery('''
      SELECT status, COUNT(*) as cnt
      FROM attendance
      WHERE date >= ?
      GROUP BY status
    ''', [thirtyDaysAgo]);

    final Map<String, int> overview = {'Present': 0, 'Absent': 0, 'Half Day': 0, 'Leave': 0};
    for (final row in res) {
      final st = row['status'] as String;
      final cnt = row['cnt'] as int;
      overview[st] = cnt;
    }
    return overview;
  }

  /// Graph 7: Inventory Quantity Overview (Top items by stock)
  Future<List<Map<String, dynamic>>> getInventoryStockDistribution() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT item_name, current_quantity, unit
      FROM inventory_items
      WHERE is_deleted = 0 AND is_active = 1
      ORDER BY current_quantity DESC
      LIMIT 8
    ''');
    return res;
  }

  /// Graph 8: Outstanding Balance by Customer (Top debtors)
  Future<List<Map<String, dynamic>>> getTopOutstandingCustomers() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT c.name as customer_name, COALESCE(SUM(inv.remaining_amount), 0.0) as outstanding
      FROM invoices inv
      INNER JOIN customers c ON inv.customer_id = c.id
      WHERE inv.status != 'Cancelled' AND inv.remaining_amount > 0
      GROUP BY c.id
      ORDER BY outstanding DESC
      LIMIT 6
    ''');
    return res;
  }

  // Reports data queries
  Future<List<Map<String, dynamic>>> getReportData(String reportType, {DateTime? startDate, DateTime? endDate}) async {
    final db = await _db;
    final startStr = startDate?.toIso8601String() ?? '1970-01-01';
    final endStr = endDate?.toIso8601String() ?? '2099-12-31';

    switch (reportType) {
      case 'customers':
        return await db.rawQuery('SELECT id, name, phone, address, registration_date, status, notes FROM customers WHERE is_deleted = 0 ORDER BY name ASC');
      case 'vehicles':
        return await db.rawQuery('''
          SELECT v.registration_number, v.vehicle_name, v.model, v.model_year, v.color, v.current_odometer, c.name as customer_name, c.phone as customer_phone
          FROM vehicles v
          INNER JOIN customers c ON v.customer_id = c.id
          WHERE v.is_deleted = 0
          ORDER BY v.vehicle_name ASC
        ''');
      case 'service_history':
        return await db.rawQuery('''
          SELECT sh.date, v.registration_number, v.vehicle_name, c.name as customer_name, sh.service_description, sh.odometer, sh.amount, sh.payment_status, sh.staff_names
          FROM vehicle_service_history sh
          INNER JOIN vehicles v ON sh.vehicle_id = v.id
          INNER JOIN customers c ON sh.customer_id = c.id
          WHERE sh.date BETWEEN ? AND ?
          ORDER BY sh.date DESC
        ''', [startStr, endStr]);
      case 'inspections':
        return await db.rawQuery('''
          SELECT i.inspection_date, v.registration_number, v.vehicle_name, c.name as customer_name, i.inspector_name, i.status, i.notes
          FROM inspections i
          INNER JOIN vehicles v ON i.vehicle_id = v.id
          INNER JOIN customers c ON i.customer_id = c.id
          WHERE i.inspection_date BETWEEN ? AND ?
          ORDER BY i.inspection_date DESC
        ''', [startStr, endStr]);
      case 'staff':
        return await db.rawQuery('''
          SELECT name, father_name, cnic, phone, designation, salary_type, basic_salary, commission_rate, joining_date, status
          FROM staff
          WHERE is_deleted = 0
          ORDER BY name ASC
        ''');
      case 'attendance':
        return await db.rawQuery('''
          SELECT a.date, s.name as staff_name, s.designation, a.status, a.check_in_time, a.check_out_time, a.notes
          FROM attendance a
          INNER JOIN staff s ON a.staff_id = s.id
          WHERE a.date BETWEEN ? AND ?
          ORDER BY a.date DESC, s.name ASC
        ''', [startStr, endStr]);
      case 'salaries':
        return await db.rawQuery('''
          SELECT sal.pay_period, s.name as staff_name, sal.salary_type, sal.basic_salary, sal.present_days, sal.absent_days, sal.gross_salary, sal.net_salary, sal.paid_amount, sal.remaining_amount, sal.status
          FROM salaries sal
          INNER JOIN staff s ON sal.staff_id = s.id
          ORDER BY sal.pay_period DESC, s.name ASC
        ''');
      case 'staff_expenses':
        return await db.rawQuery('''
          SELECT se.date, s.name as staff_name, se.category, se.description, se.amount, se.payment_method, se.vendor_details, se.reference
          FROM staff_expenses se
          INNER JOIN staff s ON se.staff_id = s.id
          WHERE se.date BETWEEN ? AND ?
          ORDER BY se.date DESC
        ''', [startStr, endStr]);
      case 'garage_expenses':
        return await db.rawQuery('SELECT date, category, description, amount, payment_method, vendor_name, vendor_company, vendor_contact, vendor_invoice_ref FROM garage_expenses WHERE date BETWEEN ? AND ? ORDER BY date DESC', [startStr, endStr]);
      case 'vendor_expenses':
        return await db.rawQuery('''
          SELECT vendor_name, vendor_company, COUNT(*) as expense_count, COALESCE(SUM(amount), 0.0) as total_spent
          FROM garage_expenses
          WHERE date BETWEEN ? AND ? AND vendor_name IS NOT NULL AND vendor_name != ''
          GROUP BY vendor_name
          ORDER BY total_spent DESC
        ''', [startStr, endStr]);
      case 'inventory':
        return await db.rawQuery('SELECT item_name, current_quantity, unit, brand, purchase_price, (current_quantity * purchase_price) as stock_value, purchase_date FROM inventory_items WHERE is_deleted = 0 ORDER BY item_name ASC');
      case 'inventory_transactions':
        return await db.rawQuery('''
          SELECT it.date_time, ii.item_name, it.transaction_type, it.previous_quantity, it.quantity_change, it.new_quantity, it.user_name, it.reason_notes, it.vendor_reference
          FROM inventory_transactions it
          INNER JOIN inventory_items ii ON it.item_id = ii.id
          WHERE it.date_time BETWEEN ? AND ?
          ORDER BY it.date_time DESC
        ''', [startStr, endStr]);
      case 'invoices':
        return await db.rawQuery('''
          SELECT inv.invoice_number, inv.date, c.name as customer_name, v.registration_number, inv.subtotal, inv.discount, inv.tax_amount, inv.grand_total, inv.paid_amount, inv.remaining_amount, inv.status
          FROM invoices inv
          INNER JOIN customers c ON inv.customer_id = c.id
          INNER JOIN vehicles v ON inv.vehicle_id = v.id
          WHERE inv.date BETWEEN ? AND ?
          ORDER BY inv.date DESC
        ''', [startStr, endStr]);
      case 'payments':
        return await db.rawQuery('''
          SELECT p.payment_date, inv.invoice_number, c.name as customer_name, p.amount, p.payment_method, p.reference_number, p.is_refund, p.notes
          FROM payments p
          INNER JOIN invoices inv ON p.invoice_id = inv.id
          INNER JOIN customers c ON p.customer_id = c.id
          WHERE p.payment_date BETWEEN ? AND ?
          ORDER BY p.payment_date DESC
        ''', [startStr, endStr]);
      case 'outstanding_balances':
        return await db.rawQuery('''
          SELECT c.name as customer_name, c.phone as customer_phone, COUNT(inv.id) as unpaid_invoices_count, COALESCE(SUM(inv.grand_total), 0.0) as total_invoiced, COALESCE(SUM(inv.paid_amount), 0.0) as total_paid, COALESCE(SUM(inv.remaining_amount), 0.0) as total_outstanding
          FROM invoices inv
          INNER JOIN customers c ON inv.customer_id = c.id
          WHERE inv.status != 'Cancelled' AND inv.remaining_amount > 0
          GROUP BY c.id
          ORDER BY total_outstanding DESC
        ''');
      case 'income_expense':
      default:
        final inc = await db.rawQuery("SELECT date(payment_date) as record_date, 'Payment Received' as category, amount, payment_method as method, 'Income' as type FROM payments WHERE payment_date BETWEEN ? AND ? AND is_refund = 0", [startStr, endStr]);
        final expG = await db.rawQuery("SELECT date(date) as record_date, category, amount, payment_method as method, 'Garage Expense' as type FROM garage_expenses WHERE date BETWEEN ? AND ?", [startStr, endStr]);
        final expS = await db.rawQuery("SELECT date(date) as record_date, category, amount, payment_method as method, 'Staff Expense' as type FROM staff_expenses WHERE date BETWEEN ? AND ?", [startStr, endStr]);
        return [...inc, ...expG, ...expS];
    }
  }
}
