import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../models/activity_log_model.dart';

class HistorySummaryData {
  final double totalRentCollected;
  final double totalPendingRent;
  final double totalExpenses;
  final double netIncome;
  final int totalPaymentsCount;
  final int totalAdmissionsCount;
  final int studentsLeftCount;
  final int partialPaymentsCount;

  HistorySummaryData({
    required this.totalRentCollected,
    required this.totalPendingRent,
    required this.totalExpenses,
    required this.netIncome,
    required this.totalPaymentsCount,
    required this.totalAdmissionsCount,
    required this.studentsLeftCount,
    required this.partialPaymentsCount,
  });
}

class HistoryRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  /// Fetch unified historical activity logs with joins and multiple filters
  Future<List<ActivityLogModel>> getHistoricalLogs({
    required String startDateTime,
    required String endDateTime,
    String? search,
    String? activityTypeFilter,
    int? studentId,
  }) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT al.*, s.full_name as student_name, s.student_id_code, r.room_number
      FROM ${DbTables.activityLogs} al
      LEFT JOIN ${DbTables.students} s ON al.student_id = s.id
      LEFT JOIN ${DbTables.rooms} r ON s.current_room_id = r.id
      WHERE al.created_at BETWEEN ? AND ?
    ''';

    final List<dynamic> whereArgs = [startDateTime, endDateTime];

    if (search != null && search.trim().isNotEmpty) {
      query += ' AND (al.description LIKE ? OR al.activity_type LIKE ? OR al.username LIKE ? OR s.full_name LIKE ? OR s.student_id_code LIKE ?)';
      whereArgs.addAll(['%$search%', '%$search%', '%$search%', '%$search%', '%$search%']);
    }

    if (activityTypeFilter != null && activityTypeFilter != 'All') {
      query += ' AND al.activity_type = ?';
      whereArgs.add(activityTypeFilter);
    }

    if (studentId != null) {
      query += ' AND al.student_id = ?';
      whereArgs.add(studentId);
    }

    query += ' ORDER BY al.created_at DESC, al.id DESC';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((m) => ActivityLogModel.fromMap(m)).toList();
  }

  /// Calculate summary KPI cards for the chosen date range
  Future<HistorySummaryData> getSummaryForDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _dbHelper.database;

    // 1. Rent Collected in date range
    final paymentRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as count FROM ${DbTables.payments} WHERE payment_date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    final totalCollected = (paymentRes.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalPaymentsCount = (paymentRes.first['count'] as int?) ?? 0;

    // 2. Expenses in date range
    final expenseRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ${DbTables.expenses} WHERE expense_date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    final totalExpenses = (expenseRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Pending Rent from Rent Records created in this timeframe
    final pendingRes = await db.rawQuery(
      "SELECT COALESCE(SUM(remaining_amount), 0) as total, COUNT(CASE WHEN status = 'Partial' THEN 1 END) as partial_count FROM ${DbTables.rentRecords} WHERE due_date BETWEEN ? AND ?",
      [startDate, endDate],
    );
    final totalPendingRent = (pendingRes.first['total'] as num?)?.toDouble() ?? 0.0;
    final partialCount = (pendingRes.first['partial_count'] as int?) ?? 0;

    // 4. Admissions in date range
    final admRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbTables.admissions} WHERE admission_date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    final admissionsCount = (admRes.first['count'] as int?) ?? 0;

    // 5. Students Left in date range
    final leftRes = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ${DbTables.students} WHERE status = 'Left' AND leaving_date BETWEEN ? AND ?",
      [startDate, endDate],
    );
    final leftCount = (leftRes.first['count'] as int?) ?? 0;

    return HistorySummaryData(
      totalRentCollected: totalCollected,
      totalPendingRent: totalPendingRent,
      totalExpenses: totalExpenses,
      netIncome: totalCollected - totalExpenses,
      totalPaymentsCount: totalPaymentsCount,
      totalAdmissionsCount: admissionsCount,
      studentsLeftCount: leftCount,
      partialPaymentsCount: partialCount,
    );
  }
}
