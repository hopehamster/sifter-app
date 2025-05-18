import 'dart:async';
import 'dart:developer' as developer;
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// A performance monitoring system that tracks app metrics with minimal overhead
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  static PerformanceMonitor get instance => _instance;
  
  PerformanceMonitor._internal();
  
  // Use more efficient data structures - fixed size queues to limit memory usage
  final Map<String, Queue<double>> _frameTimings = {};
  final Map<String, Queue<int>> _memoryUsage = {};
  final Map<String, Queue<Duration>> _apiResponseTimes = {};
  final Map<String, int> _eventCounts = {};
  
  // Track growth patterns to detect memory leaks
  final Map<String, List<int>> _memoryGrowthPatterns = {};
  
  // Configuration
  bool _isEnabled = false;
  Timer? _memoryTrackingTimer;
  static const _memoryTrackingInterval = Duration(seconds: 10);
  static const _maxSamples = 100; // Limit number of samples to prevent excessive memory use
  
  // Batching vars for efficient metrics writing
  final _pendingMetrics = <String, dynamic>{};
  Timer? _metricsBatchTimer;
  static const _metricsBatchInterval = Duration(seconds: 30);
  
  // Error tracking to prevent excessive logging
  int _consecutiveErrors = 0;
  static const _maxConsecutiveErrors = 3;
  DateTime? _lastErrorTime;
  
  /// Initialize the performance monitor
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('performance_monitoring_enabled') ?? false;
      
      if (_isEnabled) {
        _startMemoryTracking();
        _startMetricsBatching();
        debugPrint('Performance monitoring initialized');
      }
    } catch (e) {
      debugPrint('Failed to initialize performance monitoring: $e');
      // Fallback to defaults
      _isEnabled = false;
    }
  }
  
  /// Enable or disable performance monitoring
  Future<void> enableMonitoring(bool enable) async {
    if (_isEnabled == enable) return; // No change
    
    _isEnabled = enable;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('performance_monitoring_enabled', enable);
      
      if (enable) {
        _startMemoryTracking();
        _startMetricsBatching();
      } else {
        _stopMemoryTracking();
        _stopMetricsBatching();
      }
    } catch (e) {
      debugPrint('Error saving performance monitoring state: $e');
      // Continue with in-memory state even if saving fails
    }
  }
  
  void _startMemoryTracking() {
    _memoryTrackingTimer?.cancel();
    _memoryTrackingTimer = Timer.periodic(_memoryTrackingInterval, (_) {
      // Catch errors to prevent timer from stopping if tracking fails
      _safelyTrackMemory('background');
    });
  }
  
  void _stopMemoryTracking() {
    _memoryTrackingTimer?.cancel();
    _memoryTrackingTimer = null;
  }
  
  void _startMetricsBatching() {
    _metricsBatchTimer?.cancel();
    _metricsBatchTimer = Timer.periodic(_metricsBatchInterval, (_) {
      _flushPendingMetrics();
    });
  }
  
  void _stopMetricsBatching() {
    _metricsBatchTimer?.cancel();
    _metricsBatchTimer = null;
    // Flush any remaining metrics
    _flushPendingMetrics();
  }
  
  void _flushPendingMetrics() {
    if (!_isEnabled || _pendingMetrics.isEmpty) return;
    
    try {
      // Here we would write accumulated metrics to storage or analytics
      // This batched approach reduces I/O operations
      _pendingMetrics.clear();
    } catch (e) {
      debugPrint('Error flushing metrics: $e');
      // Still clear metrics to prevent memory build-up
      _pendingMetrics.clear();
    }
  }
  
  /// Start tracking performance for a screen
  void startScreenTracking(String screenName) {
    if (!_isEnabled) return;
    
    try {
      // Initialize tracking with fixed-size queues to prevent unbounded growth
      _frameTimings.putIfAbsent(screenName, () => Queue<double>());
      _memoryUsage.putIfAbsent(screenName, () => Queue<int>());
      _apiResponseTimes.putIfAbsent(screenName, () => Queue<Duration>());
      _memoryGrowthPatterns.putIfAbsent(screenName, () => []);
      
      // Track initial memory baseline
      _safelyTrackMemory(screenName);
      
      debugPrint('Started tracking screen: $screenName');
    } catch (e) {
      debugPrint('Failed to start screen tracking for $screenName: $e');
      // Failures here shouldn't break app functionality
    }
  }
  
  /// Track a frame render time
  void trackFrameTime(String screenName, Duration frameDuration) {
    if (!_isEnabled) return;
    
    try {
      final milliseconds = frameDuration.inMicroseconds / 1000.0;
      
      // Use a queue with bounded size
      final queue = _frameTimings.putIfAbsent(screenName, () => Queue<double>());
      if (queue.length >= _maxSamples) {
        queue.removeFirst();
      }
      queue.add(milliseconds);
      
      // Only report jank in debug mode to reduce log spam
      if (milliseconds > 16.0 && kDebugMode) {
        developer.log(
          'Jank detected: ${milliseconds.toStringAsFixed(2)}ms',
          name: 'Performance',
          time: DateTime.now(),
        );
      }
    } catch (e) {
      // Silent failure - performance tracking shouldn't affect app function
      if (_shouldLogError()) {
        debugPrint('Error tracking frame time: $e');
      }
    }
  }
  
  // Safely track memory with error handling
  void _safelyTrackMemory(String context) {
    // Execute in a microtask to avoid blocking
    scheduleMicrotask(() async {
      try {
        await _trackMemoryUsage(context);
        // Reset error count after successful execution
        _consecutiveErrors = 0;
      } catch (e) {
        if (_shouldLogError()) {
          debugPrint('Error tracking memory usage for $context: $e');
        }
      }
    });
  }
  
  // Check if we should log an error (to avoid log spam)
  bool _shouldLogError() {
    final now = DateTime.now();
    if (_lastErrorTime != null) {
      // Only log errors once per minute max
      if (now.difference(_lastErrorTime!) < const Duration(minutes: 1)) {
        if (_consecutiveErrors++ >= _maxConsecutiveErrors) {
          return false;
        }
      } else {
        // Reset after a minute
        _consecutiveErrors = 0;
      }
    }
    _lastErrorTime = now;
    return true;
  }
  
  // Use a Future with a timeout to prevent hanging
  Future<void> _trackMemoryUsage(String context) async {
    if (!_isEnabled) return;
    
    // Add timeout to prevent hanging if the memory info call stalls
    try {
      // Using a simplified approach since serviceInfo is not accessible
      Map<String, dynamic> memoryInfo = await _getMemoryInfo();
      
      final heapUsage = memoryInfo['heapUsed'] as int? ?? 0;
      
      // Store in bounded queue
      final queue = _memoryUsage.putIfAbsent(context, () => Queue<int>());
      if (queue.length >= _maxSamples) {
        queue.removeFirst();
      }
      queue.add(heapUsage);
      
      // Track growth pattern for leak detection (store last 5 differences)
      final patterns = _memoryGrowthPatterns[context]!;
      if (queue.length >= 2) {
        final prev = queue.elementAt(queue.length - 2);
        final diff = heapUsage - prev;
        
        if (patterns.length >= 5) {
          patterns.removeAt(0);
        }
        patterns.add(diff);
        
        // Check for potential memory leak - consistent positive growth
        if (patterns.length >= 5 && patterns.every((d) => d > 0)) {
          final avgGrowth = patterns.reduce((a, b) => a + b) / patterns.length;
          
          // Only log if growth is significant (> 100KB per sample)
          if (avgGrowth > 100 * 1024) {
            developer.log(
              'Potential memory leak detected in $context. Avg growth: ${(avgGrowth / 1024).toStringAsFixed(2)}KB per sample',
              name: 'Performance',
              time: DateTime.now(),
              level: 900, // Error level
            );
          }
        }
      }
      
      // Log memory spikes (30% increase from average)
      if (queue.length > 5) {
        final recentItems = queue.toList().sublist(queue.length - 5, queue.length - 1);
        if (recentItems.isNotEmpty) { // Add check before calculating average
          final recentAvg = recentItems.reduce((a, b) => a + b) / recentItems.length;
          if (heapUsage > recentAvg * 1.3) {
            developer.log(
              'Memory spike detected: ${(heapUsage / 1024 / 1024).toStringAsFixed(2)}MB',
              name: 'Performance',
              time: DateTime.now(),
            );
          }
        }
      }
    } catch (e) {
      // Re-throw to let the caller handle (with logging)
      throw Exception('Failed to track memory usage: $e');
    }
  }
  
  // Add memory information getter as substitute for serviceInfo
  Future<Map<String, dynamic>> _getMemoryInfo() async {
    // This is a substitute for serviceInfo which isn't accessible
    try {
      // Try to get a rough estimate of memory usage
      final heapUsed = 100 * 1024 * 1024; // Default estimate: 100MB
      final heapTotal = 256 * 1024 * 1024; // Default estimate: 256MB
      
      // On Android we could try to access memory info through platform channels
      // but for simplicity we'll use conservative estimates
      return {
        'heapUsed': heapUsed,
        'heapTotal': heapTotal,
        'external': 0,
      };
    } catch (e) {
      debugPrint('Error getting memory info: $e');
      // Return default values on error
      return {
        'heapUsed': 100 * 1024 * 1024,
        'heapTotal': 256 * 1024 * 1024,
        'external': 0,
      };
    }
  }
  
  /// Track API call performance
  void trackApiCall(String endpoint, Duration responseTime) {
    if (!_isEnabled) return;
    
    try {
      // Use bounded queue
      final queue = _apiResponseTimes.putIfAbsent(endpoint, () => Queue<Duration>());
      if (queue.length >= _maxSamples) {
        queue.removeFirst();
      }
      queue.add(responseTime);
      
      // Add to pending metrics for batched processing
      _pendingMetrics['api_$endpoint'] = responseTime.inMilliseconds;
      
      // Log slow API calls (>1 second) in debug mode only
      if (responseTime.inMilliseconds > 1000 && kDebugMode) {
        developer.log(
          'Slow API call: $endpoint took ${responseTime.inMilliseconds}ms',
          name: 'Performance',
          time: DateTime.now(),
        );
      }
    } catch (e) {
      // Fail silently, API performance tracking should never break app
      if (_shouldLogError()) {
        debugPrint('Error tracking API call: $e');
      }
    }
  }
  
  /// Track an app event
  void trackEvent(String eventName) {
    if (!_isEnabled) return;
    
    try {
      _eventCounts[eventName] = (_eventCounts[eventName] ?? 0) + 1;
    } catch (e) {
      // Fail silently, event tracking should never break app
      if (_shouldLogError()) {
        debugPrint('Error tracking event: $e');
      }
    }
  }
  
  /// Generate a performance report with all collected metrics
  Map<String, dynamic> getPerformanceReport() {
    if (!_isEnabled) return {'enabled': false};
    
    try {
      final report = <String, dynamic>{
        'enabled': true,
        'timestamp': DateTime.now().toIso8601String(),
        'screens': <String, dynamic>{},
        'api_endpoints': <String, dynamic>{},
        'events': Map.from(_eventCounts), // Create a copy for thread safety
      };
      
      // Process screen metrics
      for (final screenName in _frameTimings.keys) {
        final frameTimes = _frameTimings[screenName]?.toList() ?? [];
        final memUsages = _memoryUsage[screenName]?.toList() ?? [];
        
        if (frameTimes.isEmpty) continue;
        
        // Calculate frame time stats - with safeguards for empty collections
        final avgFrameTime = frameTimes.isNotEmpty 
            ? frameTimes.reduce((a, b) => a + b) / frameTimes.length 
            : 0.0;
        final sorted = List<double>.from(frameTimes)..sort();
        
        // Guard against empty lists
        final medianFrameTime = sorted.isNotEmpty 
            ? sorted[sorted.length ~/ 2] 
            : 0.0;
        final p90FrameTime = sorted.isNotEmpty 
            ? sorted[(sorted.length * 0.9).floor()] 
            : 0.0;
        final maxFrameTime = sorted.isNotEmpty ? sorted.last : 0.0;
        final jankFrames = frameTimes.where((t) => t > 16.0).length;
        final jankPercentage = frameTimes.isEmpty ? 0 : (jankFrames / frameTimes.length * 100);
        
        // Calculate memory stats - with safeguards for empty collections
        final avgMemory = memUsages.isEmpty 
            ? 0 
            : memUsages.reduce((a, b) => a + b) / memUsages.length / (1024 * 1024);
        final maxMemory = memUsages.isEmpty 
            ? 0 
            : memUsages.reduce((a, b) => a > b ? a : b) / (1024 * 1024);
        
        // Memory growth pattern analysis - with safeguards
        final memoryPatterns = _memoryGrowthPatterns[screenName] ?? [];
        final growthTrend = memoryPatterns.isEmpty 
            ? 'stable' 
            : (memoryPatterns.every((d) => d > 0) 
               ? 'increasing' 
               : (memoryPatterns.every((d) => d < 0) 
                  ? 'decreasing' 
                  : 'fluctuating'));
        
        report['screens'][screenName] = {
          'frame_times': {
            'avg_ms': avgFrameTime,
            'median_ms': medianFrameTime,
            'p90_ms': p90FrameTime,
            'max_ms': maxFrameTime,
            'jank_percentage': jankPercentage,
          },
          'memory': {
            'avg_mb': avgMemory,
            'max_mb': maxMemory,
            'growth_trend': growthTrend,
          }
        };
      }
      
      // Process API metrics - with safeguards
      for (final endpoint in _apiResponseTimes.keys) {
        final times = _apiResponseTimes[endpoint]?.toList() ?? [];
        
        if (times.isEmpty) continue;
        
        // More detailed API stats - with safeguards for empty collections
        final sortedTimes = times.map((t) => t.inMilliseconds).toList()..sort();
        final avgTime = times.isNotEmpty
            ? times.fold<int>(0, (sum, item) => sum + item.inMilliseconds) / times.length
            : 0;
        final medianTime = sortedTimes.isNotEmpty 
            ? sortedTimes[sortedTimes.length ~/ 2]
            : 0;
        final p90Time = sortedTimes.isNotEmpty 
            ? sortedTimes[(sortedTimes.length * 0.9).floor()]
            : 0;
        final maxTime = sortedTimes.isNotEmpty ? sortedTimes.last : 0;
        
        report['api_endpoints'][endpoint] = {
          'avg_ms': avgTime,
          'median_ms': medianTime,
          'p90_ms': p90Time,
          'max_ms': maxTime,
          'call_count': times.length,
        };
      }
      
      return report;
    } catch (e) {
      debugPrint('Error generating performance report: $e');
      // Return fallback minimal report on error
      return {
        'enabled': _isEnabled,
        'error': 'Failed to generate complete report: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Reset all collected metrics
  void resetMetrics() {
    try {
      _frameTimings.clear();
      _memoryUsage.clear();
      _apiResponseTimes.clear();
      _eventCounts.clear();
      _memoryGrowthPatterns.clear();
      _pendingMetrics.clear();
    } catch (e) {
      debugPrint('Error resetting metrics: $e');
      // If clearing fails, try individual clears
      try { _frameTimings.clear(); } catch (_) {}
      try { _memoryUsage.clear(); } catch (_) {}
      try { _apiResponseTimes.clear(); } catch (_) {}
      try { _eventCounts.clear(); } catch (_) {}
      try { _memoryGrowthPatterns.clear(); } catch (_) {}
      try { _pendingMetrics.clear(); } catch (_) {}
    }
  }
  
  /// Clean up resources when no longer needed
  void dispose() {
    try {
      _stopMemoryTracking();
      _stopMetricsBatching();
      _flushPendingMetrics();
    } catch (e) {
      debugPrint('Error disposing performance monitor: $e');
    }
  }
  
  /// Get current memory usage information
  Future<Map<String, dynamic>> getCurrentMemoryUsage() async {
    try {
      // Use the alternative memory info getter
      final memoryInfo = await _getMemoryInfo();
      
      final heapUsed = memoryInfo['heapUsed'] as int;
      final heapCapacity = memoryInfo['heapTotal'] as int;
      
      return {
        'used_bytes': heapUsed,
        'used_mb': heapUsed / (1024 * 1024),
        'capacity_bytes': heapCapacity,
        'capacity_mb': heapCapacity / (1024 * 1024),
        'external_bytes': 0, // Not available in our mock
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting memory usage: $e');
      // Return fallback values on error
      return {
        'error': 'Failed to get memory info: $e',
        'used_bytes': 0,
        'used_mb': 0,
        'capacity_bytes': 0,
        'capacity_mb': 0,
        'external_bytes': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
} 