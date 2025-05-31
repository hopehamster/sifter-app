import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../core/error/error_types.dart';
import '../core/error/error_handler.dart';

/// Utility functions for error handling
class ErrorUtils {
  /// Execute a function with error handling
  static Future<T?> safeExecute<T>(
    Future<T> Function() function, {
    ErrorCategory category = ErrorCategory.generic,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? context,
    T? defaultValue,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      ErrorHandler().handleError(
        error,
        stackTrace: stackTrace,
        category: category,
        severity: severity,
        context: context != null ? {'context': context} : null,
      );
      return defaultValue;
    }
  }

  /// Execute a synchronous function with error handling
  static T? safeExecuteSync<T>(
    T Function() function, {
    ErrorCategory category = ErrorCategory.generic,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? context,
    T? defaultValue,
  }) {
    try {
      return function();
    } catch (error, stackTrace) {
      ErrorHandler().handleError(
        error,
        stackTrace: stackTrace,
        category: category,
        severity: severity,
        context: context != null ? {'context': context} : null,
      );
      return defaultValue;
    }
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppError) {
      switch (error.runtimeType) {
        case AuthError:
          return _getAuthErrorMessage(error as AuthError);
        case NetworkError:
          return 'Network connection issue. Please check your internet connection.';
        case LocationError:
          return 'Unable to access location. Please check your location settings.';
        case ChatRoomError:
          return 'Chat room error. Please try again.';
        case ValidationError:
          return error.message;
        case PermissionError:
          return 'Permission required. Please grant the necessary permissions.';
        case StorageError:
          return 'Storage error. Please try again.';
        case ModerationError:
          return 'Content moderation issue. Please review your content.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Get specific auth error messages
  static String _getAuthErrorMessage(AuthError error) {
    final message = error.message.toLowerCase();

    if (message.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (message.contains('email')) {
      return 'Invalid email address. Please check and try again.';
    } else if (message.contains('password')) {
      return 'Invalid password. Please check and try again.';
    } else if (message.contains('user-not-found')) {
      return 'No account found with this email address.';
    } else if (message.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (message.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    } else if (message.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }

    return 'Authentication error. Please try again.';
  }

  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final message = getUserFriendlyMessage(error);

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    final message = getUserFriendlyMessage(error);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Error'),
          content: Text(message),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('Retry'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Log error for debugging
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    if (kDebugMode) {
      print('🔥 ERROR: $error');
      if (context != null) print('   Context: $context');
      if (stackTrace != null) print('   Stack: $stackTrace');
    }
  }

  /// Check if error is network related
  static bool isNetworkError(dynamic error) {
    if (error is NetworkError) return true;

    final message = error?.toString().toLowerCase() ?? '';
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket');
  }

  /// Check if error is auth related
  static bool isAuthError(dynamic error) {
    if (error is AuthError) return true;

    final message = error?.toString().toLowerCase() ?? '';
    return message.contains('auth') ||
        message.contains('login') ||
        message.contains('unauthorized') ||
        message.contains('token');
  }

  /// Get error icon based on error type
  static IconData getErrorIcon(dynamic error) {
    if (error is AuthError) return Icons.lock_outline;
    if (error is NetworkError) return Icons.wifi_off;
    if (error is LocationError) return Icons.location_off;
    if (error is PermissionError) return Icons.security;
    if (error is ValidationError) return Icons.error_outline;

    return Icons.error;
  }

  /// Get error color based on severity
  static Color getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.deepOrange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }
}
