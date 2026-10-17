import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'settings_repository.dart';

class InvoicePaymentRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<String> generateNextInvoiceNumber() async {
    final db = await _db;
    final prefixRes = await db.query('settings', columns: ['value'], where: 'key = ?', whereArgs: ['invoice_prefix']);
    final prefix = prefixRes.isNotEmpty ? prefixRes.first['value'] as String : 'INV-';

    final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM invoices');
    final count = (Sqflite.firstIntValue(countRes) ?? 0) + 1;
    return '$prefix${count.toString().padLeft(5, '0')}';
  }

  Future<List<Map<String, dynamic>>> getInvoices({
    String? status,
    String? customerId,
    String? startDate,
    String? endDate,
    String? searchQuery,
  }) async {
    final db = await _db;
    String sql = '''
      SELECT inv.*, c.name as customer_name, c.phone as customer_phone, c.address as customer_address,
             v.vehicle_name, v.registration_number, v.color, v.model_year,
             (SELECT COUNT(*) FROM invoice_items WHERE invoice_id = inv.id) as items_count
      FROM invoices inv
      INNER JOIN customers c ON inv.customer_id = c.id
      INNER JOIN vehicles v ON inv.vehicle_id = v.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (status != null && status.isNotEmpty && status != 'All') {
      sql += ' AND inv.status = ?';
      args.add(status);
    }
    if (customerId != null && customerId.isNotEmpty) {
      sql += ' AND inv.customer_id = ?';
      args.add(customerId);
    }
    if (startDate != null && endDate != null) {
      sql += ' AND inv.date BETWEEN ? AND ?';
      args.addAll([startDate, endDate]);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      sql += ' AND (LOWER(inv.invoice_number) LIKE ? OR LOWER(c.name) LIKE ? OR c.phone LIKE ? OR LOWER(v.registration_number) LIKE ?)';
      args.addAll([q, q, q, q]);
    }

    sql += ' ORDER BY inv.date DESC';
    return await db.rawQuery(sql, args);
  }

  Future<Map<String, dynamic>?> getInvoiceDetails(String invoiceId) async {
    final db = await _db;
    final invoices = await db.rawQuery('''
      SELECT inv.*, c.name as customer_name, c.phone as customer_phone, c.address as customer_address,
             v.vehicle_name, v.registration_number, v.color, v.model_year
      FROM invoices inv
      INNER JOIN customers c ON inv.customer_id = c.id
      INNER JOIN vehicles v ON inv.vehicle_id = v.id
      WHERE inv.id = ?
    ''', [invoiceId]);

    if (invoices.isEmpty) return null;

    final invoice = Map<String, dynamic>.from(invoices.first);
    final items = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    final payments = await db.query('payments', where: 'invoice_id = ?', whereArgs: [invoiceId], orderBy: 'payment_date DESC');

    invoice['items'] = items;
    invoice['payments'] = payments;
    return invoice;
  }

  Future<String> saveInvoice({
    String? id,
    String? invoiceNumber,
    required String customerId,
    required String vehicleId,
    String? jobId,
    required DateTime date,
    String? description,
    required List<Map<String, dynamic>> items,
    double discount = 0,
    double? taxRate,
    String? notes,
  }) async {
    final db = await _db;
    final invoiceId = id ?? 'inv_${const Uuid().v4().substring(0, 8)}';
    final invNum = invoiceNumber ?? await generateNextInvoiceNumber();

    // Calculate subtotal from items
    double subtotal = 0;
    for (final itm in items) {
      final qty = (itm['quantity'] as num?)?.toDouble() ?? 1.0;
      final price = (itm['unit_price'] as num?)?.toDouble() ?? 0.0;
      subtotal += (qty * price);
    }

    final rate = taxRate ?? (double.tryParse(await SettingsRepository().getSetting('tax_rate', defaultValue: '0')) ?? 0.0);
    final taxableAmount = (subtotal - discount) > 0 ? (subtotal - discount) : 0.0;
    final taxAmount = (taxableAmount * rate) / 100.0;
    final grandTotal = taxableAmount + taxAmount;

    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Check existing paid amount if editing
      final existing = await txn.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
      double existingPaid = 0;
      if (existing.isNotEmpty) {
        existingPaid = (existing.first['paid_amount'] as num?)?.toDouble() ?? 0.0;
      }

      final remaining = (grandTotal - existingPaid) > 0 ? (grandTotal - existingPaid) : 0.0;
      final status = remaining <= 0 ? 'Paid' : (existingPaid > 0 ? 'Partially Paid' : 'Unpaid');

      await txn.insert(
        'invoices',
        {
          'id': invoiceId,
          'invoice_number': invNum,
          'date': date.toIso8601String(),
          'customer_id': customerId,
          'vehicle_id': vehicleId,
          'job_id': jobId ?? '',
          'description': description ?? '',
          'subtotal': subtotal,
          'discount': discount,
          'tax_rate': rate,
          'tax_amount': taxAmount,
          'grand_total': grandTotal,
          'paid_amount': existingPaid,
          'remaining_amount': remaining,
          'status': status,
          'notes': notes ?? '',
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Re-insert invoice items
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (final itm in items) {
        final itemId = itm['id'] ?? 'inv_item_${const Uuid().v4().substring(0, 8)}';
        final qty = (itm['quantity'] as num?)?.toDouble() ?? 1.0;
        final price = (itm['unit_price'] as num?)?.toDouble() ?? 0.0;
        await txn.insert('invoice_items', {
          'id': itemId,
          'invoice_id': invoiceId,
          'description': itm['description'] ?? 'Detailing Service Item',
          'quantity': qty,
          'unit_price': price,
          'total_price': qty * price,
          'created_at': now,
        });
      }
    });

    return invoiceId;
  }

  // 2. Payments (Full, partial, multiple payments per invoice, recalculation guard)
  Future<String> recordPayment({
    required String invoiceId,
    required String customerId,
    String? vehicleId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? referenceNumber,
    bool isRefund = false,
    String? notes,
  }) async {
    final db = await _db;
    final paymentId = 'pay_${const Uuid().v4().substring(0, 8)}';
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Verify invoice exists
      final invRes = await txn.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
      if (invRes.isEmpty) throw Exception('Invoice not found');

      final inv = invRes.first;
      final currentPaid = (inv['paid_amount'] as num?)?.toDouble() ?? 0.0;
      final grandTotal = (inv['grand_total'] as num?)?.toDouble() ?? 0.0;

      final signedAmount = isRefund ? -amount : amount;
      final newPaid = currentPaid + signedAmount;
      final newRemaining = (grandTotal - newPaid) > 0 ? (grandTotal - newPaid) : 0.0;
      final newStatus = newRemaining <= 0 ? 'Paid' : (newPaid > 0 ? 'Partially Paid' : 'Unpaid');

      // 2. Insert payment record
      await txn.insert('payments', {
        'id': paymentId,
        'invoice_id': invoiceId,
        'customer_id': customerId,
        'vehicle_id': vehicleId ?? inv['vehicle_id'],
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'payment_method': paymentMethod,
        'reference_number': referenceNumber ?? '',
        'is_refund': isRefund ? 1 : 0,
        'notes': notes ?? '',
        'created_at': now,
      });

      // 3. Atomically update invoice
      await txn.update(
        'invoices',
        {
          'paid_amount': newPaid,
          'remaining_amount': newRemaining,
          'status': newStatus,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    });

    return paymentId;
  }

  Future<List<Map<String, dynamic>>> getPayments({
    String? invoiceId,
    String? customerId,
    String? startDate,
    String? endDate,
    String? searchQuery,
  }) async {
    final db = await _db;
    String sql = '''
      SELECT p.*, inv.invoice_number, c.name as customer_name, c.phone as customer_phone,
             v.vehicle_name, v.registration_number
      FROM payments p
      INNER JOIN invoices inv ON p.invoice_id = inv.id
      INNER JOIN customers c ON p.customer_id = c.id
      LEFT JOIN vehicles v ON p.vehicle_id = v.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (invoiceId != null && invoiceId.isNotEmpty) {
      sql += ' AND p.invoice_id = ?';
      args.add(invoiceId);
    }
    if (customerId != null && customerId.isNotEmpty) {
      sql += ' AND p.customer_id = ?';
      args.add(customerId);
    }
    if (startDate != null && endDate != null) {
      sql += ' AND p.payment_date BETWEEN ? AND ?';
      args.addAll([startDate, endDate]);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      sql += ' AND (LOWER(inv.invoice_number) LIKE ? OR LOWER(c.name) LIKE ? OR LOWER(p.reference_number) LIKE ?)';
      args.addAll([q, q, q]);
    }

    sql += ' ORDER BY p.payment_date DESC';
    return await db.rawQuery(sql, args);
  }

  Future<void> deleteInvoice(String id) async {
    final db = await _db;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }
}
