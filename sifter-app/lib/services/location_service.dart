import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  final _positionController = StreamController<Position>.broadcast();

  // Stream of user's current position
  Stream<Position> get positionStream => _positionController.stream;

  Position? get currentPosition => _currentPosition;

  /// Initialize location service and start tracking
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled.');
        }
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions are denied');
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions are permanently denied');
        }
        return false;
      }

      // Get initial position
      await _updateCurrentPosition();

      // Start position tracking
      _startPositionTracking();

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location service: $e');
      }
      return false;
    }
  }

  /// Update current position
  Future<void> _updateCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;
      _positionController.add(position);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current position: $e');
      }
    }
  }

  /// Start tracking position changes
  void _startPositionTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        _positionController.add(position);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error in position stream: $error');
        }
      },
    );
  }

  /// Check if user is within a specific geofenced area
  bool isWithinGeofence({
    required double chatLat,
    required double chatLng,
    required double radiusInMeters,
  }) {
    if (_currentPosition == null) return false;

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      chatLat,
      chatLng,
    );

    return distance <= radiusInMeters;
  }

  /// Get distance to a specific location in meters
  double? getDistanceTo({
    required double targetLat,
    required double targetLng,
  }) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLng,
    );
  }

  /// Check if user has moved outside all geofences they were in
  Future<List<String>> checkGeofenceExits(
    List<ChatRoomGeofence> activeGeofences,
  ) async {
    final exitedRooms = <String>[];

    for (final geofence in activeGeofences) {
      if (!isWithinGeofence(
        chatLat: geofence.latitude,
        chatLng: geofence.longitude,
        radiusInMeters: geofence.radiusInMeters,
      )) {
        exitedRooms.add(geofence.roomId);
      }
    }

    return exitedRooms;
  }

  /// Dispose of resources
  void dispose() {
    _positionStream?.cancel();
    _positionController.close();
  }
}

/// Data class for chat room geofence information
class ChatRoomGeofence {
  final String roomId;
  final double latitude;
  final double longitude;
  final double radiusInMeters;

  const ChatRoomGeofence({
    required this.roomId,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
  });
}

/// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for current position stream
final currentPositionProvider = StreamProvider<Position?>((ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.positionStream;
});
