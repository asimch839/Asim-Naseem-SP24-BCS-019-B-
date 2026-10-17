import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class InspectionRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  // Sections management
  Future<List<Map<String, dynamic>>> getSections() async {
    final db = await _db;
    return await db.query(
      'inspection_sections',
      orderBy: 'sort_order ASC',
    );
  }

  Future<void> addSection(String name) async {
    final db = await _db;
    final id = 'sec_${const Uuid().v4().substring(0, 8)}';
    final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM inspection_sections');
    final count = Sqflite.firstIntValue(countRes) ?? 0;

    await db.insert('inspection_sections', {
      'id': id,
      'name': name.trim(),
      'sort_order': count + 1,
      'is_custom': 1,
    });
  }

  Future<void> updateSection(String id, String newName) async {
    final db = await _db;
    await db.update(
      'inspection_sections',
      {'name': newName.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSection(String id) async {
    final db = await _db;
    await db.delete('inspection_sections', where: 'id = ?', whereArgs: [id]);
  }

  // Inspections list & CRUD
  Future<List<Map<String, dynamic>>> getInspections({String? vehicleId, String? customerId, String? searchQuery}) async {
    final db = await _db;
    String sql = '''
      SELECT i.*, v.vehicle_name, v.registration_number, c.name as customer_name, c.phone as customer_phone,
             (SELECT COUNT(*) FROM inspection_items WHERE inspection_id = i.id) as items_count,
             (SELECT COUNT(*) FROM inspection_photos WHERE inspection_id = i.id) as photos_count
      FROM inspections i
      INNER JOIN vehicles v ON i.vehicle_id = v.id
      INNER JOIN customers c ON i.customer_id = c.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (vehicleId != null && vehicleId.isNotEmpty) {
      sql += ' AND i.vehicle_id = ?';
      args.add(vehicleId);
    }
    if (customerId != null && customerId.isNotEmpty) {
      sql += ' AND i.customer_id = ?';
      args.add(customerId);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      sql += ' AND (LOWER(v.vehicle_name) LIKE ? OR LOWER(v.registration_number) LIKE ? OR LOWER(c.name) LIKE ?)';
      args.addAll([q, q, q]);
    }

    sql += ' ORDER BY i.inspection_date DESC';
    return await db.rawQuery(sql, args);
  }

  Future<Map<String, dynamic>?> getInspectionDetails(String inspectionId) async {
    final db = await _db;
    final inspList = await db.rawQuery('''
      SELECT i.*, v.vehicle_name, v.registration_number, v.color, v.model, v.model_year, v.current_odometer,
             c.name as customer_name, c.phone as customer_phone, c.address as customer_address
      FROM inspections i
      INNER JOIN vehicles v ON i.vehicle_id = v.id
      INNER JOIN customers c ON i.customer_id = c.id
      WHERE i.id = ?
    ''', [inspectionId]);

    if (inspList.isEmpty) return null;

    final inspection = Map<String, dynamic>.from(inspList.first);
    final items = await db.query('inspection_items', where: 'inspection_id = ?', whereArgs: [inspectionId]);
    final photos = await db.query('inspection_photos', where: 'inspection_id = ?', whereArgs: [inspectionId]);

    inspection['items'] = items;
    inspection['photos'] = photos;
    return inspection;
  }

  Future<String> saveInspection({
    String? id,
    required String vehicleId,
    required String customerId,
    String? jobId,
    String? inspectorName,
    required DateTime inspectionDate,
    String status = 'Completed',
    String? notes,
    required List<Map<String, dynamic>> items,
    List<Map<String, dynamic>> photos = const [],
  }) async {
    final db = await _db;
    final inspectionId = id ?? 'insp_${const Uuid().v4().substring(0, 8)}';
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert(
        'inspections',
        {
          'id': inspectionId,
          'vehicle_id': vehicleId,
          'customer_id': customerId,
          'job_id': jobId,
          'inspector_name': inspectorName ?? 'Service Advisor',
          'inspection_date': inspectionDate.toIso8601String(),
          'status': status,
          'notes': notes ?? '',
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Clean old items and reinsert
      await txn.delete('inspection_items', where: 'inspection_id = ?', whereArgs: [inspectionId]);
      for (final item in items) {
        final itemId = item['id'] ?? 'item_${const Uuid().v4().substring(0, 8)}';
        await txn.insert('inspection_items', {
          'id': itemId,
          'inspection_id': inspectionId,
          'section_name': item['section_name'] ?? 'General',
          'part_name': item['part_name'] ?? '',
          'condition': item['condition'] ?? 'Good',
          'damage_description': item['damage_description'] ?? '',
          'staff_remarks': item['staff_remarks'] ?? '',
          'customer_remarks': item['customer_remarks'] ?? '',
          'notes': item['notes'] ?? '',
          'view_type': item['view_type'] ?? 'general',
          'x_pos': (item['x_pos'] as num?)?.toDouble() ?? 0.0,
          'y_pos': (item['y_pos'] as num?)?.toDouble() ?? 0.0,
          'created_at': now,
        });
      }

      // Photos
      for (final photo in photos) {
        if (photo['file_path'] != null) {
          final photoId = photo['id'] ?? 'ph_${const Uuid().v4().substring(0, 8)}';
          await txn.insert('inspection_photos', {
            'id': photoId,
            'inspection_id': inspectionId,
            'item_id': photo['item_id'],
            'photo_type': photo['photo_type'] ?? 'damage',
            'file_path': photo['file_path'],
            'description': photo['description'] ?? '',
            'created_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });

    return inspectionId;
  }

  Future<void> deleteInspection(String id) async {
    final db = await _db;
    await db.delete('inspections', where: 'id = ?', whereArgs: [id]);
  }
}
