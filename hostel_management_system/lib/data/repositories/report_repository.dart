import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../../core/utils/date_formatter.dart';

class DashboardMetrics {
  final int totalStudents;
  final int activeStudents;
  final int totalRooms;
  final int totalBeds;
  final int occupiedBeds;
  final int availableBeds;
  final double occupancyRate;
  final double expectedRent;
  final double rentCollected;
  final double pendingRent;
  final double collectionRate;
  final double totalExpenses;
  final double netIncome;

  DashboardMetrics({
    required this.totalStudents,
    required this.activeStudents,
    required this.totalRooms,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.availableBeds,
    required this.occupancyRate,
    required this.expectedRent,
    required this.rentCollected,
    required this.pendingRent,
    required this.collectionRate,
    required this.totalExpenses,
    required this.netIncome,
  });
}

class ChartDataPoint {
  final String label;
  final double value1; // e.g. Collected / Income
  final double value2; // e.g. Expected / Expense
  final double value3; // e.g. Pending / Net

  ChartDataPoint({
    required this.label,
    required this.value1,
    this.value2 = 0.0,
    this.value3 = 0.0,
  });
}

class ReportRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  /// Fetch live Dashboard KPI numbers for the selected date filter
  Future<DashboardMetrics> getDashboardMetrics(String startDate, String endDate, String currentMonthIso) async {
    final db = await _dbHelper.database;

    // 1. Student counts
    final stuRes = await db.rawQuery(
      "SELECT COUNT(*) as total, COUNT(CASE WHEN status = 'Active' THEN 1 END) as active FROM ${DbTables.students}",
    );
    final totalStudents = (stuRes.first['total'] as int?) ?? 0;
    final activeStudents = (stuRes.first['active'] as int?) ?? 0;

    // 2. Room & Bed counts
    final roomRes = await db.rawQuery('SELECT COUNT(*) as total FROM ${DbTables.rooms}');
    final totalRooms = (roomRes.first['total'] as int?) ?? 0;

    final bedRes = await db.rawQuery(
      '''
      SELECT COUNT(*) as total, 
             COUNT(CASE WHEN bed_status = 'Occupied' OR current_student_id IS NOT NULL THEN 1 END) as occupied
      FROM ${DbTables.beds}
      ''',
    );
    final totalBeds = (bedRes.first['total'] as int?) ?? 0;
    final occupiedBeds = (bedRes.first['occupied'] as int?) ?? 0;
    final availableBeds = (totalBeds - occupiedBeds).clamp(0, totalBeds);
    final occupancyRate = totalBeds > 0 ? (occupiedBeds / totalBeds) * 100 : 0.0;

    // 3. Rent for current period / filtered range
    final rentRecRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(rent_amount), 0) as expected,
             COALESCE(SUM(paid_amount), 0) as paid,
             COALESCE(SUM(remaining_amount), 0) as pending
      FROM ${DbTables.rentRecords}
      WHERE rent_month = ?
      ''',
      [currentMonthIso],
    );
    final expectedRent = (rentRecRes.first['expected'] as num?)?.toDouble() ?? 0.0;
    final pendingRent = (rentRecRes.first['pending'] as num?)?.toDouble() ?? 0.0;

    // Actual payments collected in the selected date range
    final paymentRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ${DbTables.payments} WHERE payment_date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    final rentCollected = (paymentRes.first['total'] as num?)?.toDouble() ?? 0.0;
    final collectionRate = expectedRent > 0 ? (rentCollected / expectedRent) * 100 : 0.0;

    // 4. Expenses in the selected date range
    final expRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ${DbTables.expenses} WHERE expense_date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    final totalExpenses = (expRes.first['total'] as num?)?.toDouble() ?? 0.0;
    final netIncome = rentCollected - totalExpenses;

    return DashboardMetrics(
      totalStudents: totalStudents,
      activeStudents: activeStudents,
      totalRooms: totalRooms,
      totalBeds: totalBeds,
      occupiedBeds: occupiedBeds,
      availableBeds: availableBeds,
      occupancyRate: occupancyRate,
      expectedRent: expectedRent,
      rentCollected: rentCollected,
      pendingRent: pendingRent,
      collectionRate: collectionRate.clamp(0.0, 100.0),
      totalExpenses: totalExpenses,
      netIncome: netIncome,
    );
  }

  /// Get Rent Collection Series for Charts dynamically tailored to the selected date range
  Future<List<ChartDataPoint>> getRentChartData(DateTime fromDate, DateTime toDate) async {
    final db = await _dbHelper.database;
    final int diffDays = toDate.difference(fromDate).inDays.abs() + 1;

    if (diffDays <= 1) {
      // 1. Single Day / Today: Break down by 4 time intervals (Morning, Afternoon, Evening, Night)
      final startIso = DateFormatter.toIsoDate(fromDate);
      final paymentRes = await db.rawQuery('''
        SELECT amount, created_at, payment_date
        FROM ${DbTables.payments}
        WHERE payment_date = ?
      ''', [startIso]);

      final currentMonthIso = DateFormatter.toIsoMonth(fromDate);
      final monthStats = await db.rawQuery('''
        SELECT COALESCE(SUM(rent_amount), 0) as expected,
               COALESCE(SUM(remaining_amount), 0) as pending
        FROM ${DbTables.rentRecords}
        WHERE rent_month = ?
      ''', [currentMonthIso]);
      final double totalMonthExpected = (monthStats.first['expected'] as num?)?.toDouble() ?? 0.0;
      final double dailyTarget = totalMonthExpected > 0 ? (totalMonthExpected / 30.0) : 0.0;
      final double slotTarget = dailyTarget / 4.0;

      double morningColl = 0.0, afternoonColl = 0.0, eveningColl = 0.0, nightColl = 0.0;
      for (final r in paymentRes) {
        final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = (r['created_at'] as String?) ?? '';
        int hour = 12;
        if (createdAt.contains('T')) {
          final timePart = createdAt.split('T')[1];
          hour = int.tryParse(timePart.split(':')[0]) ?? 12;
        }
        if (hour >= 8 && hour < 12) {
          morningColl += amount;
        } else if (hour >= 12 && hour < 16) {
          afternoonColl += amount;
        } else if (hour >= 16 && hour < 20) {
          eveningColl += amount;
        } else {
          nightColl += amount;
        }
      }

      return [
        ChartDataPoint(
          label: 'Morning',
          value1: morningColl,
          value2: slotTarget,
          value3: (slotTarget - morningColl).clamp(0.0, double.infinity),
        ),
        ChartDataPoint(
          label: 'Afternoon',
          value1: afternoonColl,
          value2: slotTarget,
          value3: (slotTarget - afternoonColl).clamp(0.0, double.infinity),
        ),
        ChartDataPoint(
          label: 'Evening',
          value1: eveningColl,
          value2: slotTarget,
          value3: (slotTarget - eveningColl).clamp(0.0, double.infinity),
        ),
        ChartDataPoint(
          label: 'Night',
          value1: nightColl,
          value2: slotTarget,
          value3: (slotTarget - nightColl).clamp(0.0, double.infinity),
        ),
      ];
    } else if (diffDays <= 7) {
      // 2. This Week / <= 7 Days: Day-by-day (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
      final daysList = <DateTime>[];
      DateTime cur = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final end = DateTime(toDate.year, toDate.month, toDate.day);
      while (!cur.isAfter(end) && daysList.length < 7) {
        daysList.add(cur);
        cur = cur.add(const Duration(days: 1));
      }

      final startIso = DateFormatter.toIsoDate(daysList.first);
      final endIso = DateFormatter.toIsoDate(daysList.last);

      final paymentRes = await db.rawQuery('''
        SELECT payment_date, SUM(amount) as collected
        FROM ${DbTables.payments}
        WHERE payment_date BETWEEN ? AND ?
        GROUP BY payment_date
      ''', [startIso, endIso]);

      final Map<String, double> collMap = {};
      for (final r in paymentRes) {
        final d = (r['payment_date'] as String?) ?? '';
        if (d.isNotEmpty) collMap[d] = (r['collected'] as num?)?.toDouble() ?? 0.0;
      }

      final currentMonthIso = DateFormatter.toIsoMonth(fromDate);
      final monthStats = await db.rawQuery('''
        SELECT COALESCE(SUM(rent_amount), 0) as expected
        FROM ${DbTables.rentRecords}
        WHERE rent_month = ?
      ''', [currentMonthIso]);
      final double totalMonthExpected = (monthStats.first['expected'] as num?)?.toDouble() ?? 0.0;
      final double dailyTarget = totalMonthExpected > 0 ? (totalMonthExpected / 30.0) : 0.0;

      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return daysList.map((d) {
        final iso = DateFormatter.toIsoDate(d);
        final coll = collMap[iso] ?? 0.0;
        final dayName = dayNames[d.weekday - 1];
        return ChartDataPoint(
          label: dayName,
          value1: coll,
          value2: dailyTarget,
          value3: (dailyTarget - coll).clamp(0.0, double.infinity),
        );
      }).toList();
    } else if (diffDays <= 31) {
      // 3. This Month / <= 31 Days: Week-by-week
      final startIso = DateFormatter.toIsoDate(fromDate);
      final endIso = DateFormatter.toIsoDate(toDate);
      final currentMonthIso = DateFormatter.toIsoMonth(fromDate);

      final paymentRes = await db.rawQuery('''
        SELECT payment_date, SUM(amount) as collected
        FROM ${DbTables.payments}
        WHERE payment_date BETWEEN ? AND ?
        GROUP BY payment_date
      ''', [startIso, endIso]);

      final Map<String, double> collMap = {};
      for (final r in paymentRes) {
        final d = (r['payment_date'] as String?) ?? '';
        if (d.isNotEmpty) collMap[d] = (r['collected'] as num?)?.toDouble() ?? 0.0;
      }

      final monthStats = await db.rawQuery('''
        SELECT COALESCE(SUM(rent_amount), 0) as expected
        FROM ${DbTables.rentRecords}
        WHERE rent_month = ?
      ''', [currentMonthIso]);
      final double totalMonthExpected = (monthStats.first['expected'] as num?)?.toDouble() ?? 0.0;
      final double weeklyTarget = totalMonthExpected > 0 ? (totalMonthExpected / 4.0) : 0.0;

      final weekBuckets = [
        {'label': 'Week 1', 'start': 1, 'end': 7},
        {'label': 'Week 2', 'start': 8, 'end': 14},
        {'label': 'Week 3', 'start': 15, 'end': 21},
        {'label': 'Week 4', 'start': 22, 'end': 28},
        if (toDate.day > 28) {'label': 'Week 5', 'start': 29, 'end': toDate.day},
      ];

      return weekBuckets.map((bucket) {
        double weekColl = 0.0;
        final startDay = bucket['start'] as int;
        final endDay = bucket['end'] as int;
        for (int d = startDay; d <= endDay; d++) {
          final dayDate = DateTime(fromDate.year, fromDate.month, d);
          final iso = DateFormatter.toIsoDate(dayDate);
          weekColl += collMap[iso] ?? 0.0;
        }
        return ChartDataPoint(
          label: bucket['label'] as String,
          value1: weekColl,
          value2: weeklyTarget,
          value3: (weeklyTarget - weekColl).clamp(0.0, double.infinity),
        );
      }).toList();
    } else {
      // 4. This Year / Custom > 31 Days: Group by Months
      final startMonth = DateFormatter.toIsoMonth(fromDate);
      final endMonth = DateFormatter.toIsoMonth(toDate);

      final results = await db.rawQuery('''
        SELECT rr.rent_month,
               COALESCE(SUM(rr.rent_amount), 0) as expected,
               COALESCE(SUM(rr.paid_amount), 0) as collected,
               COALESCE(SUM(rr.remaining_amount), 0) as pending
        FROM ${DbTables.rentRecords} rr
        WHERE rr.rent_month BETWEEN ? AND ?
        GROUP BY rr.rent_month
        ORDER BY rr.rent_month ASC
      ''', [startMonth, endMonth]);

      if (results.isEmpty) {
        return getMonthlyRentChartData();
      }

      return results.map((row) {
        final month = (row['rent_month'] as String?) ?? '';
        return ChartDataPoint(
          label: month,
          value1: (row['collected'] as num?)?.toDouble() ?? 0.0,
          value2: (row['expected'] as num?)?.toDouble() ?? 0.0,
          value3: (row['pending'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    }
  }

  /// Get Income vs Expense Series dynamically tailored to the selected date range
  Future<List<ChartDataPoint>> getIncomeVsExpenseChartData(DateTime fromDate, DateTime toDate) async {
    final db = await _dbHelper.database;
    final int diffDays = toDate.difference(fromDate).inDays.abs() + 1;

    if (diffDays <= 1) {
      // 1. Single Day / Today: 4 Time slots (Morning, Afternoon, Evening, Night)
      final startIso = DateFormatter.toIsoDate(fromDate);
      final paymentRes = await db.rawQuery('''
        SELECT amount, created_at FROM ${DbTables.payments} WHERE payment_date = ?
      ''', [startIso]);
      final expenseRes = await db.rawQuery('''
        SELECT amount, created_at FROM ${DbTables.expenses} WHERE expense_date = ?
      ''', [startIso]);

      double morningInc = 0.0, afternoonInc = 0.0, eveningInc = 0.0, nightInc = 0.0;
      for (final r in paymentRes) {
        final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = (r['created_at'] as String?) ?? '';
        int hour = 12;
        if (createdAt.contains('T')) {
          final timePart = createdAt.split('T')[1];
          hour = int.tryParse(timePart.split(':')[0]) ?? 12;
        }
        if (hour >= 8 && hour < 12) {
          morningInc += amt;
        } else if (hour >= 12 && hour < 16) {
          afternoonInc += amt;
        } else if (hour >= 16 && hour < 20) {
          eveningInc += amt;
        } else {
          nightInc += amt;
        }
      }

      double morningExp = 0.0, afternoonExp = 0.0, eveningExp = 0.0, nightExp = 0.0;
      for (final r in expenseRes) {
        final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = (r['created_at'] as String?) ?? '';
        int hour = 12;
        if (createdAt.contains('T')) {
          final timePart = createdAt.split('T')[1];
          hour = int.tryParse(timePart.split(':')[0]) ?? 12;
        }
        if (hour >= 8 && hour < 12) {
          morningExp += amt;
        } else if (hour >= 12 && hour < 16) {
          afternoonExp += amt;
        } else if (hour >= 16 && hour < 20) {
          eveningExp += amt;
        } else {
          nightExp += amt;
        }
      }

      return [
        ChartDataPoint(label: 'Morning', value1: morningInc, value2: morningExp, value3: morningInc - morningExp),
        ChartDataPoint(label: 'Afternoon', value1: afternoonInc, value2: afternoonExp, value3: afternoonInc - afternoonExp),
        ChartDataPoint(label: 'Evening', value1: eveningInc, value2: eveningExp, value3: eveningInc - eveningExp),
        ChartDataPoint(label: 'Night', value1: nightInc, value2: nightExp, value3: nightInc - nightExp),
      ];
    } else if (diffDays <= 7) {
      // 2. This Week / <= 7 Days: Day-by-Day (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
      final daysList = <DateTime>[];
      DateTime cur = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final end = DateTime(toDate.year, toDate.month, toDate.day);
      while (!cur.isAfter(end) && daysList.length < 7) {
        daysList.add(cur);
        cur = cur.add(const Duration(days: 1));
      }

      final startIso = DateFormatter.toIsoDate(daysList.first);
      final endIso = DateFormatter.toIsoDate(daysList.last);

      final paymentRes = await db.rawQuery('''
        SELECT payment_date, SUM(amount) as income
        FROM ${DbTables.payments}
        WHERE payment_date BETWEEN ? AND ?
        GROUP BY payment_date
      ''', [startIso, endIso]);

      final expenseRes = await db.rawQuery('''
        SELECT expense_date, SUM(amount) as expense
        FROM ${DbTables.expenses}
        WHERE expense_date BETWEEN ? AND ?
        GROUP BY expense_date
      ''', [startIso, endIso]);

      final Map<String, double> incMap = {};
      for (final r in paymentRes) {
        final d = (r['payment_date'] as String?) ?? '';
        if (d.isNotEmpty) incMap[d] = (r['income'] as num?)?.toDouble() ?? 0.0;
      }

      final Map<String, double> expMap = {};
      for (final r in expenseRes) {
        final d = (r['expense_date'] as String?) ?? '';
        if (d.isNotEmpty) expMap[d] = (r['expense'] as num?)?.toDouble() ?? 0.0;
      }

      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return daysList.map((d) {
        final iso = DateFormatter.toIsoDate(d);
        final inc = incMap[iso] ?? 0.0;
        final exp = expMap[iso] ?? 0.0;
        final dayName = dayNames[d.weekday - 1];
        return ChartDataPoint(
          label: dayName,
          value1: inc,
          value2: exp,
          value3: inc - exp,
        );
      }).toList();
    } else if (diffDays <= 31) {
      // 3. This Month / <= 31 Days: Week-by-Week (Week 1, Week 2, Week 3, Week 4, Week 5)
      final startIso = DateFormatter.toIsoDate(fromDate);
      final endIso = DateFormatter.toIsoDate(toDate);

      final paymentRes = await db.rawQuery('''
        SELECT payment_date, SUM(amount) as income
        FROM ${DbTables.payments}
        WHERE payment_date BETWEEN ? AND ?
        GROUP BY payment_date
      ''', [startIso, endIso]);

      final expenseRes = await db.rawQuery('''
        SELECT expense_date, SUM(amount) as expense
        FROM ${DbTables.expenses}
        WHERE expense_date BETWEEN ? AND ?
        GROUP BY expense_date
      ''', [startIso, endIso]);

      final Map<String, double> incMap = {};
      for (final r in paymentRes) {
        final d = (r['payment_date'] as String?) ?? '';
        if (d.isNotEmpty) incMap[d] = (r['income'] as num?)?.toDouble() ?? 0.0;
      }

      final Map<String, double> expMap = {};
      for (final r in expenseRes) {
        final d = (r['expense_date'] as String?) ?? '';
        if (d.isNotEmpty) expMap[d] = (r['expense'] as num?)?.toDouble() ?? 0.0;
      }

      final weekBuckets = [
        {'label': 'Week 1', 'start': 1, 'end': 7},
        {'label': 'Week 2', 'start': 8, 'end': 14},
        {'label': 'Week 3', 'start': 15, 'end': 21},
        {'label': 'Week 4', 'start': 22, 'end': 28},
        if (toDate.day > 28) {'label': 'Week 5', 'start': 29, 'end': toDate.day},
      ];

      return weekBuckets.map((bucket) {
        double weekInc = 0.0;
        double weekExp = 0.0;
        final startDay = bucket['start'] as int;
        final endDay = bucket['end'] as int;
        for (int d = startDay; d <= endDay; d++) {
          final dayDate = DateTime(fromDate.year, fromDate.month, d);
          final iso = DateFormatter.toIsoDate(dayDate);
          weekInc += incMap[iso] ?? 0.0;
          weekExp += expMap[iso] ?? 0.0;
        }
        return ChartDataPoint(
          label: bucket['label'] as String,
          value1: weekInc,
          value2: weekExp,
          value3: weekInc - weekExp,
        );
      }).toList();
    } else {
      // 4. This Year / Custom > 31 Days: Group by Months
      final startIso = DateFormatter.toIsoDate(fromDate);
      final endIso = DateFormatter.toIsoDate(toDate);

      final paymentRes = await db.rawQuery('''
        SELECT SUBSTR(payment_date, 1, 7) as month, SUM(amount) as income
        FROM ${DbTables.payments}
        WHERE payment_date BETWEEN ? AND ?
        GROUP BY month
        ORDER BY month ASC
      ''', [startIso, endIso]);

      final expenseRes = await db.rawQuery('''
        SELECT SUBSTR(expense_date, 1, 7) as month, SUM(amount) as expense
        FROM ${DbTables.expenses}
        WHERE expense_date BETWEEN ? AND ?
        GROUP BY month
        ORDER BY month ASC
      ''', [startIso, endIso]);

      final Map<String, double> incMap = {};
      for (final r in paymentRes) {
        final m = (r['month'] as String?) ?? '';
        if (m.isNotEmpty) incMap[m] = (r['income'] as num?)?.toDouble() ?? 0.0;
      }

      final Map<String, double> expMap = {};
      for (final r in expenseRes) {
        final m = (r['month'] as String?) ?? '';
        if (m.isNotEmpty) expMap[m] = (r['expense'] as num?)?.toDouble() ?? 0.0;
      }

      final allMonths = {...incMap.keys, ...expMap.keys}.toList()..sort();
      if (allMonths.isEmpty) {
        return getMonthlyIncomeVsExpenseChartData();
      }

      return allMonths.map((m) {
        final inc = incMap[m] ?? 0.0;
        final exp = expMap[m] ?? 0.0;
        return ChartDataPoint(
          label: m,
          value1: inc,
          value2: exp,
          value3: inc - exp,
        );
      }).toList();
    }
  }

  /// Get Monthly Rent Collection Series for Charts (Last 6-12 Months)
  Future<List<ChartDataPoint>> getMonthlyRentChartData() async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT rr.rent_month,
             COALESCE(SUM(rr.rent_amount), 0) as expected,
             COALESCE(SUM(rr.paid_amount), 0) as collected,
             COALESCE(SUM(rr.remaining_amount), 0) as pending
      FROM ${DbTables.rentRecords} rr
      GROUP BY rr.rent_month
      ORDER BY rr.rent_month ASC
      LIMIT 12
    ''';

    final results = await db.rawQuery(query);
    return results.map((row) {
      final month = (row['rent_month'] as String?) ?? '';
      return ChartDataPoint(
        label: month,
        value1: (row['collected'] as num?)?.toDouble() ?? 0.0, // Collected
        value2: (row['expected'] as num?)?.toDouble() ?? 0.0,  // Expected
        value3: (row['pending'] as num?)?.toDouble() ?? 0.0,   // Pending
      );
    }).toList();
  }

  /// Get Monthly Income vs Expense Series for Charts
  Future<List<ChartDataPoint>> getMonthlyIncomeVsExpenseChartData() async {
    final db = await _dbHelper.database;
    
    // Group payments by month (SUBSTR(payment_date, 1, 7))
    final paymentRes = await db.rawQuery('''
      SELECT SUBSTR(payment_date, 1, 7) as month, SUM(amount) as income
      FROM ${DbTables.payments}
      GROUP BY month
      ORDER BY month ASC
    ''');

    // Group expenses by month
    final expenseRes = await db.rawQuery('''
      SELECT SUBSTR(expense_date, 1, 7) as month, SUM(amount) as expense
      FROM ${DbTables.expenses}
      GROUP BY month
      ORDER BY month ASC
    ''');

    final Map<String, double> incomeMap = {};
    for (final r in paymentRes) {
      final m = (r['month'] as String?) ?? '';
      if (m.isNotEmpty) incomeMap[m] = (r['income'] as num?)?.toDouble() ?? 0.0;
    }

    final Map<String, double> expenseMap = {};
    for (final r in expenseRes) {
      final m = (r['month'] as String?) ?? '';
      if (m.isNotEmpty) expenseMap[m] = (r['expense'] as num?)?.toDouble() ?? 0.0;
    }

    final allMonths = {...incomeMap.keys, ...expenseMap.keys}.toList()..sort();
    
    return allMonths.map((m) {
      final inc = incomeMap[m] ?? 0.0;
      final exp = expenseMap[m] ?? 0.0;
      return ChartDataPoint(
        label: m,
        value1: inc,
        value2: exp,
        value3: inc - exp,
      );
    }).toList();
  }
}
