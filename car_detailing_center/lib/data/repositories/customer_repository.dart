import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/customer_model.dart';
import '../models/vehicle_model.dart';

class CustomerRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<CustomerModel>> getCustomers({String? searchQuery, bool activeOnly = true}) async {
    final db = await _db;
    String whereClause = 'is_deleted = 0';
    List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause += ' AND is_active = 1';
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      whereClause += ' AND (LOWER(name) LIKE ? OR phone LIKE ?)';
      whereArgs.addAll([q, q]);
    }

    final maps = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    // Calculate live outstanding balances and visits
    final List<CustomerModel> result = [];
    for (final map in maps) {
      final customerId = map['id'] as String;
      final balance = await getCustomerOutstandingBalance(customerId);
      final visits = await getCustomerVisitCount(customerId);

      result.add(CustomerModel(
        id: customerId,
        businessId: 'local',
        fullName: map['name'] as String,
        phone: map['phone'] as String,
        address: map['address'] as String?,
        notes: map['notes'] as String?,
        status: map['status'] as String? ?? 'Active',
        totalVisits: visits,
        outstandingBalance: balance,
        createdAt: DateTime.tryParse(map['created_at'] as String) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now(),
        isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      ));
    }
    return result;
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'customers',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final map = maps.first;
    final balance = await getCustomerOutstandingBalance(id);
    final visits = await getCustomerVisitCount(id);

    return CustomerModel(
      id: id,
      businessId: 'local',
      fullName: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'Active',
      totalVisits: visits,
      outstandingBalance: balance,
      createdAt: DateTime.tryParse(map['created_at'] as String) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now(),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'customers',
      {
        'id': customer.id,
        'name': customer.fullName,
        'phone': customer.phone,
        'address': customer.address ?? '',
        'registration_date': customer.createdAt.toIso8601String(),
        'notes': customer.notes ?? '',
        'status': customer.status,
        'is_active': customer.status == 'Active' ? 1 : 0,
        'is_deleted': customer.isDeleted ? 1 : 0,
        'created_at': customer.createdAt.toIso8601String(),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCustomer(String id, {bool softDelete = true}) async {
    final db = await _db;
    if (softDelete) {
      await db.update(
        'customers',
        {'is_deleted': 1, 'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<VehicleModel>> getCustomerVehicles(String customerId) async {
    final db = await _db;
    final maps = await db.query(
      'vehicles',
      where: 'customer_id = ? AND is_deleted = 0',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );

    return maps.map((m) {
      return VehicleModel(
        id: m['id'] as String,
        businessId: 'local',
        customerId: customerId,
        make: m['vehicle_name'] as String,
        model: m['model'] as String? ?? '',
        plateNumber: m['registration_number'] as String,
        year: int.tryParse(m['model_year']?.toString() ?? '') ?? DateTime.now().year,
        color: m['color'] as String? ?? '',
        currentMileage: (m['current_odometer'] as num?)?.toInt() ?? 0,
        notes: m['notes'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(m['updated_at'] as String) ?? DateTime.now(),
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCustomerServiceHistory(String customerId) async {
    final db = await _db;
    return await db.query(
      'vehicle_service_history',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getCustomerInvoices(String customerId) async {
    final db = await _db;
    return await db.query(
      'invoices',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getCustomerPayments(String customerId) async {
    final db = await _db;
    return await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'payment_date DESC',
    );
  }

  Future<double> getCustomerOutstandingBalance(String customerId) async {
    final db = await _db;
    // Calculate sum of remaining_amount from invoices for this customer
    final res = await db.rawQuery('''
      SELECT COALESCE(SUM(remaining_amount), 0.0) as outstanding
      FROM invoices
      WHERE customer_id = ? AND status != 'Cancelled'
    ''', [customerId]);

    return (res.first['outstanding'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getCustomerVisitCount(String customerId) async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM jobs
      WHERE customer_id = ?
    ''', [customerId]);

    return Sqflite.firstIntValue(res) ?? 0;
  }
}
