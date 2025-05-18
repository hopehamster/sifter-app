import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'stress_test_config.dart';

/// Runs automated stress tests according to the test configuration
class StressTestRunner {
  // Test state
  final Map<String, Map<String, dynamic>> _deviceResults = {};
  final Map<String, List<Map<String, dynamic>>> _scenarioMetrics = {};
  bool _isRunning = false;
  final List<String> _testLog = [];
  
  /// Start the stress test sequence
  Future<void> runTests({
    List<String>? specificDevices,
    List<String>? specificScenarios,
    bool saveResults = true,
  }) async {
    if (_isRunning) {
      print('Error: Tests are already running');
      return;
    }
    
    _isRunning = true;
    _testLog.clear();
    _logMessage('==== Starting Stress Test Run at ${DateTime.now()} ====');
    
    try {
      // Determine which devices to test
      final devices = specificDevices != null
          ? StressTestConfig.deviceMatrix.where(
              (device) => specificDevices.contains(device['name'])).toList()
          : StressTestConfig.deviceMatrix;
          
      if (devices.isEmpty) {
        _logMessage('Error: No matching devices found');
        _isRunning = false;
        return;
      }
      
      // Determine which scenarios to run
      final scenarios = specificScenarios != null
          ? Map.fromEntries(
              StressTestConfig.testScenarios.entries.where(
                (entry) => specificScenarios.contains(entry.key)))
          : StressTestConfig.testScenarios;
          
      if (scenarios.isEmpty) {
        _logMessage('Error: No matching scenarios found');
        _isRunning = false;
        return;
      }
      
      // Log test plan
      _logMessage('Testing ${devices.length} devices with ${scenarios.length} scenarios');
      _logMessage('Expected duration: ${_calculateTotalDuration(devices.length, scenarios)}');
      
      // Run tests for each device
      for (final device in devices) {
        await _testDevice(device, scenarios);
      }
      
      // Generate reports
      _logMessage('Generating test reports...');
      final report = _generateTestReport();
      
      if (saveResults) {
        await _saveTestResults(report);
      }
      
      _logMessage('==== Completed Stress Test Run at ${DateTime.now()} ====');
    } catch (e) {
      _logMessage('Error during test execution: $e');
    } finally {
      _isRunning = false;
    }
  }
  
  /// Calculate the approximate total duration of all tests
  String _calculateTotalDuration(int deviceCount, Map<String, Map<String, dynamic>> scenarios) {
    var totalMinutes = 0;
    
    for (final scenario in scenarios.values) {
      final duration = scenario['duration'] as Duration;
      totalMinutes += duration.inMinutes;
    }
    
    totalMinutes *= deviceCount;
    
    // Add setup time
    totalMinutes += deviceCount * 2; // 2 minutes per device for setup
    
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    return '${hours}h ${minutes}m';
  }
  
  /// Run all test scenarios for a specific device
  Future<void> _testDevice(Map<String, dynamic> device, Map<String, Map<String, dynamic>> scenarios) async {
    final deviceName = device['name'] as String;
    _logMessage('==== Starting tests for $deviceName ====');
    _logMessage('Device specs: ${device['os']} ${device['version']}, '
        'Resolution: ${device['resolution']}, RAM: ${device['ram']}GB');
    
    _deviceResults[deviceName] = {
      'device': device,
      'scenarios': <String, dynamic>{},
      'start_time': DateTime.now().toIso8601String(),
    };
    
    // Run each scenario
    for (final entry in scenarios.entries) {
      final scenarioName = entry.key;
      final scenario = entry.value;
      
      _logMessage('Running scenario: $scenarioName on $deviceName');
      final scenarioResults = await _runScenario(device, scenarioName, scenario);
      
      _deviceResults[deviceName]?['scenarios'][scenarioName] = scenarioResults;
    }
    
    _deviceResults[deviceName]?['end_time'] = DateTime.now().toIso8601String();
    _logMessage('==== Completed tests for $deviceName ====');
  }
  
  /// Run a specific test scenario on a specific device
  Future<Map<String, dynamic>> _runScenario(
    Map<String, dynamic> device,
    String scenarioName,
    Map<String, dynamic> scenario
  ) async {
    final startTime = DateTime.now();
    final metrics = <String, dynamic>{};
    final logs = <String>{};
    
    try {
      // Simulate scenario execution
      final actions = scenario['actions'] as List<dynamic>;
      final duration = scenario['duration'] as Duration;
      
      _logMessage('  Running scenario "$scenarioName" with ${actions.length} actions, duration: ${duration.inMinutes}m');
      
      // Simulate actions
      for (final action in actions) {
        await _simulateAction(device, action as String);
      }
      
      // Simulate metrics collection
      metrics['memory'] = _simulateMemoryMetrics(device);
      metrics['cpu'] = _simulateCpuMetrics(device);
      metrics['battery'] = _simulateBatteryMetrics(device, duration);
      metrics['network'] = _simulateNetworkMetrics(device);
      metrics['rendering'] = _simulateRenderingMetrics(device);
      
      // Track all scenario metrics for later analysis
      _scenarioMetrics.putIfAbsent(scenarioName, () => []).add({
        'device': device['name'],
        'timestamp': startTime.toIso8601String(),
        'metrics': metrics,
      });
      
      // Log any simulated issues
      final simulatedIssues = _simulateRandomIssues(device, scenarioName);
      if (simulatedIssues.isNotEmpty) {
        logs.addAll(simulatedIssues);
        for (final issue in simulatedIssues) {
          _logMessage('  [ISSUE] $issue');
        }
      }
      
      return {
        'start_time': startTime.toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'success': simulatedIssues.isEmpty,
        'metrics': metrics,
        'logs': logs.toList(),
      };
    } catch (e) {
      _logMessage('  [ERROR] Failed to run scenario "$scenarioName": $e');
      
      return {
        'start_time': startTime.toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'success': false,
        'error': e.toString(),
        'metrics': metrics,
        'logs': logs.toList(),
      };
    }
  }
  
  /// Simulate executing a test action
  Future<void> _simulateAction(Map<String, dynamic> device, String action) async {
    // In a real implementation, this would drive the UI or make API calls
    // For simulation, we just wait a bit
    _logMessage('    Executing action: $action');
    
    // Simulate different action durations
    final delay = switch(action) {
      'app_launch' => Duration(milliseconds: 1500),
      'background_app' => Duration(milliseconds: 500),
      'foreground_app' => Duration(milliseconds: 1200),
      'wait_extended' => Duration(seconds: 5),
      'network_off' || 'network_on' || 'network_poor' || 'network_slow' => Duration(milliseconds: 800),
      'send_messages_bulk' || 'receive_messages_bulk' => Duration(seconds: 3),
      'simulate_concurrent_users' => Duration(seconds: 2),
      _ => Duration(seconds: 1),
    };
    
    await Future.delayed(delay);
  }
  
  /// Simulate memory usage metrics
  Map<String, dynamic> _simulateMemoryMetrics(Map<String, dynamic> device) {
    final ram = device['ram'] as int;
    
    // Simulate realistic memory usage based on device specs
    final baseMemory = 80 + (20 * ram / 8).round(); // 80MB base + device scaling
    final peakMemory = baseMemory * 1.3;
    final randomVariation = (baseMemory * 0.15 * (0.5 - (0.5 - (DateTime.now().millisecondsSinceEpoch % 100) / 100))).round();
    
    return {
      'avg_mb': baseMemory + randomVariation,
      'peak_mb': peakMemory + randomVariation,
      'variation_pct': (randomVariation / baseMemory * 100).round(),
    };
  }
  
  /// Simulate CPU usage metrics
  Map<String, dynamic> _simulateCpuMetrics(Map<String, dynamic> device) {
    // Simulate realistic CPU usage 
    final baseCpuUsage = 15; // 15% base usage
    final peakCpuUsage = 40; // 40% peak usage
    final randomVariation = (10 * (0.5 - (DateTime.now().millisecondsSinceEpoch % 100) / 100)).round();
    
    // Older devices have higher CPU usage
    final devicePenalty = device['os'] == 'iOS' 
        ? (device['version'] as String).startsWith('15') ? 1.3 : 1.0
        : (device['version'] as String).startsWith('11') ? 1.4 : 1.0;
    
    return {
      'avg_pct': (baseCpuUsage * devicePenalty + randomVariation).round(),
      'peak_pct': (peakCpuUsage * devicePenalty + randomVariation).round(),
    };
  }
  
  /// Simulate battery usage metrics
  Map<String, dynamic> _simulateBatteryMetrics(Map<String, dynamic> device, Duration duration) {
    // Base drain of 5% per hour
    final baseDrainPerHour = 5.0;
    
    // Calculate drain based on scenario duration
    final hours = duration.inMinutes / 60;
    final drain = baseDrainPerHour * hours;
    
    // Device-specific factors
    final deviceFactor = switch(device['name']) {
      'iPhone SE (2022)' => 1.2,
      'Motorola Moto G52' => 1.3,
      'Samsung Galaxy Z Fold 4' => 1.4,
      _ => 1.0,
    };
    
    return {
      'drain_pct': drain * deviceFactor,
      'drain_per_hour': baseDrainPerHour * deviceFactor,
    };
  }
  
  /// Simulate network performance metrics
  Map<String, dynamic> _simulateNetworkMetrics(Map<String, dynamic> device) {
    // Base network metrics
    final baseResponseTime = 120; // 120ms
    final randomVariation = (50 * (0.5 - (DateTime.now().millisecondsSinceEpoch % 100) / 100)).round();
    
    // Network penalties based on device and OS
    final deviceFactor = device['os'] == 'iOS' ? 0.9 : 1.1;
    
    return {
      'avg_response_ms': (baseResponseTime * deviceFactor + randomVariation).round(),
      'failed_requests_pct': (1 + (3 * (0.5 - (DateTime.now().millisecondsSinceEpoch % 100) / 100))).round(),
      'data_transferred_kb': (250 + (100 * (DateTime.now().millisecondsSinceEpoch % 100) / 100)).round(),
    };
  }
  
  /// Simulate rendering/frame rate metrics
  Map<String, dynamic> _simulateRenderingMetrics(Map<String, dynamic> device) {
    // Base frame rates
    final baseFps = 59; // 59 FPS
    
    // Device-specific penalties
    final devicePenalty = switch(device['name']) {
      'Motorola Moto G52' => 5,
      'Samsung Galaxy A53' => 3,
      'iPhone SE (2022)' => 1,
      _ => 0,
    };
    
    final randomVariation = (3 * (0.5 - (DateTime.now().millisecondsSinceEpoch % 100) / 100)).round();
    
    final avgFps = baseFps - devicePenalty + randomVariation;
    
    return {
      'avg_fps': avgFps,
      'jank_pct': (devicePenalty * 2 + (randomVariation > 0 ? 0 : 2)).clamp(0, 15),
      'frame_build_time_ms': (10 + devicePenalty).clamp(8, 30),
    };
  }
  
  /// Simulate random issues that might occur during testing
  Set<String> _simulateRandomIssues(Map<String, dynamic> device, String scenarioName) {
    final issues = <String>{};
    
    // Simulate random issues based on device and scenario
    final rand = DateTime.now().millisecondsSinceEpoch % 100;
    
    // Low-end device memory issues
    if (device['ram'] <= 4 && scenarioName == 'memory_load_test' && rand < 20) {
      issues.add('Memory pressure detected, UI redraws taking longer than expected');
    }
    
    // Network issues on certain scenarios
    if (scenarioName == 'network_resilience_test' && rand < 30) {
      issues.add('Socket timeout after network condition change');
    }
    
    // Random crash on low probability
    if (rand < 2) {
      issues.add('App terminated unexpectedly during ${scenarioName}');
    }
    
    // Device-specific issues
    if (device['name'] == 'Samsung Galaxy Z Fold 4' && rand < 15) {
      issues.add('UI layout inconsistency detected on fold transition');
    }
    
    // Battery drain issues
    if (scenarioName == 'battery_drain_test' && rand < 25) {
      issues.add('Battery drain rate higher than threshold: ${(8 + rand / 10).toStringAsFixed(1)}% per hour');
    }
    
    return issues;
  }
  
  /// Generate a comprehensive test report from all collected data
  Map<String, dynamic> _generateTestReport() {
    final report = <String, dynamic>{
      'summary': {
        'test_run_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'devices_tested': _deviceResults.length,
        'scenarios_tested': StressTestConfig.testScenarios.length,
        'success_rate': _calculateSuccessRate(),
        'performance_summary': _generatePerformanceSummary(),
      },
      'device_results': _deviceResults,
      'recommendations': _generateRecommendations(),
    };
    
    return report;
  }
  
  /// Calculate the overall success rate of tests
  double _calculateSuccessRate() {
    int totalScenarios = 0;
    int successfulScenarios = 0;
    
    for (final deviceResult in _deviceResults.values) {
      final scenarios = deviceResult['scenarios'] as Map<String, dynamic>;
      
      for (final scenarioResult in scenarios.values) {
        totalScenarios++;
        if (scenarioResult['success'] == true) {
          successfulScenarios++;
        }
      }
    }
    
    return totalScenarios > 0 ? successfulScenarios / totalScenarios : 0.0;
  }
  
  /// Generate a performance summary across all tests
  Map<String, dynamic> _generatePerformanceSummary() {
    // Calculate average metrics across all devices and scenarios
    final memoryMetrics = <double>[];
    final cpuMetrics = <double>[];
    final fpsMetrics = <double>[];
    final batteryMetrics = <double>[];
    final networkMetrics = <double>[];
    
    for (final deviceResult in _deviceResults.values) {
      final scenarios = deviceResult['scenarios'] as Map<String, dynamic>;
      
      for (final scenarioResult in scenarios.values) {
        final metrics = scenarioResult['metrics'] as Map<String, dynamic>;
        
        if (metrics.containsKey('memory')) {
          memoryMetrics.add(metrics['memory']['avg_mb'] as double);
        }
        
        if (metrics.containsKey('cpu')) {
          cpuMetrics.add(metrics['cpu']['avg_pct'] as double);
        }
        
        if (metrics.containsKey('rendering')) {
          fpsMetrics.add(metrics['rendering']['avg_fps'] as double);
        }
        
        if (metrics.containsKey('battery')) {
          batteryMetrics.add(metrics['battery']['drain_per_hour'] as double);
        }
        
        if (metrics.containsKey('network')) {
          networkMetrics.add(metrics['network']['avg_response_ms'] as double);
        }
      }
    }
    
    // Calculate averages
    final avgMemory = memoryMetrics.isNotEmpty 
        ? memoryMetrics.reduce((a, b) => a + b) / memoryMetrics.length 
        : 0.0;
        
    final avgCpu = cpuMetrics.isNotEmpty 
        ? cpuMetrics.reduce((a, b) => a + b) / cpuMetrics.length 
        : 0.0;
        
    final avgFps = fpsMetrics.isNotEmpty 
        ? fpsMetrics.reduce((a, b) => a + b) / fpsMetrics.length 
        : 0.0;
        
    final avgBatteryDrain = batteryMetrics.isNotEmpty 
        ? batteryMetrics.reduce((a, b) => a + b) / batteryMetrics.length 
        : 0.0;
        
    final avgNetworkResponse = networkMetrics.isNotEmpty 
        ? networkMetrics.reduce((a, b) => a + b) / networkMetrics.length 
        : 0.0;
    
    return {
      'avg_memory_usage_mb': avgMemory,
      'avg_cpu_usage_pct': avgCpu,
      'avg_fps': avgFps,
      'avg_battery_drain_per_hour': avgBatteryDrain,
      'avg_network_response_ms': avgNetworkResponse,
      'meets_criteria': _checkSuccessCriteria(
        avgMemory, avgFps, avgBatteryDrain, avgNetworkResponse),
    };
  }
  
  /// Check if the test results meet the success criteria
  bool _checkSuccessCriteria(
    double avgMemory, 
    double avgFps, 
    double avgBatteryDrain, 
    double avgNetworkResponse
  ) {
    final criteria = StressTestConfig.successCriteria;
    
    return avgMemory <= criteria['max_memory_usage'] &&
           avgFps >= criteria['min_acceptable_frame_rate'] &&
           avgBatteryDrain <= criteria['max_battery_drain_per_hour'] &&
           avgNetworkResponse <= criteria['max_api_response_time_p90'];
  }
  
  /// Generate recommendations based on test results
  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    final summary = _generatePerformanceSummary();
    
    // Memory recommendations
    final avgMemoryUsage = summary['avg_memory_usage_mb'] as double;
    if (avgMemoryUsage > 150) {
      recommendations.add('Memory usage is high (${avgMemoryUsage.toStringAsFixed(1)} MB). '
          'Consider implementing MemoryOptimizer for caching and resource management.');
    }
    
    // FPS recommendations
    final avgFps = summary['avg_fps'] as double;
    if (avgFps < StressTestConfig.successCriteria['min_acceptable_frame_rate']) {
      recommendations.add('Frame rate is below target (${avgFps.toStringAsFixed(1)} FPS). '
          'Optimize UI redraws and animations, especially for low-end devices.');
    }
    
    // Battery recommendations
    final avgBatteryDrain = summary['avg_battery_drain_per_hour'] as double;
    if (avgBatteryDrain > StressTestConfig.successCriteria['max_battery_drain_per_hour']) {
      recommendations.add('Battery drain is high (${avgBatteryDrain.toStringAsFixed(1)}% per hour). '
          'Reduce background activity and location updates frequency.');
    }
    
    // Network recommendations
    final avgNetworkResponse = summary['avg_network_response_ms'] as double;
    if (avgNetworkResponse > 200) {
      recommendations.add('Network response time is high (${avgNetworkResponse.toStringAsFixed(1)} ms). '
          'Implement NetworkOptimizer for request batching and optimized polling.');
    }
    
    // Add general recommendations
    recommendations.add('Continue monitoring with Firebase Performance for production metrics.');
    recommendations.add('Setup automated stress testing in CI/CD pipeline for regression detection.');
    
    return recommendations;
  }
  
  /// Save test results to a file
  Future<void> _saveTestResults(Map<String, dynamic> report) async {
    try {
      // Create the test-results directory if it doesn't exist
      final directory = Directory('test-results');
      if (!await directory.exists()) {
        await directory.create();
      }
      
      // Generate a filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'stress-test-results-$timestamp.json';
      final file = File(path.join(directory.path, fileName));
      
      // Write the report to the file
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(report));
      
      _logMessage('Test results saved to ${file.path}');
      
      // Also save the logs
      final logFileName = 'stress-test-log-$timestamp.txt';
      final logFile = File(path.join(directory.path, logFileName));
      await logFile.writeAsString(_testLog.join('\n'));
      
      _logMessage('Test log saved to ${logFile.path}');
    } catch (e) {
      _logMessage('Error saving test results: $e');
    }
  }
  
  /// Add a message to the test log
  void _logMessage(String message) {
    final timestamp = DateTime.now().toString();
    final logMessage = '[$timestamp] $message';
    
    _testLog.add(logMessage);
    print(logMessage);
  }
} 