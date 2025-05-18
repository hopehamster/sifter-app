import 'dart:io';
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sifter/models/message.dart';
import 'package:sifter/services/message_service.dart';
import 'package:sifter/services/storage_service.dart';
import 'package:sifter/utils/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'message_provider.g.dart';

@riverpod
class RoomMessagesNotifier extends _$RoomMessagesNotifier {
  late final MessageService _messageService;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  
  @override
  FutureOr<List<Message>> build(String roomId) {
    _messageService = ref.watch(messageServiceProvider);
    
    // Set up listener for room messages
    _setupMessagesListener(roomId);
    
    ref.onDispose(() {
      _messagesSubscription?.cancel();
    });
    
    return _fetchMessages(roomId);
  }
  
  void _setupMessagesListener(String roomId) {
    _messagesSubscription?.cancel();
    
    _messagesSubscription = _messageService.getMessages(roomId).listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
      
      _onMessageUpdate(messages);
    });
  }
  
  void _onMessageUpdate(List<Message> messages) {
    state = AsyncValue.data(messages);
  }
  
  Future<List<Message>> _fetchMessages(String roomId) async {
    try {
      final snapshot = await _messageService.getInitialMessages(roomId, 20);
      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }
  
  // Send a text message
  Future<Message> sendTextMessage(String roomId, String content, String senderId) async {
    try {
      final messageId = await _messageService.sendTextMessage(
        roomId: roomId, 
        senderId: senderId, 
        text: content
      );
      
      // Get the message document
      final snapshot = await _messageService.getMessage(messageId);
      return Message.fromFirestore(snapshot);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }
  
  // Send an image message
  Future<Message> sendImageMessage(String roomId, File imageFile, String senderId) async {
    try {
      final messageId = await _messageService.sendImageMessage(
        roomId: roomId,
        senderId: senderId,
        imageFile: imageFile
      );
      
      // Get the message document
      final snapshot = await _messageService.getMessage(messageId);
      return Message.fromFirestore(snapshot);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to send image message: ${e.toString()}');
    }
  }
  
  // Send a file message
  Future<Message> sendFileMessage(String roomId, File file, String fileName, String senderId) async {
    try {
      final messageId = await _messageService.sendFileMessage(
        roomId: roomId,
        senderId: senderId,
        file: file
      );
      
      // Get the message document
      final snapshot = await _messageService.getMessage(messageId);
      return Message.fromFirestore(snapshot);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to send file message: ${e.toString()}');
    }
  }
  
  // Edit a message
  Future<void> editMessage(Message message, String newContent) async {
    try {
      await _messageService.editMessage(message.id, newContent);
      
      // The state will be updated via _onMessageUpdate listener
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to edit message: ${e.toString()}');
    }
  }
  
  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      
      // The state will be updated via _onMessageUpdate listener
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }
  
  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _messageService.markMessageAsRead(messageId);
      
      // Update state optimistically
      state = AsyncValue.data(
        state.value?.map((msg) => 
          msg.id == messageId 
            ? msg.copyWith(status: MessageStatus.read) 
            : msg
        ).toList() ?? []
      );
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }
  
  // Pin a message
  Future<void> pinMessage(String messageId, bool isPinned) async {
    try {
      if (isPinned) {
        await _messageService.pinMessage(messageId);
      } else {
        await _messageService.unpinMessage(messageId);
      }
      
      // The state will be updated via _onMessageUpdate listener
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to pin message: ${e.toString()}');
    }
  }

  // Add a reaction to a message
  Future<void> addReaction(String messageId, String emoji, String userId) async {
    try {
      await _messageService.addReaction(messageId, emoji, userId);
      
      // The state will be updated via _onMessageUpdate listener
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to add reaction: ${e.toString()}');
    }
  }
  
  // Remove a reaction from a message
  Future<void> removeReaction(String messageId, String emoji, String userId) async {
    try {
      await _messageService.removeReaction(messageId, emoji, userId);
      
      // The state will be updated via _onMessageUpdate listener
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to remove reaction: ${e.toString()}');
    }
  }
}

// Provider for Message Service
@riverpod
MessageService messageService(MessageServiceRef ref) {
  return MessageService();
}

// Provider for Storage Service
@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService();
}

// Cache provider for messages
@riverpod
class MessageCache extends _$MessageCache {
  final Map<String, List<Message>> _cache = {};
  
  @override
  Map<String, List<Message>> build() {
    return _cache;
  }

  void cacheMessages(String roomId, List<Message> messages) {
    state = {...state, roomId: messages};
  }

  List<Message>? getCachedMessages(String roomId) {
    return state[roomId];
  }

  void clearCache() {
    state = {};
  }
} 