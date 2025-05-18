import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

/// Service for managing location permissions and tracking
class LocationService {
  static final LocationService _instance = LocationService._internal();
  static LocationService get instance => _instance;
  
  LocationService._internal();
  
  static const String _locationEnabledKey = 'location_enabled';
  bool _isEnabled = false;
  
  /// Initialize the location service and check if location is enabled
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_locationEnabledKey) ?? false;
    
    // If enabled in preferences, check if we actually have permission
    if (_isEnabled) {
      final status = await Geolocator.checkPermission();
      _isEnabled = status == LocationPermission.always || 
                  status == LocationPermission.whileInUse;
      
      // Update preferences if there's a mismatch
      if (!_isEnabled) {
        await prefs.setBool(_locationEnabledKey, false);
      }
    }
  }
  
  /// Get the current location if enabled and permission granted
  Future<Position?> getCurrentLocation() async {
    if (!_isEnabled) {
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }
  
  /// Check if location services are enabled
  bool get isEnabled => _isEnabled;
  
  /// Request location permission from the user
  Future<bool> requestLocationPermission() async {
    // First, check if location services are enabled on the device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to enable location services
      return false;
    }
    
    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    // Handle permanently denied
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    // If we get here, permission is granted
    _isEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, true);
    return true;
  }
  
  /// Disable location tracking
  Future<void> disableLocation() async {
    _isEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, false);
  }
  
  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
  
  /// Check if a location is within a specified radius from another location
  bool isWithinRadius(double lat1, double lon1, double lat2, double lon2, double radiusKm) {
    final distanceKm = calculateDistance(lat1, lon1, lat2, lon2);
    return distanceKm <= radiusKm;
  }
  
  // Check if the user is within the radius of nearby chat rooms and notify them
  Future<void> checkNearbyChatsAndNotify() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return;
      
      // Fetch chat rooms within a reasonable distance (e.g., 1 km)
      final chatService = ChatService(null);
      final nearbyRooms = await chatService.getNearbyRooms(
        position.latitude, 
        position.longitude, 
        1.0, // 1 km search radius
      );
      
      if (nearbyRooms.isEmpty) return;
      
      // Get previously seen rooms from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final String? seenRoomsJson = prefs.getString('seen_nearby_rooms');
      final Map<String, int> seenRooms = seenRoomsJson != null 
          ? Map<String, int>.from(json.decode(seenRoomsJson))
          : {};
      
      // Current timestamp in milliseconds
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Rooms to notify about
      final roomsToNotify = <ChatRoom>[];
      
      // Check each nearby room
      for (final room in nearbyRooms) {
        final distance = calculateDistance(
          position.latitude,
          position.longitude,
          room.latitude,
          room.longitude,
        );
        
        // Convert distance to meters
        final distanceInMeters = distance * 1000;
        
        // Check if user is within range of the chat room
        if (distanceInMeters <= room.radius * 1000) {
          // Check if we've seen this room recently (within the last hour)
          final lastSeen = seenRooms[room.id] ?? 0;
          final hourAgo = now - (60 * 60 * 1000); // 1 hour in milliseconds
          
          if (lastSeen < hourAgo) {
            // Haven't seen this room recently, add to notification list
            roomsToNotify.add(room);
            
            // Update seen timestamp
            seenRooms[room.id] = now;
          }
        }
      }
      
      // Save updated seen rooms
      await prefs.setString('seen_nearby_rooms', json.encode(seenRooms));
      
      // Show notifications for new rooms
      if (roomsToNotify.isNotEmpty) {
        final notificationService = NotificationService();
        
        if (roomsToNotify.length == 1) {
          // Single room notification
          final room = roomsToNotify.first;
          await notificationService.showLocalNotification(
            title: 'Chat Nearby: ${room.name}',
            body: 'You\'re in range of a local chat. Join now to connect with people nearby!',
            payload: json.encode({'roomId': room.id}),
          );
        } else {
          // Multiple rooms notification
          await notificationService.showLocalNotification(
            title: 'Chats Nearby',
            body: 'You\'re in range of ${roomsToNotify.length} local chats. Check them out!',
            payload: json.encode({'multiple': true}),
          );
        }
      }
    } catch (e) {
      print('Error checking nearby chats: $e');
    }
  }
}