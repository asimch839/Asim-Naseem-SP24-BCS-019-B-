import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_helper.dart';
import '../database/db_tables.dart';
import 'auth_service.dart';

class AuditService {
  /// Write an audit record directly into SQLite activity_logs table
  static Future<void> log({
    required String activityType,
    required String description,
    int? userId,
    String? username,
    int? studentId,
    int? recordId,
    DatabaseExecutor? executor,
  }) async {
    try {
      final db = executor ?? await DbHelper.instance.database;
      
      String resolvedUsername = username ?? 'Admin';
      int? resolvedUserId = userId;

      if (Get.isRegistered<AuthService>()) {
        final auth = AuthService.to;
        if (auth.currentUser.value != null) {
          resolvedUsername = username ?? auth.currentUsername;
          resolvedUserId = userId ?? auth.currentUserId;
        }
      }

      await db.insert(DbTables.activityLogs, {
        'activity_type': activityType,
        'description': description,
        'user_id': resolvedUserId,
        'username': resolvedUsername,
        'student_id': studentId,
        'record_id': recordId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // In-app activity log failure should not crash main transaction
      debugPrint('AuditService log error: $e');
    }
  }
}
