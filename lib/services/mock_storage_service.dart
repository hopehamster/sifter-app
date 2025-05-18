import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;
import 'package:sifter/services/analytics_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mock_storage_service.g.dart';

// Mock reference class to simulate Firebase Storage Reference
class MockReference {
  final String _path;
  
  MockReference(this._path);
  
  MockReference child(String childPath) {
    return MockReference('$_path/$childPath');
  }
  
  Future<String> getDownloadURL() async {
    // Return a mock URL for the file
    return 'https://mock-storage.sifter.app/$_path';
  }
  
  Future<MockUploadTask> putFile(File file, [SettableMetadata? metadata]) async {
    // Create local copy in the app's documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(file.path);
    final savedFile = await file.copy('${appDir.path}/mock_storage/$_path/$fileName');
    
    return MockUploadTask(this);
  }
  
  Future<MockUploadTask> putData(Uint8List bytes, [SettableMetadata? metadata]) async {
    // Create local copy in the app's documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final savedFile = File('${appDir.path}/mock_storage/$_path');
    await savedFile.create(recursive: true);
    await savedFile.writeAsBytes(bytes);
    
    return MockUploadTask(this);
  }
  
  Future<void> delete() async {
    // Delete the local file
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/mock_storage/$_path');
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  Future<void> updateMetadata(SettableMetadata metadata) async {
    // No-op for mock implementation
  }
  
  Future<MockListResult> listAll() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/mock_storage/$_path');
    if (!await dir.exists()) {
      return MockListResult([]);
    }
    
    final List<MockReference> items = [];
    await for (final entity in dir.list()) {
      if (entity is File) {
        items.add(MockReference('$_path/${path.basename(entity.path)}'));
      }
    }
    
    return MockListResult(items);
  }

  Future<MockStorageMetadata> getMetadata() async {
    // Return mocked metadata
    return MockStorageMetadata(
      contentType: _getMimeTypeFromPath(_path),
      size: 1024, // Mock 1KB file size
    );
  }
  
  String _getMimeTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}

// Mock upload task to simulate Firebase Storage UploadTask
class MockUploadTask {
  final MockReference ref;
  
  MockUploadTask(this.ref);
}

// Mock list result to simulate Firebase Storage ListResult
class MockListResult {
  final List<MockReference> items;
  
  MockListResult(this.items);
}

// Mock settable metadata to simulate Firebase Storage SettableMetadata
class SettableMetadata {
  final String? contentType;
  final Map<String, String>? customMetadata;
  final String? cacheControl;
  
  SettableMetadata({
    this.contentType,
    this.customMetadata,
    this.cacheControl,
  });
}

// Mock storage metadata to simulate Firebase Storage metadata
class MockStorageMetadata {
  final String? contentType;
  final int? size;
  final Map<String, String>? customMetadata;
  
  MockStorageMetadata({
    this.contentType,
    this.size,
    this.customMetadata,
  });
}

// Mock Firebase Storage to replace the real implementation
class MockFirebaseStorage {
  static final MockFirebaseStorage _instance = MockFirebaseStorage._internal();
  factory MockFirebaseStorage() => _instance;
  MockFirebaseStorage._internal();
  
  static MockFirebaseStorage get instance => _instance;
  
  MockReference ref() {
    return MockReference('');
  }
  
  MockReference refFromURL(String url) {
    // Extract path from URL
    final Uri uri = Uri.parse(url);
    final String path = uri.path.replaceFirst('/v0/b/', '').split('/o/').last;
    return MockReference(Uri.decodeComponent(path));
  }
}

@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService();
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final MockFirebaseStorage _storage = MockFirebaseStorage.instance;
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

  Future<List<MockReference>> listFiles(String path) async {
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
  
  String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpeg':
      case '.jpg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
} 