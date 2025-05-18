import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../lib/utils/optimization_manager.dart';
import '../lib/utils/memory_optimizer.dart';
import '../lib/utils/network_optimizer.dart';
import '../lib/utils/performance_monitor.dart';

/// Integration test that demonstrates the optimization utilities
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Optimization Integration Tests', () {
    late OptimizationManager optimizationManager;

    setUp(() async {
      // Set up shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      
      // Initialize the optimization manager
      optimizationManager = OptimizationManager.instance;
      await optimizationManager.initialize();
    });

    testWidgets('Apply different optimization presets', (WidgetTester tester) async {
      // Apply low memory preset
      await optimizationManager.applyPreset(OptimizationPreset.lowMemory);
      expect(optimizationManager.memory._maxCachedMessages, equals(100));
      expect(optimizationManager.memory._maxCachedRooms, equals(5));
      
      // Apply balanced preset
      await optimizationManager.applyPreset(OptimizationPreset.balanced);
      expect(optimizationManager.memory._maxCachedMessages, equals(200));
      expect(optimizationManager.memory._maxCachedRooms, equals(20));
      
      // Apply high performance preset
      await optimizationManager.applyPreset(OptimizationPreset.highPerformance);
      expect(optimizationManager.memory._maxCachedMessages, equals(500));
      expect(optimizationManager.memory._maxCachedRooms, equals(50));
    });
    
    testWidgets('Memory optimizer manages active rooms correctly', (WidgetTester tester) async {
      final memoryOptimizer = optimizationManager.memory;
      
      // Mark rooms as active
      memoryOptimizer.markRoomAsActive('room1');
      memoryOptimizer.markRoomAsActive('room2');
      memoryOptimizer.markRoomAsActive('room3');
      
      // Set up callback to track cleared rooms
      final clearedRooms = <String>[];
      memoryOptimizer.onClearRoomsCallback = (rooms) {
        clearedRooms.addAll(rooms);
      };
      
      // Test room clearing logic
      memoryOptimizer.clearUnusedRooms(['room1', 'room2', 'room3', 'room4', 'room5']);
      expect(clearedRooms, isEmpty);
      
      // Add more rooms beyond the limit
      final allRooms = List.generate(25, (index) => 'room${index+1}');
      
      // Mark the first 3 as active again to ensure they're prioritized
      memoryOptimizer.markRoomAsActive('room1');
      memoryOptimizer.markRoomAsActive('room2');
      memoryOptimizer.markRoomAsActive('room3');
      
      // Clear rooms beyond the limit
      clearedRooms.clear();
      memoryOptimizer.clearUnusedRooms(allRooms);
      
      // Verify active rooms are kept and only excess rooms are cleared
      expect(clearedRooms.length, equals(allRooms.length - memoryOptimizer._maxCachedRooms));
      expect(clearedRooms.contains('room1'), isFalse);
      expect(clearedRooms.contains('room2'), isFalse);
      expect(clearedRooms.contains('room3'), isFalse);
    });
    
    testWidgets('Network optimizer adjusts settings based on connectivity', (WidgetTester tester) async {
      final networkOptimizer = optimizationManager.network;
      
      // Test polling interval adjustments
      final baseInterval = Duration(seconds: 10);
      
      // Simulate different connectivity states
      networkOptimizer._currentConnectivity = ConnectivityResult.wifi;
      expect(networkOptimizer.getRecommendedPollingInterval(baseInterval), equals(baseInterval));
      
      networkOptimizer._currentConnectivity = ConnectivityResult.mobile;
      expect(networkOptimizer.getRecommendedPollingInterval(baseInterval), equals(baseInterval * 1.5));
      
      networkOptimizer._currentConnectivity = ConnectivityResult.none;
      expect(networkOptimizer.getRecommendedPollingInterval(baseInterval), equals(baseInterval * 4));
      
      // Test batch size adjustments
      networkOptimizer._currentConnectivity = ConnectivityResult.wifi;
      expect(networkOptimizer.getRecommendedBatchSize(), equals(networkOptimizer._batchSize));
      
      networkOptimizer._currentConnectivity = ConnectivityResult.mobile;
      expect(networkOptimizer.getRecommendedBatchSize(), equals((networkOptimizer._batchSize * 0.7).round()));
    });
    
    testWidgets('Performance monitor tracks metrics correctly', (WidgetTester tester) async {
      final performanceMonitor = optimizationManager.performance;
      
      // Enable monitoring
      performanceMonitor.enableMonitoring(true);
      
      // Track screen metrics
      performanceMonitor.startScreenTracking('TestScreen');
      
      // Simulate frame times
      performanceMonitor.trackFrameTime('TestScreen', Duration(milliseconds: 10));
      performanceMonitor.trackFrameTime('TestScreen', Duration(milliseconds: 18)); // Jank frame
      performanceMonitor.trackFrameTime('TestScreen', Duration(milliseconds: 12));
      
      // Track API calls
      performanceMonitor.trackApiCall('test/api/endpoint', Duration(milliseconds: 350));
      performanceMonitor.trackApiCall('test/api/endpoint', Duration(milliseconds: 250));
      
      // Generate report
      final report = performanceMonitor.getPerformanceReport();
      
      // Verify report contains expected data
      expect(report['enabled'], isTrue);
      expect(report['screens']['TestScreen'], isNotNull);
      expect(report['screens']['TestScreen']['frame_times']['jank_percentage'], greaterThan(0));
      expect(report['api_endpoints']['test/api/endpoint'], isNotNull);
      expect(report['api_endpoints']['test/api/endpoint']['avg_ms'], equals(300));
    });
    
    testWidgets('Optimization manager handles low memory conditions', (WidgetTester tester) async {
      // Test low memory handling
      bool lowMemoryHandlerCalled = false;
      
      // Override the low memory handler
      final originalHandler = optimizationManager.memory.handleLowMemory;
      optimizationManager.memory.handleLowMemory = () {
        lowMemoryHandlerCalled = true;
        originalHandler.call(); // Call the original handler
      };
      
      // Trigger low memory condition
      optimizationManager._handleLowMemory();
      
      // Verify handler was called
      expect(lowMemoryHandlerCalled, isTrue);
    });
  });
} 