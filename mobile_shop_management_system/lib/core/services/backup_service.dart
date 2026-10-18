import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/audit_log.dart';

class BackupService {
  /// Open directory picker and perform verified database backup to user-selected location
  static Future<String?> performBackup() async {
    final selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Folder to Save Database Backup',
    );

    if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
      return null;
    }

    final backupPath = await DatabaseHelper.instance.backupDatabase(selectedDirectory.trim());
    return backupPath;
  }

  /// Open file picker to select a backup file (.db or .json) and perform verified database restore
  static Future<bool> performRestore({required String currentUserName}) async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Select Backup File to Restore (.db or .json)',
      type: FileType.any,
    );

    if (file == null || file.path == null) {
      return false;
    }

    final backupFilePath = file.path!;
    final ext = extension(backupFilePath).toLowerCase();
    if (ext != '.db' && ext != '.json') {
      throw Exception('Invalid file format. Please select a valid database backup file ending in .db or .json');
    }

    final success = await DatabaseHelper.instance.restoreDatabase(
      backupFilePath,
      restoredBy: currentUserName,
    );
    return success;
  }

  /// Open folder picker to move the active database to a user-chosen directory
  static Future<String?> changeDataLocation() async {
    final selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Destination Folder for Shop Database Storage',
    );

    if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
      return null;
    }

    final success = await DatabaseHelper.instance.changeDatabaseLocation(selectedDirectory.trim());
    if (success) {
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

  /// Fetch list of safety backups in Backups directory
  static Future<List<File>> getSafetyBackupsList() async {
    try {
      final dirPath = await DatabaseHelper.instance.getSafetyBackupDirectory();
      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db') || f.path.endsWith('.json'))
          .toList();

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      debugPrint('Error loading safety backups: $e');
      return [];
    }
  }

  // --- Legacy Compatibility Methods ---

  static Future<Directory> getBackupDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(docs.path, 'MobileShopLab', 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  static Future<String> createBackup({String? note}) async {
    final dir = await getBackupDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'backup_$timestamp.json';
    final file = File(join(dir.path, fileName));

    final jsonContent = await DatabaseHelper.instance.exportDatabaseToJson();
    await file.writeAsString(jsonContent);

    await DatabaseHelper.instance.addAuditLog(
      AuditLog(
        id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'SYSTEM',
        userName: 'Admin/System',
        action: 'Backup Created',
        module: 'Backup & Restore',
        recordId: fileName,
        details: 'Manual/Automatic safety backup created successfully. File: $fileName ${note != null ? "($note)" : ""}',
      ),
    );

    return file.path;
  }

  static Future<List<FileSystemEntity>> listBackups() async {
    final dir = await getBackupDirectory();
    final files = dir.listSync().where((f) => f.path.endsWith('.json')).toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  static Future<void> restoreBackup(String filePath, String currentUserName) async {
    await DatabaseHelper.instance.restoreDatabase(filePath, restoredBy: currentUserName);
  }
}
