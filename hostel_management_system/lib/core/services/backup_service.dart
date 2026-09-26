import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../database/db_helper.dart';
import '../../modules/dashboard/dashboard_controller.dart';
import '../../modules/students/student_controller.dart';
import '../../modules/rooms/room_controller.dart';
import '../../modules/rent/rent_controller.dart';
import '../../modules/receipts/receipt_controller.dart';
import '../../modules/expenses/expense_controller.dart';
import '../../modules/history/history_controller.dart';
import '../../modules/reports/report_controller.dart';
import '../../modules/users/user_controller.dart';
import '../../modules/settings/settings_controller.dart';
import '../../modules/layout/main_layout_controller.dart';

class BackupService {
  /// Open directory picker and perform verified database backup
  static Future<String?> performBackup() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Folder to Save Database Backup',
    );

    if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
      return null;
    }

    final backupPath = await DbHelper.instance.backupDatabase(selectedDirectory.trim());
    return backupPath;
  }

  /// Open file picker to select a .db file and perform verified database restore
  static Future<bool> performRestore() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Backup File to Restore (.db)',
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty || result.files.single.path == null) {
      return false;
    }

    final backupFilePath = result.files.single.path!;
    if (!backupFilePath.toLowerCase().endsWith('.db')) {
      throw Exception('Invalid file format. Please select a valid SQLite database file ending in .db');
    }

    final success = await DbHelper.instance.restoreDatabase(backupFilePath);
    if (success) {
      await reloadAllAppData();
    }
    return success;
  }

  /// Open folder picker to move the active database to a user-chosen directory
  static Future<String?> changeDataLocation() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Destination Folder for Hostel Database Storage',
    );

    if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
      return null;
    }

    final success = await DbHelper.instance.changeDatabaseLocation(selectedDirectory.trim());
    if (success) {
      await reloadAllAppData();
      return selectedDirectory.trim();
    }
    return null;
  }

  /// Open any directory in Windows File Explorer
  static Future<void> openFolder(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [path]);
      }
    } catch (e) {
      debugPrint('Error opening directory in explorer: $e');
    }
  }

  /// Reinitializes all active GetX controllers and refreshes app-wide state
  static Future<void> reloadAllAppData() async {
    try {
      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().refreshData();
      }
      if (Get.isRegistered<StudentController>()) {
        await Get.find<StudentController>().fetchStudents();
      }
      if (Get.isRegistered<RoomController>()) {
        await Get.find<RoomController>().fetchRooms();
      }
      if (Get.isRegistered<RentController>()) {
        await Get.find<RentController>().fetchRentRecords();
      }
      if (Get.isRegistered<ReceiptController>()) {
        await Get.find<ReceiptController>().fetchReceipts();
      }
      if (Get.isRegistered<ExpenseController>()) {
        await Get.find<ExpenseController>().fetchExpenses();
      }
      if (Get.isRegistered<HistoryController>()) {
        await Get.find<HistoryController>().fetchHistoryLogs();
      }
      if (Get.isRegistered<ReportController>()) {
        Get.find<ReportController>().refreshReports();
      }
      if (Get.isRegistered<UserController>()) {
        await Get.find<UserController>().fetchUsers();
      }
      if (Get.isRegistered<SettingsController>()) {
        final settingsCtrl = Get.find<SettingsController>();
        await settingsCtrl.fetchSettings();
        await settingsCtrl.loadDatabaseInfo();
      }
      if (Get.isRegistered<MainLayoutController>()) {
        await Get.find<MainLayoutController>().loadSettings();
      }
    } catch (e) {
      debugPrint('Error reloading app data after database change: $e');
    }
  }
}
