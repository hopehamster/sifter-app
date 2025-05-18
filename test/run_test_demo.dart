import 'dart:async';
import 'stress_test_runner.dart';
import 'stress_test_config.dart';
import 'package:flutter/material.dart';

/// Demo script to run a subset of tests to showcase testing functionality
Future<void> main() async {
  print('Sifter App Test Demo');
  print('===================');
  print('This demo will run a subset of stress tests to demonstrate the testing framework');
  
  // Run limited device/scenario combinations for quicker demo
  final demoDevices = [
    'iPhone 15 Pro Max',
    'Google Pixel 7 Pro',
    'Samsung Galaxy A53' // Lower-end device to show performance differences
  ];
  
  final demoScenarios = [
    'standard_user_flow',
    'memory_load_test'
  ];
  
  print('\nRunning tests on ${demoDevices.length} devices with ${demoScenarios.length} scenarios');
  print('Demo devices: ${demoDevices.join(", ")}');
  print('Demo scenarios: ${demoScenarios.join(", ")}');
  
  final runner = StressTestRunner();
  
  final stopwatch = Stopwatch()..start();
  print('\nStarting stress tests...');

  await runner.runTests(
    specificDevices: demoDevices,
    specificScenarios: demoScenarios,
    saveResults: true,
  );
  
  stopwatch.stop();
  
  print('\nDemo tests completed in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s');
  print('Test results have been saved to the test-results directory');
  print('\nNext steps:');
  print('1. Review test reports in the test-results directory');
  print('2. Run full tests using: dart test/run_stress_tests.dart');
  print('3. Run specific device tests with: dart test/run_stress_tests.dart --devices="iPhone 15,Google Pixel 7 Pro"');
  print('4. Implement OptimizationManager in your app to apply the recommended optimizations');
} 