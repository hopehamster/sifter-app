import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:sifter/services/database_service.dart';
import 'package:sifter/services/message_service.dart';
import 'package:sifter/models/chat_room.dart';
import 'dart:math' as math;

class RoomService {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  final DatabaseService _database = DatabaseService();
  final MessageService _messageService = MessageService();
  final AnalyticsService _analytics = AnalyticsService();

  // Create a new room
  Future<String> createRoom({
    required String name,
    required String creatorId,
    String? description,
    bool isPrivate = false,
    List<String>? members,
  }) async {
    try {
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
      };

      final roomId = await _database.createRoom(roomData);
      await _analytics.logEvent('room_created', parameters: {
        'room_id': roomId,
        'is_private': isPrivate,
        'member_count': (members?.length ?? 1) + 1,
      });

      return roomId;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'create_room_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Update room details
  Future<void> updateRoom({
    required String roomId,
    String? name,
    String? description,
    bool? isPrivate,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (isPrivate != null) updates['isPrivate'] = isPrivate;

      await _database.updateRoom(roomId, updates);
      await _analytics.logEvent('room_updated', parameters: {
        'room_id': roomId,
        'updates': updates,
      });
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'update_room_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _database.deleteRoom(roomId);
      await _analytics.logEvent('room_deleted', parameters: {
        'room_id': roomId,
      });
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'delete_room_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Add member to room
  Future<void> addMember(String roomId, String userId) async {
    try {
      await _database.updateRoom(roomId, {
        'members': FieldValue.arrayUnion([userId]),
        'unreadCount.$userId': 0,
      });
      await _analytics.logEvent('member_added', parameters: {
        'room_id': roomId,
        'user_id': userId,
      });
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'add_member_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Remove member from room
  Future<void> removeMember(String roomId, String userId) async {
    try {
      await _database.updateRoom(roomId, {
        'members': FieldValue.arrayRemove([userId]),
        'unreadCount.$userId': FieldValue.delete(),
      });
      await _analytics.logEvent('member_removed', parameters: {
        'room_id': roomId,
        'user_id': userId,
      });
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'remove_member_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Get room details
  Future<DocumentSnapshot> getRoom(String roomId) async {
    try {
      return await _database.rooms.doc(roomId).get();
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_room_error',
        'error_message': e.toString(),
      });
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

  // Update last message
  Future<void> updateLastMessage(String roomId, String messageId) async {
    try {
      final message = await _messageService.getMessage(messageId);
      final data = message.data() as Map<String, dynamic>;

      await _database.updateRoom(roomId, {
        'lastMessage': data['text'] ?? 'Media message',
        'lastMessageSender': data['senderId'],
        'lastMessageTime': data['timestamp'],
      });

      // Update unread count for all members except sender
      final room = await getRoom(roomId);
      final roomData = room.data() as Map<String, dynamic>;
      final members = List<String>.from(roomData['members'] ?? []);
      final senderId = data['senderId'];

      for (final memberId in members) {
        if (memberId != senderId) {
          await _database.updateRoom(roomId, {
            'unreadCount.$memberId': FieldValue.increment(1),
          });
        }
      }
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'update_last_message_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Mark room as read
  Future<void> markRoomAsRead(String roomId, String userId) async {
    try {
      await _database.updateRoom(roomId, {
        'unreadCount.$userId': 0,
      });
      await _analytics.logEvent('room_marked_read', parameters: {
        'room_id': roomId,
        'user_id': userId,
      });
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'mark_room_read_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Get room members
  Future<List<String>> getRoomMembers(String roomId) async {
    try {
      final room = await getRoom(roomId);
      final data = room.data() as Map<String, dynamic>;
      return List<String>.from(data['members'] ?? []);
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_room_members_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Check if user is member of room
  Future<bool> isUserMember(String roomId, String userId) async {
    try {
      final members = await getRoomMembers(roomId);
      return members.contains(userId);
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'check_membership_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Get room unread count
  Future<int> getUnreadCount(String roomId, String userId) async {
    try {
      final room = await getRoom(roomId);
      final data = room.data() as Map<String, dynamic>;
      final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
      return unreadCount?[userId] ?? 0;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_unread_count_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Get a specific room by ID
  Future<ChatRoom?> getRoomById(String roomId) async {
    try {
      final doc = await _database.rooms.doc(roomId).get();
      
      if (doc.exists) {
        return ChatRoom.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_room_error',
        'error_message': e.toString(),
      });
      return null;
    }
  }

  // Create a new room from ChatRoom object
  Future<ChatRoom> createRoomObject(ChatRoom room) async {
    try {
      final docRef = _database.rooms.doc();
      final roomWithId = room.copyWith(id: docRef.id);
      
      await docRef.set(roomWithId.toJson());
      
      // Log room creation
      await _analytics.logEvent('room_created', parameters: {
        'room_id': roomWithId.id,
        'room_name': roomWithId.name,
        'created_by': roomWithId.createdBy,
      });
      
      return roomWithId;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'create_room_error',
        'error_message': e.toString(),
      });
      rethrow;
    }
  }

  // Update an existing room with ChatRoom object
  Future<void> updateRoomObject(ChatRoom room) async {
    try {
      await _database.updateRoom(room.id, room.toJson());
      
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
      rethrow;
    }
  }

  // Get a list of rooms for a user with ChatRoom objects
  Future<List<ChatRoom>> getUserRoomsList(String userId) async {
    try {
      final snapshot = await _database.rooms
          .where('members', arrayContains: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => ChatRoom.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_user_rooms_error',
        'error_message': e.toString(),
      });
      return [];
    }
  }

  // Get nearby rooms based on location
  Future<List<ChatRoom>> getNearbyRooms(double latitude, double longitude, double radiusKm) async {
    try {
      // This is a simplified implementation. In a real app, you would use
      // geohashing or a specialized database for geo queries
      final snapshot = await _database.rooms
          .where('isPrivate', isEqualTo: false)
          .get();
          
      final allRooms = snapshot.docs
          .map((doc) => ChatRoom.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Filter rooms by distance
      return allRooms.where((room) {
        // Ensure room has location metadata
        if (room.metadata['location'] == null ||
            room.metadata['radius'] == null) {
          return false;
        }
        
        // Calculate distance
        final roomLat = room.metadata['location']['latitude'] as double;
        final roomLng = room.metadata['location']['longitude'] as double;
        final roomRadius = room.metadata['radius'] as double;
        
        // Calculate distance using the Haversine formula
        final distance = _calculateDistance(
          latitude, longitude, roomLat, roomLng);
          
        // Room is within range if distance is less than radius
        return distance <= roomRadius;
      }).toList();
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'get_nearby_rooms_error',
        'error_message': e.toString(),
      });
      return [];
    }
  }
  
  // Join a room
  Future<bool> joinRoom(String roomId, String userId, {String? password}) async {
    try {
      final roomDoc = await _database.rooms.doc(roomId).get();
      
      if (!roomDoc.exists) {
        return false;
      }
      
      final room = ChatRoom.fromJson(roomDoc.data() as Map<String, dynamic>);
      
      // Check if password is required
      if (room.isPasswordProtected && room.password != password) {
        return false;
      }
      
      // Add user to members
      await _database.updateRoom(roomId, {
        'members': FieldValue.arrayUnion([userId]),
      });
      
      // Log join event
      await _analytics.logEvent('room_joined', parameters: {
        'room_id': roomId,
        'user_id': userId,
      });
      
      return true;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'join_room_error',
        'error_message': e.toString(),
      });
      return false;
    }
  }
  
  // Leave a room
  Future<bool> leaveRoom(String roomId, String userId) async {
    try {
      await _database.updateRoom(roomId, {
        'members': FieldValue.arrayRemove([userId]),
      });
      
      // Log leave event
      await _analytics.logEvent('room_left', parameters: {
        'room_id': roomId,
        'user_id': userId,
      });
      
      return true;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'error_type': 'leave_room_error',
        'error_message': e.toString(),
      });
      return false;
    }
  }
  
  // Calculate distance between two coordinates using the Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) * math.sin(dLon / 2) * 
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2));
      
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }
  
  // Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
} 