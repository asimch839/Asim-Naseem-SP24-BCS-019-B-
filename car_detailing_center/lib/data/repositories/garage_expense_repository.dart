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
  }) async {
    final db = await _db;
    String sql = 'SELECT * FROM garage_expenses WHERE 1=1';
    final List<dynamic> args = [];

    if (category != null && category.isNotEmpty && category != 'All') {
      sql += ' AND category = ?';
      args.add(category);
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
      sql += ' AND (LOWER(description) LIKE ? OR LOWER(category) LIKE ? OR LOWER(vendor_name) LIKE ?)';
      args.addAll([q, q, q]);
    }

    sql += ' ORDER BY date DESC';
    final maps = await db.rawQuery(sql, args);

    return maps.map((m) {
      return ExpenseModel(
        id: m['id'] as String,
        businessId: 'local',
        category: m['category'] as String,
        description: m['description'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.tryParse(m['date'] as String) ?? DateTime.now(),
        paymentMethod: m['payment_method'] as String,
        vendorName: m['vendor_name'] as String?,
        vendorCompany: m['vendor_company'] as String?,
        vendorPhone: m['vendor_contact'] as String?,
        vendorAddress: m['vendor_address'] as String?,
        referenceNumber: m['vendor_invoice_ref'] as String?,
        notes: m['notes'] as String?,
        receiptUrl: m['receipt_path'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String) ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> saveExpense(ExpenseModel expense) async {
    final db = await _db;
    final expId = expense.id.isNotEmpty ? expense.id : 'gexp_${const Uuid().v4().substring(0, 8)}';

    await db.insert(
      'garage_expenses',
      {
        'id': expId,
        'category': expense.category.trim(),
        'description': expense.description.trim(),
        'amount': expense.amount,
        'date': expense.date.toIso8601String(),
        'payment_method': expense.paymentMethod,
        'vendor_name': expense.vendorName ?? '',
        'vendor_company': expense.vendorCompany ?? '',
        'vendor_contact': expense.vendorPhone ?? '',
        'vendor_address': expense.vendorAddress ?? '',
        'vendor_invoice_ref': expense.referenceNumber ?? '',
        'receipt_path': expense.receiptUrl ?? '',
        'notes': expense.notes ?? '',
        'created_at': expense.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await _db;
    await db.delete('garage_expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getUniqueCategories() async {
    final db = await _db;
    final res = await db.rawQuery('SELECT DISTINCT category FROM garage_expenses ORDER BY category ASC');
    return res.map((r) => r['category'] as String).where((c) => c.isNotEmpty).toList();
  }
}
