import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:sifter/services/database_service.dart';
import 'package:sifter/services/storage_service.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../models/user.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final DatabaseService _database = DatabaseService();
  final StorageService _storage = StorageService();
  final AnalyticsService _analytics = AnalyticsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _messagesCollection = 'messages';

  // Send text message
  Future<String> sendTextMessage({
    required String roomId,
    required String senderId,
    required String text,
    String? replyToMessageId,
  }) async {
    try {
      final messageData = {
        'roomId': roomId,
        'senderId': senderId,
        'text': text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'replyToMessageId': replyToMessageId,
      };

      final messageId = await _database.createMessage(messageData);
      await _analytics.logEvent('text_message_sent', parameters: {
        'room_id': roomId,
        'message_id': messageId,
      });

      return messageId;
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'send_text_message_error',
      );
      rethrow;
    }
  }

  // Send image message
  Future<String> sendImageMessage({
    required String roomId,
    required String senderId,
    required File imageFile,
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      final imageUrl = await _storage.uploadFile(imageFile, 'images/$roomId');
      final messageData = {
        'roomId': roomId,
        'senderId': senderId,
        'imageUrl': imageUrl,
        'caption': caption,
        'type': 'image',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'replyToMessageId': replyToMessageId,
      };

      final messageId = await _database.createMessage(messageData);
      await _analytics.logEvent('image_message_sent', parameters: {
        'room_id': roomId,
        'message_id': messageId,
      });

      return messageId;
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'send_image_message_error',
      );
      rethrow;
    }
  }

  // Send file message
  Future<String> sendFileMessage({
    required String roomId,
    required String senderId,
    required File file,
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      final fileUrl = await _storage.uploadFile(file, 'files/$roomId');
      final messageData = {
        'roomId': roomId,
        'senderId': senderId,
        'fileUrl': fileUrl,
        'fileName': file.path.split('/').last,
        'fileSize': file.lengthSync(),
        'fileType': file.path.split('.').last,
        'caption': caption,
        'type': 'file',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'replyToMessageId': replyToMessageId,
      };

      final messageId = await _database.createMessage(messageData);
      await _analytics.logEvent('file_message_sent', parameters: {
        'room_id': roomId,
        'message_id': messageId,
        'file_type': file.path.split('.').last,
      });

      return messageId;
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'send_file_message_error',
      );
      rethrow;
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _database.deleteMessage(messageId);
      await _analytics.logEvent('message_deleted', parameters: {
        'message_id': messageId,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'delete_message_error',
      );
      rethrow;
    }
  }

  // Edit message
  Future<void> editMessage(String messageId, String newText) async {
    try {
      await _database.updateMessage(messageId, {
        'text': newText,
        'edited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
      await _analytics.logEvent('message_edited', parameters: {
        'message_id': messageId,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'edit_message_error',
      );
      rethrow;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _database.updateMessage(messageId, {
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
      await _analytics.logEvent('message_read', parameters: {
        'message_id': messageId,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'mark_message_read_error',
      );
      rethrow;
    }
  }

  // Get messages for a room
  Stream<QuerySnapshot> getMessages(String roomId) {
    return _database.getMessages(roomId);
  }

  // Get initial messages with pagination
  Future<QuerySnapshot> getInitialMessages(String roomId, int limit) async {
    try {
      final query = _firestore.collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
          
      return await query.get();
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'get_initial_messages_error',
      );
      rethrow;
    }
  }
  
  // Get more messages for pagination
  Future<QuerySnapshot> getMoreMessages(String roomId, DocumentSnapshot lastDoc, int limit) async {
    try {
      final query = _firestore.collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastDoc)
          .limit(limit);
          
      return await query.get();
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'get_more_messages_error',
      );
      rethrow;
    }
  }

  // Search messages in a room
  Future<QuerySnapshot> searchMessages(String roomId, String query) async {
    try {
      return await _database.searchMessages(roomId, query);
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'search_messages_error',
      );
      rethrow;
    }
  }

  // Get message by ID
  Future<DocumentSnapshot> getMessage(String messageId) async {
    try {
      return await _database.messages.doc(messageId).get();
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'get_message_error',
      );
      rethrow;
    }
  }

  // Get message replies
  Future<List<Message>> getMessageReplies(String messageId) async {
    try {
      final snapshot = await _firestore.collection(_messagesCollection)
          .where('replyToMessageId', isEqualTo: messageId)
          .orderBy('timestamp', descending: false)
          .get();
      
      return snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'get_message_replies_error',
      );
      throw Exception('Failed to get message replies: $e');
    }
  }

  // Count message replies
  Future<int> getMessageReplyCount(String messageId) async {
    try {
      final snapshot = await _firestore.collection(_messagesCollection)
          .where('replyToMessageId', isEqualTo: messageId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'get_message_reply_count_error',
      );
      throw Exception('Failed to get message reply count: $e');
    }
  }

  // Send reply to a message
  Future<String> sendReply({
    required String roomId,
    required String senderId,
    required String text,
    required String parentMessageId,
  }) async {
    try {
      final messageData = {
        'roomId': roomId,
        'senderId': senderId,
        'text': text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'replyToMessageId': parentMessageId,
      };

      final messageId = await _database.createMessage(messageData);
      
      // Update the parent message with the latest reply info
      await _database.updateMessage(parentMessageId, {
        'lastReplyAt': FieldValue.serverTimestamp(),
        'replyCount': FieldValue.increment(1),
      });
      
      await _analytics.logEvent('reply_sent', parameters: {
        'room_id': roomId,
        'message_id': messageId,
        'parent_message_id': parentMessageId,
      });

      return messageId;
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'send_reply_error',
      );
      rethrow;
    }
  }

  // Pin message
  Future<void> pinMessage(String messageId) async {
    try {
      await _database.updateMessage(messageId, {
        'pinned': true,
        'pinnedAt': FieldValue.serverTimestamp(),
      });
      await _analytics.logEvent('message_pinned', parameters: {
        'message_id': messageId,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'pin_message_error',
      );
      rethrow;
    }
  }

  // Unpin message
  Future<void> unpinMessage(String messageId) async {
    try {
      await _database.updateMessage(messageId, {
        'pinned': false,
      });
      await _analytics.logEvent('message_unpinned', parameters: {
        'message_id': messageId,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'unpin_message_error',
      );
      rethrow;
    }
  }

  // Get pinned messages
  Stream<QuerySnapshot> getPinnedMessages(String roomId) {
    return _database.messages
        .where('roomId', isEqualTo: roomId)
        .where('pinned', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Add reaction to a message
  Future<void> addReaction(String messageId, String emoji, String userId) async {
    try {
      // First check if the reaction already exists
      final messageDoc = await _database.messages.doc(messageId).get();
      final messageData = messageDoc.data() as Map<String, dynamic>;
      
      Map<String, dynamic> reactions = messageData['reactions'] ?? {};
      
      if (!reactions.containsKey(emoji)) {
        reactions[emoji] = [];
      }
      
      List<String> users = List<String>.from(reactions[emoji] ?? []);
      if (!users.contains(userId)) {
        users.add(userId);
      }
      
      reactions[emoji] = users;
      
      await _database.updateMessage(messageId, {
        'reactions': reactions,
      });
      
      await _analytics.logEvent('message_reaction_added', parameters: {
        'message_id': messageId,
        'emoji': emoji,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'add_reaction_error',
      );
      rethrow;
    }
  }
  
  // Remove reaction from a message
  Future<void> removeReaction(String messageId, String emoji, String userId) async {
    try {
      final messageDoc = await _database.messages.doc(messageId).get();
      final messageData = messageDoc.data() as Map<String, dynamic>;
      
      Map<String, dynamic> reactions = Map<String, dynamic>.from(messageData['reactions'] ?? {});
      
      if (reactions.containsKey(emoji)) {
        List<String> users = List<String>.from(reactions[emoji] ?? []);
        users.remove(userId);
        
        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }
        
        await _database.updateMessage(messageId, {
          'reactions': reactions,
        });
      }
      
      await _analytics.logEvent('message_reaction_removed', parameters: {
        'message_id': messageId,
        'emoji': emoji,
      });
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'remove_reaction_error',
      );
      rethrow;
    }
  }
  
  // Get all reactions for a message
  Future<Map<String, List<String>>> getReactions(String messageId) async {
    try {
      final messageDoc = await _database.messages.doc(messageId).get();
      
      if (!messageDoc.exists) {
        return {};
      }
      
      final messageData = messageDoc.data() as Map<String, dynamic>;
      final reactionsData = messageData['reactions'] as Map<String, dynamic>? ?? {};
      
      // Convert to Map<String, List<String>>
      Map<String, List<String>> reactions = {};
      
      reactionsData.forEach((emoji, users) {
        reactions[emoji] = List<String>.from(users);
      });
      
      return reactions;
    } catch (e, stackTrace) {
      await _analytics.logError(
        e,
        stackTrace,
        reason: 'get_reactions_error',
      );
      rethrow;
    }
  }

  // Use this for creating messages directly with the Message model
  Future<Message> createMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    required MessageType type,
    required int timestamp,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = Message(
        id: _firestore.collection(_messagesCollection).doc().id,
        chatRoomId: chatRoomId,
        senderId: senderId,
        content: content,
        type: type,
        timestamp: timestamp,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );

      await _firestore.collection(_messagesCollection).doc(message.id).set(message.toJson());
      return message;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> updateMessage(Message message) async {
    try {
      await _firestore.collection(_messagesCollection).doc(message.id).update(message.toJson());
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  Future<void> markAsRead(String messageId, String userId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'readBy.$userId': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  Future<void> markAsDelivered(String messageId, String userId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'deliveredTo.$userId': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as delivered: $e');
    }
  }

  Future<void> forwardMessage(String messageId, String targetRoomId) async {
    try {
      final messageDoc = await getMessage(messageId);
      final messageData = messageDoc.data() as Map<String, dynamic>;
      
      final forwardedMessage = Message(
        id: _firestore.collection(_messagesCollection).doc().id,
        chatRoomId: targetRoomId,
        senderId: messageData['senderId'],
        content: messageData['content'],
        type: MessageType.values[messageData['type']],
        timestamp: DateTime.now().millisecondsSinceEpoch,
        metadata: {
          ...?messageData['metadata'],
          'forwardedFrom': messageId,
          'forwardedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await _firestore
          .collection(_messagesCollection)
          .doc(forwardedMessage.id)
          .set(forwardedMessage.toJson());
    } catch (e) {
      throw Exception('Failed to forward message: $e');
    }
  }

  Future<void> deleteAllMessages(String roomId) async {
    try {
      final messages = await _firestore
          .collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all messages: $e');
    }
  }
} 