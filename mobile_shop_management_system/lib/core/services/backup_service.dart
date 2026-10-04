import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/audit_log.dart';

class BackupService {
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
    // 1. Create safety backup first
    await createBackup(note: 'Pre-restore safety snapshot');

    // 2. Read selected backup
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Selected backup file not found.');
    }
    final content = await file.readAsString();

    // 3. Restore into database
    await DatabaseHelper.instance.restoreDatabaseFromJson(content);

    // 4. Log restore event
    await DatabaseHelper.instance.addAuditLog(
      AuditLog(
        id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'ADMIN',
        userName: currentUserName,
        action: 'Database Restored',
        module: 'Backup & Restore',
        recordId: basename(filePath),
        details: 'Database restored from backup: ${basename(filePath)} by $currentUserName',
      ),
    );
  }
}
