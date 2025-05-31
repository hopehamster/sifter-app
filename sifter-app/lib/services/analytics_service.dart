import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for analytics, error tracking, and user behavior monitoring
class AnalyticsService {
  static const String _appName = 'SifterChat';
  static const String _version = '1.0.0';

  bool _isInitialized = false;
  SharedPreferences? _prefs;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;

      await logEvent('app_initialized', {
        'platform': 'flutter',
        'version': _version,
      });
    } catch (e) {
      // Fallback - don't let analytics initialization crash the app
      print('Analytics initialization failed: $e');
    }
  }

  /// Log custom events
  Future<void> logEvent(String eventName,
      [Map<String, dynamic>? parameters]) async {
    try {
      if (!_isInitialized) return;

      final timestamp = DateTime.now().toIso8601String();
      final eventData = {
        'event': eventName,
        'timestamp': timestamp,
        'parameters': parameters ?? {},
      };

      // For now, just print events - in production, send to analytics backend
      print('Analytics Event: $eventName - $eventData');

      // Store locally for debugging/offline analytics
      await _storeEventLocally(eventName, eventData);
    } catch (e) {
      print('Failed to log analytics event: $e');
    }
  }

  /// Store event locally for offline analytics
  Future<void> _storeEventLocally(
      String eventName, Map<String, dynamic> eventData) async {
    try {
      if (_prefs == null) return;

      final events = _prefs!.getStringList('analytics_events') ?? [];
      events.add('$eventName:${DateTime.now().millisecondsSinceEpoch}');

      // Keep only last 100 events to prevent excessive storage
      if (events.length > 100) {
        events.removeRange(0, events.length - 100);
      }

      await _prefs!.setStringList('analytics_events', events);
    } catch (e) {
      print('Failed to store event locally: $e');
    }
  }

  /// Log user authentication events
  Future<void> logAuthEvent(String action,
      {Map<String, dynamic>? extra}) async {
    await logEvent('auth_$action', {
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log chat-related events
  Future<void> logChatEvent(
    String action, {
    String? roomId,
    int? messageCount,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? extra,
  }) async {
    await logEvent('chat_$action', {
      'action': action,
      'room_id': roomId,
      'message_count': messageCount,
      'has_location': latitude != null && longitude != null,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log location-related events
  Future<void> logLocationEvent(
    String action, {
    double? latitude,
    double? longitude,
    double? accuracy,
    Map<String, dynamic>? extra,
  }) async {
    await logEvent('location_$action', {
      'action': action,
      'has_coordinates': latitude != null && longitude != null,
      'accuracy': accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log moderation events
  Future<void> logModerationEvent(
    String action, {
    String? userId,
    String? roomId,
    String? reason,
    Map<String, dynamic>? extra,
  }) async {
    await logEvent('moderation_$action', {
      'action': action,
      'user_id': userId,
      'room_id': roomId,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log app performance metrics
  Future<void> logPerformanceEvent(
    String metric, {
    double? value,
    String? unit,
    Map<String, dynamic>? extra,
  }) async {
    await logEvent('performance_$metric', {
      'metric': metric,
      'value': value,
      'unit': unit,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log user behavior events
  Future<void> logUserBehavior(
    String action, {
    String? screen,
    String? element,
    Map<String, dynamic>? extra,
  }) async {
    await logEvent('user_$action', {
      'action': action,
      'screen': screen,
      'element': element,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log errors with context
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    try {
      if (!_isInitialized) {
        print('Error: $error');
        return;
      }

      // Log error details
      await logEvent('error_occurred', {
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
        'context': context,
        'has_stack_trace': stackTrace != null,
        'stack_trace': stackTrace?.toString(),
        ...?extra,
      });

      // Also print for debugging
      print('ERROR [$context]: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  /// Set user properties for analytics
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      if (!_isInitialized || _prefs == null) return;

      for (final entry in properties.entries) {
        await _prefs!.setString('user_${entry.key}', entry.value.toString());
      }
    } catch (e) {
      print('Failed to set user properties: $e');
    }
  }

  /// Set user ID for tracking
  Future<void> setUserId(String userId) async {
    try {
      if (!_isInitialized || _prefs == null) return;

      await _prefs!.setString('user_id', userId);
      await logEvent('user_identified', {'user_id': userId});
    } catch (e) {
      print('Failed to set user ID: $e');
    }
  }

  /// Clear user data (for logout)
  Future<void> clearUser() async {
    try {
      if (!_isInitialized || _prefs == null) return;

      // Remove user-specific keys
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('user_')).toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }

      await logEvent('user_logged_out');
    } catch (e) {
      print('Failed to clear user data: $e');
    }
  }

  /// Track screen views
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async {
    await logEvent('screen_view', {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?properties,
    });
  }

  /// Track app state changes
  Future<void> trackAppStateChange(String state) async {
    await logEvent('app_state_change', {
      'state': state,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(
    String feature, {
    Map<String, dynamic>? context,
  }) async {
    await logEvent('feature_used', {
      'feature': feature,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    });
  }

  /// Track conversion events
  Future<void> trackConversion(
    String event, {
    double? value,
    String? currency,
    Map<String, dynamic>? properties,
  }) async {
    await logEvent('conversion_$event', {
      'event': event,
      'value': value,
      'currency': currency,
      'timestamp': DateTime.now().toIso8601String(),
      ...?properties,
    });
  }

  /// Common analytics events specific to Sifter Chat

  // Authentication tracking
  Future<void> trackSignUp(String method) async {
    await logAuthEvent('sign_up', extra: {'method': method});
  }

  Future<void> trackSignIn(String method) async {
    await logAuthEvent('sign_in', extra: {'method': method});
  }

  Future<void> trackSignOut() async {
    await logAuthEvent('sign_out');
  }

  // Chat tracking
  Future<void> trackChatCreated(
    String roomId, {
    bool isNSFW = false,
    bool hasPassword = false,
    bool allowsAnonymous = false,
    int maxMembers = 0,
  }) async {
    await logChatEvent(
      'room_created',
      roomId: roomId,
      extra: {
        'is_nsfw': isNSFW,
        'has_password': hasPassword,
        'allows_anonymous': allowsAnonymous,
        'max_members': maxMembers,
      },
    );
  }

  Future<void> trackChatJoined(String roomId, {bool wasInvited = false}) async {
    await logChatEvent(
      'room_joined',
      roomId: roomId,
      extra: {'was_invited': wasInvited},
    );
  }

  Future<void> trackChatLeft(String roomId, {String? reason}) async {
    await logChatEvent(
      'room_left',
      roomId: roomId,
      extra: {'reason': reason},
    );
  }

  Future<void> trackMessageSent(
    String roomId, {
    int messageLength = 0,
    bool containsLink = false,
  }) async {
    await logChatEvent(
      'message_sent',
      roomId: roomId,
      extra: {
        'message_length': messageLength,
        'contains_link': containsLink,
      },
    );
  }

  // Location tracking
  Future<void> trackLocationPermissionRequested() async {
    await logLocationEvent('permission_requested');
  }

  Future<void> trackLocationPermissionGranted() async {
    await logLocationEvent('permission_granted');
  }

  Future<void> trackLocationPermissionDenied() async {
    await logLocationEvent('permission_denied');
  }

  Future<void> trackGeofenceEntered(String roomId) async {
    await logLocationEvent(
      'geofence_entered',
      extra: {'room_id': roomId},
    );
  }

  Future<void> trackGeofenceExited(String roomId) async {
    await logLocationEvent(
      'geofence_exited',
      extra: {'room_id': roomId},
    );
  }

  // Moderation tracking
  Future<void> trackUserBlocked(String blockedUserId, {String? reason}) async {
    await logModerationEvent(
      'user_blocked',
      userId: blockedUserId,
      reason: reason,
    );
  }

  Future<void> trackUserReported(
    String reportedUserId, {
    String? reason,
    String? category,
  }) async {
    await logModerationEvent(
      'user_reported',
      userId: reportedUserId,
      reason: reason,
      extra: {'category': category},
    );
  }

  Future<void> trackRoomReported(
    String roomId, {
    String? reason,
    String? category,
  }) async {
    await logModerationEvent(
      'room_reported',
      roomId: roomId,
      reason: reason,
      extra: {'category': category},
    );
  }

  // App usage tracking
  Future<void> trackAppOpen() async {
    await logEvent('app_opened');
  }

  Future<void> trackAppClosed() async {
    await logEvent('app_closed');
  }

  Future<void> trackSettingsChanged(String setting, dynamic value) async {
    await logEvent('settings_changed', {
      'setting': setting,
      'value': value.toString(),
    });
  }

  Future<void> trackDarkModeToggled(bool enabled) async {
    await trackSettingsChanged('dark_mode', enabled);
  }

  Future<void> trackNotificationToggled(String type, bool enabled) async {
    await trackSettingsChanged('notification_$type', enabled);
  }

  /// Get analytics summary for debugging
  Map<String, dynamic> getAnalyticsSummary() {
    if (_prefs == null) return {};

    final events = _prefs!.getStringList('analytics_events') ?? [];
    final userId = _prefs!.getString('user_id');

    return {
      'total_events': events.length,
      'user_id': userId,
      'recent_events': events.take(10).toList(),
      'app_version': _version,
    };
  }
}

/// Provider for AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final service = AnalyticsService();
  service.initialize();
  return service;
});
