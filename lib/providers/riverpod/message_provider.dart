import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sifter/models/app_state.dart';
import 'package:sifter/models/message.dart';
import 'package:sifter/services/message_service.dart';
import 'package:sifter/services/storage_service.dart';
import 'package:sifter/utils/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'message_provider.g.dart';

@riverpod
class RoomMessagesNotifier extends _$RoomMessagesNotifier {
  late final MessageService _messageService;
  late final StorageService _storageService;
  
  @override
  FutureOr<List<Message>> build(String roomId) {
    _messageService = ref.watch(messageServiceProvider);
    _storageService = ref.watch(storageServiceProvider);
    
    // Listen to messages for this room
    _messageService.listenToRoomMessages(roomId, _onMessageUpdate);
    
    ref.onDispose(() {
      _messageService.stopListeningToRoomMessages(roomId);
    });
    
    return _fetchMessages(roomId);
  }
  
  void _onMessageUpdate(List<Message> messages) {
    state = AsyncValue.data(messages);
  }
  
  Future<List<Message>> _fetchMessages(String roomId) async {
    try {
      return await _messageService.getMessages(roomId);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }
  
  // Send a text message
  Future<Message> sendTextMessage(String roomId, String content, String senderId) async {
    try {
      final message = Message(
        id: '',
        roomId: roomId,
        senderId: senderId,
        content: content,
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sending,
      );
      
      final savedMessage = await _messageService.sendMessage(message);
      return savedMessage;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }
  
  // Send an image message
  Future<Message> sendImageMessage(String roomId, File imageFile, String senderId) async {
    try {
      // First upload the image
      final imageUrl = await _storageService.uploadImage(imageFile, 'chat_images/$roomId');
      
      final message = Message(
        id: '',
        roomId: roomId,
        senderId: senderId,
        content: imageUrl,
        timestamp: DateTime.now(),
        type: MessageType.image,
        status: MessageStatus.sending,
      );
      
      final savedMessage = await _messageService.sendMessage(message);
      return savedMessage;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to send image message: ${e.toString()}');
    }
  }
  
  // Send a file message
  Future<Message> sendFileMessage(String roomId, File file, String fileName, String senderId) async {
    try {
      // First upload the file
      final fileUrl = await _storageService.uploadFile(file, 'chat_files/$roomId', fileName);
      
      final message = Message(
        id: '',
        roomId: roomId,
        senderId: senderId,
        content: fileUrl,
        timestamp: DateTime.now(),
        type: MessageType.file,
        metadata: {'fileName': fileName},
        status: MessageStatus.sending,
      );
      
      final savedMessage = await _messageService.sendMessage(message);
      return savedMessage;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to send file message: ${e.toString()}');
    }
  }
  
  // Edit a message
  Future<void> editMessage(Message message, String newContent) async {
    try {
      final updatedMessage = message.copyWith(
        content: newContent,
        isEdited: true,
        lastEditTimestamp: DateTime.now(),
      );
      
      await _messageService.updateMessage(updatedMessage);
      
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
      await _messageService.pinMessage(messageId, isPinned);
      
      // The state will be updated via _onMessageUpdate listener
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to pin message: ${e.toString()}');
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