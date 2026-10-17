import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<Map<String, dynamic>>> getVehiclesWithCustomerInfo({String? searchQuery, String? customerId}) async {
    final db = await _db;
    String sql = '''
      SELECT v.*, c.name as customer_name, c.phone as customer_phone
      FROM vehicles v
      INNER JOIN customers c ON v.customer_id = c.id
      WHERE v.is_deleted = 0
    ''';
    final List<dynamic> args = [];

    if (customerId != null && customerId.isNotEmpty) {
      sql += ' AND v.customer_id = ?';
      args.add(customerId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      sql += ' AND (LOWER(v.vehicle_name) LIKE ? OR LOWER(v.registration_number) LIKE ? OR LOWER(c.name) LIKE ? OR c.phone LIKE ?)';
      args.addAll([q, q, q, q]);
    }

    sql += ' ORDER BY v.created_at DESC';
    return await db.rawQuery(sql, args);
  }

  Future<VehicleModel?> getVehicleById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'vehicles',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final m = maps.first;

    return VehicleModel(
      id: m['id'] as String,
      businessId: 'local',
      customerId: m['customer_id'] as String,
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
  }

  Future<void> saveVehicle(VehicleModel vehicle) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'vehicles',
      {
        'id': vehicle.id,
        'customer_id': vehicle.customerId,
        'vehicle_name': vehicle.make,
        'registration_number': vehicle.plateNumber,
        'model': vehicle.model,
        'model_year': vehicle.year.toString(),
        'color': vehicle.color,
        'current_odometer': vehicle.currentMileage?.toDouble() ?? 0.0,
        'notes': vehicle.notes ?? '',
        'is_deleted': 0,
        'created_at': vehicle.createdAt.toIso8601String(),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateOdometer(String vehicleId, double newOdometer) async {
    final db = await _db;
    await db.update(
      'vehicles',
      {
        'current_odometer': newOdometer,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }

  Future<void> addServiceHistory({
    required String vehicleId,
    required String customerId,
    String? jobId,
    required DateTime date,
    required String serviceDescription,
    required double odometer,
    required double amount,
    DateTime? deliveryDate,
    String paymentStatus = 'Unpaid',
    String? staffNames,
    String? notes,
  }) async {
    final db = await _db;
    final historyId = 'vsh_${const Uuid().v4().substring(0, 8)}';

    await db.insert(
      'vehicle_service_history',
      {
        'id': historyId,
        'vehicle_id': vehicleId,
        'customer_id': customerId,
        'job_id': jobId,
        'date': date.toIso8601String(),
        'service_description': serviceDescription,
        'odometer': odometer,
        'amount': amount,
        'delivery_date': deliveryDate?.toIso8601String(),
        'payment_status': paymentStatus,
        'staff_names': staffNames ?? '',
        'notes': notes ?? '',
        'created_at': DateTime.now().toIso8601String(),
      },
    );

    // Update current odometer if higher
    final current = await db.query(
      'vehicles',
      columns: ['current_odometer'],
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
    if (current.isNotEmpty) {
      final curOdo = (current.first['current_odometer'] as num?)?.toDouble() ?? 0;
      if (odometer > curOdo) {
        await updateOdometer(vehicleId, odometer);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getVehicleServiceHistory(String vehicleId) async {
    final db = await _db;
    return await db.query(
      'vehicle_service_history',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteVehicle(String id) async {
    final db = await _db;
    await db.update(
      'vehicles',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
