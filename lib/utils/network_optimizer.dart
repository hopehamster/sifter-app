import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Network optimization strategies to improve app performance and reduce data usage
class NetworkOptimizer {
  static final NetworkOptimizer _instance = NetworkOptimizer._internal();
  static NetworkOptimizer get instance => _instance;
  
  NetworkOptimizer._internal();
  
  // Configuration
  bool _isEnabled = true;
  bool _adaptivePolling = true;
  int _maxConcurrentRequests = 6;
  int _retryLimit = 3;
  Duration _baseRetryDelay = Duration(milliseconds: 500);
  int _batchSize = 20;
  
  // State tracking
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  final Map<String, int> _endpointFailures = {};
  final Map<String, DateTime> _circuitBreakerExpiry = {};
  int _activeRequests = 0;
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, double> _endpointResponseTimes = {};
  
  // Request prioritization
  final _pendingRequests = <RequestItem>[];
  Timer? _requestProcessingTimer;
  static const _requestProcessingInterval = Duration(milliseconds: 100);
  
  // Request compression settings
  bool _compressRequests = true;
  int _compressionThreshold = 1024; // 1KB
  
  // Connectivity monitoring
  StreamSubscription? _connectivitySubscription;
  Timer? _connectivityRecoveryTimer;
  
  // Monitoring health
  DateTime _lastConnectivityCheck = DateTime.now();
  bool _isConnectivityMonitoringHealthy = true;
  
  /// Initialize the network optimizer
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('network_optimization_enabled') ?? true;
      _adaptivePolling = prefs.getBool('adaptive_polling') ?? true;
      _compressRequests = prefs.getBool('compress_requests') ?? true;
      
      // Load other settings from shared preferences
      _maxConcurrentRequests = prefs.getInt('max_concurrent_requests') ?? 6;
      _retryLimit = prefs.getInt('retry_limit') ?? 3;
      _batchSize = prefs.getInt('batch_size') ?? 20;
      final retryDelayMs = prefs.getInt('base_retry_delay_ms') ?? 500;
      _baseRetryDelay = Duration(milliseconds: retryDelayMs);
      
      // Start monitoring connectivity changes
      await _initConnectivity();
      _startRequestProcessing();
      
      // Start periodic health checks for connectivity monitoring
      _startConnectivityMonitoringHealthChecks();
      
      debugPrint('Network optimizer initialized with max $_maxConcurrentRequests concurrent requests');
    } catch (e) {
      debugPrint('Error initializing network optimizer: $e');
      // Still try to set up connectivity monitoring as a fallback
      _initConnectivityFallback();
    }
  }
  
  // Initialize connectivity monitoring with error handling
  Future<void> _initConnectivity() async {
    try {
      _currentConnectivity = await Connectivity().checkConnectivity()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Connectivity check timed out, assuming WiFi');
        return ConnectivityResult.wifi; // Fallback to WiFi on timeout
      });
      
      // Setup subscription with error handling
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        _updateConnectivity,
        onError: (e) {
          debugPrint('Connectivity monitoring error: $e');
          _isConnectivityMonitoringHealthy = false;
          _tryRestartConnectivityMonitoring();
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize connectivity monitoring: $e');
      _currentConnectivity = ConnectivityResult.wifi; // Default to wifi as fallback
      _isConnectivityMonitoringHealthy = false;
      _tryRestartConnectivityMonitoring();
    }
  }
  
  // Fallback initialization when full init fails
  void _initConnectivityFallback() {
    _currentConnectivity = ConnectivityResult.wifi; // Safe default
    _maxConcurrentRequests = 4; // Conservative value
    _retryLimit = 2;
    _batchSize = 10;
    _baseRetryDelay = Duration(milliseconds: 750);
    
    try {
      // Try to start minimal connectivity monitoring
      Connectivity().onConnectivityChanged.listen(
        (result) {
          _currentConnectivity = result;
          debugPrint('Connectivity changed to $result (fallback mode)');
        },
        onError: (_) {} // Ignore errors in fallback mode
      );
      _startRequestProcessing();
    } catch (_) {
      // Last resort - just assume we're online
      debugPrint('Running with minimal network optimization (no connectivity monitoring)');
    }
  }
  
  // Start periodic health checks to make sure connectivity monitoring works
  void _startConnectivityMonitoringHealthChecks() {
    Timer.periodic(Duration(minutes: 5), (_) {
      if (DateTime.now().difference(_lastConnectivityCheck) > Duration(minutes: 15)) {
        // No connectivity updates for 15 minutes, which is unusual
        debugPrint('Connectivity monitoring appears stalled, restarting');
        _isConnectivityMonitoringHealthy = false;
        _tryRestartConnectivityMonitoring();
      }
    });
  }
  
  // Try to restart connectivity monitoring if it fails
  void _tryRestartConnectivityMonitoring() {
    if (!_isConnectivityMonitoringHealthy) {
      _connectivityRecoveryTimer?.cancel();
      _connectivityRecoveryTimer = Timer(Duration(seconds: 30), () async {
        try {
          // Clean up existing subscription
          await _connectivitySubscription?.cancel();
          
          // Try to reinitialize
          await _initConnectivity();
          _isConnectivityMonitoringHealthy = true;
          debugPrint('Successfully restarted connectivity monitoring');
        } catch (e) {
          debugPrint('Failed to restart connectivity monitoring: $e');
          // Schedule another retry
          _tryRestartConnectivityMonitoring();
        }
      });
    }
  }
  
  void _updateConnectivity(ConnectivityResult result) {
    _lastConnectivityCheck = DateTime.now();
    final previous = _currentConnectivity;
    _currentConnectivity = result;
    
    // When connectivity changes, reset some of the tracking data
    if (previous != result) {
      debugPrint('Connectivity changed from $previous to $result');
      
      if (result != ConnectivityResult.none) {
        // Clear circuit breakers when connectivity is restored
        _circuitBreakerExpiry.clear();
        
        // Process pending requests that might have been blocked
        _processNextRequests();
      }
    }
  }
  
  void _startRequestProcessing() {
    _requestProcessingTimer?.cancel();
    _requestProcessingTimer = Timer.periodic(_requestProcessingInterval, (_) {
      try {
        _processNextRequests();
      } catch (e) {
        debugPrint('Error in request processing timer: $e');
        // Continue running even if there's an error
      }
    });
  }
  
  void _stopRequestProcessing() {
    _requestProcessingTimer?.cancel();
    _requestProcessingTimer = null;
  }
  
  /// Process pending requests based on priority and concurrency limits
  void _processNextRequests() {
    if (!_isEnabled || _pendingRequests.isEmpty || _activeRequests >= _maxConcurrentRequests) {
      return;
    }
    
    try {
      // Make a safe copy to avoid concurrent modification issues
      final pendingCopy = List<RequestItem>.from(_pendingRequests);
      
      // Sort pending requests by priority and add time
      pendingCopy.sort();
      
      // Calculate how many requests we can process
      final requestsToProcess = min(
          _maxConcurrentRequests - _activeRequests, 
          pendingCopy.length);
      
      // Process as many requests as allowed by concurrency limit
      for (var i = 0; i < requestsToProcess; i++) {
        if (_pendingRequests.isEmpty) break;
        
        final request = _pendingRequests.removeAt(0);
        _activeRequests++;
        
        // Execute the request
        _safelyExecuteRequest(request);
      }
    } catch (e) {
      debugPrint('Error processing network requests: $e');
      // Recover from error state
      if (_activeRequests < 0) _activeRequests = 0;
    }
  }
  
  // Execute a request with proper error handling
  void _safelyExecuteRequest(RequestItem request) {
    request.execute().then((_) {
      _activeRequests = max(0, _activeRequests - 1);
      _processNextRequests(); // Process more after one completes
    }).catchError((e) {
      _activeRequests = max(0, _activeRequests - 1);
      debugPrint('Error executing request to ${request.endpoint}: $e');
      
      // Still mark this request as failed for circuit breaker tracking
      trackRequestEnd(request.endpoint, false);
      
      _processNextRequests();
    });
  }
  
  /// Update network optimization settings
  Future<void> updateSettings({
    bool? isEnabled,
    bool? adaptivePolling,
    int? maxConcurrentRequests,
    int? retryLimit,
    Duration? baseRetryDelay,
    int? batchSize,
    bool? compressRequests,
    int? compressionThreshold,
  }) async {
    try {
      if (isEnabled != null) _isEnabled = isEnabled;
      if (adaptivePolling != null) _adaptivePolling = adaptivePolling;
      if (maxConcurrentRequests != null) _maxConcurrentRequests = maxConcurrentRequests;
      if (retryLimit != null) _retryLimit = retryLimit;
      if (baseRetryDelay != null) _baseRetryDelay = baseRetryDelay;
      if (batchSize != null) _batchSize = batchSize;
      if (compressRequests != null) _compressRequests = compressRequests;
      if (compressionThreshold != null) _compressionThreshold = compressionThreshold;
      
      // Save settings
      final prefs = await SharedPreferences.getInstance();
      if (isEnabled != null) await prefs.setBool('network_optimization_enabled', isEnabled);
      if (adaptivePolling != null) await prefs.setBool('adaptive_polling', adaptivePolling);
      if (maxConcurrentRequests != null) await prefs.setInt('max_concurrent_requests', maxConcurrentRequests);
      if (retryLimit != null) await prefs.setInt('retry_limit', retryLimit);
      if (baseRetryDelay != null) await prefs.setInt('base_retry_delay_ms', baseRetryDelay.inMilliseconds);
      if (batchSize != null) await prefs.setInt('batch_size', batchSize);
      if (compressRequests != null) await prefs.setBool('compress_requests', compressRequests);
      
      debugPrint('Network optimizer settings updated');
    } catch (e) {
      debugPrint('Error updating network optimizer settings: $e');
      // Continue with in-memory settings even if saving fails
    }
  }
  
  /// Returns if the request should be compressed based on size and settings
  bool shouldCompressRequest(int dataSize) {
    if (!_isEnabled || !_compressRequests) return false;
    return dataSize >= _compressionThreshold;
  }
  
  /// Get the recommended polling interval based on network conditions
  Duration getRecommendedPollingInterval(Duration baseInterval) {
    if (!_isEnabled || !_adaptivePolling) return baseInterval;
    
    try {
      switch (_currentConnectivity) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
          return baseInterval;
        case ConnectivityResult.mobile:
          return baseInterval * 1.5;
        case ConnectivityResult.none:
          return baseInterval * 4;
        default:
          return baseInterval * 2;
      }
    } catch (e) {
      debugPrint('Error calculating polling interval: $e');
      // Fallback to base interval + 50% as a safe default
      return baseInterval * 1.5;
    }
  }
  
  /// Get the recommended batch size based on network conditions
  int getRecommendedBatchSize() {
    if (!_isEnabled || !_adaptivePolling) return _batchSize;
    
    try {
      switch (_currentConnectivity) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
          return _batchSize;
        case ConnectivityResult.mobile:
          return (_batchSize * 0.7).round();
        case ConnectivityResult.none:
          return (_batchSize * 0.3).round();
        default:
          return (_batchSize * 0.5).round();
      }
    } catch (e) {
      debugPrint('Error calculating batch size: $e');
      // Fallback to 50% of configured batch size as a conservative default
      return (_batchSize * 0.5).round();
    }
  }
  
  /// Determine if a request should be allowed based on current conditions
  Future<bool> shouldAllowRequest() async {
    if (!_isEnabled) return true;
    
    // Check actual device network connectivity if connectivity monitoring seems broken
    if (!_isConnectivityMonitoringHealthy) {
      try {
        // Replace Socket.fromSync with proper async Socket connection test
        bool hasConnection = false;
        try {
          final socket = await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 2));
          socket.destroy();
          hasConnection = true;
        } catch (_) {
          hasConnection = false;
        }
        
        // If we got here, there's likely internet connection
        return hasConnection && _activeRequests < _maxConcurrentRequests;
      } catch (_) {
        // On failure to connect, assume no connectivity
        return false;
      }
    }
    
    if (_currentConnectivity == ConnectivityResult.none) {
      return false; // No connectivity, don't attempt
    }
    
    return _activeRequests < _maxConcurrentRequests;
  }
  
  /// Adds a request to the prioritized queue rather than executing immediately
  Future<void> enqueueRequest(String endpoint, Future<void> Function() requestFn, {
    RequestPriority priority = RequestPriority.normal,
    bool bypassCircuitBreaker = false
  }) {
    final completer = Completer<void>();
    
    try {
      // Check if circuit breaker is active for this endpoint
      if (!bypassCircuitBreaker && _isCircuitBreakerActive(endpoint)) {
        completer.completeError(Exception('Circuit breaker active for $endpoint'));
        return completer.future;
      }
      
      _pendingRequests.add(RequestItem(
        endpoint: endpoint,
        priority: priority,
        requestFn: requestFn,
        completer: completer,
        addTime: DateTime.now(),
      ));
      
      // Trigger processing in case it wasn't already running
      _processNextRequests();
    } catch (e) {
      // Make sure the caller gets notified of the error
      completer.completeError(Exception('Failed to enqueue request: $e'));
    }
    
    return completer.future;
  }
  
  /// Track the start of a network request
  void trackRequestStart() {
    _activeRequests++;
  }
  
  /// Track the completion of a network request
  void trackRequestEnd(String endpoint, bool success, [Duration? responseTime]) {
    _activeRequests = max(0, _activeRequests - 1);
    
    if (!_isEnabled) return;
    
    try {
      _lastRequestTime[endpoint] = DateTime.now();
      
      if (success) {
        // Reset failure count on success
        _endpointFailures[endpoint] = 0;
        
        // Track response time for this endpoint
        if (responseTime != null) {
          final oldAvg = _endpointResponseTimes[endpoint] ?? 0;
          final oldWeight = 0.7; // Weight given to historical data
          final newWeight = 0.3; // Weight given to new data
          
          _endpointResponseTimes[endpoint] = (oldAvg * oldWeight) + 
              (responseTime.inMilliseconds * newWeight);
        }
      } else {
        // Increment failure count
        _endpointFailures[endpoint] = (_endpointFailures[endpoint] ?? 0) + 1;
        
        // Apply circuit breaker if failure threshold reached
        if (_endpointFailures[endpoint]! >= _retryLimit) {
          _applyCircuitBreaker(endpoint);
        }
      }
    } catch (e) {
      debugPrint('Error tracking request end: $e');
      // Don't throw - this is a non-critical tracking function
    }
  }
  
  /// Apply circuit breaker pattern to failing endpoints
  void _applyCircuitBreaker(String endpoint) {
    try {
      // Set expiry time proportional to the number of recent failures
      final failureCount = _endpointFailures[endpoint] ?? 0;
      final baseDelay = _baseRetryDelay.inMilliseconds;
      
      // Exponential backoff with jitter for circuit breaker
      final jitter = Random().nextInt(baseDelay ~/ 2);
      final delay = min(Duration(minutes: 5).inMilliseconds, 
          baseDelay * pow(2, min(failureCount, 8)).toInt() + jitter);
      
      final expiry = DateTime.now().add(Duration(milliseconds: delay));
      _circuitBreakerExpiry[endpoint] = expiry;
      
      debugPrint('Circuit breaker applied to $endpoint until ${expiry.toIso8601String()}');
    } catch (e) {
      debugPrint('Error applying circuit breaker: $e');
      // Fallback to a fixed 30 second circuit breaker
      _circuitBreakerExpiry[endpoint] = DateTime.now().add(Duration(seconds: 30));
    }
  }
  
  /// Check if circuit breaker is active for an endpoint
  bool _isCircuitBreakerActive(String endpoint) {
    try {
      final expiry = _circuitBreakerExpiry[endpoint];
      if (expiry == null) return false;
      
      if (DateTime.now().isAfter(expiry)) {
        // Expiry has passed, remove circuit breaker
        _circuitBreakerExpiry.remove(endpoint);
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking circuit breaker: $e');
      return false; // Default to allowing the request on error
    }
  }
  
  /// Get retry delay for a failed request with exponential backoff and jitter
  Duration getRetryDelay(String endpoint, int attemptNumber) {
    if (!_isEnabled) return Duration.zero;
    
    try {
      final baseDelay = _baseRetryDelay.inMilliseconds;
      final jitter = Random().nextInt(baseDelay ~/ 2);
      final delay = baseDelay * pow(2, min(attemptNumber, 8)).toInt() + jitter;
      
      return Duration(milliseconds: delay);
    } catch (e) {
      debugPrint('Error calculating retry delay: $e');
      // Fallback to a simple linear delay
      return Duration(milliseconds: 500 * (attemptNumber + 1));
    }
  }
  
  /// Get the image quality to use based on network conditions
  double getRecommendedImageQuality() {
    if (!_isEnabled || !_adaptivePolling) return 1.0;
    
    try {
      switch (_currentConnectivity) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
          return 1.0; // Full quality
        case ConnectivityResult.mobile:
          return 0.8; // Slightly reduced
        case ConnectivityResult.none:
          return 0.5; // Significantly reduced
        default:
          return 0.7;
      }
    } catch (e) {
      debugPrint('Error getting recommended image quality: $e');
      return 0.7; // Reasonable fallback
    }
  }
  
  /// Check if prefetching should be enabled based on network conditions
  bool shouldEnablePrefetching() {
    if (!_isEnabled) return true;
    
    try {
      switch (_currentConnectivity) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
          return true;
        case ConnectivityResult.mobile:
          return true; // Still allow on mobile, but will be limited by batch size
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error checking prefetch status: $e');
      return false; // Conservative default - don't prefetch on error
    }
  }
  
  /// Get a network condition report
  Map<String, dynamic> getNetworkReport() {
    try {
      return {
        'connectivity': _currentConnectivity.toString(),
        'connectivity_monitoring_healthy': _isConnectivityMonitoringHealthy,
        'active_requests': _activeRequests,
        'pending_requests': _pendingRequests.length,
        'circuit_breakers': _circuitBreakerExpiry.length,
        'endpoints': {
          for (final endpoint in _lastRequestTime.keys)
            endpoint: {
              'last_request': _lastRequestTime[endpoint]?.toIso8601String(),
              'failures': _endpointFailures[endpoint] ?? 0,
              'avg_response_time': _endpointResponseTimes[endpoint]?.toStringAsFixed(1),
              'circuit_breaker': _isCircuitBreakerActive(endpoint),
            }
        }
      };
    } catch (e) {
      debugPrint('Error generating network report: $e');
      // Return minimal report
      return {
        'error': 'Failed to generate network report: $e',
        'connectivity': _currentConnectivity.toString(),
        'active_requests': _activeRequests,
      };
    }
  }
  
  /// Clean up resources
  void dispose() {
    try {
      _connectivitySubscription?.cancel();
      _stopRequestProcessing();
      _connectivityRecoveryTimer?.cancel();
    } catch (e) {
      debugPrint('Error disposing network optimizer: $e');
    }
  }
}

/// Priority levels for network requests
enum RequestPriority {
  critical(0),   // Must complete ASAP (user-initiated actions)
  high(1),       // Important but not critical (visible data)
  normal(2),     // Standard priority (most requests)
  low(3),        // Background operations (prefetching)
  veryLow(4);    // Only when idle (analytics, etc.)
  
  const RequestPriority(this.value);
  final int value;
}

/// Represents a network request in the priority queue
class RequestItem implements Comparable<RequestItem> {
  final String endpoint;
  final RequestPriority priority;
  final Future<void> Function() requestFn;
  final Completer<void> completer;
  final DateTime addTime;
  
  RequestItem({
    required this.endpoint,
    required this.priority,
    required this.requestFn,
    required this.completer,
    required this.addTime,
  });
  
  Future<void> execute() async {
    try {
      // Add timeout to prevent hanging requests
      await requestFn().timeout(Duration(seconds: 60), onTimeout: () {
        throw TimeoutException('Request to $endpoint timed out after 60 seconds');
      });
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    }
  }
  
  @override
  int compareTo(RequestItem other) {
    // First compare by priority
    final priorityComparison = priority.value.compareTo(other.priority.value);
    if (priorityComparison != 0) return priorityComparison;
    
    // If same priority, older requests come first (FIFO)
    return addTime.compareTo(other.addTime);
  }
} 