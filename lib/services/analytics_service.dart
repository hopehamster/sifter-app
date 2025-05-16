import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_service.g.dart';

@riverpod
AnalyticsService analyticsService(AnalyticsServiceRef ref) {
  return AnalyticsService();
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      print('Failed to log analytics event: $e');
    }
  }

  Future<void> setUserProperties({
    String? userId,
    String? userRole,
    bool? isPremium,
    String? userLocation,
  }) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
        await _crashlytics.setUserIdentifier(userId);
      }

      await _analytics.setUserProperty(
        name: 'user_role',
        value: userRole,
      );

      await _analytics.setUserProperty(
        name: 'is_premium',
        value: isPremium?.toString(),
      );

      await _analytics.setUserProperty(
        name: 'user_location',
        value: userLocation ?? '',
      );
    } catch (e) {
      print('Failed to set user properties: $e');
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      print('Failed to log screen view: $e');
    }
  }

  Future<void> logLogin({
    required String method,
    bool success = true,
    String? errorMessage,
  }) async {
    try {
      await _analytics.logLogin(
        loginMethod: method,
      );

      if (!success) {
        await _analytics.logEvent(
          name: 'login_error',
          parameters: {
            'method': method,
            'error': errorMessage,
          },
        );
      }
    } catch (e) {
      print('Failed to log login event: $e');
    }
  }

  Future<void> logSignUp({
    required String method,
    bool success = true,
    String? errorMessage,
  }) async {
    try {
      await _analytics.logSignUp(
        signUpMethod: method,
      );

      if (!success) {
        await _analytics.logEvent(
          name: 'signup_error',
          parameters: {
            'method': method,
            'error': errorMessage,
          },
        );
      }
    } catch (e) {
      print('Failed to log signup event: $e');
    }
  }

  Future<void> logSearch({
    required String searchTerm,
    String? category,
    int? resultCount,
  }) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
      );

      if (category != null || resultCount != null) {
        await _analytics.logEvent(
          name: 'search_results',
          parameters: {
            if (category != null) 'category': category,
            if (resultCount != null) 'result_count': resultCount,
          },
        );
      }
    } catch (e) {
      print('Failed to log search event: $e');
    }
  }

  Future<void> logShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: itemId,
        method: method ?? 'unknown',
      );
    } catch (e) {
      print('Failed to log share event: $e');
    }
  }

  Future<void> logError(
    dynamic error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error': error.toString(),
          'reason': reason,
          'fatal': fatal,
        },
      );
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  Future<void> logPerformance({
    required String name,
    required int duration,
    Map<String, dynamic>? attributes,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'performance_metric',
        parameters: {
          'name': name,
          'duration': duration,
          if (attributes != null) ...attributes,
        },
      );
    } catch (e) {
      print('Failed to log performance metric: $e');
    }
  }

  Future<void> logUserEngagement({
    required String action,
    required String screen,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_engagement',
        parameters: {
          'action': action,
          'screen': screen,
          if (parameters != null) ...parameters,
        },
      );
    } catch (e) {
      print('Failed to log user engagement: $e');
    }
  }
} 