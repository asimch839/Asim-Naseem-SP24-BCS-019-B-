import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/models/user_model.dart';
import '../../data/models/business_model.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<BusinessModel?> currentBusiness = Rx<BusinessModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isLoggedIn = false.obs;

  String get businessId => currentBusiness.value?.id ?? 'default_business';

  bool get isAdmin => currentUser.value?.role == AppConstants.roleAdmin;
  bool get isManager => currentUser.value?.role == AppConstants.roleManager;

  bool canAccessSalaries() => currentUser.value?.canAccessSalaries() ?? false;
  bool canAccessFinancials() => currentUser.value?.canAccessFinancials() ?? false;
  bool canManageStaff() => currentUser.value?.canManageStaff() ?? false;
  bool canManageInventory() => currentUser.value?.canManageInventory() ?? true;

  @override
  void onInit() {
    super.onInit();
    _checkStoredSession();
  }

  Future<void> _checkStoredSession() async {
    isLoading.value = true;
    try {
      final db = await AppDatabase.instance.database;
      final settings = await db.query('settings');
      final Map<String, String> map = {};
      for (final s in settings) {
        map[s['key'] as String] = s['value'] as String;
      }
      currentBusiness.value = BusinessModel(
        id: 'default_business',
        name: map['business_name'] ?? 'Apex Car Detailing & Studio',
        ownerId: 'admin',
        phone: map['phone'] ?? '+92 300 1234567',
        whatsapp: map['whatsapp'],
        email: map['email'] ?? 'admin@autodetail.com',
        address: map['address'] ?? 'Plot 42, Auto Sector, Main Boulevard',
        currency: map['currency'] ?? 'Rs.',
        timezone: map['timezone'] ?? 'Asia/Karachi (PKT +05:00)',
        taxRate: double.tryParse(map['tax_rate'] ?? '0') ?? 0.0,
        jobPrefix: map['job_prefix'] ?? 'JOB-',
        invoicePrefix: map['invoice_prefix'] ?? 'INV-',
        globalLowStockThreshold: double.tryParse(map['low_stock_threshold'] ?? '5') ?? 5.0,
      );

      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('active_user_id');

      if (savedUserId != null && savedUserId.isNotEmpty) {
        final db = await AppDatabase.instance.database;
        final maps = await db.query(
          'users',
          where: 'id = ? AND is_active = 1',
          whereArgs: [savedUserId],
        );
        if (maps.isNotEmpty) {
          currentUser.value = UserModel.fromMap(maps.first, savedUserId);
          isLoggedIn.value = true;
        }
      }
    } catch (e) {
      debugPrint('Error restoring local session: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> login(String emailOrUsername, String password) async {
    isLoading.value = true;
    try {
      final db = await AppDatabase.instance.database;
      final clean = emailOrUsername.trim().toLowerCase();

      final maps = await db.query(
        'users',
        where: '(LOWER(email) = ? OR LOWER(username) = ?) AND is_active = 1',
        whereArgs: [clean, clean],
      );

      if (maps.isEmpty) {
        return 'Invalid credentials. User not found.';
      }

      final userData = maps.first;
      final storedPassword = userData['password_hash'] as String;

      if (storedPassword != password.trim()) {
        return 'Incorrect password. Please try again.';
      }

      final user = UserModel.fromMap(userData, userData['id'] as String);
      currentUser.value = user;
      isLoggedIn.value = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_user_id', user.uid);

      return null;
    } catch (e) {
      debugPrint('Local Login Error: $e');
      return 'Login failed: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_user_id');
      currentUser.value = null;
      isLoggedIn.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      final db = await AppDatabase.instance.database;
      final clean = email.trim().toLowerCase();
      final maps = await db.query(
        'users',
        where: 'LOWER(email) = ? AND is_active = 1',
        whereArgs: [clean],
      );
      if (maps.isEmpty) {
        return 'No active user found with this email address.';
      }
      await db.insert('audit_logs', {
        'id': 'aud_${DateTime.now().millisecondsSinceEpoch}',
        'action': 'PASSWORD_RESET_REQUESTED',
        'table_name': 'users',
        'record_id': maps.first['id'] as String,
        'old_values': '',
        'new_values': 'Password reset initiated for $clean',
        'user_name': maps.first['full_name'] as String? ?? 'User',
        'timestamp': DateTime.now().toIso8601String(),
      });
      return null;
    } catch (e) {
      return 'Password reset failed: $e';
    }
  }

  void updateCurrentUser(UserModel updated) {
    currentUser.value = updated;
  }

  void updateCurrentBusiness(BusinessModel updated) {
    currentBusiness.value = updated;
  }
}
