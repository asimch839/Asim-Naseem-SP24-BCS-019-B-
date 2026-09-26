import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/constants/app_strings.dart';
import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../../core/services/audit_service.dart';
import '../models/hostel_settings_model.dart';

class SettingsRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<HostelSettingsModel> getSettings() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DbTables.hostelSettings,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (results.isEmpty) {
      final initial = HostelSettingsModel(
        hostelName: AppStrings.appName,
        address: 'Main Campus Road, City',
        phone: '+92 300 1234567',
        email: 'info@hostel.local',
        receiptPrefix: 'REC-',
        receiptFooter: 'Thank you for choosing our hostel! Please keep this receipt safe.',
        authorizedPerson: 'Hostel Warden / Manager',
        defaultMonthlyRent: 15000.0,
        rentDueDay: 5,
        currency: 'PKR',
        updatedAt: DateTime.now().toIso8601String(),
      );
      await db.insert(DbTables.hostelSettings, initial.toMap());
      return initial;
    }

    final model = HostelSettingsModel.fromMap(results.first);
    // Auto-migrate legacy default name to official hostel name
    if (model.hostelName == 'Hostel Management System') {
      final updated = model.copyWith(hostelName: AppStrings.appName);
      await db.update(
        DbTables.hostelSettings,
        {'hostel_name': AppStrings.appName},
        where: 'id = ?',
        whereArgs: [1],
      );
      return updated;
    }

    return model;
  }

  Future<void> updateSettings(HostelSettingsModel settings) async {
    final db = await _dbHelper.database;
    final current = await getSettings();
    final map = settings.toMap();
    map['hostel_name'] = current.hostelName; // Enforce locked hostel name at repository level
    map['updated_at'] = DateTime.now().toIso8601String();

    await db.insert(
      DbTables.hostelSettings,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await AuditService.log(
      activityType: 'Settings Updated',
      description: 'Hostel settings updated.',
    );
  }
}
