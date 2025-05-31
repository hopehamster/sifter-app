# Error Handling Documentation

## Overview

The Sifter App implements a comprehensive error handling system that categorizes errors, provides appropriate user feedback, and implements recovery strategies. This document outlines the error handling architecture, categories, and implementation details.

## Error Categories

### 1. Critical Errors
- Authentication failures
- Database connection issues
- Location service failures
- Configuration errors
- System crashes

### 2. High Severity Errors
- Data synchronization issues
- Validation errors
- Permission denials
- Network connectivity problems
- API failures

### 3. User Errors
- Invalid input
- Out-of-range locations
- Duplicate chat rooms
- Permission requests
- Form validation errors

## Implementation

### Error Classes

```dart
abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppError(this.message, {this.code, this.details});
}

class CriticalError extends AppError {
  CriticalError(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class HighSeverityError extends AppError {
  HighSeverityError(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class UserError extends AppError {
  UserError(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}
```

### Error Handler

```dart
class ErrorHandler {
  static Future<T> handle<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on CriticalError catch (e) {
      await _handleCriticalError(e);
      rethrow;
    } on HighSeverityError catch (e) {
      await _handleHighSeverityError(e);
      rethrow;
    } on UserError catch (e) {
      _handleUserError(e);
      rethrow;
    } catch (e) {
      await _handleUnexpectedError(e);
      rethrow;
    }
  }

  static Future<void> _handleCriticalError(CriticalError error) async {
    // Log error
    await _logError(error);
    
    // Show error UI
    _showErrorUI(
      title: 'Critical Error',
      message: error.message,
      action: ErrorAction.restart,
    );
    
    // Report to analytics
    await _reportError(error);
  }

  static Future<void> _handleHighSeverityError(HighSeverityError error) async {
    // Log error
    await _logError(error);
    
    // Show error UI
    _showErrorUI(
      title: 'Error',
      message: error.message,
      action: ErrorAction.retry,
    );
    
    // Report to analytics
    await _reportError(error);
  }

  static void _handleUserError(UserError error) {
    // Show user-friendly message
    _showErrorUI(
      title: 'Error',
      message: error.message,
      action: ErrorAction.dismiss,
    );
  }

  static Future<void> _handleUnexpectedError(dynamic error) async {
    // Log error
    await _logError(error);
    
    // Show generic error UI
    _showErrorUI(
      title: 'Unexpected Error',
      message: 'An unexpected error occurred. Please try again.',
      action: ErrorAction.retry,
    );
    
    // Report to analytics
    await _reportError(error);
  }
}
```

## Recovery Strategies

### 1. Automatic Recovery

#### Network Operations
```dart
class NetworkOperation {
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } on NetworkError catch (e) {
        attempts++;
        if (attempts == maxRetries) rethrow;
        await Future.delayed(delay * attempts);
      }
    }
    throw Exception('Max retries exceeded');
  }
}
```

#### Service Reconnection
```dart
class ServiceConnection {
  static Future<void> reconnect({
    required Future<void> Function() connect,
    int maxAttempts = 3,
  }) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        await connect();
        return;
      } catch (e) {
        attempts++;
        if (attempts == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }
}
```

### 2. User-Initiated Recovery

#### Retry Options
```dart
class RetryAction {
  static Future<T> withUserConfirmation<T>({
    required Future<T> Function() operation,
    required BuildContext context,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final shouldRetry = await showDialog<bool>(
        context: context,
        builder: (context) => RetryDialog(error: e),
      );
      
      if (shouldRetry == true) {
        return await operation();
      }
      rethrow;
    }
  }
}
```

#### Alternative Actions
```dart
class AlternativeAction {
  static Future<T> withFallback<T>({
    required Future<T> Function() primaryAction,
    required Future<T> Function() fallbackAction,
    required BuildContext context,
  }) async {
    try {
      return await primaryAction();
    } catch (e) {
      final useFallback = await showDialog<bool>(
        context: context,
        builder: (context) => FallbackDialog(error: e),
      );
      
      if (useFallback == true) {
        return await fallbackAction();
      }
      rethrow;
    }
  }
}
```

## UI Components

### Error Dialog
```dart
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final ErrorAction action;

  const ErrorDialog({
    required this.error,
    required this.action,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(error.message),
      content: Text(error.details?.toString() ?? ''),
      actions: [
        if (action == ErrorAction.dismiss)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        if (action == ErrorAction.retry)
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Retry'),
          ),
        if (action == ErrorAction.restart)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Restart app
            },
            child: Text('Restart'),
          ),
      ],
    );
  }
}
```

### Error Snackbar
```dart
class ErrorSnackbar extends StatelessWidget {
  final AppError error;

  const ErrorSnackbar({
    required this.error,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SnackBar(
      content: Text(error.message),
      action: SnackBarAction(
        label: 'Dismiss',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
  }
}
```

## Logging

### Error Logger
```dart
class ErrorLogger {
  static Future<void> logError(dynamic error, {StackTrace? stackTrace}) async {
    // Log to console
    print('Error: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }

    // Log to file
    await _logToFile(error, stackTrace);

    // Log to analytics
    await _logToAnalytics(error, stackTrace);
  }

  static Future<void> _logToFile(dynamic error, StackTrace? stackTrace) async {
    final log = '''
      Time: ${DateTime.now()}
      Error: $error
      Stack trace: $stackTrace
    ''';

    await File('error.log').writeAsString(log, mode: FileMode.append);
  }

  static Future<void> _logToAnalytics(dynamic error, StackTrace? stackTrace) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'error',
      parameters: {
        'error': error.toString(),
        'stack_trace': stackTrace?.toString(),
      },
    );
  }
}
```

## Testing

### Error Handler Tests
```dart
void main() {
  group('ErrorHandler', () {
    test('handles critical error', () async {
      final error = CriticalError('Test critical error');
      
      expect(
        () => ErrorHandler.handle(() => throw error),
        throwsA(isA<CriticalError>()),
      );
    });

    test('handles high severity error', () async {
      final error = HighSeverityError('Test high severity error');
      
      expect(
        () => ErrorHandler.handle(() => throw error),
        throwsA(isA<HighSeverityError>()),
      );
    });

    test('handles user error', () async {
      final error = UserError('Test user error');
      
      expect(
        () => ErrorHandler.handle(() => throw error),
        throwsA(isA<UserError>()),
      );
    });
  });
}
```

## Best Practices

1. **Error Categorization**
   - Use appropriate error categories
   - Provide meaningful error messages
   - Include relevant error details

2. **Error Recovery**
   - Implement automatic recovery where possible
   - Provide clear user recovery options
   - Handle edge cases gracefully

3. **Error Logging**
   - Log all errors with context
   - Include stack traces
   - Use appropriate log levels

4. **User Experience**
   - Show user-friendly error messages
   - Provide clear recovery actions
   - Maintain app stability

5. **Testing**
   - Test error handling paths
   - Verify recovery strategies
   - Test error UI components 