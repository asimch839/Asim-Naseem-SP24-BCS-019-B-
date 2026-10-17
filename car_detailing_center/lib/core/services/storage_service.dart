import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'local_storage_service.dart';

class StorageService extends GetxService {
  static StorageService get to => Get.isRegistered<StorageService>() ? Get.find<StorageService>() : StorageService();
  static final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<List<XFile>> pickMultiImage() async {
    try {
      return await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  Future<FilePickerResult?> pickFile({List<String>? allowedExtensions}) async {
    try {
      return await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Offline Local storage method
  static Future<String?> uploadFile({
    required Uint8List bytes,
    required String path,
    String contentType = 'image/jpeg',
  }) async {
    try {
      return await LocalStorageService.to.saveBytesLocally(bytes, fileName: path.split('/').last);
    } catch (e) {
      debugPrint('Offline Storage Save Error: $e');
      return null;
    }
  }

  Future<String?> uploadFileWithDetails({
    required String businessId,
    required String category,
    required String entityId,
    required File file,
    String? customFileName,
  }) async {
    try {
      return await LocalStorageService.to.saveFileLocally(file, subFolder: category);
    } catch (e) {
      debugPrint('Offline Storage Save Error: $e');
      return null;
    }
  }

  Future<String?> uploadBytes({
    required String businessId,
    required String category,
    required String entityId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    try {
      return await LocalStorageService.to.saveBytesLocally(bytes, fileName: fileName, subFolder: category);
    } catch (e) {
      debugPrint('Offline Storage Save Bytes Error: $e');
      return null;
    }
  }

  static Future<String?> saveLocalFile({
    required List<int> bytes,
    required String fileName,
    String subfolder = 'general',
  }) async {
    try {
      return await LocalStorageService.to.saveBytesLocally(
        Uint8List.fromList(bytes),
        fileName: fileName,
        subFolder: subfolder,
      );
    } catch (e) {
      debugPrint('SaveLocalFile Error: $e');
      return null;
    }
  }
}
