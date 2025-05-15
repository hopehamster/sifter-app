import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:math';

class LocationService with ChangeNotifier {
  Location location = Location();
  LocationData? currentPosition;
  LocationData? lastKnownPosition;
  StreamSubscription<LocationData>? _locationSubscription;

  LocationService() {
    _initLocationService();
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    currentPosition = await location.getLocation();
    lastKnownPosition = currentPosition;

    _locationSubscription =
        location.onLocationChanged.listen((LocationData newPosition) {
      currentPosition = newPosition;
      lastKnownPosition = newPosition;
      notifyListeners();
    });
  }

  Future<LocationData?> getCurrentPosition() async {
    try {
      return await location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  static final Location _location = Location();

  static Future<bool> isLocationEnabled() async {
    return await _location.serviceEnabled();
  }

  static Future<void> enableLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) return;
    }

    await _location.enableBackgroundMode(enable: true);
  }

  static Future<void> disableLocation() async {
    await _location.enableBackgroundMode(enable: false);
  }
}
