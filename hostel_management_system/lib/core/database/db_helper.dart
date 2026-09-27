import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/database_info_model.dart';
import '../services/audit_service.dart';
import 'db_tables.dart';
import 'db_seeder.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._internal();
  factory DbHelper() => instance;
  DbHelper._internal();

  Database? _database;
  static const String _defaultDbFileName = 'hostel_database.db';

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  DatabaseFactory get _dbFactory {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  /// Initialize SQLite FFI for Desktop and open database
  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
    }

    final String dbPath = await getDatabaseFilePath();
    final dbDir = Directory(p.dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    // Check if target file exists, if not attempt seamless legacy migration
    final targetFile = File(dbPath);
    if (!await targetFile.exists()) {
      await _migrateLegacyDatabaseIfFound(dbPath);
    }

    final db = await _dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      ),
    );

    // Seed defaults if brand new database
    await DbSeeder.seedInitialData(db);

    return db;
  }

  Future<void> _onConfigure(Database db) async {
    // Enable SQLite foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
    try {
      // WAL mode for high concurrency and crash resilience
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
    } catch (e) {
      debugPrint('Note: WAL mode configuration exception: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final query in DbTables.createTablesQueries) {
      await db.execute(query);
    }
  }

  /// Returns the platform-safe default AppData directory:
  /// e.g. %LOCALAPPDATA%/HostelManagementSystem/
  Future<String> getDefaultDatabaseDirectory() async {
    String basePath;
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.trim().isNotEmpty) {
        basePath = localAppData.trim();
      } else {
        final supportDir = await getApplicationSupportDirectory();
        basePath = supportDir.path;
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      final docDir = await getApplicationDocumentsDirectory();
      basePath = docDir.path;
    } else {
      final supportDir = await getApplicationSupportDirectory();
      basePath = supportDir.path;
    }

    final hmsDir = p.join(basePath, 'HostelManagementSystem');
    final dir = Directory(hmsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return hmsDir;
  }

  /// Returns the dedicated safety backups directory:
  /// e.g. %LOCALAPPDATA%/HostelManagementSystem/Backups/
  Future<String> getSafetyBackupDirectory() async {
    final defaultDir = await getDefaultDatabaseDirectory();
    final backupDir = Directory(p.join(defaultDir, 'Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  /// Returns the configuration file used to persist custom storage paths & backup history
  Future<File> getConfigFile() async {
    final defaultDir = await getDefaultDatabaseDirectory();
    return File(p.join(defaultDir, 'config.json'));
  }

  /// Returns the active database directory (either custom configured or default AppData)
  Future<String> getConfiguredDatabaseDirectory() async {
    final defaultDir = await getDefaultDatabaseDirectory();
    final configFile = await getConfigFile();
    if (await configFile.exists()) {
      try {
        final content = await configFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final customDir = json['database_dir'] as String?;
        if (customDir != null && customDir.trim().isNotEmpty) {
          final dir = Directory(customDir.trim());
          if (await dir.exists()) {
            return dir.path;
          }
        }
      } catch (e) {
        debugPrint('Error reading config.json: $e');
      }
    }
    return defaultDir;
  }

  /// Saves or updates the storage pointer and backup timestamp in config.json
  Future<void> saveConfig({
    String? databaseDir,
    String? lastBackupAt,
    String? lastBackupPath,
  }) async {
    final configFile = await getConfigFile();
    Map<String, dynamic> data = {};
    if (await configFile.exists()) {
      try {
        data = jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (databaseDir != null) data['database_dir'] = databaseDir;
    if (lastBackupAt != null) data['last_backup_at'] = lastBackupAt;
    if (lastBackupPath != null) data['last_backup_path'] = lastBackupPath;

    await configFile.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  /// Returns the absolute path where the active database is located
  Future<String> getDatabaseFilePath() async {
    final dir = await getConfiguredDatabaseDirectory();
    return p.join(dir, _defaultDbFileName);
  }

  /// Seamless migration of existing data from previous locations if found
  Future<void> _migrateLegacyDatabaseIfFound(String targetDbPath) async {
    try {
      final defaultDir = await getDefaultDatabaseDirectory();
      final legacyCandidates = <String>[
        // Old AppData name
        p.join(defaultDir, 'hostel_management_system.db'),
      ];

      // Check legacy Documents location
      try {
        final docDir = await getApplicationDocumentsDirectory();
        legacyCandidates.add(p.join(docDir.path, 'HostelManagementSystem', 'hostel_management_system.db'));
        legacyCandidates.add(p.join(docDir.path, 'HostelManagementSystem', 'hostel_database.db'));
      } catch (_) {}

      for (final candidate in legacyCandidates) {
        final f = File(candidate);
        if (await f.exists() && (await f.length()) > 0) {
          debugPrint('Migrating existing legacy database from: $candidate to $targetDbPath');
          await f.copy(targetDbPath);
          break;
        }
      }
    } catch (e) {
      debugPrint('Legacy migration check notice: $e');
    }
  }

  /// Close database instance (e.g. before restore, migration, or location switch)
  Future<void> closeDatabase() async {
    if (_database != null) {
      try {
        if (_database!.isOpen) {
          await _database!.close();
        }
      } catch (e) {
        debugPrint('Error closing database: $e');
      }
      _database = null;
    }
  }

  /// Flush write-ahead log to main DB file
  Future<void> checkpoint() async {
    if (_database != null && _database!.isOpen) {
      try {
        await _database!.rawQuery('PRAGMA wal_checkpoint(FULL)');
      } catch (e) {
        debugPrint('Checkpoint notice: $e');
      }
    }
  }

  /// Automatically create a safety snapshot before major operations (restore, migration)
  Future<String> createSafetyBackup({required String reason}) async {
    final currentDbPath = await getDatabaseFilePath();
    final currentFile = File(currentDbPath);
    if (!await currentFile.exists() || (await currentFile.length()) == 0) {
      return '';
    }

    await checkpoint();

    final backupDir = await getSafetyBackupDirectory();
    final timeStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final fileName = 'SafetyBackup_${reason}_$timeStr.db';
    final destPath = p.join(backupDir, fileName);

    await currentFile.copy(destPath);
    debugPrint('Safety backup created at $destPath');
    return destPath;
  }

  /// Change database storage folder with validation, safety backup, and integrity check
  Future<bool> changeDatabaseLocation(String newDirectoryPath) async {
    final targetDir = Directory(newDirectoryPath.trim());
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 1. Verify folder writability
    final probeFile = File(p.join(targetDir.path, '.probe_${DateTime.now().millisecondsSinceEpoch}'));
    try {
      await probeFile.writeAsString('probe');
      await probeFile.delete();
    } catch (e) {
      throw Exception('Selected directory is not writable. Please check permissions: $e');
    }

    final currentDir = await getConfiguredDatabaseDirectory();
    if (p.canonicalize(currentDir) == p.canonicalize(targetDir.path)) {
      throw Exception('Selected folder is already the active database storage location.');
    }

    // 2. Automatic safety backup of current data
    await createSafetyBackup(reason: 'pre_migration');

    // 3. Flush & close current DB connection
    await checkpoint();
    await closeDatabase();

    // 4. Safely copy database file(s) to new folder
    final currentDbPath = p.join(currentDir, _defaultDbFileName);
    final targetDbPath = p.join(targetDir.path, _defaultDbFileName);

    final currentFile = File(currentDbPath);
    if (await currentFile.exists()) {
      await currentFile.copy(targetDbPath);
    }

    // Also copy WAL & SHM files if present
    final currentWal = File('$currentDbPath-wal');
    if (await currentWal.exists()) {
      await currentWal.copy('$targetDbPath-wal');
    }
    final currentShm = File('$currentDbPath-shm');
    if (await currentShm.exists()) {
      await currentShm.copy('$targetDbPath-shm');
    }

    // 5. Verify copied database at destination
    Database? testDb;
    try {
      testDb = await _dbFactory.openDatabase(
        targetDbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final check = await testDb.rawQuery('PRAGMA integrity_check');
      if (check.isEmpty || check.first.values.first.toString().toLowerCase() != 'ok') {
        throw Exception('Integrity check failed on copied database.');
      }
      final tables = await testDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      if (!tableNames.contains(DbTables.students) || !tableNames.contains(DbTables.rooms)) {
        throw Exception('Required schema tables missing in migrated database.');
      }
    } catch (e) {
      // If verification failed, cleanup and revert
      final targetFile = File(targetDbPath);
      if (await targetFile.exists()) await targetFile.delete();
      _database = await _initDatabase();
      throw Exception('Database migration verification failed: $e. Original database was preserved.');
    } finally {
      await testDb?.close();
    }

    // 6. Verification succeeded: save new directory in config and switch
    await saveConfig(databaseDir: targetDir.path);
    _database = await _initDatabase();

    await AuditService.log(
      activityType: 'Data Location Changed',
      description: 'Hostel database moved to ${targetDir.path}',
    );

    return true;
  }

  /// Create a complete verified backup of the database to destination
  Future<String> backupDatabase(String destinationDirectoryOrPath) async {
    final currentDbPath = await getDatabaseFilePath();
    final currentFile = File(currentDbPath);
    if (!await currentFile.exists()) {
      throw Exception('Database file does not exist to backup.');
    }

    // Flush WAL
    await checkpoint();

    String finalPath;
    if (FileSystemEntity.isDirectorySync(destinationDirectoryOrPath)) {
      final now = DateTime.now();
      final timeStr = DateFormat('yyyy-MM-dd_HH-mm').format(now);
      final fileName = 'HostelBackup_$timeStr.db';
      finalPath = p.join(destinationDirectoryOrPath, fileName);
    } else {
      finalPath = destinationDirectoryOrPath;
    }

    // Ensure parent directory exists
    final parentDir = Directory(p.dirname(finalPath));
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    await currentFile.copy(finalPath);

    // Save last backup timestamp
    final timestampIso = DateTime.now().toIso8601String();
    await saveConfig(lastBackupAt: timestampIso, lastBackupPath: finalPath);

    // Also update settings table if accessible
    try {
      final db = await database;
      await db.update(
        DbTables.hostelSettings,
        {'backup_path': finalPath, 'updated_at': timestampIso},
        where: 'id = 1',
      );
    } catch (_) {}

    await AuditService.log(
      activityType: 'Database Backup',
      description: 'Manual database backup created at $finalPath',
    );

    return finalPath;
  }

  /// Validate and restore database from a chosen backup file path
  Future<bool> restoreDatabase(String sourceBackupPath) async {
    final sourceFile = File(sourceBackupPath);
    if (!await sourceFile.exists()) {
      throw Exception('Selected backup file does not exist.');
    }

    if (!sourceBackupPath.toLowerCase().endsWith('.db')) {
      throw Exception('Invalid file extension. Please select a valid SQLite .db file.');
    }

    // 1. Pre-validate backup file integrity before touching active database
    Database? testDb;
    try {
      testDb = await _dbFactory.openDatabase(
        sourceBackupPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final check = await testDb.rawQuery('PRAGMA integrity_check');
      if (check.isEmpty || check.first.values.first.toString().toLowerCase() != 'ok') {
        throw Exception('Backup file integrity check failed. The file may be corrupt.');
      }
      final tables = await testDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      if (!tableNames.contains(DbTables.students) || !tableNames.contains(DbTables.users)) {
        throw Exception('The selected file is not a valid Hostel Management System database.');
      }
    } catch (e) {
      throw Exception('Validation failed for backup file: $e');
    } finally {
      await testDb?.close();
    }

    // 2. Create automatic safety backup of current data before overwriting
    await createSafetyBackup(reason: 'pre_restore');

    // 3. Close active database connection
    await checkpoint();
    await closeDatabase();

    final currentDbPath = await getDatabaseFilePath();

    // 4. Remove stale WAL & SHM files if present
    final walFile = File('$currentDbPath-wal');
    if (await walFile.exists()) await walFile.delete();
    final shmFile = File('$currentDbPath-shm');
    if (await shmFile.exists()) await shmFile.delete();

    // 5. Replace current database with backup file
    await sourceFile.copy(currentDbPath);

    // 6. Reopen database and verify
    _database = await _initDatabase();

    await AuditService.log(
      activityType: 'Database Restored',
      description: 'Database restored successfully from $sourceBackupPath',
    );

    return true;
  }

  /// Fetch live database metrics, table record counts, and storage metadata
  Future<DatabaseInfoModel> getDatabaseInfo() async {
    final dbPath = await getDatabaseFilePath();
    final dir = p.dirname(dbPath);
    final file = File(dbPath);
    int sizeBytes = 0;
    DateTime? modified;
    if (await file.exists()) {
      sizeBytes = await file.length();
      modified = await file.lastModified();
    }

    String? lastBackup;
    final configFile = await getConfigFile();
    if (await configFile.exists()) {
      try {
        final json = jsonDecode(await configFile.readAsString());
        lastBackup = json['last_backup_at'] as String?;
      } catch (_) {}
    }

    int totalRecords = 0;
    final Map<String, int> tableCounts = {};

    try {
      final db = await database;
      final tables = [
        DbTables.students,
        DbTables.rooms,
        DbTables.beds,
        DbTables.admissions,
        DbTables.roomAllocations,
        DbTables.rentRecords,
        DbTables.payments,
        DbTables.receipts,
        DbTables.expenses,
        DbTables.activityLogs,
        DbTables.users,
      ];

      for (final t in tables) {
        try {
          final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM $t');
          final count = (res.first['cnt'] as int?) ?? 0;
          tableCounts[t] = count;
          totalRecords += count;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error calculating database record counts: $e');
    }

    return DatabaseInfoModel(
      path: dbPath,
      directory: dir,
      fileSizeBytes: sizeBytes,
      fileSizeFormatted: formatBytes(sizeBytes),
      totalRecords: totalRecords,
      tableCounts: tableCounts,
      lastModified: modified,
      lastBackupAt: lastBackup,
      isConnected: _database != null && _database!.isOpen,
    );
  }

  /// List existing safety backups in Backups folder
  Future<List<File>> getSafetyBackupsList() async {
    final backupDir = Directory(await getSafetyBackupDirectory());
    if (!await backupDir.exists()) return [];

    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.db'))
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
