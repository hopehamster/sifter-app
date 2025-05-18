import 'stress_test_runner.dart';

/// Entry point for running stress tests
/// 
/// To run specific devices:
/// dart test/run_stress_tests.dart --devices="iPhone 15,Google Pixel 7 Pro"
///
/// To run specific scenarios:
/// dart test/run_stress_tests.dart --scenarios="memory_load_test,network_resilience_test"
///
/// To run both specific devices and scenarios:
/// dart test/run_stress_tests.dart --devices="iPhone 15" --scenarios="memory_load_test"
void main(List<String> arguments) async {
  print('Sifter App Stress Test Runner');
  print('=============================');
  
  // Parse command line arguments
  List<String>? specificDevices;
  List<String>? specificScenarios;
  
  for (final arg in arguments) {
    if (arg.startsWith('--devices=')) {
      specificDevices = arg.substring('--devices='.length).split(',');
      print('Running tests for specific devices: ${specificDevices.join(', ')}');
    } else if (arg.startsWith('--scenarios=')) {
      specificScenarios = arg.substring('--scenarios='.length).split(',');
      print('Running specific test scenarios: ${specificScenarios.join(', ')}');
    }
  }
  
  // Create and run the test runner
  final runner = StressTestRunner();
  
  print('Starting stress tests...');
  await runner.runTests(
    specificDevices: specificDevices,
    specificScenarios: specificScenarios,
    saveResults: true,
  );
  
  print('Stress tests completed');
} 