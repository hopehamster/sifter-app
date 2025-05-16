import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sifter/services/analytics_service.dart';
import 'user_service.dart';

part 'notification_service.g.dart';

@riverpod
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AnalyticsService _analytics = AnalyticsService();
  final UserService _userService = UserService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for iOS
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize notifications: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      await _analytics.logEvent('topic_subscribed', parameters: {'topic': topic});
    } catch (e) {
      print('Failed to subscribe to topic: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      await _analytics.logEvent('topic_unsubscribed', parameters: {'topic': topic});
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
      rethrow;
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? senderId,
    String? currentUserId,
  }) async {
    // Skip notification if it's from a muted user
    if (senderId != null && currentUserId != null) {
      final isMuted = await _userService.isUserMuted(currentUserId, senderId);
      
      if (isMuted) {
        // Skip notification for muted user
        return;
      }
    }
    
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'sifter_channel',
      'Sifter Notifications',
      channelDescription: 'Notification channel for Sifter',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iOSNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      print('Failed to cancel notifications: $e');
      rethrow;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        await showLocalNotification(
          title: notification.title ?? 'New Message',
          body: notification.body ?? '',
          payload: message.data.toString(),
        );
      }
    } catch (e) {
      print('Failed to handle foreground message: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // TODO: Implement navigation based on notification data
    print('Notification tapped: ${message.data}');
  }

  void _onNotificationTap(NotificationResponse response) {
    // TODO: Implement navigation based on notification payload
    print('Local notification tapped: ${response.payload}');
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _analytics.logEvent('background_notification_received', parameters: {
      'title': message.notification?.title,
      'body': message.notification?.body,
    });
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // TODO: Implement background message handling
  print('Handling background message: ${message.messageId}');
}

enum NotificationImportance {
  low,
  medium,
  high,
} 