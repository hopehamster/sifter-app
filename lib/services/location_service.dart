import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  final Location _location = Location();
  LocationData? _lastKnownLocation;
  bool _isListening = false;

  LocationData? get lastKnownLocation => _lastKnownLocation;

  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> isLocationEnabled() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      return false;
    }
  }

  Future<void> enableLocation() async {
    try {
      final enabled = await _location.requestService();
      if (!enabled) {
        throw Exception('Location services could not be enabled');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disableLocation() async {
    try {
      await _location.enableBackgroundMode(enable: false);
      _isListening = false;
    } catch (e) {
      rethrow;
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      if (!await isLocationEnabled()) {
        throw Exception('Location services are disabled');
      }

      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      _lastKnownLocation = await _location.getLocation();
      return _lastKnownLocation;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startLocationUpdates({
    required Function(LocationData) onLocationChanged,
    required Function(dynamic) onError,
    double minDistance = 10, // meters
    int minTime = 1000, // milliseconds
  }) async {
    try {
      if (!await isLocationEnabled()) {
        throw Exception('Location services are disabled');
      }

      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      await _location.enableBackgroundMode(enable: true);
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: minTime,
        distanceFilter: minDistance,
      );

      _location.onLocationChanged.listen(
        (LocationData locationData) {
          _lastKnownLocation = locationData;
          onLocationChanged(locationData);
        },
        onError: (dynamic error) {
          onError(error);
        },
      );

      _isListening = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopLocationUpdates() async {
    try {
      await _location.enableBackgroundMode(enable: false);
      _isListening = false;
    } catch (e) {
      rethrow;
    }
  }

  bool get isListening => _isListening;

  Future<double?> getDistanceTo(double targetLat, double targetLng) async {
    try {
      if (_lastKnownLocation == null) {
        await getCurrentLocation();
      }

      if (_lastKnownLocation == null) {
        return null;
      }

      return _calculateDistance(
        _lastKnownLocation!.latitude!,
        _lastKnownLocation!.longitude!,
        targetLat,
        targetLng,
      );
    } catch (e) {
      return null;
    }
  }

  double _calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLat)) *
            math.cos(_toRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }
}