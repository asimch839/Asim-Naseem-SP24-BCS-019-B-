import '../../core/database/db_helper.dart';
import '../../core/database/db_tables.dart';
import '../../core/utils/password_hasher.dart';
import '../../core/services/audit_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<UserModel?> authenticate(String username, String password) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DbTables.users,
      where: 'username = ? AND is_active = 1',
      whereArgs: [username.trim()],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final user = UserModel.fromMap(results.first);
    final isValid = PasswordHasher.verifyPassword(password, user.salt, user.passwordHash);

    if (isValid) {
      await AuditService.log(
        activityType: 'User Login',
        description: 'User "${user.username}" (${user.role}) logged in.',
        userId: user.id,
        username: user.username,
      );
      return user;
    }
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
