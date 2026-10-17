import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/inventory_item_model.dart';
import 'settings_repository.dart';

class InventoryRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<InventoryItemModel>> getItems({String? searchQuery, bool activeOnly = true}) async {
    final db = await _db;
    String whereClause = 'is_deleted = 0';
    final List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause += ' AND is_active = 1';
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      whereClause += ' AND (LOWER(item_name) LIKE ? OR LOWER(brand) LIKE ?)';
      whereArgs.addAll([q, q]);
    }

    final maps = await db.query(
      'inventory_items',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'item_name ASC',
    );

    return maps.map((m) {
      return InventoryItemModel(
        id: m['id'] as String,
        businessId: 'local',
        name: m['item_name'] as String,
        brand: m['brand'] as String? ?? '',
        unit: m['unit'] as String,
        quantity: (m['current_quantity'] as num).toDouble(),
        unitCost: (m['purchase_price'] as num).toDouble(),
        unitPrice: (m['purchase_price'] as num).toDouble(), // Compatible with model
        description: m['description'] as String?,
        notes: m['notes'] as String?,
        purchaseDate: m['purchase_date'] != null ? DateTime.tryParse(m['purchase_date'] as String) : null,
        isActive: (m['is_active'] as int? ?? 1) == 1,
        isDeleted: (m['is_deleted'] as int? ?? 0) == 1,
        createdAt: DateTime.tryParse(m['created_at'] as String) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(m['updated_at'] as String) ?? DateTime.now(),
      );
    }).toList();
  }

  Future<InventoryItemModel?> getItemById(String id) async {
    final db = await _db;
    final maps = await db.query('inventory_items', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final m = maps.first;

    return InventoryItemModel(
      id: m['id'] as String,
      businessId: 'local',
      name: m['item_name'] as String,
      brand: m['brand'] as String? ?? '',
      unit: m['unit'] as String,
      quantity: (m['current_quantity'] as num).toDouble(),
      unitCost: (m['purchase_price'] as num).toDouble(),
      unitPrice: (m['purchase_price'] as num).toDouble(),
      description: m['description'] as String?,
      notes: m['notes'] as String?,
      purchaseDate: m['purchase_date'] != null ? DateTime.tryParse(m['purchase_date'] as String) : null,
      isActive: (m['is_active'] as int? ?? 1) == 1,
      isDeleted: (m['is_deleted'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(m['created_at'] as String) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updated_at'] as String) ?? DateTime.now(),
    );
  }

  Future<String> saveItem({
    String? id,
    required String itemName,
    double currentQuantity = 0,
    String? brand,
    required String unit,
    double purchasePrice = 0,
    DateTime? purchaseDate,
    String? description,
    String? notes,
  }) async {
    final db = await _db;
    final itemId = id ?? 'itm_${const Uuid().v4().substring(0, 8)}';
    final now = DateTime.now().toIso8601String();
    final pDateStr = purchaseDate?.toIso8601String() ?? now;

    await db.transaction((txn) async {
      final existing = await txn.query('inventory_items', where: 'id = ?', whereArgs: [itemId]);
      if (existing.isEmpty) {
        // Insert new item
        await txn.insert('inventory_items', {
          'id': itemId,
          'item_name': itemName.trim(),
          'current_quantity': currentQuantity >= 0 ? currentQuantity : 0,
          'brand': brand?.trim() ?? '',
          'unit': unit.trim(),
          'purchase_price': purchasePrice >= 0 ? purchasePrice : 0,
          'purchase_date': pDateStr,
          'description': description?.trim() ?? '',
          'notes': notes?.trim() ?? '',
          'is_active': 1,
          'is_deleted': 0,
          'created_at': now,
          'updated_at': now,
        });

        // Record Initial Stock Transaction
        if (currentQuantity > 0) {
          await txn.insert('inventory_transactions', {
            'id': 'tx_${const Uuid().v4().substring(0, 8)}',
            'item_id': itemId,
            'previous_quantity': 0.0,
            'quantity_change': currentQuantity,
            'new_quantity': currentQuantity,
            'transaction_type': 'Initial',
            'date_time': now,
            'user_name': 'Admin',
            'reason_notes': 'Initial stock registration',
            'created_at': now,
          });
        }
      } else {
        // Edit existing item metadata (protecting quantity so it's changed only via transactions)
        await txn.update(
          'inventory_items',
          {
            'item_name': itemName.trim(),
            'brand': brand?.trim() ?? '',
            'unit': unit.trim(),
            'purchase_price': purchasePrice >= 0 ? purchasePrice : 0,
            'purchase_date': pDateStr,
            'description': description?.trim() ?? '',
            'notes': notes?.trim() ?? '',
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [itemId],
        );
      }
    });

    return itemId;
  }

  /// Atomically adjust stock (increase or decrease) with full transaction log & negative quantity guard
  Future<void> adjustStock({
    required String itemId,
    required double changeAmount, // Positive for increase, negative for deduction
    required String transactionType, // Purchase, Job Usage, Adjustment, Return
    required String reasonNotes,
    String? userName,
    String? jobId,
    String? vendorReference,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final res = await txn.query('inventory_items', where: 'id = ?', whereArgs: [itemId]);
      if (res.isEmpty) throw Exception('Item not found');

      final current = (res.first['current_quantity'] as num).toDouble();
      final newQuantity = current + changeAmount;

      if (newQuantity < 0) {
        throw Exception('Insufficient stock. Current: $current, requested change: $changeAmount');
      }

      // Update current quantity
      await txn.update(
        'inventory_items',
        {
          'current_quantity': newQuantity,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );

      // Record transaction
      await txn.insert('inventory_transactions', {
        'id': 'tx_${const Uuid().v4().substring(0, 8)}',
        'item_id': itemId,
        'previous_quantity': current,
        'quantity_change': changeAmount,
        'new_quantity': newQuantity,
        'transaction_type': transactionType,
        'date_time': now,
        'user_name': userName ?? 'User',
        'job_id': jobId ?? '',
        'vendor_reference': vendorReference ?? '',
        'reason_notes': reasonNotes,
        'created_at': now,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getItemTransactions(String itemId) async {
    final db = await _db;
    return await db.query(
      'inventory_transactions',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'date_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions({String? startDate, String? endDate}) async {
    final db = await _db;
    String sql = '''
      SELECT t.*, i.item_name, i.brand, i.unit
      FROM inventory_transactions t
      INNER JOIN inventory_items i ON t.item_id = i.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];
    if (startDate != null && endDate != null) {
      sql += ' AND t.date_time BETWEEN ? AND ?';
      args.addAll([startDate, endDate]);
    }
    sql += ' ORDER BY t.date_time DESC';
    return await db.rawQuery(sql, args);
  }

  Future<void> deleteItem(String id, {bool softDelete = true}) async {
    final db = await _db;
    if (softDelete) {
      await db.update('inventory_items', {'is_deleted': 1, 'is_active': 0, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    } else {
      await db.delete('inventory_items', where: 'id = ?', whereArgs: [id]);
    }
  }

  /// Inventory Dashboard Metrics (Real SQLite calculations)
  Future<Map<String, dynamic>> getInventoryDashboardMetrics() async {
    final db = await _db;
    final threshold = await SettingsRepository().getLowStockThreshold();

    final allItems = await db.rawQuery('''
      SELECT COUNT(*) as total_items,
             COALESCE(SUM(current_quantity * purchase_price), 0.0) as total_val
      FROM inventory_items
      WHERE is_deleted = 0 AND is_active = 1
    ''');

    final outOfStockRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM inventory_items
      WHERE is_deleted = 0 AND is_active = 1 AND current_quantity <= 0
    ''');

    final lowStockRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM inventory_items
      WHERE is_deleted = 0 AND is_active = 1 AND current_quantity > 0 AND current_quantity <= ?
    ''', [threshold]);

    return {
      'total_items': Sqflite.firstIntValue(allItems) ?? 0,
      'total_purchase_value': (allItems.first['total_val'] as num?)?.toDouble() ?? 0.0,
      'out_of_stock': Sqflite.firstIntValue(outOfStockRes) ?? 0,
      'low_stock': Sqflite.firstIntValue(lowStockRes) ?? 0,
      'threshold': threshold,
    };
  }

  Future<Map<String, dynamic>> getInventoryDashboard() => getInventoryDashboardMetrics();
  Future<List<Map<String, dynamic>>> getStockTransactions(String itemId) => getItemTransactions(itemId);
}
