import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../../core/services/audit_service.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<List<ExpenseModel>> getExpenses({
    String? search,
    String? categoryFilter,
    String? startDate,
    String? endDate,
  }) async {
    final db = await _dbHelper.database;
    String query = 'SELECT * FROM ${DbTables.expenses}';

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR description LIKE ? OR notes LIKE ?)');
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (categoryFilter != null && categoryFilter != 'All') {
      whereClauses.add('category = ?');
      whereArgs.add(categoryFilter);
    }

    if (startDate != null && endDate != null) {
      whereClauses.add('expense_date BETWEEN ? AND ?');
      whereArgs.addAll([startDate, endDate]);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY expense_date DESC, id DESC';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<int> addExpense(ExpenseModel expense) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final map = expense.toMap();
    map.remove('id');
    map['created_at'] = now;

    final id = await db.insert(DbTables.expenses, map);

    await AuditService.log(
      activityType: 'Expense Added',
      description: 'Expense "${expense.title}" of Rs. ${expense.amount} (${expense.category}) recorded.',
      recordId: id,
    );

    return id;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await _dbHelper.database;
    final map = expense.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();

    await db.update(
      DbTables.expenses,
      map,
      where: 'id = ?',
      whereArgs: [expense.id],
    );

    await AuditService.log(
      activityType: 'Expense Updated',
      description: 'Expense ID ${expense.id} details updated.',
      recordId: expense.id,
    );
  }

  Future<void> deleteExpense(int id, String title) async {
    final db = await _dbHelper.database;
    await db.delete(DbTables.expenses, where: 'id = ?', whereArgs: [id]);

    await AuditService.log(
      activityType: 'Expense Deleted',
      description: 'Expense "$title" (ID $id) deleted.',
      recordId: id,
    );
  }

  /// Get category-wise breakdown for a date range
  Future<Map<String, double>> getCategoryWiseExpenses(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT category, SUM(amount) as total
      FROM ${DbTables.expenses}
      WHERE expense_date BETWEEN ? AND ?
      GROUP BY category
      ORDER BY total DESC
    ''';

    final results = await db.rawQuery(query, [startDate, endDate]);
    final Map<String, double> categoryMap = {};
    for (final row in results) {
      final category = (row['category'] as String?) ?? 'Other';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      categoryMap[category] = total;
    }
    return categoryMap;
  }
}
