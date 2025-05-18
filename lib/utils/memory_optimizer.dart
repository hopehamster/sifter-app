import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Memory optimization strategies to prevent excessive resource usage in the app
class MemoryOptimizer {
  static final MemoryOptimizer _instance = MemoryOptimizer._internal();
  static MemoryOptimizer get instance => _instance;
  
  MemoryOptimizer._internal();
  
  // Configuration
  bool _isEnabled = true;
  int _maxCachedMessages = 200;
  int _maxCachedRooms = 20;
  int _imageCacheSizeBytes = 20 * 1024 * 1024; // 20 MB default
  int _messagePreloadCount = 30;
  int _maxCacheSize = 50 * 1024 * 1024; // 50 MB default
  bool _aggressiveCleanup = false;
  double _lowMemoryThreshold = 0.15; // 15% threshold
  
  // Active state tracking
  final _activeRooms = HashSet<String>();
  final _lastAccessTimes = <String, DateTime>{};
  final _roomMessageCounts = <String, int>{};
  
  // Memory usage tracking
  int _estimatedMemoryUsage = 0;
  DateTime? _lastCleanupTime;
  DateTime? _lastMemoryPressureTime;
  
  // Background state
  bool _isInBackground = false;
  Timer? _backgroundCleanupTimer;
  
  // Cache management
  final _cachedResources = <String, CachedResource>{};
  int _totalCacheSize = 0;
  final _lruCache = LinkedHashMap<String, int>();
  
  // Callbacks
  Function(List<String>)? onClearRoomsCallback;
  Function(bool)? onLowMemoryCallback;
  
  // Error handling
  int _consecutiveErrors = 0;
  static const _maxConsecutiveErrors = 3;
  
  /// Initialize the memory optimizer
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('memory_optimization_enabled') ?? true;
      
      // Load settings from preferences
      _maxCachedMessages = prefs.getInt('max_cached_messages') ?? 200;
      _maxCachedRooms = prefs.getInt('max_cached_rooms') ?? 20;
      _imageCacheSizeBytes = prefs.getInt('image_cache_size_bytes') ?? (20 * 1024 * 1024);
      _messagePreloadCount = prefs.getInt('message_preload_count') ?? 30;
      
      // Apply image cache settings to Flutter's built-in cache with safety checks
      _safelySetImageCache(_imageCacheSizeBytes);
      
      debugPrint('Memory optimizer initialized with $_maxCachedRooms max rooms, $_maxCachedMessages max messages');
    } catch (e) {
      debugPrint('Error initializing memory optimizer: $e');
      // Use safe defaults if initialization fails
      _isEnabled = true; // Default to enabled for safety
      _maxCachedMessages = 100; // Conservative default
      _maxCachedRooms = 10; // Conservative default
      _imageCacheSizeBytes = 10 * 1024 * 1024; // 10 MB as conservative default
      _messagePreloadCount = 20; // Conservative default
      
      // Try to set the image cache even if other initialization fails
      _safelySetImageCache(_imageCacheSizeBytes);
    }
  }
  
  // Safely set the image cache size with fallback
  void _safelySetImageCache(int sizeBytes) {
    try {
      if (PaintingBinding.instance != null) {
        PaintingBinding.instance.imageCache.maximumSizeBytes = sizeBytes;
      }
    } catch (e) {
      debugPrint('Error setting image cache size: $e');
      // Cache setting failure is non-critical
    }
  }
  
  /// Update memory optimization settings
  Future<void> updateSettings({
    int? maxCacheSize,
    bool? aggressiveCleanup,
    double? lowMemoryThreshold,
  }) async {
    if (!_isEnabled) return;
    
    try {
      if (maxCacheSize != null) _maxCacheSize = maxCacheSize;
      if (aggressiveCleanup != null) _aggressiveCleanup = aggressiveCleanup;
      if (lowMemoryThreshold != null) _lowMemoryThreshold = lowMemoryThreshold;
      
      // Apply the settings immediately
      await _applySettings();
      
      // Save the settings to persistent storage
      final prefs = await SharedPreferences.getInstance();
      if (maxCacheSize != null) await prefs.setInt('memory_max_cache_size', maxCacheSize);
      if (aggressiveCleanup != null) await prefs.setBool('memory_aggressive_cleanup', aggressiveCleanup);
      if (lowMemoryThreshold != null) await prefs.setDouble('memory_low_threshold', lowMemoryThreshold);
      
      debugPrint('Memory optimizer settings updated');
    } catch (e) {
      debugPrint('Failed to update memory optimizer settings: $e');
      // Continue with current settings
    }
  }
  
  /// Apply current settings
  Future<void> _applySettings() async {
    // Example: adjust cache sizes based on settings
    if (PaintingBinding.instance != null) {
      PaintingBinding.instance.imageCache.maximumSizeBytes = (_maxCacheSize / 2).round(); // Half for images
    }
    
    // Clear caches if aggressive cleanup is enabled
    if (_aggressiveCleanup) {
      await clearImageCache();
      await clearMemoryCache();
    }
  }
  
  /// Clear the image cache
  Future<void> clearImageCache() async {
    try {
      if (PaintingBinding.instance != null) {
        PaintingBinding.instance.imageCache.clear();
      }
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }
  
  /// Clear memory cache
  Future<void> clearMemoryCache() async {
    try {
      _cachedResources.clear();
      _totalCacheSize = 0;
    } catch (e) {
      debugPrint('Error clearing memory cache: $e');
    }
  }
  
  /// Enable or disable memory optimization
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    
    // If enabling after being disabled, do an immediate cleanup
    if (enabled && !_isEnabled) {
      _scheduleCleanup(immediate: true);
    }
  }
  
  /// Mark a room as actively used to prevent cleanup
  void markRoomAsActive(String roomId) {
    if (!_isEnabled) return;
    
    try {
      _activeRooms.add(roomId);
      _lastAccessTimes[roomId] = DateTime.now();
      _updateLRU(roomId);
    } catch (e) {
      _handleError('Error marking room as active: $e');
    }
  }
  
  /// Update the LRU (Least Recently Used) cache
  void _updateLRU(String key) {
    try {
      // Remove and re-add to move to the end (most recently used)
      _lruCache.remove(key);
      _lruCache[key] = 1;
      
      // If we exceed the LRU cache size, remove oldest items
      while (_lruCache.length > _maxCachedRooms * 2) {
        // Additional safeguard for empty map (shouldn't happen but just in case)
        if (_lruCache.isEmpty) break;
        final oldestKey = _lruCache.keys.first;
        _lruCache.remove(oldestKey);
      }
    } catch (e) {
      _handleError('Error updating LRU cache: $e');
      // Try to recover by clearing the LRU cache if it's in a bad state
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        _lruCache.clear();
        _consecutiveErrors = 0; // Reset after recovery attempt
      }
    }
  }
  
  /// Handle errors with smart handling to prevent error spam
  void _handleError(String message) {
    _consecutiveErrors++;
    
    // Only log frequent errors a limited number of times
    if (_consecutiveErrors <= _maxConsecutiveErrors) {
      debugPrint(message);
    } else if (_consecutiveErrors == _maxConsecutiveErrors + 1) {
      // Log one final message when we start suppressing
      debugPrint('$message (suppressing further similar errors)');
    }
    
    // Reset error count periodically
    Timer(const Duration(minutes: 5), () {
      _consecutiveErrors = 0;
    });
  }
  
  /// Track memory usage of messages in a room
  void trackRoomMessageCount(String roomId, int messageCount) {
    if (!_isEnabled) return;
    
    try {
      final oldCount = _roomMessageCounts[roomId] ?? 0;
      _roomMessageCounts[roomId] = messageCount;
      
      // Approximate memory calculation (very rough estimate)
      const avgMessageSizeBytes = 2048; // 2KB per message average
      final memoryDelta = (messageCount - oldCount) * avgMessageSizeBytes;
      _estimatedMemoryUsage += memoryDelta;
      
      // Use max to prevent negative values if counts decrease
      _estimatedMemoryUsage = max(0, _estimatedMemoryUsage);
      
      // If this room exceeds message count, schedule a cleanup
      if (messageCount > _maxCachedMessages && oldCount <= _maxCachedMessages) {
        debugPrint('Room $roomId exceeds message limit ($messageCount), scheduling cleanup');
        _scheduleCleanup();
      }
      
      // If total estimated memory is extremely high, trigger immediate cleanup
      if (_estimatedMemoryUsage > 200 * 1024 * 1024) { // > 200MB
        debugPrint('High estimated memory usage (${_estimatedMemoryUsage ~/ (1024 * 1024)}MB), triggering immediate cleanup');
        _scheduleCleanup(immediate: true);
      }
    } catch (e) {
      _handleError('Error tracking room message count: $e');
    }
  }
  
  /// Add a resource to the cache with size tracking
  void addToCache(String key, dynamic resource, int sizeBytes) {
    if (!_isEnabled) return;
    
    try {
      // Validate size before adding (defensive check)
      if (sizeBytes <= 0 || sizeBytes > 50 * 1024 * 1024) { // > 50MB is suspicious
        debugPrint('Warning: Attempted to cache resource with invalid size: $sizeBytes bytes');
        sizeBytes = min(10 * 1024 * 1024, max(1024, sizeBytes)); // Clamp to reasonable range
      }
      
      final existingResource = _cachedResources[key];
      if (existingResource != null) {
        _totalCacheSize -= existingResource.sizeBytes;
      }
      
      _cachedResources[key] = CachedResource(
        resource: resource,
        sizeBytes: sizeBytes,
        accessTime: DateTime.now(),
      );
      
      _totalCacheSize += sizeBytes;
      _updateLRU(key);
      
      // If cache is too large, remove least recently used items
      _enforceCacheSize();
    } catch (e) {
      _handleError('Error adding resource to cache: $e');
      
      // If cache tracking is having issues, clear it as last resort
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        try {
          _cachedResources.clear();
          _totalCacheSize = 0;
          debugPrint('Cache tracking error detected, cleared cache as recovery measure');
          _consecutiveErrors = 0; // Reset after recovery attempt
        } catch (_) {
          // Silently continue if even this fails
        }
      }
    }
  }
  
  /// Get a cached resource
  T? getFromCache<T>(String key) {
    if (!_isEnabled) return null;
    
    try {
      final resource = _cachedResources[key];
      if (resource != null) {
        // Update access time
        _cachedResources[key] = CachedResource(
          resource: resource.resource,
          sizeBytes: resource.sizeBytes,
          accessTime: DateTime.now(),
        );
        _updateLRU(key);
        return resource.resource as T?;
      }
    } catch (e) {
      _handleError('Error retrieving resource from cache: $e');
    }
    return null;
  }
  
  /// Ensure the cache doesn't exceed size limits
  void _enforceCacheSize() {
    if (_totalCacheSize <= _imageCacheSizeBytes) return;
    
    try {
      // First make a safety check on total cache size
      int calculatedSize = 0;
      for (final entry in _cachedResources.entries) {
        calculatedSize += entry.value.sizeBytes;
      }
      
      // If there's a big discrepancy, reset the tracking
      if (calculatedSize < _totalCacheSize * 0.5 || calculatedSize > _totalCacheSize * 1.5) {
        debugPrint('Cache size tracking discrepancy detected: tracked=$_totalCacheSize, calculated=$calculatedSize');
        _totalCacheSize = calculatedSize;
      }
      
      // Sort by least recently accessed
      final sortedResources = _cachedResources.entries.toList()
        ..sort((a, b) => a.value.accessTime.compareTo(b.value.accessTime));
      
      // Remove oldest items until we're under the limit
      for (final entry in sortedResources) {
        if (_totalCacheSize <= _imageCacheSizeBytes * 0.8) break; // Keep 20% buffer
        
        final key = entry.key;
        final size = entry.value.sizeBytes;
        
        _cachedResources.remove(key);
        _totalCacheSize -= size;
        
        debugPrint('Removed resource from cache: $key (${size ~/ 1024}KB)');
      }
    } catch (e) {
      _handleError('Error enforcing cache size: $e');
      
      // Last resort cache clear if we keep having issues
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        try {
          _cachedResources.clear();
          _totalCacheSize = 0;
          _consecutiveErrors = 0;
        } catch (_) {
          // Silently continue if even this fails
        }
      }
    }
  }
  
  // Return max of two integers - helper function for safety
  int max(int a, int b) => a > b ? a : b;
  
  // Return min of two integers - helper function for safety
  int min(int a, int b) => a < b ? a : b;
  
  /// Schedule a cleanup in the near future
  void _scheduleCleanup({bool immediate = false}) {
    // Don't schedule if we recently cleaned up
    if (!immediate && _lastCleanupTime != null && 
        DateTime.now().difference(_lastCleanupTime!) < Duration(seconds: 30)) {
      return;
    }
    
    if (immediate) {
      // Execute cleanup immediately
      _cleanupMemory();
    } else {
      // Use microtask to avoid blocking the UI
      scheduleMicrotask(() {
        _cleanupMemory();
      });
    }
  }
  
  /// Clean up excess memory usage
  void _cleanupMemory() {
    if (!_isEnabled) return;
    
    try {
      _lastCleanupTime = DateTime.now();
      
      // Clean up image cache if needed
      _safelyCleanImageCache();
      
      // Clean up LRU cache if needed
      _safelyCleanLRUCache();
      
      // Check if we have rooms with too many messages
      _identifyRoomsForCleanup();
    } catch (e) {
      _handleError('Error during memory cleanup: $e');
      
      // Try individual cleanup steps if the combined approach failed
      try { _safelyCleanImageCache(); } catch (_) {}
      try { _safelyCleanLRUCache(); } catch (_) {}
      try { _identifyRoomsForCleanup(); } catch (_) {}
    }
  }
  
  // Safely clean the image cache
  void _safelyCleanImageCache() {
    try {
      if (PaintingBinding.instance != null &&
          PaintingBinding.instance.imageCache.currentSizeBytes > _imageCacheSizeBytes) {
        final oldSize = PaintingBinding.instance.imageCache.currentSizeBytes;
        PaintingBinding.instance.imageCache.clear();
        debugPrint('Cleared image cache (${oldSize ~/ 1024}KB)');
      }
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
      // This is non-critical, can continue without it
    }
  }
  
  // Safely clean the LRU cache
  void _safelyCleanLRUCache() {
    try {
      while (_lruCache.length > _maxCachedRooms * 1.5) {
        if (_lruCache.isEmpty) break; // Safety check
        final oldestKey = _lruCache.keys.first;
        _lruCache.remove(oldestKey);
      }
    } catch (e) {
      debugPrint('Error cleaning LRU cache: $e');
      // If cleaning fails, try to reset the whole cache
      try { _lruCache.clear(); } catch (_) {}
    }
  }
  
  // Identify rooms that need cleanup
  void _identifyRoomsForCleanup() {
    try {
      final roomsToClear = <String>[];
      
      for (final entry in _roomMessageCounts.entries) {
        final roomId = entry.key;
        final count = entry.value;
        
        if (count > _maxCachedMessages && !_activeRooms.contains(roomId)) {
          roomsToClear.add(roomId);
          debugPrint('Requesting cleanup of room $roomId ($count messages)');
        }
      }
      
      // Notify if rooms need cleanup
      if (roomsToClear.isNotEmpty && onClearRoomsCallback != null) {
        try {
          onClearRoomsCallback!(roomsToClear);
        } catch (e) {
          debugPrint('Error in room cleanup callback: $e');
        }
      }
    } catch (e) {
      debugPrint('Error identifying rooms for cleanup: $e');
    }
  }
  
  /// Get the number of messages to preload for a room
  int getMessagePreloadCount() {
    if (!_isEnabled) return 50; // Default if not optimizing
    
    try {
      // Adjust based on memory pressure and device capabilities
      if (_isInBackground) {
        return max(5, _messagePreloadCount ~/ 2);
      } else if (_estimatedMemoryUsage > 100 * 1024 * 1024) { // > 100MB
        return max(10, _messagePreloadCount ~/ 1.5);
      } else {
        return _messagePreloadCount;
      }
    } catch (e) {
      _handleError('Error calculating message preload count: $e');
      // Return conservative default on error
      return 20; 
    }
  }
  
  /// Clear unused rooms to free up memory
  void clearUnusedRooms(List<String> allRoomIds) {
    if (!_isEnabled) return;
    
    try {
      final roomsToKeep = <String>{};
      final roomsToClear = <String>[];
      
      // Always keep active rooms
      roomsToKeep.addAll(_activeRooms);
      
      // If we have more rooms than our limit, decide which to keep
      if (allRoomIds.length > _maxCachedRooms) {
        // Create a list of rooms sorted by last access time (most recent first)
        final sortedRooms = _lastAccessTimes.entries
            .where((e) => allRoomIds.contains(e.key))
            .toList();
            
        // Sort safely with error handling
        try {
          sortedRooms.sort((a, b) => b.value.compareTo(a.value));
        } catch (e) {
          debugPrint('Error sorting rooms by access time: $e');
          // Just continue with unsorted list as fallback
        }
        
        // Keep the most recently accessed rooms up to our limit
        for (final entry in sortedRooms) {
          if (roomsToKeep.length >= _maxCachedRooms) break;
          roomsToKeep.add(entry.key);
        }
        
        // Determine which rooms to clear
        for (final roomId in allRoomIds) {
          if (!roomsToKeep.contains(roomId)) {
            roomsToClear.add(roomId);
          }
        }
        
        if (roomsToClear.isNotEmpty) {
          debugPrint('Clearing ${roomsToClear.length} unused rooms');
          
          // Call the callback safely
          if (onClearRoomsCallback != null) {
            try {
              onClearRoomsCallback!(roomsToClear);
            } catch (e) {
              debugPrint('Error in room cleanup callback: $e');
              // Continue with cache cleanup anyway
            }
          }
          
          // Update cache info
          _updateCacheAfterRoomCleanup(roomsToClear);
        }
      }
    } catch (e) {
      _handleError('Error clearing unused rooms: $e');
      
      // If we had too many errors, do a more aggressive cleanup
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        _triggerEmergencyCleanup();
      }
    }
  }
  
  // Update cache tracking after room cleanup
  void _updateCacheAfterRoomCleanup(List<String> roomsToClear) {
    try {
      for (final roomId in roomsToClear) {
        _estimatedMemoryUsage -= (_roomMessageCounts[roomId] ?? 0) * 2048;
        _roomMessageCounts.remove(roomId);
        _lastAccessTimes.remove(roomId);
        _lruCache.remove(roomId);
      }
      
      // Safety check - ensure memory usage doesn't go negative
      _estimatedMemoryUsage = max(0, _estimatedMemoryUsage);
    } catch (e) {
      debugPrint('Error updating cache after room cleanup: $e');
    }
  }
  
  // Trigger emergency cleanup when memory tracking is unreliable
  void _triggerEmergencyCleanup() {
    debugPrint('Triggering emergency memory cleanup');
    
    try {
      // Clear all caches
      PaintingBinding.instance?.imageCache?.clear();
      _cachedResources.clear();
      _totalCacheSize = 0;
      
      // Reset error counter
      _consecutiveErrors = 0;
      
      // Keep only active rooms at this point
      final activeRoomsCopy = Set<String>.from(_activeRooms);
      final roomsToRemove = <String>[];
      
      for (final roomId in _roomMessageCounts.keys) {
        if (!activeRoomsCopy.contains(roomId)) {
          roomsToRemove.add(roomId);
        }
      }
      
      _updateCacheAfterRoomCleanup(roomsToRemove);
      
      // Notify callback
      if (roomsToRemove.isNotEmpty && onClearRoomsCallback != null) {
        try {
          onClearRoomsCallback!(roomsToRemove);
        } catch (_) {
          // Ignore errors in callback during emergency cleanup
        }
      }
      
      // Notify listeners about memory pressure
      try {
        onLowMemoryCallback?.call(true);
      } catch (_) {
        // Ignore callback errors
      }
    } catch (e) {
      debugPrint('Failed during emergency cleanup: $e');
      // Not much else we can do at this point
    }
  }
  
  /// Handle app going to background
  void onAppBackground() {
    if (!_isEnabled) return;
    
    try {
      _isInBackground = true;
      debugPrint('App in background, reducing memory usage');
      
      // Clear image cache
      _safelyCleanImageCache();
      
      // Schedule periodic cleanup while in background
      _backgroundCleanupTimer?.cancel();
      _backgroundCleanupTimer = Timer.periodic(Duration(minutes: 5), (timer) {
        if (_isInBackground) {
          handleLowMemory();
        } else {
          timer.cancel();
        }
      });
      
      // Clear non-active resources
      _clearNonActiveResources();
      
      // Notify listeners
      _safelyNotifyLowMemory(true);
    } catch (e) {
      _handleError('Error handling app going to background: $e');
      
      // Try to do minimal cleanup if the full process failed
      try { PaintingBinding.instance?.imageCache?.clear(); } catch (_) {}
    }
  }
  
  // Safely clear non-active resources
  void _clearNonActiveResources() {
    try {
      final keysToRemove = <String>[];
      for (final entry in _cachedResources.entries) {
        final key = entry.key;
        if (!_activeRooms.any((roomId) => key.contains(roomId))) {
          keysToRemove.add(key);
          _totalCacheSize -= entry.value.sizeBytes;
        }
      }
      
      for (final key in keysToRemove) {
        _cachedResources.remove(key);
      }
      
      // Safety check - ensure cache size doesn't go negative
      _totalCacheSize = max(0, _totalCacheSize);
    } catch (e) {
      debugPrint('Error clearing non-active resources: $e');
      
      // Last resort - clear everything
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        try {
          _cachedResources.clear();
          _totalCacheSize = 0;
        } catch (_) {}
      }
    }
  }
  
  // Safely notify about memory state changes
  void _safelyNotifyLowMemory(bool isLowMemory) {
    if (onLowMemoryCallback != null) {
      try {
        onLowMemoryCallback!(isLowMemory);
      } catch (e) {
        debugPrint('Error in low memory callback: $e');
      }
    }
  }
  
  /// Handle app coming to foreground
  void onAppForeground() {
    if (!_isEnabled) return;
    
    try {
      _isInBackground = false;
      _backgroundCleanupTimer?.cancel();
      debugPrint('App in foreground, resuming normal memory usage');
      
      // Notify listeners
      _safelyNotifyLowMemory(false);
    } catch (e) {
      _handleError('Error handling app coming to foreground: $e');
    }
  }
  
  /// Handle low memory condition
  void handleLowMemory() {
    if (!_isEnabled) return;
    
    try {
      // Don't trigger too frequently
      final now = DateTime.now();
      if (_lastMemoryPressureTime != null && 
          now.difference(_lastMemoryPressureTime!) < Duration(seconds: 30)) {
        return;
      }
      _lastMemoryPressureTime = now;
      
      debugPrint('Handling low memory condition');
      
      // Clear all caches
      PaintingBinding.instance?.imageCache?.clear();
      _cachedResources.clear();
      _totalCacheSize = 0;
      
      // Keep only active rooms in memory
      final roomsToKeep = _activeRooms.toSet();
      final roomsToClear = <String>[];
      
      for (final roomId in _roomMessageCounts.keys.toList()) {
        if (!roomsToKeep.contains(roomId)) {
          roomsToClear.add(roomId);
        }
      }
      
      if (roomsToClear.isNotEmpty) {
        debugPrint('Clearing ${roomsToClear.length} rooms due to low memory');
        
        // Notify callback
        if (onClearRoomsCallback != null) {
          try {
            onClearRoomsCallback!(roomsToClear);
          } catch (e) {
            debugPrint('Error in room cleanup callback: $e');
          }
        }
        
        // Update tracking data
        _updateCacheAfterRoomCleanup(roomsToClear);
      }
      
      // Notify listeners
      _safelyNotifyLowMemory(true);
    } catch (e) {
      _handleError('Error handling low memory condition: $e');
      
      // If regular handling fails, try emergency cleanup
      _triggerEmergencyCleanup();
    }
  }
  
  /// Get memory statistics
  Map<String, dynamic> getMemoryStats() {
    try {
      return {
        'total_cached_resources': _cachedResources.length,
        'total_cache_size_kb': _totalCacheSize ~/ 1024,
        'image_cache_size_kb': PaintingBinding.instance?.imageCache?.currentSizeBytes.toString() ?? 'unknown',
        'image_cache_count': PaintingBinding.instance?.imageCache?.currentSize.toString() ?? 'unknown',
        'active_rooms': _activeRooms.length,
        'tracked_rooms': _roomMessageCounts.length,
        'estimated_memory_usage_mb': _estimatedMemoryUsage ~/ (1024 * 1024),
        'is_in_background': _isInBackground,
      };
    } catch (e) {
      debugPrint('Error generating memory stats: $e');
      
      // Return minimal information on error
      return {
        'error': 'Failed to generate complete memory stats',
        'cached_resources_count': _cachedResources.length,
        'active_rooms': _activeRooms.length,
        'is_in_background': _isInBackground,
      };
    }
  }
}

/// Represents a cached resource with size tracking
class CachedResource {
  final dynamic resource;
  final int sizeBytes;
  final DateTime accessTime;
  
  CachedResource({
    required this.resource,
    required this.sizeBytes,
    required this.accessTime,
  });
} 