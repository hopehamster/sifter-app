import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:sifter/services/database_service.dart';
import 'package:sifter/services/message_service.dart';

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
      await _analytics.logError(
        error: 'create_room_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'update_room_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'delete_room_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'add_member_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'remove_member_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Get room details
  Future<DocumentSnapshot> getRoom(String roomId) async {
    try {
      return await _database.rooms.doc(roomId).get();
    } catch (e) {
      await _analytics.logError(
        error: 'get_room_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'update_last_message_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'mark_room_read_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'get_room_members_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Check if user is member of room
  Future<bool> isUserMember(String roomId, String userId) async {
    try {
      final members = await getRoomMembers(roomId);
      return members.contains(userId);
    } catch (e) {
      await _analytics.logError(
        error: 'check_membership_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'get_unread_count_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
} 