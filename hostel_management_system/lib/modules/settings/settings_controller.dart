import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/db_helper.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/backup_service.dart';
import '../../data/models/database_info_model.dart';
import '../../data/models/hostel_settings_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../layout/main_layout_controller.dart';

class SettingsController extends GetxController {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final UserRepository _userRepo = UserRepository();

  final formKey = GlobalKey<FormState>();

  // Text Controllers for General Settings
  final hostelNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final authorizedPersonCtrl = TextEditingController();
  final receiptPrefixCtrl = TextEditingController();
  final receiptFooterCtrl = TextEditingController();
  final defaultRentCtrl = TextEditingController();
  final dueDayCtrl = TextEditingController();
  final currencyCtrl = TextEditingController();

  // Change Password State & Controllers
  final passwordFormKey = GlobalKey<FormState>();
  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final isCurrentPasswordVisible = false.obs;
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isChangingPassword = false.obs;

  // Navigation tab (0 = General Settings, 1 = Data & Backup, 2 = Account & Security)
  final selectedTab = 0.obs;

  // Loading flags
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isBackingUp = false.obs;
  final isRestoring = false.obs;
  final isMigratingLocation = false.obs;
  final isLoadingDbInfo = false.obs;
  final isClearingCache = false.obs;

  // Database telemetry
  final dbInfo = Rx<DatabaseInfoModel?>(null);
  final safetyBackups = <File>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
    loadDatabaseInfo();
  }

  Future<void> fetchSettings() async {
    isLoading.value = true;
    try {
      final s = await _settingsRepo.getSettings();
      hostelNameCtrl.text = s.hostelName;
      addressCtrl.text = s.address;
      phoneCtrl.text = s.phone;
      emailCtrl.text = s.email;
      authorizedPersonCtrl.text = s.authorizedPerson;
      receiptPrefixCtrl.text = s.receiptPrefix;
      receiptFooterCtrl.text = s.receiptFooter;
      defaultRentCtrl.text = s.defaultMonthlyRent.toStringAsFixed(0);
      dueDayCtrl.text = s.rentDueDay.toString();
      currencyCtrl.text = s.currency;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load live database information (location, size, record counts, backup time)
  Future<void> loadDatabaseInfo() async {
    isLoadingDbInfo.value = true;
    try {
      final info = await DbHelper.instance.getDatabaseInfo();
      dbInfo.value = info;
      safetyBackups.value = await DbHelper.instance.getSafetyBackupsList();
    } catch (e) {
      debugPrint('Failed to load database telemetry: $e');
    } finally {
      isLoadingDbInfo.value = false;
    }
  }

  Future<void> saveSettings() async {
    if (!formKey.currentState!.validate()) return;

    isSaving.value = true;
    try {
      final current = await _settingsRepo.getSettings();
      final updated = HostelSettingsModel(
        hostelName: current.hostelName, // Hostel name is locked and cannot be changed
        address: addressCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        authorizedPerson: authorizedPersonCtrl.text.trim(),
        receiptPrefix: receiptPrefixCtrl.text.trim(),
        receiptFooter: receiptFooterCtrl.text.trim(),
        defaultMonthlyRent: double.tryParse(defaultRentCtrl.text) ?? 15000.0,
        rentDueDay: int.tryParse(dueDayCtrl.text) ?? 5,
        currency: currencyCtrl.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _settingsRepo.updateSettings(updated);
      Get.snackbar(
        'Success',
        'Hostel configuration saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
      );

      // Update header in MainLayoutController
      if (Get.isRegistered<MainLayoutController>()) {
        Get.find<MainLayoutController>().loadSettings();
      }
    } catch (e) {
      Get.snackbar('Save Failed', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  /// Change data storage location with safety backup and verification
  Future<void> changeDataLocation() async {
    isMigratingLocation.value = true;
    try {
      final newPath = await BackupService.changeDataLocation();
      if (newPath != null) {
        await loadDatabaseInfo();
        Get.snackbar(
          'Location Changed',
          'Database successfully migrated to $newPath and verified.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Migration Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isMigratingLocation.value = false;
    }
  }

  /// Open active database folder in Windows Explorer
  Future<void> openDatabaseFolder() async {
    final dir = dbInfo.value?.directory;
    if (dir != null && dir.isNotEmpty) {
      await BackupService.openFolder(dir);
    }
  }

  /// Perform manual database backup
  Future<void> performBackup() async {
    isBackingUp.value = true;
    try {
      final path = await BackupService.performBackup();
      if (path != null) {
        await loadDatabaseInfo();
        Get.snackbar(
          'Backup Created',
          'Database successfully backed up to $path',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Backup Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    } finally {
      isBackingUp.value = false;
    }
  }

  /// Perform verified database restore
  Future<void> performRestore() async {
    isRestoring.value = true;
    try {
      final success = await BackupService.performRestore();
      if (success) {
        await fetchSettings();
        await loadDatabaseInfo();
        Get.snackbar(
          'Database Restored',
          'Database restored successfully! All records have been reloaded.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Restore Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    } finally {
      isRestoring.value = false;
    }
  }

  void toggleCurrentPasswordVisibility() {
    isCurrentPasswordVisible.value = !isCurrentPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Change password for currently logged-in user
  Future<void> changePassword() async {
    final user = AuthService.to.currentUser.value;
    if (user == null || user.id == null) {
      Get.snackbar(
        'Authentication Required',
        'No active user session found.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }

    if (!passwordFormKey.currentState!.validate()) return;

    if (newPasswordCtrl.text.trim() != confirmPasswordCtrl.text.trim()) {
      Get.snackbar(
        'Validation Mismatch',
        'New password and confirm password do not match.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    isChangingPassword.value = true;
    try {
      final updatedUser = await _userRepo.changePassword(
        userId: user.id!,
        currentPassword: currentPasswordCtrl.text.trim(),
        newPassword: newPasswordCtrl.text.trim(),
      );

      // Keep AuthService state in sync
      AuthService.to.setUser(updatedUser);

      // Reset form fields
      currentPasswordCtrl.clear();
      newPasswordCtrl.clear();
      confirmPasswordCtrl.clear();

      Get.snackbar(
        'Password Changed Successfully',
        'Your password has been updated. Please remember to use your new password next time you log in.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'Change Password Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isChangingPassword.value = false;
    }
  }

  /// Clean temporary files, purge image cache, and optimize SQLite storage (VACUUM)
  Future<void> clearAppCache() async {
    isClearingCache.value = true;
    try {
      int clearedFilesCount = 0;
      int clearedBytes = 0;

      // 1. Clear Flutter Image Cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 2. Clear System Temp Directory for the App
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          final entities = tempDir.listSync(recursive: true);
          for (final entity in entities) {
            try {
              if (entity is File) {
                clearedBytes += await entity.length();
                await entity.delete();
                clearedFilesCount++;
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Temp dir clear notice: $e');
      }

      // 3. Compact SQLite Database (Free unused disk pages & optimize)
      try {
        final db = await DbHelper.instance.database;
        await db.rawQuery('VACUUM');
        await db.rawQuery('PRAGMA optimize');
      } catch (e) {
        debugPrint('SQLite vacuum notice: $e');
      }

      await loadDatabaseInfo();

      final sizeFormatted = DbHelper.formatBytes(clearedBytes);
      Get.snackbar(
        'Cache Cleared Successfully',
        'Freed $sizeFormatted across $clearedFilesCount temporary files and optimized database storage.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Cache Clear', 'Cache cleanup completed with note: $e');
    } finally {
      isClearingCache.value = false;
    }
  }

  @override
  void onClose() {
    hostelNameCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    authorizedPersonCtrl.dispose();
    receiptPrefixCtrl.dispose();
    receiptFooterCtrl.dispose();
    defaultRentCtrl.dispose();
    dueDayCtrl.dispose();
    currencyCtrl.dispose();
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
