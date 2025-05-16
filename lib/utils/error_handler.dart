import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler(ref);
});

/// A utility class for handling errors in a consistent way throughout the app.
class ErrorHandler {
  final Ref ref;

  ErrorHandler(this.ref);

  /// Log an error to Crashlytics and console
  static void logError(dynamic error, StackTrace? stack, {String? message}) {
    if (kDebugMode) {
      print('ERROR: ${message ?? error.toString()}');
      print('STACK: ${stack.toString()}');
    }
    
    // Report to Crashlytics if in production
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: message,
      );
    }
  }
  
  /// Show a snackbar with an error message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Handle an exception and show a snackbar
  static void handleException(BuildContext context, dynamic error, {String? fallbackMessage}) {
    final message = error is Exception 
        ? error.toString().replaceAll('Exception: ', '')
        : fallbackMessage ?? 'An unexpected error occurred';
    
    showErrorSnackBar(context, message);
  }
  
  /// Get a user-friendly error message from an exception
  static String getErrorMessage(dynamic error, {String fallbackMessage = 'An unexpected error occurred'}) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    
    return fallbackMessage;
  }
  
  /// Build a widget for displaying errors with a retry button
  static Widget buildErrorWidget(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void handleError(dynamic error, StackTrace? stackTrace) {
    // Log error
    logError(error, stackTrace);
  }

  void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class ErrorBoundary extends ConsumerWidget {
  final Widget child;
  final Widget Function(BuildContext, Object, StackTrace) onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: child,
      onError: (error, stack) {
        ErrorHandler.logError(error, stack);
        return onError(context, error, stack);
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 