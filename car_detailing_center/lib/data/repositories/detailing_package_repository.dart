import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/detailing_package_model.dart';

class DetailingPackageRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<DetailingPackageModel>> getPackages({bool activeOnly = true}) async {
    final db = await _db;
    String whereClause = 'is_deleted = 0';
    if (activeOnly) {
      whereClause += ' AND is_active = 1';
    }

    final maps = await db.query(
      'detailing_packages',
      where: whereClause,
      orderBy: 'sort_order ASC, created_at ASC',
    );

    return maps.map((m) => DetailingPackageModel.fromMap(m)).toList();
  }

  Future<DetailingPackageModel?> getPackageById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'detailing_packages',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DetailingPackageModel.fromMap(maps.first);
  }

  Future<void> savePackage(DetailingPackageModel package) async {
    final db = await _db;
    await db.insert(
      'detailing_packages',
      package.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePackage(String id, {bool softDelete = true}) async {
    final db = await _db;
    if (softDelete) {
      await db.update(
        'detailing_packages',
        {
          'is_deleted': 1,
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete(
        'detailing_packages',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> reorderPackages(List<DetailingPackageModel> packages) async {
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < packages.length; i++) {
      batch.update(
        'detailing_packages',
        {'sort_order': i + 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [packages[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}
