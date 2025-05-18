import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:retry/retry.dart';

/// Utility class for handling API operations with retry mechanisms and circuit breaker pattern
class ApiUtils {
  /// Circuit breaker state management
  static final Map<String, _CircuitBreakerState> _circuitStates = {};
  
  /// Default timeout for operations
  static const Duration defaultTimeout = Duration(seconds: 10);
  
  /// Default retry settings
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(milliseconds: 200);
  static const double randomizationFactor = 0.25;
  
  /// Circuit breaker settings
  static const int failureThreshold = 5;
  static const Duration resetTimeout = Duration(seconds: 30);
  
  /// Execute an operation with retry logic
  /// 
  /// [operation] - The async operation to execute
  /// [retryHint] - Hint for logging/tracking
  /// [maxAttempts] - Maximum number of retry attempts
  /// [delayFactor] - Exponential backoff factor for retries
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    String retryHint = 'api_operation',
    int? maxAttempts,
    Duration? delayFactor,
    double? randomization,
    Duration? timeout,
  }) async {
    // Generate a unique ID for this operation for circuit breaker tracking
    final operationId = retryHint;
    
    // Check if circuit is open for this operation type
    if (_isCircuitOpen(operationId)) {
      throw Exception('Circuit breaker open for operation: $operationId');
    }
    
    try {
      return await retry(
        () => operation().timeout(timeout ?? defaultTimeout),
        maxAttempts: maxAttempts ?? maxRetries,
        delayFactor: delayFactor ?? initialDelay,
        randomizationFactor: randomization ?? randomizationFactor,
        onRetry: (e) {
          _recordFailure(operationId);
          Sentry.captureException(e, hint: {'action': retryHint, 'attempt': 'retry'});
        },
      );
    } catch (e) {
      // Record final failure and potentially trip circuit breaker
      _recordFailure(operationId);
      Sentry.captureException(e, hint: {'action': retryHint, 'attempt': 'final'});
      rethrow;
    }
  }
  
  /// Record a success for the operation
  static void recordSuccess(String operationId) {
    _getCircuitState(operationId).recordSuccess();
  }
  
  /// Check if circuit breaker is open for an operation
  static bool _isCircuitOpen(String operationId) {
    return _getCircuitState(operationId).isOpen;
  }
  
  /// Record a failure for the operation
  static void _recordFailure(String operationId) {
    _getCircuitState(operationId).recordFailure();
  }
  
  /// Get or create circuit breaker state for an operation
  static _CircuitBreakerState _getCircuitState(String operationId) {
    if (!_circuitStates.containsKey(operationId)) {
      _circuitStates[operationId] = _CircuitBreakerState(
        failureThreshold: failureThreshold,
        resetTimeout: resetTimeout,
      );
    }
    return _circuitStates[operationId]!;
  }
}

/// Internal class to track circuit breaker state
class _CircuitBreakerState {
  final int failureThreshold;
  final Duration resetTimeout;
  int _failureCount = 0;
  bool _isOpen = false;
  DateTime? _openedAt;
  
  _CircuitBreakerState({
    required this.failureThreshold,
    required this.resetTimeout,
  });
  
  /// Record a successful operation
  void recordSuccess() {
    _failureCount = 0;
    _isOpen = false;
    _openedAt = null;
  }
  
  /// Record a failed operation
  void recordFailure() {
    _failureCount++;
    
    // Trip the circuit if threshold reached
    if (_failureCount >= failureThreshold) {
      _isOpen = true;
      _openedAt = DateTime.now();
      
      // Schedule automatic reset after timeout
      Timer(resetTimeout, _tryReset);
    }
  }
  
  /// Try to reset the circuit breaker to half-open state
  void _tryReset() {
    if (!_isOpen) return;
    
    final now = DateTime.now();
    final openDuration = now.difference(_openedAt!);
    
    if (openDuration >= resetTimeout) {
      // Move to half-open state
      _isOpen = false;
      // Keep failure count to quickly re-open if still failing
    }
  }
  
  /// Get whether the circuit is currently open
  bool get isOpen {
    // If circuit is open but reset timeout has passed, allow a trial request
    if (_isOpen && _openedAt != null) {
      final now = DateTime.now();
      final openDuration = now.difference(_openedAt!);
      if (openDuration >= resetTimeout) {
        return false; // Allow trial request (half-open state)
      }
    }
    return _isOpen;
  }
} 