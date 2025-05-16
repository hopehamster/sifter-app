import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:convert';

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
} 