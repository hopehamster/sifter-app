import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/services/message_service.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Stream<QuerySnapshot> getMessages(String roomId) {
    return _messageService.getMessages(roomId);
  }

  Future<void> sendTextMessage({
    required String roomId,
    required String senderId,
    required String text,
    String? replyToMessageId,
  }) async {
    _setLoading(true);
    try {
      await _messageService.sendTextMessage(
        roomId: roomId,
        senderId: senderId,
        text: text,
        replyToMessageId: replyToMessageId,
      );
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendImageMessage({
    required String roomId,
    required String senderId,
    required dynamic imageFile,
    String? caption,
    String? replyToMessageId,
  }) async {
    _setLoading(true);
    try {
      await _messageService.sendImageMessage(
        roomId: roomId,
        senderId: senderId,
        imageFile: imageFile,
        caption: caption,
        replyToMessageId: replyToMessageId,
      );
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendFileMessage({
    required String roomId,
    required String senderId,
    required dynamic file,
    String? caption,
    String? replyToMessageId,
  }) async {
    _setLoading(true);
    try {
      await _messageService.sendFileMessage(
        roomId: roomId,
        senderId: senderId,
        file: file,
        caption: caption,
        replyToMessageId: replyToMessageId,
      );
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    _setLoading(true);
    try {
      await _messageService.deleteMessage(messageId);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    _setLoading(true);
    try {
      await _messageService.editMessage(messageId, newText);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messageService.markMessageAsRead(messageId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Stream<QuerySnapshot> getMessageReplies(String messageId) {
    return _messageService.getMessageReplies(messageId);
  }

  Future<void> pinMessage(String messageId) async {
    try {
      await _messageService.pinMessage(messageId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> unpinMessage(String messageId) async {
    try {
      await _messageService.unpinMessage(messageId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Stream<QuerySnapshot> getPinnedMessages(String roomId) {
    return _messageService.getPinnedMessages(roomId);
  }

  Future<QuerySnapshot> searchMessages(String roomId, String query) async {
    return await _messageService.searchMessages(roomId, query);
  }
  
  // Methods for pagination
  Future<QuerySnapshot> getInitialMessages(String roomId, int limit) async {
    _setLoading(true);
    try {
      final result = await _messageService.getInitialMessages(roomId, limit);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> getMoreMessages(String roomId, DocumentSnapshot lastDoc, int limit) async {
    _setLoading(true);
    try {
      final result = await _messageService.getMoreMessages(roomId, lastDoc, limit);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // New methods for reactions
  Future<void> addReaction(String messageId, String emoji, String userId) async {
    try {
      await _messageService.addReaction(messageId, emoji, userId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> removeReaction(String messageId, String emoji, String userId) async {
    try {
      await _messageService.removeReaction(messageId, emoji, userId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<Map<String, List<String>>> getReactions(String messageId) async {
    try {
      return await _messageService.getReactions(messageId);
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }
} 