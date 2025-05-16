import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CustomCacheManager {
  static const key = 'customCacheKey';
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 100,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }
}

class ImageCacheManager {
  static const key = 'imageCacheKey';
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 100,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }
}

class FileCacheManager {
  static const key = 'fileCacheKey';
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 50,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }
}

class AudioCacheManager {
  static const key = 'audioCacheKey';
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 20,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }
}

class VideoCacheManager {
  static const key = 'videoCacheKey';
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 10,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }
}

class CacheUtils {
  static Future<void> clearAllCache() async {
    await CustomCacheManager.instance.emptyCache();
    await ImageCacheManager.instance.emptyCache();
    await FileCacheManager.instance.emptyCache();
    await AudioCacheManager.instance.emptyCache();
    await VideoCacheManager.instance.emptyCache();
  }

  static Future<void> clearOldCache() async {
    final cacheDir = await getTemporaryDirectory();
    final now = DateTime.now();
    
    // Clear files older than 30 days
    final files = cacheDir.listSync();
    for (var file in files) {
      if (file is File) {
        final stat = await file.stat();
        if (now.difference(stat.modified).inDays > 30) {
          await file.delete();
        }
      }
    }
  }

  static Future<int> getCacheSize() async {
    final cacheDir = await getTemporaryDirectory();
    int size = 0;
    
    final files = cacheDir.listSync();
    for (var file in files) {
      if (file is File) {
        final stat = await file.stat();
        size += stat.size;
      }
    }
    
    return size;
  }

  static String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 