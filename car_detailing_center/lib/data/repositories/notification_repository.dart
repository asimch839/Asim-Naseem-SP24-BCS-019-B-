import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'settings_repository.dart';

class NotificationRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<Map<String, dynamic>>> getNotifications({bool unreadOnly = false}) async {
    final db = await _db;
    String sql = 'SELECT * FROM notifications';
    if (unreadOnly) {
      sql += ' WHERE is_read = 0';
    }
    sql += ' ORDER BY date_time DESC LIMIT 50';
    return await db.rawQuery(sql);
  }

  Future<int> getUnreadCount() async {
    final db = await _db;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM notifications WHERE is_read = 0');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> markAsRead(String id) async {
    final db = await _db;
    await db.update('notifications', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAllAsRead() async {
    final db = await _db;
    await db.update('notifications', {'is_read': 1});
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.insert('notifications', {
      'id': 'notif_${const Uuid().v4().substring(0, 8)}',
      'title': title,
      'message': message,
      'type': type,
      'related_id': relatedId ?? '',
      'is_read': 0,
      'date_time': now,
      'created_at': now,
    });
  }

  /// Automatically scans SQLite database and generates fresh local reminders
  Future<void> refreshReminders() async {
    final db = await _db;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Check Low Stock / Out of Stock
    final threshold = await SettingsRepository().getLowStockThreshold();
    final stockItems = await db.rawQuery('''
      SELECT id, item_name, current_quantity, unit
      FROM inventory_items
      WHERE is_deleted = 0 AND is_active = 1 AND current_quantity <= ?
    ''', [threshold]);

    for (final itm in stockItems) {
      final qty = (itm['current_quantity'] as num).toDouble();
      final name = itm['item_name'] as String;
      final unit = itm['unit'] as String;

      final existing = await db.query(
        'notifications',
        where: 'type = ? AND related_id = ? AND date_time LIKE ?',
        whereArgs: [qty <= 0 ? 'out_stock' : 'low_stock', itm['id'], '$todayStr%'],
      );

      if (existing.isEmpty) {
        await addNotification(
          title: qty <= 0 ? 'Out of Stock Alert' : 'Low Stock Warning',
          message: qty <= 0
              ? '$name is completely out of stock!'
              : '$name is low on stock ($qty $unit remaining).',
          type: qty <= 0 ? 'out_stock' : 'low_stock',
          relatedId: itm['id'] as String,
        );
      }
    }

    // 2. Check Vehicle Delivery Due
    final jobsDue = await db.rawQuery('''
      SELECT j.id, j.job_number, v.vehicle_name, v.registration_number
      FROM jobs j
      INNER JOIN vehicles v ON j.vehicle_id = v.id
      WHERE (j.expected_delivery_date LIKE '$todayStr%' OR j.status = 'Ready for Delivery')
        AND j.status NOT IN ('Delivered', 'Cancelled')
    ''');

    for (final j in jobsDue) {
      final existing = await db.query(
        'notifications',
        where: 'type = ? AND related_id = ? AND date_time LIKE ?',
        whereArgs: ['delivery_due', j['id'], '$todayStr%'],
      );

      if (existing.isEmpty) {
        await addNotification(
          title: 'Vehicle Delivery Due',
          message: 'Job #${j['job_number']} for ${j['vehicle_name']} (${j['registration_number']}) is due for delivery.',
          type: 'delivery_due',
          relatedId: j['id'] as String,
        );
      }
    }

    // 3. Outstanding Payments Warning
    final overdueInvoices = await db.rawQuery('''
      SELECT inv.id, inv.invoice_number, inv.remaining_amount, c.name as customer_name
      FROM invoices inv
      INNER JOIN customers c ON inv.customer_id = c.id
      WHERE inv.status != 'Paid' AND inv.status != 'Cancelled' AND inv.remaining_amount > 5000
    ''');

    for (final inv in overdueInvoices) {
      final existing = await db.query(
        'notifications',
        where: 'type = ? AND related_id = ? AND date_time LIKE ?',
        whereArgs: ['payment_due', inv['id'], '$todayStr%'],
      );

      if (existing.isEmpty) {
        await addNotification(
          title: 'Outstanding Payment Due',
          message: 'Invoice #${inv['invoice_number']} for ${inv['customer_name']} has unpaid balance of PKR ${inv['remaining_amount']}.',
          type: 'payment_due',
          relatedId: inv['id'] as String,
        );
      }
    }
  }
}
