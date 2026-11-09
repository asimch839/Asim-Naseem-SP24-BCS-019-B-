import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/expense_model.dart';

class GarageExpenseRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<ExpenseModel>> getExpenses({
    String? category,
    String? startDate,
    String? endDate,
    String? vendorQuery,
    String? searchQuery,
    bool? onlyPending,
  }) async {
    final db = await _db;
    final List<dynamic> args = [];
    String sql = 'SELECT * FROM garage_expenses WHERE 1=1';

    if (onlyPending == true) {
      sql += ' AND isCompleted = 0';
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      sql += ' AND (category = ? OR name = ?)';
      args.addAll([category, category]);
    }
    if (startDate != null && endDate != null) {
      sql += ' AND date BETWEEN ? AND ?';
      args.addAll([startDate, endDate]);
    }
    if (vendorQuery != null && vendorQuery.trim().isNotEmpty) {
      final q = '%${vendorQuery.trim().toLowerCase()}%';
      sql += ' AND (LOWER(vendor_name) LIKE ? OR LOWER(vendor_company) LIKE ?)';
      args.addAll([q, q]);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      sql += ' AND (LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(vendor_name) LIKE ?)';
      args.addAll([q, q, q]);
    }
    sql += ' ORDER BY date DESC';
    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => ExpenseModel.fromMap(m, m['id'] as String)).toList();
  }

  Future<void> saveExpense(ExpenseModel expense) async {
    final db = await _db;
    final expId = expense.id.isNotEmpty
        ? expense.id
        : 'gexp_${const Uuid().v4().substring(0, 8)}';
    final data = expense.toMap();
    data['id'] = expId;
    await db.insert(
      'garage_expenses',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markCompleted(String expenseId) async {
    final db = await _db;
    await db.update(
      'garage_expenses',
      {'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await _db;
    await db.delete('garage_expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getUniqueCategories() async {
    final db = await _db;
    final res = await db.rawQuery(
        'SELECT DISTINCT category FROM garage_expenses ORDER BY category ASC');
    return res
        .map((r) => r['category'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
  }
}
