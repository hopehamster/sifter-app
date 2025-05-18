import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:sifter/services/database_service.dart';
import 'package:sifter/services/message_service.dart';
import 'package:sifter/models/chat_room.dart';
import 'dart:math' as math;
import 'package:sifter/services/location_service.dart';
import 'package:sifter/services/points_service.dart';
import 'package:sifter/utils/api_utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class RoomService {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  final DatabaseService _database = DatabaseService();
  final MessageService _messageService = MessageService();
  final AnalyticsService _analytics = AnalyticsService();
  final LocationService _locationService = LocationService.instance;
  final PointsService _pointsService = PointsService();

  // Get nearby rooms around the user's current location
  Future<List<ChatRoom>> fetchNearbyRooms() async {
    try {
      // Get the user's current location
      final userLocation = await ApiUtils.retryOperation(
        () => _locationService.getCurrentLocation(),
        retryHint: 'get_current_location',
      );
      
      if (userLocation == null) {
        await _analytics.logEvent('error', parameters: {
          'error_type': 'fetch_nearby_rooms_error',
          'error_message': 'Could not get user location',
        });
        return [];
      }
      
      // Default radius in kilometers (500m = 0.5km)
      const defaultRadius = 0.5;
      
      // Get rooms from radius
      return getNearbyRooms(
        userLocation.latitude,
        userLocation.longitude,
        defaultRadius
      );
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'fetch_nearby_rooms_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'fetch_nearby_rooms'});
      return [];
    }
  }

  // Create a new room with enhanced features
  Future<String> createRoom({
    required String name,
    required String creatorId,
    String? description,
    bool isPrivate = false,
    List<String>? members,
    double latitude = 0.0,
    double longitude = 0.0,
    double radius = 0.2,
    bool isNsfw = false,
    String? password,
    String? rules,
    int? themeColor,
    bool allowAnonymous = true,
  }) async {
    try {
      // Create the room with the 24-hour expiration
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: 24));
      
      final roomData = {
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'isPrivate': isPrivate,
        'members': members ?? [creatorId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageSender': null,
        'unreadCount': {},
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'isNsfw': isNsfw,
        'password': password,
        'rules': rules ?? 'Be respectful to all users. No spam or advertising.',
        'themeColor': themeColor ?? 0xFF2196F3, // Default blue
        'allowAnonymous': allowAnonymous,
        'isActive': true,
        'participants': 1,
        'expiresAt': expiresAt.toIso8601String(),
        'lastActivityAt': now.toIso8601String(),
        'activityLog': {
          creatorId: {
            'joinedAt': now.toIso8601String(),
            'lastActive': now.millisecondsSinceEpoch,
          }
        }
      };

      final roomId = await ApiUtils.retryOperation(
        () => _database.createRoom(roomData),
        retryHint: 'create_room',
      );
      
      // Award points for creating a room
      await _pointsService.rewardForGroupCreation(
        creatorId, 
        isNsfw: isNsfw, 
        isPasswordProtected: password != null && password.isNotEmpty
      );
      
      // Log room creation
      await _analytics.logEvent('room_created', parameters: {
        'room_id': roomId,
        'is_private': isPrivate,
        'member_count': (members?.length ?? 1) + 1,
        'is_nsfw': isNsfw,
        'has_password': password != null && password.isNotEmpty,
      });

      return roomId;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'create_room_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'create_room'});
      rethrow;
    }
  }

  // Update room details
  Future<void> updateRoom({
    required String roomId,
    String? name,
    String? description,
    bool? isPrivate,
    String? rules,
    int? themeColor,
    bool? isNsfw,
    bool? allowAnonymous,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastActivityAt': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (isPrivate != null) updates['isPrivate'] = isPrivate;
      if (rules != null) updates['rules'] = rules;
      if (themeColor != null) updates['themeColor'] = themeColor;
      if (isNsfw != null) updates['isNsfw'] = isNsfw;
      if (allowAnonymous != null) updates['allowAnonymous'] = allowAnonymous;

      await ApiUtils.retryOperation(
        () => _database.updateRoom(roomId, updates),
        retryHint: 'update_room',
      );
      
      await _analytics.logEvent('room_updated', parameters: {
        'room_id': roomId,
        'updates': updates.keys.toList(),
      });
      
      // Reset the room's expiration time
      await resetRoomExpiration(roomId);
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'update_room_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'update_room'});
      rethrow;
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      await ApiUtils.retryOperation(
        () => _database.deleteRoom(roomId),
        retryHint: 'delete_room',
      );
      
      await _analytics.logEvent('room_deleted', parameters: {
        'room_id': roomId,
      });
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'delete_room_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'delete_room'});
      rethrow;
    }
  }

  // Add member to room with point rewards
  Future<void> addMember(String roomId, String userId) async {
    try {
      final roomDoc = await ApiUtils.retryOperation(
        () => _database.rooms.doc(roomId).get(),
        retryHint: 'get_room_details',
      );
      
      if (!roomDoc.exists) {
        throw Exception('Room not found');
      }
      
      final roomData = roomDoc.data() as Map<String, dynamic>;
      final isNsfw = roomData['isNsfw'] as bool? ?? false;
      
      final now = DateTime.now();
      
      // Updates for the room
      await ApiUtils.retryOperation(
        () => _database.updateRoom(roomId, {
          'members': FieldValue.arrayUnion([userId]),
          'unreadCount.$userId': 0,
          'participants': FieldValue.increment(1),
          'lastActivityAt': now.toIso8601String(),
          // Add user to activity log
          'activityLog.$userId': {
            'joinedAt': now.toIso8601String(),
            'lastActive': now.millisecondsSinceEpoch,
          }
        }),
        retryHint: 'add_member',
      );
      
      // Award points
      await _pointsService.rewardForJoiningGroup(userId, isNsfw: isNsfw);
      
      // Log analytics
      await _analytics.logEvent('member_added', parameters: {
        'room_id': roomId,
        'user_id': userId,
        'is_nsfw': isNsfw,
      });
      
      // Reset the room's expiration time
      await resetRoomExpiration(roomId);
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'add_member_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'add_member'});
      rethrow;
    }
  }

  // Remove member from room
  Future<void> removeMember(String roomId, String userId) async {
    try {
      final now = DateTime.now();
      
      await ApiUtils.retryOperation(
        () => _database.updateRoom(roomId, {
          'members': FieldValue.arrayRemove([userId]),
          'unreadCount.$userId': FieldValue.delete(),
          'participants': FieldValue.increment(-1),
          'lastActivityAt': now.toIso8601String(),
          // Remove user from activity log
          'activityLog.$userId': FieldValue.delete(),
        }),
        retryHint: 'remove_member',
      );
      
      // Check if room is now empty and update empty time
      final roomDoc = await ApiUtils.retryOperation(
        () => _database.rooms.doc(roomId).get(),
        retryHint: 'get_room_after_remove',
      );
      
      if (roomDoc.exists) {
        final roomData = roomDoc.data() as Map<String, dynamic>;
        final members = roomData['members'] as List<dynamic>? ?? [];
        
        if (members.isEmpty) {
          await ApiUtils.retryOperation(
            () => _database.updateRoom(roomId, {
              'emptyTime': now.toIso8601String(),
            }),
            retryHint: 'update_empty_time',
          );
        }
      }
      
      await _analytics.logEvent('member_removed', parameters: {
        'room_id': roomId,
        'user_id': userId,
      });
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'remove_member_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'remove_member'});
      rethrow;
    }
  }

  // Get room details
  Future<DocumentSnapshot> getRoom(String roomId) async {
    try {
      return await ApiUtils.retryOperation(
        () => _database.rooms.doc(roomId).get(),
        retryHint: 'get_room',
      );
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_room_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'get_room'});
      rethrow;
    }
  }

  // Get all rooms for a user
  Stream<QuerySnapshot> getUserRooms(String userId) {
    return _database.rooms
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Update last message with room expiration reset
  Future<void> updateLastMessage(String roomId, String messageId) async {
    try {
      final message = await ApiUtils.retryOperation(
        () => _messageService.getMessage(messageId),
        retryHint: 'get_message',
      );
      
      final data = message.data() as Map<String, dynamic>;
      final now = DateTime.now();

      await ApiUtils.retryOperation(
        () => _database.updateRoom(roomId, {
          'lastMessage': data['text'] ?? 'Media message',
          'lastMessageSender': data['senderId'],
          'lastMessageTime': data['timestamp'],
          'unreadCount': FieldValue.increment(1),
          'lastActivityAt': now.toIso8601String(),
          // Reset expiration
          'expiresAt': now.add(Duration(hours: 24)).toIso8601String(),
        }),
        retryHint: 'update_last_message',
      );
      
      // Award points for sending a message
      await _pointsService.rewardForSendingMessage(data['senderId']);
      
      // Update user's activity timestamp
      await ApiUtils.retryOperation(
        () => _database.updateRoom(roomId, {
          'activityLog.${data['senderId']}.lastActive': now.millisecondsSinceEpoch,
        }),
        retryHint: 'update_user_activity',
      );
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'update_last_message_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'update_last_message'});
    }
  }

  // Mark room as read for a user
  Future<void> markRoomAsRead(String roomId, String userId) async {
    try {
      final now = DateTime.now();
      
      await ApiUtils.retryOperation(
        () => _database.updateRoom(roomId, {
          'readBy.$userId': now,
          'unreadCount.$userId': 0,
          'activityLog.$userId.lastActive': now.millisecondsSinceEpoch,
        }),
        retryHint: 'mark_room_read',
      );
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'mark_room_read_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'mark_room_read'});
    }
  }

  // Reset room expiration time (extends the room for another 24 hours)
  Future<void> resetRoomExpiration(String roomId) async {
    try {
      final now = DateTime.now();
      
      await ApiUtils.retryOperation(
        () => _database.updateRoom(roomId, {
          'expiresAt': now.add(Duration(hours: 24)).toIso8601String(),
          'lastActivityAt': now.toIso8601String(),
        }),
        retryHint: 'reset_room_expiration',
      );
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'reset_room_expiration_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'reset_room_expiration'});
    }
  }

  // Create a ChatRoom object with Freezed model
  Future<ChatRoom> createRoomObject(ChatRoom room) async {
    try {
      final docRef = _database.rooms.doc();
      final roomWithId = room.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 24)),
        lastActivityAt: DateTime.now(),
      );
      
      await ApiUtils.retryOperation(
        () => docRef.set(roomWithId.toJson()),
        retryHint: 'create_room_object',
      );
      
      // Log room creation
      await _analytics.logEvent('room_created', parameters: {
        'room_id': roomWithId.id,
        'room_name': roomWithId.name,
        'created_by': roomWithId.createdBy,
        'is_nsfw': roomWithId.isNsfw,
      });
      
      // Award points for creating room
      await _pointsService.rewardForGroupCreation(
        roomWithId.createdBy,
        isNsfw: roomWithId.isNsfw,
        isPasswordProtected: roomWithId.isPasswordProtected,
      );
      
      return roomWithId;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'create_room_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'create_room_object'});
      rethrow;
    }
  }

  // Update an existing room with ChatRoom object
  Future<void> updateRoomObject(ChatRoom room) async {
    try {
      final now = DateTime.now();
      final updatedRoom = room.copyWith(
        updatedAt: now,
        lastActivityAt: now,
        expiresAt: now.add(Duration(hours: 24)), // Reset expiration
      );
      
      await ApiUtils.retryOperation(
        () => _database.updateRoom(room.id, updatedRoom.toJson()),
        retryHint: 'update_room_object',
      );
      
      // Log room update
      await _analytics.logEvent('room_updated', parameters: {
        'room_id': room.id,
        'room_name': room.name,
      });
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'update_room_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'update_room_object'});
      rethrow;
    }
  }

  // Get a list of rooms for a user with ChatRoom objects
  Future<List<ChatRoom>> getUserRoomsList(String userId) async {
    try {
      final snapshot = await ApiUtils.retryOperation(
        () => _database.rooms
            .where('members', arrayContains: userId)
            .get(),
        retryHint: 'get_user_rooms_list',
      );
      
      return snapshot.docs
          .map((doc) => ChatRoom.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_user_rooms_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'get_user_rooms_list'});
      return [];
    }
  }

  // Get nearby rooms based on location
  Future<List<ChatRoom>> getNearbyRooms(double latitude, double longitude, double radiusKm) async {
    try {
      // This is a simplified implementation. In a real app, you would use
      // geohashing or a specialized database for geo queries
      final snapshot = await ApiUtils.retryOperation(
        () => _database.rooms
            .where('isPrivate', isEqualTo: false)
            .get(),
        retryHint: 'get_nearby_rooms',
      );
          
      final allRooms = snapshot.docs
          .map((doc) => ChatRoom.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Filter rooms by distance and check if expired
      final filteredRooms = allRooms.where((room) {
        // Skip expired or inactive rooms
        if (room.isExpired || room.isInactive || !room.isActive) {
          return false;
        }
        
        // Calculate distance using the Haversine formula
        final distance = _calculateDistance(
          latitude, longitude, room.latitude, room.longitude);
          
        // Only include rooms within the search radius (typically 500m)
        return distance <= radiusKm;
      }).toList();
      
      // Sort by distance (closest first)
      filteredRooms.sort((a, b) {
        final distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
        final distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
      
      return filteredRooms;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_nearby_rooms_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'get_nearby_rooms'});
      return [];
    }
  }
  
  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
        
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
  
  // Join a room with validation
  Future<bool> joinRoom(String roomId, String userId, {String? password}) async {
    try {
      final roomDoc = await ApiUtils.retryOperation(
        () => getRoom(roomId),
        retryHint: 'get_room_for_join',
      );
      
      if (!roomDoc.exists) {
        return false;
      }
      
      final roomData = roomDoc.data() as Map<String, dynamic>;
      
      // Check if password-protected and validate password
      if (roomData['password'] != null && roomData['password'] != password) {
        return false;
      }
      
      // Check if room is NSFW and user is authenticated
      if (roomData['isNsfw'] == true && userId.isEmpty) {
        return false;
      }
      
      // Add user to room
      await addMember(roomId, userId);
      
      // Award points
      final isNsfw = roomData['isNsfw'] as bool? ?? false;
      await _pointsService.rewardForJoiningGroup(userId, isNsfw: isNsfw);
      
      return true;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'join_room_error',
        'error_message': e.toString(),
      });
      Sentry.captureException(e, hint: {'action': 'join_room'});
      return false;
    }
  }

  // Update user activity in a room
  Future<void> updateLastActivity(String roomId, String userId) async {
    try {
      final now = DateTime.now();
      
      await ApiUtils.retryOperation(
        () => _database.updateRoom(roomId, {
          'lastActivityAt': now.toIso8601String(),
          'expiresAt': now.add(Duration(hours: 24)).toIso8601String(),
          'activityLog.$userId.lastActive': now.millisecondsSinceEpoch,
        }),
        retryHint: 'update_activity',
      );
      
    } catch (e) {
      Sentry.captureException(e, hint: {'action': 'update_activity'});
    }
  }
  
  // Create a room with customization options
  Future<String> createCustomRoom({
    required String name,
    required String creatorId,
    String? description,
    required double latitude,
    required double longitude,
    double radius = 0.2,
    bool isNsfw = false,
    String? password,
    String? rules,
    int? themeColor,
    bool allowAnonymous = true,
  }) async {
    try {
      // Create the room with the 24-hour expiration
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: 24));
      
      final roomData = {
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'createdAt': FieldValue.serverTimestamp(),
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'isNsfw': isNsfw,
        'password': password,
        'rules': rules ?? 'Be respectful to all users. No spam or advertising.',
        'themeColor': themeColor ?? 0xFF2196F3, // Default blue
        'allowAnonymous': allowAnonymous,
        'isActive': true,
        'participants': 1,
        'expiresAt': expiresAt.toIso8601String(),
        'lastActivityAt': now.toIso8601String(),
        'activityLog': {
          creatorId: {
            'joinedAt': now.toIso8601String(),
            'lastActive': now.millisecondsSinceEpoch,
          }
        }
      };

      final roomId = await _database.createRoom(roomData);
      
      // Award points for creating a room
      await _pointsService.rewardForGroupCreation(
        creatorId, 
        isNsfw: isNsfw, 
        isPasswordProtected: password != null && password.isNotEmpty
      );
      
      // Log room creation
      await _analytics.logEvent('room_created', parameters: {
        'room_id': roomId,
        'is_nsfw': isNsfw,
        'has_password': password != null && password.isNotEmpty,
      });

      return roomId;
    } catch (e) {
      Sentry.captureException(e, hint: {'action': 'create_custom_room'});
      rethrow;
    }
  }
  
  // Check if a room is expired
  Future<bool> isRoomExpired(String roomId) async {
    try {
      final roomDoc = await _database.rooms.doc(roomId).get();
      
      if (!roomDoc.exists) return true;
      
      final roomData = roomDoc.data() as Map<String, dynamic>;
      
      // Check expiration timestamp
      if (roomData.containsKey('expiresAt')) {
        final expiresAt = DateTime.parse(roomData['expiresAt'] as String);
        if (DateTime.now().isAfter(expiresAt)) {
          return true;
        }
      }
      
      // Check last activity timestamp
      if (roomData.containsKey('lastActivityAt')) {
        final lastActivity = DateTime.parse(roomData['lastActivityAt'] as String);
        final difference = DateTime.now().difference(lastActivity);
        if (difference.inHours >= 24) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      Sentry.captureException(e, hint: {'action': 'check_room_expired'});
      return true; // Assume expired on error
    }
  }
} 