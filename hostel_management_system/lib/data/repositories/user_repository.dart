import 'package:flutter/foundation.dart';
import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../../core/utils/password_hasher.dart';
import '../../core/services/audit_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  /// Ensures the default admin user exists in the database.
  /// If no admin user is found, creates one with default credentials.
  Future<void> ensureAdminExists() async {
    try {
      final db = await _dbHelper.database;
      final adminCheck = await db.query(
        DbTables.users,
        where: 'username = ?',
        whereArgs: ['admin'],
        limit: 1,
      );

      if (adminCheck.isEmpty) {
        debugPrint('[AUTH] No admin user found — creating default admin account.');
        final salt = PasswordHasher.generateSalt();
        final hash = PasswordHasher.hashPassword('admin@123', salt);
        final now = DateTime.now().toIso8601String();

        await db.insert(DbTables.users, {
          'username': 'admin',
          'password_hash': hash,
          'salt': salt,
          'full_name': 'Administrator',
          'role': 'Admin',
          'is_active': 1,
          'created_at': now,
          'updated_at': null,
        });
        debugPrint('[AUTH] Default admin user created successfully.');
      } else {
        debugPrint('[AUTH] Admin user already exists in database.');
      }
    } catch (e) {
      debugPrint('[AUTH] Error ensuring admin exists: $e');
    }
  }

  Future<UserModel?> authenticate(String username, String password) async {
    debugPrint('[AUTH] ====== LOGIN ATTEMPT ======');
    debugPrint('[AUTH] Username entered: "$username"');
    debugPrint('[AUTH] Password entered: "$password"');

    final db = await _dbHelper.database;

    // First ensure at least admin user exists
    await ensureAdminExists();

    final results = await db.query(
      DbTables.users,
      where: 'username = ? AND is_active = 1',
      whereArgs: [username.trim()],
      limit: 1,
    );

    debugPrint('[AUTH] Query results count: ${results.length}');

    if (results.isEmpty) {
      debugPrint('[AUTH] ❌ No user found with username "$username". Login REJECTED.');
      return null;
    }

    final user = UserModel.fromMap(results.first);
    debugPrint('[AUTH] Found user: "${user.username}", role: "${user.role}", id: ${user.id}');
    debugPrint('[AUTH] Stored hash: "${user.passwordHash}"');
    debugPrint('[AUTH] Stored salt: "${user.salt}"');

    final computedHash = PasswordHasher.hashPassword(password, user.salt);
    debugPrint('[AUTH] Computed hash for entered password: "$computedHash"');
    debugPrint('[AUTH] Hashes match: ${computedHash == user.passwordHash}');

    final isValid = PasswordHasher.verifyPassword(password, user.salt, user.passwordHash);
    debugPrint('[AUTH] PasswordHasher.verifyPassword result: $isValid');

    if (isValid) {
      debugPrint('[AUTH] ✅ Password CORRECT — Login ALLOWED for "${user.username}".');
      await AuditService.log(
        activityType: 'User Login',
        description: 'User "${user.username}" (${user.role}) logged in.',
        userId: user.id,
        username: user.username,
      );
      return user;
    }

    debugPrint('[AUTH] ❌ Password WRONG — Login REJECTED for "${user.username}".');
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await _dbHelper.database;
    final results = await db.query(DbTables.users, orderBy: 'id ASC');
    return results.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final db = await _dbHelper.database;
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(password, salt);
    final now = DateTime.now().toIso8601String();

    final id = await db.insert(DbTables.users, {
      'username': username.trim(),
      'password_hash': hash,
      'salt': salt,
      'full_name': fullName.trim(),
      'role': role,
      'is_active': 1,
      'created_at': now,
    });

    await AuditService.log(
      activityType: 'User Created',
      description: 'New user "$username" created with role $role.',
      recordId: id,
    );

    return id;
  }

  Future<int> updateUser({
    required int id,
    required String fullName,
    required String role,
    required int isActive,
    String? newPassword,
  }) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> data = {
      'full_name': fullName.trim(),
      'role': role,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hashPassword(newPassword.trim(), salt);
      data['password_hash'] = hash;
      data['salt'] = salt;
    }

    final count = await db.update(
      DbTables.users,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );

    await AuditService.log(
      activityType: 'User Updated',
      description: 'User ID $id details updated.',
      recordId: id,
    );

    return count;
  }

  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      DbTables.users,
      where: 'id = ?',
      whereArgs: [id],
    );

    await AuditService.log(
      activityType: 'User Deleted',
      description: 'User ID $id deleted.',
      recordId: id,
    );

    return count;
  }

  /// Changes the password of an existing user after verifying their current password.
  Future<UserModel> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DbTables.users,
      where: 'id = ? AND is_active = 1',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) {
      throw Exception('User account not found or deactivated.');
    }

    final user = UserModel.fromMap(results.first);
    final isCurrentValid = PasswordHasher.verifyPassword(
      currentPassword,
      user.salt,
      user.passwordHash,
    );

    if (!isCurrentValid) {
      throw Exception('Current password does not match. Please verify and try again.');
    }

    if (newPassword.trim().length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }

    final newSalt = PasswordHasher.generateSalt();
    final newHash = PasswordHasher.hashPassword(newPassword.trim(), newSalt);
    final now = DateTime.now().toIso8601String();

    await db.update(
      DbTables.users,
      {
        'password_hash': newHash,
        'salt': newSalt,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    await AuditService.log(
      activityType: 'Password Changed',
      description: 'User "${user.username}" changed their account password.',
      userId: user.id,
      username: user.username,
      recordId: user.id,
    );

    return user.copyWith(
      passwordHash: newHash,
      salt: newSalt,
      updatedAt: now,
    );
  }

  /// Checks whether the default "admin" account is still using the initial default password "admin@123".
  Future<bool> isDefaultAdminActive() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        DbTables.users,
        where: 'username = ? AND is_active = 1',
        whereArgs: ['admin'],
        limit: 1,
      );

      if (results.isEmpty) return false;

      final user = UserModel.fromMap(results.first);
      return PasswordHasher.verifyPassword('admin@123', user.salt, user.passwordHash);
    } catch (_) {
      return false;
    }
  }
}
