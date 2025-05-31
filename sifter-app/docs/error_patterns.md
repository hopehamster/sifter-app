# Top 10 Error Patterns and Fixes

## 1. Inconsistent ErrorHandler Initialization
**Problem**: Many services are creating new `ErrorHandler` instances instead of using the singleton.
**Fix**: Replace all `ErrorHandler()` with `ErrorHandler.instance`
```dart
// Incorrect
final errorHandler = ErrorHandler();

// Correct
final errorHandler = ErrorHandler.instance;
```

## 2. Missing Required Parameters in Service Constructors
**Problem**: Services extending `ServiceBaseImpl` need proper error handler initialization.
**Fix**: Update all service constructors to use `ErrorHandler.instance`
```dart
// Incorrect
class MyService extends ServiceBaseImpl {
  MyService() : super(errorHandler: ErrorHandler());
}

// Correct
class MyService extends ServiceBaseImpl {
  MyService() : super(errorHandler: ErrorHandler.instance);
}
```

## 3. Incorrect Base Class Extension
**Problem**: Some services might be extending `BaseService` instead of `ServiceBaseImpl`.
**Fix**: Update all services to extend `ServiceBaseImpl`
```dart
// Incorrect
class MyService extends BaseService {
  // ...
}

// Correct
class MyService extends ServiceBaseImpl {
  // ...
}
```

## 4. Missing Required Overrides
**Problem**: Services need to implement `onInitialize()` and `onDispose()`.
**Fix**: Add these methods to all services
```dart
class MyService extends ServiceBaseImpl {
  @override
  Future<void> onInitialize() async {
    // Initialization logic
  }

  @override
  Future<void> onDispose() async {
    // Cleanup logic
  }
}
```

## 5. Inconsistent Error Handling Methods
**Problem**: Some services use direct error handling instead of `executeWithErrorHandling`.
**Fix**: Standardize error handling using the base class methods
```dart
// Incorrect
try {
  await someOperation();
} catch (e) {
  handleError(e, 'Error message');
}

// Correct
return executeWithErrorHandling(
  operation: () => someOperation(),
  operationName: 'someOperation',
  category: ErrorCategory.operation,
  severity: ErrorSeverity.medium,
);
```

## 6. Missing Error Categories
**Problem**: Inconsistent use of `ErrorCategory` in error handling.
**Fix**: Add proper error categories to all error handling calls
```dart
handleError(
  error,
  stackTrace,
  category: ErrorCategory.authentication,  // Add appropriate category
  // ...
);
```

## 7. Missing Error Severity
**Problem**: Inconsistent use of `ErrorSeverity` in error handling.
**Fix**: Add proper severity levels to all error handling calls
```dart
handleError(
  error,
  stackTrace,
  severity: ErrorSeverity.medium,  // Add appropriate severity
  // ...
);
```

## 8. Incorrect Provider Initialization
**Problem**: Some providers might be creating new instances instead of using singletons.
**Fix**: Update providers to use singleton instances
```dart
// Incorrect
final myServiceProvider = Provider<MyService>((ref) {
  return MyService(errorHandler: ErrorHandler());
});

// Correct
final myServiceProvider = Provider<MyService>((ref) {
  return MyService(errorHandler: ErrorHandler.instance);
});
```

## 9. Missing Error Context
**Problem**: Inconsistent error context in error handling calls.
**Fix**: Add proper context to all error handling calls
```dart
handleError(
  error,
  stackTrace,
  context: {
    'operation': 'userLogin',
    'userId': userId,
    'timestamp': DateTime.now().toIso8601String(),
  },
  // ...
);
```

## 10. Incorrect Error Recovery Strategy
**Problem**: Missing or incorrect recovery strategies in error handling.
**Fix**: Add proper recovery strategies to error handling calls
```dart
handleError(
  error,
  stackTrace,
  recoveryStrategy: RecoveryStrategy.retry,
  recoveryAction: RecoveryAction.retry,
  // ...
);
```

## Implementation Priority
1. Start with ErrorHandler initialization (1) as it affects all other patterns
2. Fix service constructors (2) and base class extensions (3)
3. Add required overrides (4)
4. Standardize error handling methods (5)
5. Add missing categories (6) and severity (7)
6. Fix provider initialization (8)
7. Add error context (9)
8. Implement recovery strategies (10)

## Success Criteria
- All services use `ErrorHandler.instance`
- All services properly extend `ServiceBaseImpl`
- All required methods are implemented
- Error handling is consistent across the codebase
- All error handling calls include proper categories and severity
- Providers use singleton instances
- Error context is provided where relevant
- Recovery strategies are properly implemented 