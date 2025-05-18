import 'dart:async';

/// Defines the configuration for automated stress testing
class StressTestConfig {
  // Device matrix - key specifications for top 20 devices to simulate
  static const List<Map<String, dynamic>> deviceMatrix = [
    // iOS devices
    {'name': 'iPhone 15 Pro Max', 'os': 'iOS', 'version': '17.4', 'resolution': '1290x2796', 'ram': 8},
    {'name': 'iPhone 15', 'os': 'iOS', 'version': '17.4', 'resolution': '1179x2556', 'ram': 6},
    {'name': 'iPhone 14 Pro', 'os': 'iOS', 'version': '17.4', 'resolution': '1179x2556', 'ram': 6},
    {'name': 'iPhone 13', 'os': 'iOS', 'version': '17.4', 'resolution': '1170x2532', 'ram': 4},
    {'name': 'iPhone SE (2022)', 'os': 'iOS', 'version': '17.4', 'resolution': '750x1334', 'ram': 4},
    {'name': 'iPad Pro 12.9" (2022)', 'os': 'iOS', 'version': '17.4', 'resolution': '2048x2732', 'ram': 16},
    {'name': 'iPad Air (2022)', 'os': 'iOS', 'version': '17.4', 'resolution': '1640x2360', 'ram': 8},
    
    // Android devices
    {'name': 'Samsung Galaxy S23 Ultra', 'os': 'Android', 'version': '13.0', 'resolution': '1440x3088', 'ram': 12},
    {'name': 'Samsung Galaxy S22', 'os': 'Android', 'version': '13.0', 'resolution': '1080x2340', 'ram': 8},
    {'name': 'Google Pixel 7 Pro', 'os': 'Android', 'version': '13.0', 'resolution': '1440x3120', 'ram': 12},
    {'name': 'Google Pixel 6a', 'os': 'Android', 'version': '13.0', 'resolution': '1080x2400', 'ram': 6},
    {'name': 'OnePlus 10 Pro', 'os': 'Android', 'version': '12.0', 'resolution': '1440x3216', 'ram': 12},
    {'name': 'Xiaomi 13', 'os': 'Android', 'version': '12.0', 'resolution': '1080x2400', 'ram': 8},
    {'name': 'Motorola Edge 30 Pro', 'os': 'Android', 'version': '12.0', 'resolution': '1080x2400', 'ram': 8},
    {'name': 'Samsung Galaxy A53', 'os': 'Android', 'version': '12.0', 'resolution': '1080x2400', 'ram': 6},
    {'name': 'Samsung Galaxy Z Fold 4', 'os': 'Android', 'version': '12.0', 'resolution': '1812x2176', 'ram': 12},
    {'name': 'Nothing Phone (1)', 'os': 'Android', 'version': '12.0', 'resolution': '1080x2400', 'ram': 8},
    {'name': 'Oppo Find X5 Pro', 'os': 'Android', 'version': '12.0', 'resolution': '1440x3216', 'ram': 12},
    {'name': 'Motorola Moto G52', 'os': 'Android', 'version': '12.0', 'resolution': '1080x2400', 'ram': 4},
    {'name': 'Realme GT Neo 3', 'os': 'Android', 'version': '12.0', 'resolution': '1080x2412', 'ram': 8},
  ];

  // Test scenarios to run on each device
  static const Map<String, Map<String, dynamic>> testScenarios = {
    'standard_user_flow': {
      'description': 'Standard user flow including registration, room creation, messaging',
      'duration': Duration(minutes: 10),
      'actions': [
        'app_launch',
        'registration', 
        'create_room', 
        'send_messages',
        'join_room',
        'background_app',
        'foreground_app',
      ],
    },
    'location_stress_test': {
      'description': 'Test frequent location updates and geofencing',
      'duration': Duration(minutes: 15),
      'actions': [
        'app_launch',
        'login',
        'enable_location',
        'create_room',
        'change_location',
        'change_location',
        'change_location',
        'join_room',
        'change_location',
        'background_app',
        'change_location',
        'foreground_app',
      ],
    },
    'memory_load_test': {
      'description': 'High memory usage test with many rooms and messages',
      'duration': Duration(minutes: 20),
      'actions': [
        'app_launch',
        'login',
        'join_room',
        'send_messages_bulk',
        'join_room',
        'send_messages_bulk',
        'join_room',
        'send_messages_bulk',
        'background_app',
        'foreground_app',
        'navigate_rooms',
      ],
    },
    'network_resilience_test': {
      'description': 'Test app behavior under poor network conditions',
      'duration': Duration(minutes: 15),
      'actions': [
        'app_launch',
        'login',
        'join_room',
        'network_poor',
        'send_messages',
        'network_off',
        'send_messages',
        'network_on',
        'background_app',
        'network_slow',
        'foreground_app',
      ],
    },
    'battery_drain_test': {
      'description': 'Measure battery usage during extended background operation',
      'duration': Duration(hours: 1),
      'actions': [
        'app_launch',
        'login',
        'create_room',
        'background_app',
        'wait_extended',
        'change_location',
        'foreground_app',
      ],
    },
    'concurrent_users_test': {
      'description': 'Test with many concurrent users in a single room',
      'duration': Duration(minutes: 30),
      'actions': [
        'app_launch',
        'login',
        'join_popular_room',
        'simulate_concurrent_users',
        'send_messages_rapid',
        'receive_messages_bulk',
      ],
    },
  };

  // Monitoring parameters
  static const monitoringConfig = {
    'capture_memory_interval': Duration(seconds: 30),
    'capture_battery_interval': Duration(minutes: 5),
    'capture_frame_rate': true,
    'capture_network_requests': true,
    'capture_crash_reports': true,
    'record_logs': true,
  };

  // Simulated conditions
  static const simulatedConditions = {
    'network_conditions': [
      'perfect', // Full speed, no latency
      'good', // 30ms latency, occasional packet loss
      'poor', // 100ms latency, 5% packet loss
      'very_poor', // 300ms latency, 15% packet loss
      'offline', // No connectivity
      'intermittent', // Connection drops periodically
    ],
    'battery_levels': [
      'full', // 90-100%
      'medium', // 40-60%
      'low', // 10-20%
      'critical', // Below 5%
    ],
    'background_state': [
      'foreground',
      'background_short', // 1-5 minutes
      'background_medium', // 30 minutes
      'background_long', // 4+ hours
    ],
    'location_scenarios': [
      'static',
      'walking',
      'driving',
      'random_jumps',
      'no_signal',
      'accuracy_poor',
    ],
  };

  // Success criteria
  static const successCriteria = {
    'max_acceptable_crash_rate': 0.1, // 0.1% of sessions
    'min_acceptable_frame_rate': 55, // FPS
    'max_memory_usage': 200, // MB
    'max_battery_drain_per_hour': 8, // % per hour
    'max_api_response_time_p90': 2000, // ms
    'max_ttfb': 500, // Time to first byte for critical API calls (ms)
    'max_startup_time': 2500, // ms
  };
} 