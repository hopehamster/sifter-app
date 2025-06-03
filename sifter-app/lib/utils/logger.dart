import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static const String _tag = 'SifterApp';

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? component}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, component: component);
    }
  }

  /// Log info messages (only in debug mode)
  static void info(String message, {String? component}) {
    if (kDebugMode) {
      _log(LogLevel.info, message, component: component);
    }
  }

  /// Log warning messages (in debug and release)
  static void warning(String message, {String? component}) {
    _log(LogLevel.warning, message, component: component);
  }

  /// Log error messages (in debug and release)
  static void error(String message,
      {String? component, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, component: component);
    if (error != null && kDebugMode) {
      _log(LogLevel.error, 'Error details: $error', component: component);
    }
    if (stackTrace != null && kDebugMode) {
      _log(LogLevel.error, 'Stack trace: $stackTrace', component: component);
    }
  }

  /// Internal logging method
  static void _log(LogLevel level, String message, {String? component}) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final componentStr = component != null ? '[$component] ' : '';

    // Use different emojis for different log levels
    String emoji;
    switch (level) {
      case LogLevel.debug:
        emoji = '🔍';
        break;
      case LogLevel.info:
        emoji = 'ℹ️';
        break;
      case LogLevel.warning:
        emoji = '⚠️';
        break;
      case LogLevel.error:
        emoji = '💥';
        break;
    }

    if (kDebugMode) {
      print('$emoji [$_tag] $levelStr $componentStr$message');
    } else if (level == LogLevel.error || level == LogLevel.warning) {
      // In production, only log warnings and errors
      // You could integrate with a crash reporting service here
      print('[$_tag] $levelStr $componentStr$message');
    }
  }

  /// Log authentication events (with privacy protection)
  static void auth(String event, {bool success = true, String? errorMessage}) {
    if (kDebugMode) {
      if (success) {
        debug('Auth: $event', component: 'AUTH');
      } else {
        Logger.error('Auth failed: $event - ${errorMessage ?? 'Unknown error'}',
            component: 'AUTH');
      }
    }
  }

  /// Log navigation events
  static void navigation(String from, String to) {
    debug('Navigation: $from → $to', component: 'NAV');
  }

  /// Log user actions (without sensitive data)
  static void userAction(String action, {Map<String, dynamic>? metadata}) {
    final metaStr = metadata?.toString() ?? '';
    final fullMessage = metaStr.isNotEmpty ? '$action - $metaStr' : action;
    info('User action: $fullMessage', component: 'USER');
  }

  /// Sanitize sensitive information for logging
  static String sanitize(String? sensitive) {
    if (sensitive == null) return 'null';
    if (sensitive.length <= 4) return '***';
    return '${sensitive.substring(0, 2)}***${sensitive.substring(sensitive.length - 2)}';
  }

  /// Sanitize phone numbers
  static String sanitizePhone(String? phone) {
    if (phone == null) return 'null';
    if (phone.length <= 6) return '***';
    return '${phone.substring(0, 3)}***${phone.substring(phone.length - 3)}';
  }
}
