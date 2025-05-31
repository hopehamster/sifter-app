import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of moderation notifications
enum ModerationType {
  warning,
  blocked,
  banned,
  reported,
  roomDeleted,
}

/// Service for handling local notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _messageNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Load user preferences
      await _loadNotificationPreferences();

      _isInitialized = true;
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: Initialization failed - $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'sifter_chat',
            'Sifter Chat',
            description: 'General notifications for Sifter Chat',
            importance: Importance.high,
          ),
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'moderation',
            'Moderation Alerts',
            description: 'Notifications for moderation actions',
            importance: Importance.max,
          ),
        );
  }

  /// Load notification preferences from storage
  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _messageNotificationsEnabled =
          prefs.getBool('message_notifications') ?? true;
      _soundEnabled = prefs.getBool('notification_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
    } catch (e) {
      debugPrint('NotificationService: Error loading preferences - $e');
    }
  }

  /// Save notification preferences
  Future<void> saveNotificationPreferences({
    bool? messageNotifications,
    bool? sound,
    bool? vibration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (messageNotifications != null) {
        _messageNotificationsEnabled = messageNotifications;
        await prefs.setBool('message_notifications', messageNotifications);
      }

      if (sound != null) {
        _soundEnabled = sound;
        await prefs.setBool('notification_sound', sound);
      }

      if (vibration != null) {
        _vibrationEnabled = vibration;
        await prefs.setBool('notification_vibration', vibration);
      }

      debugPrint('NotificationService: Preferences saved successfully');
    } catch (e) {
      debugPrint('NotificationService: Error saving preferences - $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to appropriate screen
  }

  /// Show a local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'sifter_chat',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'moderation' ? 'Moderation Alerts' : 'Sifter Chat',
      channelDescription: channelId == 'moderation'
          ? 'Notifications for moderation actions'
          : 'General notifications for Sifter Chat',
      importance: channelId == 'moderation' ? Importance.max : Importance.high,
      priority: channelId == 'moderation' ? Priority.max : Priority.high,
      playSound: _soundEnabled,
      enableVibration: _vibrationEnabled,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _soundEnabled,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show notification for moderation action
  Future<void> showModerationNotification({
    required String title,
    required String message,
    required ModerationType type,
    String? roomId,
  }) async {
    if (!_messageNotificationsEnabled) return;

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      payload: roomId,
      channelId: 'moderation',
    );
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // Request local notification permissions
      final localPermission = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      debugPrint(
          'NotificationService: Local permission granted: $localPermission');
      return localPermission ?? false;
    } catch (e) {
      debugPrint('NotificationService: Permission request failed - $e');
      return false;
    }
  }

  /// Show notification for new message
  Future<void> showNewMessageNotification({
    required String roomName,
    required String senderName,
    required String message,
    String? roomId,
  }) async {
    if (!_messageNotificationsEnabled) return;

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '$senderName in $roomName',
      body: message,
      payload: roomId,
    );
  }

  /// Show notification for room activity
  Future<void> showRoomActivityNotification({
    required String roomName,
    required String activity,
    String? roomId,
  }) async {
    if (!_messageNotificationsEnabled) return;

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: roomName,
      body: activity,
      payload: roomId,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Getters for notification preferences
  bool get isMessageNotificationsEnabled => _messageNotificationsEnabled;
  bool get isSoundEnabled => _soundEnabled;
  bool get isVibrationEnabled => _vibrationEnabled;

  /// Dispose method
  void dispose() {
    // Nothing to dispose for local notifications
  }
}

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});
