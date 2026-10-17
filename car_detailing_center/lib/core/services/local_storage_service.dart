import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:archive/archive_io.dart';
import '../../data/database/app_database.dart';

class LocalStorageService extends GetxService {
  static LocalStorageService get to => Get.find();
  final ImagePicker _picker = ImagePicker();

  late Directory _mediaDir;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initMediaDirectory();
  }

  Future<void> _initMediaDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    _mediaDir = Directory(p.join(docsDir.path, 'car_detailing_media'));
    if (!await _mediaDir.exists()) {
      await _mediaDir.create(recursive: true);
    }
  }

  Future<Directory> get mediaDirectory async {
    if (!await _mediaDir.exists()) {
      await _mediaDir.create(recursive: true);
    }
    return _mediaDir;
  }

  /// Pick single image from gallery or camera and save locally to app media directory
  Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.gallery,
    String subFolder = 'general',
  }) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xFile == null) return null;

      return await saveFileLocally(File(xFile.path), subFolder: subFolder);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images and save them locally
  Future<List<String>> pickAndSaveMultiImage({String subFolder = 'inspections'}) async {
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      final List<String> savedPaths = [];
      for (final f in files) {
        final saved = await saveFileLocally(File(f.path), subFolder: subFolder);
        if (saved != null) savedPaths.add(saved);
      }
      return savedPaths;
    } catch (e) {
      debugPrint('Error picking multi images: $e');
      return [];
    }
  }

  /// Save raw bytes locally (e.g. digital signature or exported document)
  Future<String?> saveBytesLocally(
    Uint8List bytes, {
    required String fileName,
    String subFolder = 'signatures',
  }) async {
    try {
      final targetDir = Directory(p.join(_mediaDir.path, subFolder));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final filePath = p.join(targetDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('Error saving bytes locally: $e');
      return null;
    }
  }

  /// Copy an existing file into the local managed media folder
  Future<String?> saveFileLocally(File sourceFile, {String subFolder = 'general'}) async {
    try {
      final ext = p.extension(sourceFile.path);
      final uniqueName = '${const Uuid().v4()}$ext';
      final targetDir = Directory(p.join(_mediaDir.path, subFolder));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final destinationPath = p.join(targetDir.path, uniqueName);
      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving file locally: $e');
      return null;
    }
  }

  /// Create a complete offline backup archive (.zip) containing SQLite database + all media files
  Future<String?> createCompleteBackup(String destinationFolderPath) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docsDir.path, 'car_detailing_center.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Database file does not exist');
      }

      // Checkpoint WAL in SQLite to make sure all data is committed
      final db = await AppDatabase.instance.database;
      try {
        await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
      } catch (_) {}

      final archive = Archive();

      // Add database file
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('car_detailing_center.db', dbBytes.length, dbBytes));

      // Add media files
      if (await _mediaDir.exists()) {
        final mediaFiles = _mediaDir.listSync(recursive: true);
        for (final entity in mediaFiles) {
          if (entity is File) {
            final relativePath = p.relative(entity.path, from: _mediaDir.path);
            final fileBytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile('media/$relativePath', fileBytes.length, fileBytes));
          }
        }
      }

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData == null) throw Exception('Failed to compress backup');

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final backupFileName = 'apex_backup_$timestamp.zip';
      final backupPath = p.join(destinationFolderPath, backupFileName);

      final backupFile = File(backupPath);
      await backupFile.writeAsBytes(zipData);

      return backupPath;
    } catch (e) {
      debugPrint('Backup Error: $e');
      rethrow;
    }
  }

  /// Restore complete backup from a .zip archive
  Future<bool> restoreCompleteBackup(String zipFilePath) async {
    try {
      final zipFile = File(zipFilePath);
      if (!await zipFile.exists()) return false;

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Verify that archive has car_detailing_center.db
      final hasDb = archive.any((f) => f.name == 'car_detailing_center.db');
      if (!hasDb) {
        throw Exception('Invalid backup: car_detailing_center.db not found');
      }

      // Close current active database
      await AppDatabase.instance.close();

      final docsDir = await getApplicationDocumentsDirectory();
      final targetDbPath = p.join(docsDir.path, 'car_detailing_center.db');

      for (final file in archive) {
        if (file.isFile) {
          if (file.name == 'car_detailing_center.db') {
            final f = File(targetDbPath);
            await f.writeAsBytes(file.content as List<int>);
          } else if (file.name.startsWith('media/')) {
            final relPath = file.name.replaceFirst('media/', '');
            final outPath = p.join(_mediaDir.path, relPath);
            final outFile = File(outPath);
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
          }
        }
      }

      // Re-initialize database
      await AppDatabase.instance.database;
      return true;
    } catch (e) {
      debugPrint('Restore Error: $e');
      rethrow;
    }
  }
}
