import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class SettingsRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<Map<String, String>> getAllSettings() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('settings');
    final Map<String, String> results = {};
    for (final row in maps) {
      results[row['key'] as String] = row['value'] as String;
    }
    return results;
  }

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final db = await _db;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSettings(Map<String, String> settings) async {
    final db = await _db;
    final batch = db.batch();
    settings.forEach((key, value) {
      batch.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }

  Future<double> getLowStockThreshold() async {
    final val = await getSetting('low_stock_threshold', defaultValue: '5');
    return double.tryParse(val) ?? 5.0;
  }
}
