import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_types.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<AppError> _errorHistory = [];

  /// Handle an error with context
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    ErrorCategory category = ErrorCategory.generic,
    Map<String, dynamic>? context,
  }) {
    final appError = _convertToAppError(error, category: category);

    // Add to error history
    _errorHistory.add(appError);

    // Log error based on severity
    _logError(appError, stackTrace, severity, context);

    // Report to analytics/crash reporting if needed
    _reportError(appError, stackTrace, severity, context);
  }

  /// Convert any error to AppError
  AppError _convertToAppError(dynamic error, {ErrorCategory? category}) {
    if (error is AppError) {
      return error;
    }

    final message = error?.toString() ?? 'Unknown error occurred';

    switch (category) {
      case ErrorCategory.authentication:
        return AuthError(message);
      case ErrorCategory.network:
        return NetworkError(message);
      case ErrorCategory.location:
        return LocationError(message);
      case ErrorCategory.chatRoom:
        return ChatRoomError(message);
      case ErrorCategory.validation:
        return ValidationError(message);
      case ErrorCategory.permission:
        return PermissionError(message);
      case ErrorCategory.storage:
        return StorageError(message);
      case ErrorCategory.moderation:
        return ModerationError(message);
      default:
        return GenericError(message);
    }
  }

  /// Log error to console
  void _logError(
    AppError error,
    StackTrace? stackTrace,
    ErrorSeverity severity,
    Map<String, dynamic>? context,
  ) {
    if (kDebugMode) {
      print('🔥 ERROR [${severity.name.toUpperCase()}]: ${error.message}');
      if (error.code != null) print('   Code: ${error.code}');
      if (context != null) print('   Context: $context');
      if (stackTrace != null) print('   Stack: $stackTrace');
    }
  }

  /// Report error to external services
  void _reportError(
    AppError error,
    StackTrace? stackTrace,
    ErrorSeverity severity,
    Map<String, dynamic>? context,
  ) {
    // In production, report to Firebase Crashlytics, Sentry, etc.
    if (severity == ErrorSeverity.critical) {
      // Report critical errors immediately
      if (kDebugMode) {
        print('🚨 CRITICAL ERROR REPORTED: ${error.message}');
      }
    }
  }

  /// Get recent errors
  List<AppError> getRecentErrors([int limit = 10]) {
    return _errorHistory.reversed.take(limit).toList();
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Check if there are any unhandled errors
  bool get hasUnhandledErrors => _errorHistory.isNotEmpty;

  /// Get error count by category
  Map<ErrorCategory, int> getErrorStats() {
    final stats = <ErrorCategory, int>{};

    for (final error in _errorHistory) {
      final category = _getErrorCategory(error);
      stats[category] = (stats[category] ?? 0) + 1;
    }

    return stats;
  }

  /// Get error category from AppError type
  ErrorCategory _getErrorCategory(AppError error) {
    switch (error.runtimeType) {
      case AuthError:
        return ErrorCategory.authentication;
      case NetworkError:
        return ErrorCategory.network;
      case LocationError:
        return ErrorCategory.location;
      case ChatRoomError:
        return ErrorCategory.chatRoom;
      case ValidationError:
        return ErrorCategory.validation;
      case PermissionError:
        return ErrorCategory.permission;
      case StorageError:
        return ErrorCategory.storage;
      case ModerationError:
        return ErrorCategory.moderation;
      default:
        return ErrorCategory.generic;
    }
  }
}

/// Extension for easy error handling
extension ErrorHandling on Object {
  void handleError({
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    ErrorCategory category = ErrorCategory.generic,
    Map<String, dynamic>? context,
  }) {
    ErrorHandler().handleError(
      this,
      stackTrace: stackTrace,
      severity: severity,
      category: category,
      context: context,
    );
  }
}

/// Provider for ErrorHandler
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});
