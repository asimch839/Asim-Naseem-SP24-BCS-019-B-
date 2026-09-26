import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/salary_record.dart';

/// Local database service managing salary calculations with Hive
class SalaryStorageService {
  static const String boxName = 'salary_records_box';
  static Box? _mockBox;

  /// Initialize Hive and open the salary records box
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  /// Initialize with a custom or test box
  @visibleForTesting
  static void setMockBox(Box? box) {
    _mockBox = box;
  }

  /// Get reference to the opened box
  static Box get _box {
    if (_mockBox != null) return _mockBox!;
    if (!Hive.isBoxOpen(boxName)) {
      throw HiveError(
          'Box $boxName is not open. Call SalaryStorageService.init() before accessing records.');
    }
    return Hive.box(boxName);
  }

  /// Get listenable for reactive UI updates
  static ValueListenable<Box> listenable() {
    if (_mockBox != null) {
      return _mockBox!.listenable();
    }
    if (!Hive.isBoxOpen(boxName)) {
      // Return a dummy ValueNotifier holding an in-memory box if not open in tests
      return ValueNotifier<Box>(Hive.box(boxName));
    }
    return _box.listenable();
  }

  /// Retrieve all saved salary records, newest first
  static List<SalaryRecord> getAllRecords() {
    if (_mockBox == null && !Hive.isBoxOpen(boxName)) {
      return [];
    }
    final List<SalaryRecord> records = [];
    for (int i = 0; i < _box.length; i++) {
      final item = _box.getAt(i);
      if (item is Map) {
        try {
          records.add(SalaryRecord.fromMap(item));
        } catch (e) {
          debugPrint('Error parsing record at index $i: $e');
        }
      }
    }
    // Sort descending by creation date
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  /// Save or update a calculation record
  static Future<void> saveRecord(SalaryRecord record) async {
    await _box.put(record.id, record.toMap());
  }

  /// Delete a calculation record by id
  static Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }

  /// Clear all saved history
  static Future<void> clearAllRecords() async {
    await _box.clear();
  }

  /// Total count of saved records
  static int get count {
    if (_mockBox == null && !Hive.isBoxOpen(boxName)) {
      return 0;
    }
    return _box.length;
  }
}
