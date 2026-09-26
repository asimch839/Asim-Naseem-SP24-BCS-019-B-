import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../utils/password_hasher.dart';
import 'db_tables.dart';

class DbSeeder {
  static Future<void> seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // 1. Check & Seed Default Admin User
    final userCheck = await db.query(DbTables.users, limit: 1);
    if (userCheck.isEmpty) {
      final salt = PasswordHasher.generateSalt();
      final passwordHash = PasswordHasher.hashPassword('admin@123', salt);

      await db.insert(DbTables.users, {
        'username': 'admin',
        'password_hash': passwordHash,
        'salt': salt,
        'full_name': 'Administrator',
        'role': 'Admin',
        'is_active': 1,
        'created_at': now,
        'updated_at': null,
      });

      // Also create a sample Office Staff account
      final staffSalt = PasswordHasher.generateSalt();
      final staffPasswordHash = PasswordHasher.hashPassword('staff123', staffSalt);
      await db.insert(DbTables.users, {
        'username': 'staff',
        'password_hash': staffPasswordHash,
        'salt': staffSalt,
        'full_name': 'Office Staff',
        'role': 'Office Staff',
        'is_active': 1,
        'created_at': now,
        'updated_at': null,
      });
    }

    // 2. Check & Seed Hostel Settings
    final settingsCheck = await db.query(DbTables.hostelSettings, limit: 1);
    if (settingsCheck.isEmpty) {
      await db.insert(DbTables.hostelSettings, {
        'id': 1,
        'hostel_name': 'Sardar 4 Boys Hostel',
        'address': 'Main University Road, Campus Town',
        'phone': '+92 300 1234567',
        'email': 'admin@hostel.local',
        'logo_path': null,
        'receipt_prefix': 'REC-',
        'receipt_footer': 'Thank you for choosing our hostel! Please keep this receipt safe.',
        'authorized_person': 'Hostel Warden / Manager',
        'default_monthly_rent': 15000.0,
        'rent_due_day': 5,
        'currency': 'PKR',
        'backup_path': null,
        'updated_at': now,
      });
    }

    // 3. Check & Seed Initial Activity Log
    final logCheck = await db.query(DbTables.activityLogs, limit: 1);
    if (logCheck.isEmpty) {
      await db.insert(DbTables.activityLogs, {
        'activity_type': 'System Initialized',
        'description': 'Hostel Management System initialized with default configuration.',
        'user_id': 1,
        'username': 'admin',
        'created_at': now,
      });
    }
  }
}
