import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'memory_optimizer.dart';
import 'network_optimizer.dart';
import 'performance_monitor.dart';

/// Central manager for all optimization features in the app
class OptimizationManager {
  static final OptimizationManager _instance = OptimizationManager._internal();
  static OptimizationManager get instance => _instance;
  
  OptimizationManager._internal();
  
  // Services
  late final MemoryOptimizer _memoryOptimizer;
  late final NetworkOptimizer _networkOptimizer;
  late final PerformanceMonitor _performanceMonitor;
  
  // Configuration
  bool _isEnabled = true;
  bool _adaptiveMode = true;
  late final AppLifecycleListener _lifecycleListener;
  
  // Device details
  DeviceCategory _deviceCategory = DeviceCategory.medium;
  DeviceInfo? _deviceInfo;
  String _appVersion = "1.0.0"; // Default version
  
  // Optimization state
  late OptimizationPreset _activePreset;
  Map<OptimizationMetric, double> _metricScores = {};
  
  // Usage tracking
  final _sessionStartTime = DateTime.now();
  bool _isFirstBoot = false;
  Timer? _periodicOptimizationTimer;
  
  // Memory pressure detection
  final _memoryPressureStreamController = StreamController<MemoryPressureLevel>.broadcast();
  Stream<MemoryPressureLevel> get memoryPressureStream => _memoryPressureStreamController.stream;
  
  /// Initialize all optimization services
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('optimization_enabled') ?? true;
    _adaptiveMode = prefs.getBool('adaptive_optimization') ?? true;
    _isFirstBoot = prefs.getBool('first_boot') ?? true;
    
    if (_isFirstBoot) {
      await prefs.setBool('first_boot', false);
    }
    
    // Initialize services
    _memoryOptimizer = MemoryOptimizer.instance;
    _networkOptimizer = NetworkOptimizer.instance;
    _performanceMonitor = PerformanceMonitor.instance;
    
    await _memoryOptimizer.initialize();
    await _networkOptimizer.initialize();
    await _performanceMonitor.initialize();
    
    // Get device information
    await _initializeDeviceInfo();
    
    // Register for app lifecycle events
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _handleAppLifecycleStateChange,
      onPause: _handleAppPause,
      onResume: _handleAppResume,
    );
    
    // Register for memory pressure events
    await _setupMemoryPressureDetection();
    
    // Determine and apply optimal preset for this device
    _activePreset = await calculateOptimalPreset();
    await applyPreset(_activePreset);
    
    // Start periodic optimization if enabled
    if (_adaptiveMode) {
      _startPeriodicOptimization();
    }
    
    debugPrint('Optimization manager initialized, enabled: $_isEnabled, adaptive: $_adaptiveMode');
    debugPrint('Device category: ${_deviceCategory.name}, applying preset: ${_activePreset.name}');
  }
  
  /// Get device information to help determine optimization strategy
  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      // Replace packageInfo with hardcoded version
      _appVersion = "1.0.0"; // Set a default version
      
      int ramMB = 0;
      String deviceModel = 'unknown';
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        // Use conservative estimate since totalMemory isn't available directly
        ramMB = androidInfo.supportedAbis.length > 2 ? 4 * 1024 : 2 * 1024;
        deviceModel = androidInfo.model;
        
        _deviceInfo = DeviceInfo(
          platform: 'Android',
          model: androidInfo.model,
          osVersion: androidInfo.version.release,
          sdkVersion: androidInfo.version.sdkInt.toString(),
          totalRamMB: ramMB,
          manufacturer: androidInfo.manufacturer,
          // Screen size not directly available in newer versions
          screenSize: 'Unknown',
        );
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceModel = iosInfo.model;
        
        // iOS doesn't expose RAM directly, use model to estimate
        ramMB = _estimateIOSRam(iosInfo.model);
        
        _deviceInfo = DeviceInfo(
          platform: 'iOS',
          model: iosInfo.model,
          osVersion: iosInfo.systemVersion,
          sdkVersion: iosInfo.utsname.version,
          totalRamMB: ramMB,
          manufacturer: 'Apple',
          screenSize: 'Unknown', // Not directly available
        );
      }
      
      // Categorize device based on RAM and model
      _deviceCategory = _categorizeDevice(ramMB, deviceModel);
      
    } catch (e) {
      debugPrint('Error getting device info: $e');
      _deviceCategory = DeviceCategory.medium; // Default to medium if we can't get info
    }
  }
  
  /// Estimate iOS device RAM based on model
  int _estimateIOSRam(String model) {
    // Use model to estimate RAM (approximate values)
    if (model.contains('iPhone15') || model.contains('iPhone16')) {
      return 8 * 1024; // Newer iPhones ~8GB
    } else if (model.contains('iPhone14')) {
      return 6 * 1024; // iPhone 14 ~6GB
    } else if (model.contains('iPhone13') || model.contains('iPhone12')) {
      return 4 * 1024; // iPhone 12/13 ~4GB
    } else if (model.contains('iPhone11') || model.contains('iPhone10')) {
      return 3 * 1024; // iPhone X/11 ~3GB
    } else if (model.contains('iPad')) {
      if (model.contains('Pro')) {
        return 8 * 1024; // iPad Pro ~8GB+
      }
      return 4 * 1024; // Other iPads ~4GB
    }
    return 2 * 1024; // Older devices ~2GB
  }
  
  /// Categorize device based on specifications
  DeviceCategory _categorizeDevice(int ramMB, String model) {
    // High-end devices
    if (ramMB >= 8 * 1024 || 
        model.contains('iPhone15') || 
        model.contains('iPhone16') ||
        model.contains('Pro') || 
        model.contains('Ultra') || 
        model.contains('Fold') ||
        model.contains('Pixel 7') ||
        model.contains('Pixel 8') ||
        model.contains('Galaxy S23') ||
        model.contains('Galaxy S24')) {
      return DeviceCategory.high;
    }
    
    // Low-end devices
    if (ramMB <= 3 * 1024 ||
        model.contains('A1') ||
        model.contains('A2') ||
        model.contains('A3') ||
        model.contains('J2') ||
        model.contains('J3') ||
        model.contains('Go') ||
        model.contains('Lite') ||
        model.contains('iPhone8') ||
        model.contains('iPhone7')) {
      return DeviceCategory.low;
    }
    
    // Medium devices (default)
    return DeviceCategory.medium;
  }
  
  /// Set up detection for low memory conditions
  Future<void> _setupMemoryPressureDetection() async {
    if (!_isEnabled) return;
    
    // Listen for platform channels memory warnings
    const MethodChannel('app/memory_pressure')
      .setMethodCallHandler((call) async {
        if (call.method == 'onLowMemory') {
          final level = call.arguments['level'] as int? ?? 1;
          final memoryLevel = level >= 2 
            ? MemoryPressureLevel.critical 
            : MemoryPressureLevel.moderate;
          
          _handleMemoryPressure(memoryLevel);
        }
        return null;
      });
    
    // Setup periodic memory checks
    Timer.periodic(Duration(minutes: 1), (_) {
      _checkMemoryStatus();
    });
  }
  
  /// Check memory status periodically
  Future<void> _checkMemoryStatus() async {
    if (!_isEnabled) return;
    
    try {
      final memoryInfo = await _performanceMonitor.getCurrentMemoryUsage();
      final memoryUsageMB = memoryInfo['used_mb'] as double? ?? 0;
      final totalMemoryMB = _deviceInfo?.totalRamMB ?? 4096;
      
      final memoryPercentage = memoryUsageMB / totalMemoryMB * 100;
      
      if (memoryPercentage > 85) {
        _handleMemoryPressure(MemoryPressureLevel.critical);
      } else if (memoryPercentage > 70) {
        _handleMemoryPressure(MemoryPressureLevel.moderate);
      }
    } catch (e) {
      debugPrint('Error checking memory status: $e');
    }
  }
  
  /// Start periodic optimization evaluations
  void _startPeriodicOptimization() {
    _periodicOptimizationTimer?.cancel();
    _periodicOptimizationTimer = Timer.periodic(Duration(minutes: 10), (_) async {
      if (_isEnabled && _adaptiveMode) {
        final metrics = await _evaluatePerformanceMetrics();
        _adjustOptimizationsBasedOnMetrics(metrics);
      }
    });
  }
  
  /// Stop periodic optimization evaluations
  void _stopPeriodicOptimization() {
    _periodicOptimizationTimer?.cancel();
    _periodicOptimizationTimer = null;
  }
  
  /// Enable or disable all optimizations
  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;
    
    _isEnabled = enabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('optimization_enabled', enabled);
    
    // Apply to individual services
    _memoryOptimizer.setEnabled(enabled);
    await _networkOptimizer.updateSettings(isEnabled: enabled);
    _performanceMonitor.enableMonitoring(enabled);
    
    if (enabled && _adaptiveMode) {
      _startPeriodicOptimization();
    } else {
      _stopPeriodicOptimization();
    }
    
    debugPrint('Optimization ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Set adaptive mode which dynamically adjusts optimizations based on device conditions
  Future<void> setAdaptiveMode(bool adaptive) async {
    if (_adaptiveMode == adaptive) return;
    
    _adaptiveMode = adaptive;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adaptive_optimization', adaptive);
    
    // Apply to network optimizer which has adaptive settings
    await _networkOptimizer.updateSettings(adaptivePolling: adaptive);
    
    if (_isEnabled && adaptive) {
      _startPeriodicOptimization();
    } else {
      _stopPeriodicOptimization();
    }
    
    debugPrint('Adaptive optimization ${adaptive ? 'enabled' : 'disabled'}');
  }
  
  /// Calculate the optimal preset based on device capabilities and app usage
  Future<OptimizationPreset> calculateOptimalPreset() async {
    try {
      // Default to balanced preset
      if (_deviceCategory == DeviceCategory.high) {
        return OptimizationPreset.performance;
      } else if (_deviceCategory == DeviceCategory.low) {
        return OptimizationPreset.efficiency;
      }
      
      // For medium devices, consider battery level and user preferences
      final prefs = await SharedPreferences.getInstance();
      final preferPerformance = prefs.getBool('prefer_performance') ?? false;
      final preferEfficiency = prefs.getBool('prefer_efficiency') ?? false;
      
      if (preferPerformance) {
        return OptimizationPreset.performance;
      } else if (preferEfficiency) {
        return OptimizationPreset.efficiency;
      }
      
      return OptimizationPreset.balanced;
    } catch (e) {
      debugPrint('Error calculating optimal preset: $e');
      return OptimizationPreset.balanced; // Safe default
    }
  }
  
  /// Apply a set of optimization presets based on device capabilities
  Future<void> applyPreset(OptimizationPreset preset) async {
    try {
      switch (preset) {
        case OptimizationPreset.performance:
          await _memoryOptimizer.updateSettings(
            maxCacheSize: 100 * 1024 * 1024, // 100 MB
            aggressiveCleanup: false,
            lowMemoryThreshold: 0.1, // 10%
          );
          await _networkOptimizer.updateSettings(
            maxConcurrentRequests: 8,
            compressRequests: false,
          );
          await _performanceMonitor.enableMonitoring(true);
          break;
        
        case OptimizationPreset.balanced:
          await _memoryOptimizer.updateSettings(
            maxCacheSize: 50 * 1024 * 1024, // 50 MB
            aggressiveCleanup: false,
            lowMemoryThreshold: 0.15, // 15%
          );
          await _networkOptimizer.updateSettings(
            maxConcurrentRequests: 6,
            compressRequests: true,
          );
          await _performanceMonitor.enableMonitoring(true);
          break;
        
        case OptimizationPreset.efficiency:
          await _memoryOptimizer.updateSettings(
            maxCacheSize: 25 * 1024 * 1024, // 25 MB
            aggressiveCleanup: true,
            lowMemoryThreshold: 0.2, // 20%
          );
          await _networkOptimizer.updateSettings(
            maxConcurrentRequests: 4,
            compressRequests: true,
          );
          await _performanceMonitor.enableMonitoring(false);
          break;
          
        // Handle additional cases for backward compatibility
        default:
          await _memoryOptimizer.updateSettings(
            maxCacheSize: 50 * 1024 * 1024, // 50 MB default
            aggressiveCleanup: false,
            lowMemoryThreshold: 0.15, // 15% default
          );
          break;
      }
      
      _activePreset = preset;
      
      // Save the applied preset
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_preset', preset.toString().split('.').last);
      
      debugPrint('Applied optimization preset: ${preset.toString().split('.').last}');
    } catch (e) {
      debugPrint('Error applying preset: $e');
      // Continue with default settings
    }
  }
  
  /// Evaluate current performance metrics to determine optimization needs
  Future<Map<OptimizationMetric, double>> _evaluatePerformanceMetrics() async {
    final metrics = <OptimizationMetric, double>{};
    
    // Get performance report
    final report = _performanceMonitor.getPerformanceReport();
    
    // Calculate frame rate score (higher is better)
    double frameRateScore = 0;
    int screenCount = 0;
    for (final screenData in (report['screens'] as Map<String, dynamic>? ?? {}).values) {
      final frameData = screenData['frame_times'] as Map<String, dynamic>? ?? {};
      final jankPercentage = frameData['jank_percentage'] as double? ?? 0;
      
      // 0 jank = score 1.0, 10% jank = score 0.5, 20%+ jank = score 0
      frameRateScore += max(0, 1.0 - (jankPercentage / 20.0));
      screenCount++;
    }
    metrics[OptimizationMetric.frameRate] = screenCount > 0 
        ? frameRateScore / screenCount 
        : 0.5; // Default if no data
    
    // Calculate memory score (higher is better)
    double memoryScore = 1.0;
    if (_deviceInfo != null) {
      final totalRamMB = _deviceInfo!.totalRamMB;
      final memoryUsage = await _performanceMonitor.getCurrentMemoryUsage();
      final usedMemoryMB = memoryUsage['used_mb'] as double? ?? 0;
      
      // Calculate score based on percentage of RAM used
      final usagePercentage = min(1.0, usedMemoryMB / totalRamMB);
      
      // 30% or less usage = score 1.0, 80%+ usage = score 0
      memoryScore = max(0, 1.0 - ((usagePercentage - 0.3) / 0.5));
    }
    metrics[OptimizationMetric.memory] = memoryScore;
    
    // Calculate network score (higher is better)
    double networkScore = 0;
    int endpointCount = 0;
    for (final endpointData in (report['api_endpoints'] as Map<String, dynamic>? ?? {}).values) {
      final avgResponseMs = endpointData['avg_ms'] as double? ?? 0;
      
      // Score based on response time: 100ms or less = 1.0, 1000ms+ = 0
      final endpointScore = max(0, 1.0 - (avgResponseMs / 1000.0));
      networkScore += endpointScore;
      endpointCount++;
    }
    metrics[OptimizationMetric.network] = endpointCount > 0 
        ? networkScore / endpointCount 
        : 0.7; // Default if no data
    
    // Store metrics for reference
    _metricScores = metrics;
    
    return metrics;
  }
  
  /// Adjust optimizations based on performance metrics
  void _adjustOptimizationsBasedOnMetrics(Map<OptimizationMetric, double> metrics) async {
    if (!_isEnabled || !_adaptiveMode) return;
    
    final avgScore = metrics.values.reduce((a, b) => a + b) / metrics.length;
    
    // Only change preset if there's a significant difference
    if (avgScore < 0.4 && _activePreset != OptimizationPreset.efficiency) {
      await applyPreset(OptimizationPreset.efficiency);
      debugPrint('Performance metrics low (${avgScore.toStringAsFixed(2)}), switching to efficiency preset');
    } else if (avgScore > 0.8 && _activePreset == OptimizationPreset.efficiency) {
      await applyPreset(OptimizationPreset.balanced);
      debugPrint('Performance metrics good (${avgScore.toStringAsFixed(2)}), switching to balanced preset');
    } else if (avgScore > 0.9 && _activePreset == OptimizationPreset.balanced) {
      await applyPreset(OptimizationPreset.performance);
      debugPrint('Performance metrics excellent (${avgScore.toStringAsFixed(2)}), switching to performance preset');
    }
  }
  
  /// Get access to the memory optimizer
  MemoryOptimizer get memory => _memoryOptimizer;
  
  /// Get access to the network optimizer
  NetworkOptimizer get network => _networkOptimizer;
  
  /// Get access to the performance monitor
  PerformanceMonitor get performance => _performanceMonitor;
  
  /// Handle app lifecycle state changes
  void _handleAppLifecycleStateChange(AppLifecycleState state) {
    if (!_isEnabled) return;
    
    debugPrint('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is terminated
        _performanceMonitor.resetMetrics();
        break;
      case AppLifecycleState.inactive:
        // App is in an inactive state (e.g. phone call)
        _memoryOptimizer.handleLowMemory();
        break;
      case AppLifecycleState.paused:
        // App is in the background
        _memoryOptimizer.onAppBackground();
        break;
      case AppLifecycleState.resumed:
        // App is in the foreground
        _memoryOptimizer.onAppForeground();
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        _memoryOptimizer.onAppBackground();
        break;
    }
  }
  
  /// Handle app pause event
  void _handleAppPause() {
    if (!_isEnabled) return;
    
    debugPrint('App paused');
    // Save performance metrics when app goes to background
    _savePerformanceReport();
  }
  
  /// Handle app resume event
  void _handleAppResume() {
    if (!_isEnabled) return;
    
    debugPrint('App resumed');
    
    // Check optimization settings when resuming
    if (_adaptiveMode) {
      _evaluatePerformanceMetrics().then(_adjustOptimizationsBasedOnMetrics);
    }
  }
  
  /// Handle low memory conditions
  void _handleMemoryPressure(MemoryPressureLevel level) {
    if (!_isEnabled) return;
    
    debugPrint('Memory pressure detected: ${level.name}');
    
    // Broadcast memory pressure event
    _memoryPressureStreamController.add(level);
    
    _memoryOptimizer.handleLowMemory();
    
    // When in adaptive mode, apply the low memory preset for critical pressure
    if (_adaptiveMode && level == MemoryPressureLevel.critical) {
      applyPreset(OptimizationPreset.efficiency);
    }
  }
  
  /// Generate and save a performance report
  Future<Map<String, dynamic>> _savePerformanceReport() async {
    if (!_isEnabled) return {'enabled': false};
    
    final report = _performanceMonitor.getPerformanceReport();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      await prefs.setString('last_performance_report_$timestamp', 
        report.toString());
    } catch (e) {
      debugPrint('Failed to save performance report: $e');
    }
    
    return report;
  }
  
  /// Generate optimization recommendations based on device performance
  Future<List<String>> generateOptimizationRecommendations() async {
    final recommendations = <String>[];
    
    if (!_isEnabled) {
      recommendations.add('Enable optimization features for improved performance');
      return recommendations;
    }
    
    final report = _performanceMonitor.getPerformanceReport();
    
    if (report['screens'] == null) {
      recommendations.add('Insufficient performance data collected');
      return recommendations;
    }
    
    // Check screens with performance issues
    for (final entry in (report['screens'] as Map<String, dynamic>).entries) {
      final screenName = entry.key;
      final screenMetrics = entry.value as Map<String, dynamic>;
      
      final frameMetrics = screenMetrics['frame_times'] as Map<String, dynamic>?;
      if (frameMetrics != null) {
        final jankPercentage = frameMetrics['jank_percentage'] as double;
        if (jankPercentage > 10) {
          recommendations.add('Screen "$screenName" has high jank percentage (${jankPercentage.toStringAsFixed(1)}%). '
            'Consider optimizing animations and reducing widget rebuilds.');
        }
      }
      
      final memoryMetrics = screenMetrics['memory'] as Map<String, dynamic>?;
      if (memoryMetrics != null) {
        final avgMemory = memoryMetrics['avg_mb'] as double;
        final memoryTrend = memoryMetrics['growth_trend'] as String? ?? 'unknown';
        
        if (avgMemory > 150) {
          recommendations.add('Screen "$screenName" has high memory usage (${avgMemory.toStringAsFixed(1)} MB). '
            'Consider implementing memory optimizations like image caching and widget recycling.');
        }
        
        if (memoryTrend == 'increasing') {
          recommendations.add('Screen "$screenName" shows increasing memory usage pattern. '
            'This may indicate a memory leak. Review dispose methods and cache clearing.');
        }
      }
    }
    
    // Check API endpoints with performance issues
    for (final entry in (report['api_endpoints'] as Map<String, dynamic>? ?? {}).entries) {
      final endpoint = entry.key;
      final metrics = entry.value as Map<String, dynamic>;
      
      final avgResponseTime = metrics['avg_ms'] as double;
      if (avgResponseTime > 1000) {
        recommendations.add('API endpoint "$endpoint" has slow response time (${avgResponseTime.toStringAsFixed(0)} ms). '
          'Consider optimizing the backend or implementing caching strategies.');
      }
    }
    
    // Overall recommendations
    if (_deviceCategory == DeviceCategory.low) {
      recommendations.add('This device is classified as low-end. Consider reducing animations, '
        'limiting image resolutions, and optimizing list rendering for better performance.');
    }
    
    return recommendations;
  }
  
  /// Get optimization status information
  Map<String, dynamic> getOptimizationStatus() {
    final sessionDuration = DateTime.now().difference(_sessionStartTime);
    
    return {
      'enabled': _isEnabled,
      'adaptive_mode': _adaptiveMode,
      'device_category': _deviceCategory.name,
      'active_preset': _activePreset.name,
      'session_duration_minutes': sessionDuration.inMinutes,
      'performance_metrics': _metricScores.map((k, v) => MapEntry(k.name, v)),
      'memory_stats': _memoryOptimizer.getMemoryStats(),
      'network_stats': _networkOptimizer.getNetworkReport(),
    };
  }
  
  /// Clean up resources
  void dispose() {
    _lifecycleListener.dispose();
    _stopPeriodicOptimization();
    _memoryPressureStreamController.close();
  }
}

/// Device performance categories
enum DeviceCategory {
  low,    // Older/budget devices with limited resources
  medium, // Mid-range devices with adequate resources
  high    // High-end devices with abundant resources
}

/// Performance metrics being tracked
enum OptimizationMetric {
  frameRate, // UI responsiveness and smoothness
  memory,    // Memory usage and management
  network    // Network performance and efficiency
}

/// Memory pressure severity levels
enum MemoryPressureLevel {
  moderate, // Memory is running low
  critical  // Memory is critically low
}

/// Optimization presets for different device categories
enum OptimizationPreset {
  /// Maximum performance, minimal optimization
  performance,
  
  /// Balance between performance and resource usage
  balanced,
  
  /// Maximize battery life and minimize resource usage
  efficiency,
}

/// Device information for optimization decisions
class DeviceInfo {
  final String platform;
  final String model;
  final String osVersion;
  final String sdkVersion;
  final int totalRamMB;
  final String manufacturer;
  final String screenSize;
  
  DeviceInfo({
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.sdkVersion,
    required this.totalRamMB,
    required this.manufacturer,
    required this.screenSize,
  });
  
  @override
  String toString() {
    return 'DeviceInfo{platform: $platform, model: $model, totalRamMB: ${totalRamMB}MB, osVersion: $osVersion}';
  }
} 