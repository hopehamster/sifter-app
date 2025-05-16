import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sifter/services/analytics_service.dart';

part 'storage_service.g.dart';

@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService();
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  Future<String> uploadFile(File file, String path, {Map<String, String>? metadata}) async {
    try {
      final ref = _storage.ref().child(path);
      
      final uploadMetadata = SettableMetadata(
        contentType: _getMimeType(file.path),
        customMetadata: metadata,
        cacheControl: 'private,max-age=0',
      );

      final uploadTask = await ref.putFile(file, uploadMetadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'file_upload_error',
      );
      rethrow;
    }
  }

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    String? mimeType,
    Map<String, String>? metadata,
    bool isPublic = false,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      
      final uploadMetadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: metadata,
        cacheControl: isPublic ? 'public,max-age=31536000' : 'private,max-age=0',
      );

      final uploadTask = await ref.putData(bytes, uploadMetadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'file_upload_error',
      );
      rethrow;
    }
  }

  Future<File> downloadFile(String url) async {
    try {
      return await _cacheManager.getSingleFile(url);
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'file_download_error',
      );
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
      await _cacheManager.removeFile(path);

      await _analytics.logEvent('file_deleted', parameters: {
        'file_path': path,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'file_delete_error',
      );
      rethrow;
    }
  }

  Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'get_file_url_error',
      );
      rethrow;
    }
  }

  Future<void> updateMetadata({
    required String path,
    Map<String, String>? metadata,
    String? contentType,
    bool isPublic = false,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.updateMetadata(
        SettableMetadata(
          contentType: contentType,
          customMetadata: metadata,
          cacheControl: isPublic ? 'public,max-age=31536000' : 'private,max-age=0',
        ),
      );

      await _analytics.logEvent('file_metadata_updated', parameters: {
        'file_path': path,
        'metadata': metadata,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'update_metadata_error',
      );
      rethrow;
    }
  }

  Future<List<Reference>> listFiles(String path) async {
    try {
      final result = await _storage.ref().child(path).listAll();
      return result.items;
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'list_files_error',
      );
      rethrow;
    }
  }

  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();

      await _analytics.logEvent('cache_cleared');
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'cache_clear_error',
      );
      rethrow;
    }
  }

  Future<String> getCachePath(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      return file.path;
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'cache_path_error',
      );
      rethrow;
    }
  }

  Future<bool> isFileCached(String url) async {
    try {
      final file = await _cacheManager.getFileFromCache(url);
      return file != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> preloadFile(String url) async {
    try {
      await _cacheManager.getSingleFile(url);
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'preload_file_error',
      );
    }
  }

  Future<void> preloadFiles(List<String> urls) async {
    try {
      await Future.wait(urls.map((url) => preloadFile(url)));
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'preload_files_error',
      );
    }
  }

  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> getTemporaryFilePath() async {
    final directory = await getTemporaryDirectory();
    return path.join(directory.path, DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<String> getApplicationDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<int> getFileSize(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      await _analytics.logError(
        e,
        StackTrace.current,
        reason: 'get_file_size_error',
      );
      rethrow;
    }
  }

  Future<String> getFileType(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      final metadata = await ref.getMetadata();
      return metadata.contentType ?? 'unknown';
    } catch (e) {
      await _analytics.logError(
        e,
        StackTrace.current,
        reason: 'get_file_type_error',
      );
      rethrow;
    }
  }
} 