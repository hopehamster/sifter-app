import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'dart:math' as Math;

part 'chat_service.g.dart';

@riverpod
ChatService chatService(ChatServiceRef ref) {
  return ChatService(ref);
}

class ChatService {
  final Ref _ref;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final StorageService _storage;
  final NotificationService _notifications;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _roomsCollection = 'chat_rooms';
  final String _messagesCollection = 'messages';
  
  // User service for checking blocked users
  late final UserService _userService;

  ChatService(this._ref)
      : _storage = _ref.read(storageServiceProvider),
        _notifications = _ref.read(notificationServiceProvider) {
    _userService = UserService();
  }

  // Get messages with filter for blocked users
  Stream<List<Message>> streamMessagesFiltered(String chatRoomId, String currentUserId) {
    return _db
        .child('messages/$chatRoomId')
        .orderByChild('timestamp')
        .onValue
        .asyncMap((event) async {
          final List<Message> messages = [];
          
          if (event.snapshot.value != null) {
            final Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;
                
            // Get list of users blocked by current user
            final blockedUsers = await _userService.getBlockedUsers(currentUserId);
                
            data.forEach((key, value) {
              final message = Message.fromJson(Map<String, dynamic>.from(value));
              
              // Only add message if sender is not blocked
              if (!blockedUsers.contains(message.senderId)) {
                messages.add(message);
              }
            });
          }
          
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  // Get messages without filtering
  Stream<List<Message>> streamMessages(String chatRoomId) {
    return _db
        .child('messages/$chatRoomId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final List<Message> messages = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          messages.add(Message.fromJson(Map<String, dynamic>.from(value)));
        });
      }
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }
  
  // Get chat rooms filtered by blocked users
  Stream<List<ChatRoom>> streamChatRoomsFiltered(String userId) {
    return _db
        .child('chat_rooms')
        .orderByChild('lastMessageTimestamp')
        .onValue
        .asyncMap((event) async {
          final List<ChatRoom> chatRooms = [];
          
          if (event.snapshot.value != null) {
            final Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;
                
            // Get list of users blocked by current user
            final blockedUsers = await _userService.getBlockedUsers(userId);
                
            data.forEach((key, value) {
              final room = ChatRoom.fromJson(Map<String, dynamic>.from(value));
              
              // Only add room if it's not a direct chat with a blocked user
              if (room.type == ChatRoomType.group || 
                  !room.participants.any((participant) => blockedUsers.contains(participant))) {
                chatRooms.add(room);
              }
            });
          }
          
          // Sort by lastMessageTimestamp if available
          chatRooms.sort((a, b) {
            if (a.lastMessageTimestamp == null && b.lastMessageTimestamp == null) {
              return 0;
            } else if (a.lastMessageTimestamp == null) {
              return 1;
            } else if (b.lastMessageTimestamp == null) {
              return -1;
            }
            return b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!);
          });
          return chatRooms;
        });
  }

  // Check if a message should be visible to the user (not from blocked user)
  Future<bool> isMessageVisible(Message message, String currentUserId) async {
    final blockedUsers = await _userService.getBlockedUsers(currentUserId);
    return !blockedUsers.contains(message.senderId);
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = Message(
        id: _db.child('messages').push().key!,
        chatRoomId: chatRoomId,
        senderId: senderId,
        content: content,
        type: type,
        metadata: metadata,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        status: MessageStatus.sending,
      );

      await _db.child('messages/$chatRoomId/${message.id}').set(message.toJson());
      await _updateChatRoom(chatRoomId, message);
      await _notifyRecipients(chatRoomId, message);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> sendMediaMessage({
    required String chatRoomId,
    required String senderId,
    required String filePath,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}-${path.basename(filePath)}';
      final storagePath = 'chat_media/$chatRoomId/$fileName';

      final downloadUrl = await _storage.uploadFile(
        file,
        storagePath,
        metadata: {
          'chatRoomId': chatRoomId,
          'senderId': senderId,
          'type': type.toString(),
        },
      );

      await sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        content: downloadUrl,
        type: type,
        metadata: metadata,
      );
    } catch (e) {
      throw Exception('Failed to send media message: $e');
    }
  }

  Future<void> updateMessageStatus({
    required String chatRoomId,
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      await _db
          .child('messages/$chatRoomId/$messageId/status')
          .set(status.index);
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  Future<void> deleteMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      final message = await _db
          .child('messages/$chatRoomId/$messageId')
          .get()
          .then((snapshot) => Message.fromJson(
              Map<String, dynamic>.from(snapshot.value as Map)));

      if (message.type != MessageType.text) {
        await _storage.deleteFile(message.content);
      }

      await _db.child('messages/$chatRoomId/$messageId').remove();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> editMessage({
    required String chatRoomId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      await _db.child('messages/$chatRoomId/$messageId').update({
        'content': newContent,
        'edited': true,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // First markAsRead implementation for Firebase Realtime DB
  Future<void> markAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await _db.child('chat_rooms/$chatRoomId/readBy/$userId').set(
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Future<void> _updateChatRoom(String chatRoomId, Message message) async {
    try {
      await _db.child('chat_rooms/$chatRoomId').update({
        'lastMessage': message.content,
        'lastMessageType': message.type.toString(),
        'lastMessageTimestamp': message.timestamp,
        'lastMessageSenderId': message.senderId,
      });
    } catch (e) {
      throw Exception('Failed to update chat room: $e');
    }
  }

  Future<void> _notifyRecipients(String chatRoomId, Message message) async {
    try {
      final chatRoom = await _db
          .child('chat_rooms/$chatRoomId')
          .get()
          .then((snapshot) => ChatRoom.fromJson(
              Map<String, dynamic>.from(snapshot.value as Map)));

      for (final userId in chatRoom.participants) {
        if (userId != message.senderId) {
          await _notifications.showLocalNotification(
            title: chatRoom.name.isNotEmpty ? chatRoom.name : 'New Message',
            body: message.type == MessageType.text
                ? message.content
                : '${message.type.toString().split('.').last} message',
            payload: jsonEncode({
              'chatRoomId': chatRoomId,
              'messageId': message.id,
            }),
          );
        }
      }
    } catch (e) {
      print('Failed to notify recipients: $e');
    }
  }

  // First createChatRoom implementation for Firebase Realtime DB
  Future<void> createRealtimeDBChatRoom({
    required String name,
    required List<String> participants,
    String? description,
    String? photoUrl,
  }) async {
    try {
      final chatRoomId = _db.child('chat_rooms').push().key!;
      final chatRoom = ChatRoom(
        id: chatRoomId,
        name: name,
        type: ChatRoomType.group,  // Set an appropriate type
        memberIds: participants,  // Renamed from participants to memberIds
        createdBy: participants.isNotEmpty ? participants[0] : '',
        participants: participants,  // Keep the original participants field
        description: description,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await _db.child('chat_rooms/$chatRoomId').set(chatRoom.toJson());

      for (final userId in participants) {
        await _db.child('user_chats/$userId/$chatRoomId').set({
          'lastRead': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<void> leaveChatRoom({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await _db.child('chat_rooms/$chatRoomId/participants/$userId').remove();
      await _db.child('user_chats/$userId/$chatRoomId').remove();
    } catch (e) {
      throw Exception('Failed to leave chat room: $e');
    }
  }

  Stream<List<ChatRoom>> streamUserChats(String userId) {
    return _db
        .child('user_chats/$userId')
        .onValue
        .asyncMap((event) async {
      final List<ChatRoom> chatRooms = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        for (final chatRoomId in data.keys) {
          final chatRoom = await _db
              .child('chat_rooms/$chatRoomId')
              .get()
              .then((snapshot) => ChatRoom.fromJson(
                  Map<String, dynamic>.from(snapshot.value as Map)));
          chatRooms.add(chatRoom);
        }
      }
      // Sort appropriately based on available fields
      chatRooms.sort((a, b) {
        if (a.lastMessageTimestamp == null && b.lastMessageTimestamp == null) {
          return 0;
        } else if (a.lastMessageTimestamp == null) {
          return 1;
        } else if (b.lastMessageTimestamp == null) {
          return -1;
        }
        return b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!);
      });
      return chatRooms;
    });
  }

  // Second createChatRoom implementation for Firestore
  Future<ChatRoom> createChatRoom({
    required String name,
    required List<String> memberIds,
    required ChatRoomType type,
    String? description,
    String? photoUrl,
    String? createdBy,
    bool? isGroup,
  }) async {
    try {
      final room = ChatRoom(
        id: _firestore.collection(_roomsCollection).doc().id,
        name: name,
        memberIds: memberIds,
        type: type,
        createdBy: createdBy ?? (memberIds.isNotEmpty ? memberIds[0] : ''),
        description: description,
        photoUrl: photoUrl,
        isGroup: isGroup,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(_roomsCollection).doc(room.id).set(room.toJson());
      return room;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<void> updateChatRoom(ChatRoom room) async {
    try {
      await _firestore.collection(_roomsCollection).doc(room.id).update(room.toJson());
    } catch (e) {
      throw Exception('Failed to update chat room: $e');
    }
  }

  Future<void> deleteChatRoom(String roomId) async {
    try {
      // Delete all messages in the room
      final messages = await _firestore
          .collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete the room
      batch.delete(_firestore.collection(_roomsCollection).doc(roomId));
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat room: $e');
    }
  }

  Future<ChatRoom> getChatRoom(String roomId) async {
    try {
      final doc = await _firestore.collection(_roomsCollection).doc(roomId).get();
      if (!doc.exists) {
        throw Exception('Chat room not found');
      }
      return ChatRoom.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get chat room: $e');
    }
  }

  Stream<ChatRoom> streamChatRoom(String roomId) {
    return _firestore
        .collection(_roomsCollection)
        .doc(roomId)
        .snapshots()
        .map((doc) => ChatRoom.fromJson(doc.data()!));
  }

  Stream<List<ChatRoom>> streamUserChatRooms(String userId) {
    return _firestore
        .collection(_roomsCollection)
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromJson(doc.data()))
            .toList());
  }

  Future<void> addMember(String roomId, String userId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  Future<void> removeMember(String roomId, String userId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  Future<void> updateLastMessage(String roomId, Message message) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'lastMessage': message.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last message: $e');
    }
  }

  // Second markAsRead implementation for Firestore
  Future<void> markFirestoreAsRead(String roomId, String userId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'readBy.$userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  Future<void> pinChatRoom(String roomId, bool isPinned) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'isPinned': isPinned,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to pin chat room: $e');
    }
  }

  Future<void> muteChatRoom(String roomId, String userId, bool isMuted) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'mutedBy.$userId': isMuted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mute chat room: $e');
    }
  }

  Future<void> archiveChatRoom(String roomId, String userId, bool isArchived) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'archivedBy.$userId': isArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to archive chat room: $e');
    }
  }

  Future<List<ChatRoom>> searchChatRooms(String userId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(_roomsCollection)
          .where('memberIds', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => ChatRoom.fromJson(doc.data()))
          .where((room) =>
              room.name.toLowerCase().contains(query.toLowerCase()) ||
              (room.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    } catch (e) {
      throw Exception('Failed to search chat rooms: $e');
    }
  }

  Future<List<ChatRoom>> getPublicGroups() async {
    try {
      final snapshot = await _firestore
          .collection(_roomsCollection)
          .where('type', isEqualTo: ChatRoomType.group.toString())
          .where('isPrivate', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => ChatRoom.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get public groups: $e');
    }
  }

  // Track typing status of users
  Future<void> setTyping(String chatRoomId, String userId, bool isTyping) async {
    try {
      if (isTyping) {
        await _db.child('typing/$chatRoomId/$userId').set(
          DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        await _db.child('typing/$chatRoomId/$userId').remove();
      }
    } catch (e) {
      throw Exception('Failed to update typing status: $e');
    }
  }

  // Stream of typing users in a chat room
  Stream<Set<String>> streamTypingUsers(String chatRoomId) {
    return _db.child('typing/$chatRoomId').onValue.map((event) {
      final Set<String> typingUsers = {};
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        
        // Add all users who have typed in the last 5 seconds
        final now = DateTime.now().millisecondsSinceEpoch;
        data.forEach((userId, timestamp) {
          if (now - (timestamp as int) < 5000) {
            typingUsers.add(userId as String);
          }
        });
      }
      return typingUsers;
    });
  }

  // Get all chat rooms near a specific location
  Future<List<ChatRoom>> getNearbyRooms(double latitude, double longitude, double radiusKm) async {
    try {
      // Get all rooms from Firebase
      final snapshot = await _db.child('rooms').get();
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<ChatRoom> rooms = [];
        
        // Process each room
        data.forEach((key, value) {
          final Map<String, dynamic> roomData = Map<String, dynamic>.from(value);
          final room = ChatRoom(
            id: key,
            name: roomData['name'] ?? '',
            description: roomData['description'] ?? '',
            creatorId: roomData['creatorId'] ?? '',
            createdAt: DateTime.parse(roomData['createdAt'] ?? DateTime.now().toIso8601String()),
            latitude: roomData['latitude'] ?? 0.0,
            longitude: roomData['longitude'] ?? 0.0,
            radius: roomData['radius'] ?? 5.0, // Default 5km radius
            participants: roomData['participants'] ?? 0,
            isActive: roomData['isActive'] ?? true,
            type: roomData['password'] != null ? ChatRoomType.private : ChatRoomType.public,
          );
          
          // Only include active rooms
          if (room.isActive) {
            // Calculate distance between room center and user location
            final distance = _calculateDistance(
              latitude, longitude, room.latitude, room.longitude);
            
            // Check if user is within search radius of the room
            if (distance <= radiusKm) {
              rooms.add(room);
            }
          }
        });
        
        // Sort by distance (closest first)
        rooms.sort((a, b) {
          final distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
          final distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
        
        return rooms;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get nearby rooms: $e');
    }
  }
  
  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(lat1)) * Math.cos(_toRadians(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
        
    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * (Math.pi / 180);
  }

  // Check and clean up expired or inactive chat rooms
  Future<void> cleanupExpiredRooms() async {
    try {
      final snapshot = await _db.child('rooms').get();
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<String> roomsToRemove = [];
        
        final now = DateTime.now();
        
        data.forEach((key, value) {
          final Map<String, dynamic> roomData = Map<String, dynamic>.from(value);
          
          // Check expiration date if it exists
          if (roomData.containsKey('expiresAt')) {
            final expiresAt = DateTime.parse(roomData['expiresAt']);
            if (now.isAfter(expiresAt)) {
              roomsToRemove.add(key);
            }
          }
          
          // Also check last activity time if it exists
          if (roomData.containsKey('lastActivity')) {
            final lastActivity = DateTime.parse(roomData['lastActivity']);
            // If no activity for 24 hours, mark for removal
            if (now.difference(lastActivity).inHours > 24) {
              roomsToRemove.add(key);
            }
          }
          
          // Check participant count - remove if empty for more than 1 hour
          if (roomData.containsKey('participants') && 
              roomData['participants'] == 0 &&
              roomData.containsKey('emptyTime')) {
            final emptyTime = DateTime.parse(roomData['emptyTime']);
            if (now.difference(emptyTime).inHours > 1) {
              roomsToRemove.add(key);
            }
          }
        });
        
        // Remove expired rooms
        for (final roomId in roomsToRemove) {
          await _db.child('rooms/$roomId').update({
            'isActive': false,
            'removedAt': now.toIso8601String(),
          });
          
          // Keep the chat history but mark it as inactive
          print('Marked room $roomId as inactive due to expiration or inactivity');
        }
      }
    } catch (e) {
      print('Error cleaning up expired rooms: $e');
    }
  }
  
  // Update the last activity time for a chat room
  Future<void> updateRoomActivity(String roomId) async {
    try {
      await _db.child('rooms/$roomId').update({
        'lastActivity': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating room activity: $e');
    }
  }
  
  // Update participant count when someone joins or leaves
  Future<void> updateParticipantCount(String roomId, int delta) async {
    try {
      // Get current count
      final snapshot = await _db.child('rooms/$roomId/participants').get();
      int currentCount = 0;
      
      if (snapshot.exists) {
        currentCount = snapshot.value as int;
      }
      
      // Calculate new count and ensure it's not negative
      int newCount = (currentCount + delta) < 0 ? 0 : currentCount + delta;
      
      // Update the count
      await _db.child('rooms/$roomId').update({
        'participants': newCount,
      });
      
      // If room becomes empty, set the empty time
      if (newCount == 0) {
        await _db.child('rooms/$roomId').update({
          'emptyTime': DateTime.now().toIso8601String(),
        });
      } else if (currentCount == 0 && newCount > 0) {
        // If room was empty and now has participants, remove the empty time
        await _db.child('rooms/$roomId').update({
          'emptyTime': null,
        });
      }
    } catch (e) {
      print('Error updating participant count: $e');
    }
  }

  // Get details for a single chat room
  Future<ChatRoom?> getRoomDetails(String roomId) async {
    try {
      final snapshot = await _db.child('rooms/$roomId').get();
      
      if (snapshot.exists) {
        final Map<String, dynamic> roomData = Map<String, dynamic>.from(
          snapshot.value as Map);
          
        return ChatRoom(
          id: roomId,
          name: roomData['name'] ?? '',
          description: roomData['description'] ?? '',
          creatorId: roomData['creatorId'] ?? '',
          createdAt: DateTime.parse(roomData['createdAt'] ?? DateTime.now().toIso8601String()),
          latitude: roomData['latitude'] ?? 0.0,
          longitude: roomData['longitude'] ?? 0.0,
          radius: roomData['radius'] ?? 0.2, // Default to 200m radius
          participants: roomData['participants'] ?? 0,
          isActive: roomData['isActive'] ?? true,
          type: roomData['password'] != null ? ChatRoomType.private : ChatRoomType.public,
          allowAnonymous: roomData['allowAnonymous'] ?? false,
          isNsfw: roomData['isNsfw'] ?? false,
          expiresAt: roomData['expiresAt'] != null ? DateTime.parse(roomData['expiresAt']) : null,
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting room details: $e');
      return null;
    }
  }
  
  // Update chat room settings
  Future<void> updateChatRoomSettings(String roomId, Map<String, dynamic> settings) async {
    try {
      await _db.child('rooms/$roomId').update(settings);
      
      // Update last activity timestamp
      await _db.child('rooms/$roomId').update({
        'lastActivity': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update chat room settings: $e');
    }
  }
  
  // Deactivate a chat room (soft delete)
  Future<void> deactivateChatRoom(String roomId) async {
    try {
      await _db.child('rooms/$roomId').update({
        'isActive': false,
        'deactivatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to deactivate chat room: $e');
    }
  }
  
  // Report inappropriate content in a chat room
  Future<void> reportChatRoom(String roomId, String reporterId, String reason) async {
    try {
      final reportId = _db.child('reports').push().key!;
      
      await _db.child('reports/$reportId').set({
        'roomId': roomId,
        'reporterId': reporterId,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report chat room: $e');
    }
  }
  
  // Report an inappropriate message
  Future<void> reportMessage(String roomId, String messageId, String reporterId, String reason) async {
    try {
      final reportId = _db.child('reports').push().key!;
      
      await _db.child('reports/$reportId').set({
        'roomId': roomId,
        'messageId': messageId,
        'reporterId': reporterId,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
      
      // Mark the message as reported
      await _db.child('messages/$roomId/$messageId').update({
        'reported': true,
        'reportCount': ServerValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }
  
  // Block a user from a chat room (for moderators only)
  Future<void> blockUserFromRoom(String roomId, String userId, String blockedBy) async {
    try {
      await _db.child('rooms/$roomId/blockedUsers/$userId').set({
        'blockedBy': blockedBy,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to block user from room: $e');
    }
  }
  
  // Check if a user is blocked from a chat room
  Future<bool> isUserBlockedFromRoom(String roomId, String userId) async {
    try {
      final snapshot = await _db.child('rooms/$roomId/blockedUsers/$userId').get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }
  
  // Reset chat room expiration time (extends the life of the chat room)
  Future<void> resetRoomExpiration(String roomId) async {
    try {
      // Set expiration to 24 hours from now
      final newExpiresAt = DateTime.now().add(Duration(hours: 24)).toIso8601String();
      
      await _db.child('rooms/$roomId').update({
        'expiresAt': newExpiresAt,
        'lastActivity': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to reset room expiration: $e');
    }
  }
  
  // Get the list of active participants in a chat room
  Future<List<String>> getActiveParticipants(String roomId) async {
    try {
      // Get users who sent a message in the last 10 minutes
      final tenMinutesAgo = DateTime.now().subtract(Duration(minutes: 10)).millisecondsSinceEpoch;
      
      final snapshot = await _db
          .child('messages/$roomId')
          .orderByChild('timestamp')
          .startAt(tenMinutesAgo)
          .get();
      
      final Set<String> activeUsers = {};
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          final Map<String, dynamic> messageData = Map<String, dynamic>.from(value);
          activeUsers.add(messageData['senderId'] as String);
        });
      }
      
      return activeUsers.toList();
    } catch (e) {
      print('Error getting active participants: $e');
      return [];
    }
  }
} 