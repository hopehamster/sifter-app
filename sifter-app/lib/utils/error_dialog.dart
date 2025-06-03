import 'package:flutter/material.dart';

import '../core/error/error_types.dart';
import 'error_utils.dart';

/// Reusable error dialog widget
class ErrorDialog extends StatelessWidget {
  final dynamic error;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final bool showRetry;

  const ErrorDialog({
    super.key,
    required this.error,
    this.title,
    this.onRetry,
    this.onCancel,
    this.showRetry = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = ErrorUtils.getUserFriendlyMessage(error);
    final errorIcon = ErrorUtils.getErrorIcon(error);

    return AlertDialog(
      icon: Icon(
        errorIcon,
        color: Theme.of(context).colorScheme.error,
        size: 32,
      ),
      title: Text(title ?? 'Error'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(errorMessage),
          if (error is AppError && error.code != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error Code: ${error.code}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        if (showRetry && onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
    bool showRetry = false,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        title: title,
        onRetry: onRetry,
        onCancel: onCancel,
        showRetry: showRetry,
      ),
    );
  }
}

/// Simple error snackbar
class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({
    super.key,
    required dynamic error,
    VoidCallback? onRetry,
    super.duration = const Duration(seconds: 4),
  }) : super(
          content: Row(
            children: [
              Icon(
                ErrorUtils.getErrorIcon(error),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ErrorUtils.getUserFriendlyMessage(error),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
        );

  /// Show error snackbar
  static void show(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      ErrorSnackBar(
        error: error,
        onRetry: onRetry,
        duration: duration,
      ),
    );
  }
}

/// Error banner widget
class ErrorBanner extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showRetry;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = ErrorUtils.getUserFriendlyMessage(error);
    final errorIcon = ErrorUtils.getErrorIcon(error);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                errorIcon,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                ),
            ],
          ),
          if (showRetry && onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error page widget for full-screen errors
class ErrorPage extends StatelessWidget {
  final dynamic error;
  final String? title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final Widget? customAction;

  const ErrorPage({
    super.key,
    required this.error,
    this.title,
    this.subtitle,
    this.onRetry,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = ErrorUtils.getUserFriendlyMessage(error);
    final errorIcon = ErrorUtils.getErrorIcon(error);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                errorIcon,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                title ?? 'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle ?? errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (customAction != null)
                customAction!
              else if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
