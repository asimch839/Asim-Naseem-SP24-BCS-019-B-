import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/vendor_model.dart';

class VendorRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  static const List<String> defaultCategories = [
    'Detailing Chemicals & Shampoos',
    'Polishing & Ceramic Coatings',
    'PPF & Tinting Films',
    'Equipment & Machinery',
    'Microfiber & Accessories',
    'Garage Utilities & Facilities',
    'Spare Parts & Tools',
    'General Supplies',
  ];

  Future<List<VendorModel>> getVendors({
    String? searchQuery,
    String? category,
    String? status,
    bool activeOnly = false,
  }) async {
    final db = await _db;
    String whereClause = 'is_deleted = 0';
    final List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause += " AND status = 'Active'";
    } else if (status != null && status.isNotEmpty && status != 'All') {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      whereClause += ' AND (LOWER(name) LIKE ? OR LOWER(company) LIKE ? OR phone LIKE ? OR LOWER(notes) LIKE ?)';
      whereArgs.addAll([q, q, q, q]);
    }

    final maps = await db.query(
      'vendors',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => VendorModel.fromMap(m)).toList();
  }

  Future<VendorModel?> getVendorById(String id) async {
    final db = await _db;
    final maps = await db.query('vendors', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return VendorModel.fromMap(maps.first);
  }

  Future<String> saveVendor(VendorModel vendor) async {
    final db = await _db;
    final vendorId = vendor.id.isNotEmpty ? vendor.id : 'vnd_${const Uuid().v4().substring(0, 8)}';
    final now = DateTime.now().toIso8601String();

    final toSave = vendor.copyWith(
      updatedAt: DateTime.now(),
    );

    final map = toSave.toMap();
    map['id'] = vendorId;
    if (vendor.id.isEmpty) {
      map['created_at'] = now;
    }

    await db.insert(
      'vendors',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return vendorId;
  }

  Future<void> deleteVendor(String id, {bool softDelete = true}) async {
    final db = await _db;
    if (softDelete) {
      await db.update(
        'vendors',
        {
          'is_deleted': 1,
          'status': 'Inactive',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete('vendors', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<String>> getCategories() async {
    final db = await _db;
    final res = await db.rawQuery('SELECT DISTINCT category FROM vendors WHERE is_deleted = 0 AND category IS NOT NULL');
    final dbCats = res.map((r) => r['category'] as String?).where((c) => c != null && c.isNotEmpty).cast<String>().toList();

    final set = <String>{...defaultCategories, ...dbCats};
    return set.toList();
  }

  /// Get logged expenses associated with this vendor from garage_expenses
  Future<List<Map<String, dynamic>>> getVendorExpenses(String vendorName, {String? company}) async {
    final db = await _db;
    final qName = '%${vendorName.trim().toLowerCase()}%';
    String sql = '''
      SELECT * FROM garage_expenses
      WHERE LOWER(vendor_name) LIKE ?
    ''';
    final args = <dynamic>[qName];

    if (company != null && company.trim().isNotEmpty) {
      sql += ' OR LOWER(vendor_company) LIKE ?';
      args.add('%${company.trim().toLowerCase()}%');
    }

    sql += ' ORDER BY date DESC';
    return await db.rawQuery(sql, args);
  }

  /// Total amount spent with this vendor
  Future<double> getVendorTotalSpend(String vendorName, {String? company}) async {
    final expenses = await getVendorExpenses(vendorName, company: company);
    return expenses.fold<double>(0.0, (acc, item) => acc + ((item['amount'] as num?)?.toDouble() ?? 0.0));
  }

  /// Aggregated metrics for vendor management dashboard
  Future<Map<String, dynamic>> getVendorMetrics() async {
    final db = await _db;

    final counts = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_vendors,
        SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) as active_vendors,
        COALESCE(SUM(current_balance), 0.0) as total_balance
      FROM vendors
      WHERE is_deleted = 0
    ''');

    final totalSpendRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as total_expense
      FROM garage_expenses
      WHERE vendor_name IS NOT NULL AND TRIM(vendor_name) != ''
    ''');

    final first = counts.isNotEmpty ? counts.first : {};
    final spendFirst = totalSpendRes.isNotEmpty ? totalSpendRes.first : {};

    return {
      'total_vendors': (first['total_vendors'] as num?)?.toInt() ?? 0,
      'active_vendors': (first['active_vendors'] as num?)?.toInt() ?? 0,
      'total_balance': (first['total_balance'] as num?)?.toDouble() ?? 0.0,
      'total_spend': (spendFirst['total_expense'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
