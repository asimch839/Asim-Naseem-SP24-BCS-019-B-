import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../../core/services/audit_service.dart';
import '../models/room_model.dart';
import '../models/bed_model.dart';

class RoomRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<List<RoomModel>> getAllRooms({String? search, String? statusFilter}) async {
    final db = await _dbHelper.database;
    
    String query = '''
      SELECT r.*, 
        COUNT(CASE WHEN b.bed_status = 'Occupied' OR b.current_student_id IS NOT NULL THEN 1 END) as occupied_beds_count
      FROM ${DbTables.rooms} r
      LEFT JOIN ${DbTables.beds} b ON r.id = b.room_id
    ''';

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(r.room_number LIKE ? OR r.block LIKE ? OR r.floor LIKE ?)');
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (statusFilter != null && statusFilter != 'All') {
      whereClauses.add('r.room_status = ?');
      whereArgs.add(statusFilter);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' GROUP BY r.id ORDER BY r.room_number ASC';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((m) => RoomModel.fromMap(m)).toList();
  }

  Future<RoomModel?> getRoomById(int id) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT r.*, 
        COUNT(CASE WHEN b.bed_status = 'Occupied' OR b.current_student_id IS NOT NULL THEN 1 END) as occupied_beds_count
      FROM ${DbTables.rooms} r
      LEFT JOIN ${DbTables.beds} b ON r.id = b.room_id
      WHERE r.id = ?
      GROUP BY r.id
    ''';
    final results = await db.rawQuery(query, [id]);
    if (results.isEmpty) return null;
    return RoomModel.fromMap(results.first);
  }

  Future<List<BedModel>> getBedsByRoomId(int roomId) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT b.*, r.room_number, s.full_name as student_name, s.student_id_code
      FROM ${DbTables.beds} b
      INNER JOIN ${DbTables.rooms} r ON b.room_id = r.id
      LEFT JOIN ${DbTables.students} s ON b.current_student_id = s.id
      WHERE b.room_id = ?
      ORDER BY b.bed_number ASC
    ''';
    final results = await db.rawQuery(query, [roomId]);
    return results.map((m) => BedModel.fromMap(m)).toList();
  }

  Future<List<BedModel>> getAvailableBedsByRoomId(int roomId) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT b.*, r.room_number
      FROM ${DbTables.beds} b
      INNER JOIN ${DbTables.rooms} r ON b.room_id = r.id
      WHERE b.room_id = ? AND b.bed_status = 'Available' AND b.current_student_id IS NULL
      ORDER BY b.bed_number ASC
    ''';
    final results = await db.rawQuery(query, [roomId]);
    return results.map((m) => BedModel.fromMap(m)).toList();
  }

  /// Create room and generate default beds
  Future<int> createRoom(RoomModel room) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final roomMap = room.toMap();
      roomMap.remove('id');
      roomMap['created_at'] = now;

      final roomId = await txn.insert(DbTables.rooms, roomMap);

      // Create Beds: Bed 1, Bed 2, ...
      for (int i = 1; i <= room.totalBeds; i++) {
        await txn.insert(DbTables.beds, {
          'room_id': roomId,
          'bed_number': 'Bed $i',
          'bed_status': 'Available',
          'current_student_id': null,
          'created_at': now,
        });
      }

      await AuditService.log(
        activityType: 'Room Added',
        description: 'Room ${room.roomNumber} created with ${room.totalBeds} beds.',
        recordId: roomId,
        executor: txn,
      );

      return roomId;
    });
  }

  Future<void> updateRoom(RoomModel room) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final roomMap = room.toMap();
    roomMap['updated_at'] = now;

    await db.update(
      DbTables.rooms,
      roomMap,
      where: 'id = ?',
      whereArgs: [room.id],
    );

    await AuditService.log(
      activityType: 'Room Updated',
      description: 'Room ${room.roomNumber} details updated.',
      recordId: room.id,
    );
  }

  Future<void> deleteRoom(int roomId, String roomNumber) async {
    final db = await _dbHelper.database;
    // Check if any occupied beds exist
    final occupiedCheck = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ${DbTables.beds} WHERE room_id = ? AND (bed_status = 'Occupied' OR current_student_id IS NOT NULL)",
      [roomId],
    );
    final count = (occupiedCheck.first['count'] as int?) ?? 0;
    if (count > 0) {
      throw Exception('Cannot delete room $roomNumber because it contains occupied beds.');
    }

    await db.delete(DbTables.rooms, where: 'id = ?', whereArgs: [roomId]);

    await AuditService.log(
      activityType: 'Room Deleted',
      description: 'Room $roomNumber deleted.',
      recordId: roomId,
    );
  }

  Future<void> updateBedStatus(int bedId, String newStatus) async {
    final db = await _dbHelper.database;
    await db.update(
      DbTables.beds,
      {
        'bed_status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bedId],
    );
  }

  /// Recalculate and update room status based on current bed occupancies
  Future<void> syncRoomStatus(int roomId, [DatabaseExecutor? executor]) async {
    final db = executor ?? await _dbHelper.database;
    final beds = await db.query(DbTables.beds, where: 'room_id = ?', whereArgs: [roomId]);
    if (beds.isEmpty) return;

    final total = beds.length;
    final occupied = beds.where((b) => b['bed_status'] == 'Occupied' || b['current_student_id'] != null).length;
    final maintenance = beds.where((b) => b['bed_status'] == 'Maintenance').length;

    String calculatedStatus = 'Available';
    if (maintenance == total) {
      calculatedStatus = 'Maintenance';
    } else if (occupied >= total) {
      calculatedStatus = 'Full';
    } else {
      calculatedStatus = 'Available';
    }

    await db.update(
      DbTables.rooms,
      {
        'room_status': calculatedStatus,
        'total_beds': total,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }
}
