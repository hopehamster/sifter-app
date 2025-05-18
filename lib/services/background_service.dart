import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'background_service.g.dart';

/// Service responsible for background tasks including:
/// - Location monitoring
/// - Chat room expiration
/// - Activity tracking
/// - Periodic cleanup of expired rooms
class BackgroundService {
  static const String _notificationChannelId = 'sifter_background';
  static const String _notificationId = 'sifter_background_notification';
  static const String _portName = 'sifter_background_port';
  
  /// Initialize and start the background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Sifter Background Service',
        initialNotificationContent: 'Monitoring nearby chats',
        foregroundServiceNotificationId: int.parse(_notificationId),
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    await service.startService();
  }
  
  /// iOS background task handler - required but actually runs onStart
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
  
  /// Main background task entry point
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    // Initialize Firebase if needed
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print('Failed to initialize Firebase in background: $e');
    }
    
    // Set up port for communication with main app
    final ReceivePort receivePort = ReceivePort();
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName);
    
    // Register the send port
    if (sendPort != null) {
      sendPort.send(null);
    }
    
    // Listen for messages from main app
    receivePort.listen((message) {
      // Handle messages from main app
      if (message is Map<String, dynamic>) {
        if (message['action'] == 'updateLocation') {
          _updateCurrentLocation(
            message['latitude'] as double, 
            message['longitude'] as double
          );
        }
      }
    });
    
    // If using Android, set as a foreground service
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
    
    // Schedule periodic tasks
    // Check nearby chats every 5 minutes
    Timer.periodic(Duration(minutes: 5), (timer) => _checkNearbyChats());
    
    // Check room expiration every 15 minutes
    Timer.periodic(Duration(minutes: 15), (timer) => _checkRoomExpiration());
    
    // Update user activity in rooms every 5 minutes
    Timer.periodic(Duration(minutes: 5), (timer) => _updateUserActivity());
    
    // Notify the service is running
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    
    // Initial status update
    _updateServiceStatus(service, 'Running background tasks');
  }
  
  /// Update the service notification to show current status
  static void _updateServiceStatus(ServiceInstance service, String message) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Sifter Active',
        content: message,
      );
    }
    
    // Send status update to main app
    service.invoke('update', {'status': message, 'timestamp': DateTime.now().toIso8601String()});
  }
  
  /// Save current location to shared preferences for later use
  static Future<void> _updateCurrentLocation(double latitude, double longitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', latitude);
      await prefs.setDouble('last_longitude', longitude);
      await prefs.setInt('last_location_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error storing location in background: $e');
      Sentry.captureException(e, hint: {'action': 'update_location_background'});
    }
  }
  
  /// Retrieve the last known location
  static Future<Position?> _getLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble('last_latitude');
      final longitude = prefs.getDouble('last_longitude');
      final timestamp = prefs.getInt('last_location_time');
      
      if (latitude != null && longitude != null && timestamp != null) {
        return Position(
          latitude: latitude,
          longitude: longitude,
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      
      // Try to get actual location if we don't have a saved one
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known location: $e');
      Sentry.captureException(e, hint: {'action': 'get_last_location'});
      return null;
    }
  }
  
  /// Check for nearby chat rooms and save to shared preferences
  static Future<void> _checkNearbyChats() async {
    try {
      final position = await _getLastKnownLocation();
      if (position == null) return;
      
      final db = FirebaseDatabase.instance.ref();
      
      // Get rooms within approximately 1km (quick filter)
      final lat = position.latitude;
      final lng = position.longitude;
      final latRange = 0.01; // Roughly 1km
      final lngRange = 0.01; 
      
      final snapshot = await db.child('rooms')
          .orderByChild('latitude')
          .startAt(lat - latRange)
          .endAt(lat + latRange)
          .get();
      
      if (!snapshot.exists) return;
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> nearbyRooms = [];
      
      data.forEach((key, value) {
        final Map<String, dynamic> room = Map<String, dynamic>.from(value);
        
        // Further filter by longitude
        final roomLng = room['longitude'] as double;
        if (roomLng >= lng - lngRange && roomLng <= lng + lngRange) {
          // Calculate actual distance
          final distance = Geolocator.distanceBetween(
            lat, lng, room['latitude'] as double, roomLng);
          
          // Only include rooms within their defined radius
          if (distance <= (room['radius'] as double) * 1000) {
            nearbyRooms.add({
              'id': key,
              'name': room['name'],
              'distance': distance,
            });
          }
        }
      });
      
      // Save nearby rooms to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nearby_rooms', 
        nearbyRooms.map((r) => '${r['id']}:${r['name']}:${r['distance']}').join(','));
      
    } catch (e) {
      print('Error checking nearby chats: $e');
      Sentry.captureException(e, hint: {'action': 'check_nearby_chats'});
    }
  }
  
  /// Check for expired rooms and mark them as inactive
  static Future<void> _checkRoomExpiration() async {
    try {
      final db = FirebaseDatabase.instance.ref();
      final now = DateTime.now();
      
      // Get all active rooms
      final snapshot = await db.child('rooms')
          .orderByChild('isActive')
          .equalTo(true)
          .get();
      
      if (!snapshot.exists) return;
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final List<String> roomsToDeactivate = [];
      
      data.forEach((key, value) {
        final Map<String, dynamic> room = Map<String, dynamic>.from(value);
        
        // Check if the room has an expiration time
        if (room.containsKey('expiresAt')) {
          final expiresAt = DateTime.parse(room['expiresAt'] as String);
          if (now.isAfter(expiresAt)) {
            roomsToDeactivate.add(key);
          }
        }
        
        // Check for inactivity (24 hours without messages)
        if (room.containsKey('lastActivityAt')) {
          final lastActivity = DateTime.parse(room['lastActivityAt'] as String);
          if (now.difference(lastActivity).inHours >= 24) {
            roomsToDeactivate.add(key);
          }
        } else if (room.containsKey('createdAt')) {
          // If no activity, check creation time
          final createdAt = DateTime.parse(room['createdAt'] as String);
          if (now.difference(createdAt).inHours >= 24) {
            roomsToDeactivate.add(key);
          }
        }
        
        // Check for empty rooms (no participants for at least 1 hour)
        if (room.containsKey('participants') && 
            (room['participants'] as int) == 0 &&
            room.containsKey('emptyTime')) {
          final emptyTime = DateTime.parse(room['emptyTime'] as String);
          if (now.difference(emptyTime).inHours >= 1) {
            roomsToDeactivate.add(key);
          }
        }
      });
      
      // Mark rooms as inactive
      for (final roomId in roomsToDeactivate) {
        await db.child('rooms/$roomId').update({
          'isActive': false,
          'deactivatedAt': now.toIso8601String(),
          'deactivatedReason': 'auto_expiration',
        });
        
        print('Room $roomId marked as inactive due to expiration');
      }
      
      // Update counters
      if (roomsToDeactivate.isNotEmpty) {
        await db.child('stats/expiredRooms')
            .set(ServerValue.increment(roomsToDeactivate.length));
      }
      
    } catch (e) {
      print('Error checking room expiration: $e');
      Sentry.captureException(e, hint: {'action': 'check_room_expiration'});
    }
  }
  
  /// Update user activity timestamps in active rooms
  static Future<void> _updateUserActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');
      if (userId == null) return;
      
      final currentRoomId = prefs.getString('current_room_id');
      if (currentRoomId == null) return;
      
      final db = FirebaseDatabase.instance.ref();
      
      // Update the user's activity timestamp in the current room
      await db.child('rooms/$currentRoomId/activityLog/$userId').update({
        'lastActive': ServerValue.timestamp,
      });
      
      // Also update the room's activity timestamp
      await db.child('rooms/$currentRoomId').update({
        'lastActivityAt': DateTime.now().toIso8601String(),
      });
      
      // Reset the room's expiration time
      await db.child('rooms/$currentRoomId').update({
        'expiresAt': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
      });
      
    } catch (e) {
      print('Error updating user activity: $e');
      Sentry.captureException(e, hint: {'action': 'update_user_activity'});
    }
  }
}

@riverpod
BackgroundService backgroundService(BackgroundServiceRef ref) {
  return BackgroundService();
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _isInitialized = false;

  /// Initialize the background service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure the background service
      await _configureService();
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize background service: $e');
    }
  }

  /// Configure the background service
  Future<void> _configureService() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sifter_background_channel',
      'Sifter Background Service',
      description: 'Channel for Sifter background service',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'sifter_background_channel',
        initialNotificationTitle: 'Sifter',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onBackgroundIOS,
      ),
    );
  }

  /// Start the background service
  Future<void> startService() async {
    if (!_isInitialized) {
      await initialize();
    }

    _service.startService();
  }

  /// Stop the background service
  Future<void> stopService() async {
    _service.invoke('stopService');
  }

  /// Check if the service is running
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// Invoke a command in the background service
  Future<void> invokeCommand(String command, [Map<String, dynamic>? args]) async {
    _service.invoke(command, args);
  }

  /// Register for location updates
  Future<void> registerLocationUpdates() async {
    _service.invoke('startLocationUpdates');
  }

  /// Unregister from location updates
  Future<void> unregisterLocationUpdates() async {
    _service.invoke('stopLocationUpdates');
  }

  /// Handle service initialization from main.dart
  Future<void> handleInitialization() async {
    try {
      await initialize();
    } catch (e) {
      print('Error during background service initialization: $e');
      // Continue with app startup even if background service fails
    }
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Location updates handler
  service.on('startLocationUpdates').listen((event) async {
    _startLocationUpdates(service);
  });

  service.on('stopLocationUpdates').listen((event) {
    _stopLocationUpdates();
  });

  // Initial state
  service.invoke('update', {'running': true});
}

@pragma('vm:entry-point')
Future<bool> _onBackgroundIOS(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // For iOS, we return true to indicate the service should run in background
  return true;
}

// Location tracking vars
StreamSubscription<Position>? _positionStreamSubscription;
Timer? _locationUpdateTimer;

// Start location updates
void _startLocationUpdates(ServiceInstance service) async {
  // Stop any existing subscriptions
  _stopLocationUpdates();

  try {
    // Request permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    // Start position updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      service.invoke('locationUpdate', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp != null ? position.timestamp.toIso8601String() : DateTime.now().toIso8601String(),
      });
    }, onError: (error) {
      print('Position stream error: $error');
      // Try to recover by restarting after a delay
      Future.delayed(const Duration(minutes: 1), () {
        if (_positionStreamSubscription == null) {
          _startLocationUpdates(service);
        }
      });
    });

    // Also set up a periodic check to ensure we're still tracking
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        service.invoke('locationUpdate', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp != null ? position.timestamp.toIso8601String() : DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Error in periodic position update: $e');
      }
    });
  } catch (e) {
    print('Error starting location updates: $e');
  }
}

// Stop location updates
void _stopLocationUpdates() {
  _positionStreamSubscription?.cancel();
  _positionStreamSubscription = null;
  
  _locationUpdateTimer?.cancel();
  _locationUpdateTimer = null;
} 