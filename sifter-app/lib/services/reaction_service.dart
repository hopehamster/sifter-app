import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message_reaction.dart';
import '../core/error/error_handler.dart';
import '../core/error/error_types.dart';

/// Service for managing message reactions
class ReactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a reaction to a message
  Future<bool> addReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String userDisplayName,
    required ReactionType type,
    required String content,
    String? giphyId,
    String? lottieAsset,
  }) async {
    try {
      final reaction = MessageReaction(
        id: '${DateTime.now().millisecondsSinceEpoch}_$userId',
        messageId: messageId,
        userId: userId,
        userDisplayName: userDisplayName,
        type: type,
        content: content,
        createdAt: DateTime.now(),
        giphyId: giphyId,
        lottieAsset: lottieAsset,
      );

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .doc(reaction.id)
          .set(reaction.toJson());

      debugPrint('Reaction added successfully: ${reaction.content}');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler().handleError(
        e,
        stackTrace: stackTrace,
        category: ErrorCategory.chatRoom,
        severity: ErrorSeverity.medium,
        context: {
          'action': 'add_reaction',
          'roomId': roomId,
          'messageId': messageId,
          'type': type.name,
        },
      );
      debugPrint('Failed to add reaction: $e');
      return false;
    }
  }

  /// Remove a reaction from a message
  Future<bool> removeReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String content,
  }) async {
    try {
      // Find and delete the user's reaction with this content
      final reactionsQuery = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .where('userId', isEqualTo: userId)
          .where('content', isEqualTo: content)
          .get();

      for (final doc in reactionsQuery.docs) {
        await doc.reference.delete();
      }

      debugPrint('Reaction removed successfully: $content');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler().handleError(
        e,
        stackTrace: stackTrace,
        category: ErrorCategory.chatRoom,
        severity: ErrorSeverity.medium,
        context: {
          'action': 'remove_reaction',
          'roomId': roomId,
          'messageId': messageId,
        },
      );
      debugPrint('Failed to remove reaction: $e');
      return false;
    }
  }

  /// Get reactions for a specific message
  Stream<List<MessageReaction>> getMessageReactions({
    required String roomId,
    required String messageId,
  }) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .collection('reactions')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageReaction.fromJson(doc.data()))
          .toList();
    }).handleError((error, stackTrace) {
      ErrorHandler().handleError(
        error,
        stackTrace: stackTrace,
        category: ErrorCategory.chatRoom,
        severity: ErrorSeverity.low,
        context: {
          'action': 'get_message_reactions',
          'roomId': roomId,
          'messageId': messageId,
        },
      );
    });
  }

  /// Check if user has already reacted to a message with specific content
  Future<bool> hasUserReacted({
    required String roomId,
    required String messageId,
    required String userId,
    required String content,
  }) async {
    try {
      final query = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .where('userId', isEqualTo: userId)
          .where('content', isEqualTo: content)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user reaction: $e');
      return false;
    }
  }

  /// Get reaction summary for a message
  Future<MessageReactionSummary> getReactionSummary({
    required String roomId,
    required String messageId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .get();

      final reactions = snapshot.docs
          .map((doc) => MessageReaction.fromJson(doc.data()))
          .toList();

      // Group reactions by content
      final grouped = <String, List<MessageReaction>>{};
      for (final reaction in reactions) {
        grouped.putIfAbsent(reaction.content, () => []).add(reaction);
      }

      return MessageReactionSummary(
        messageId: messageId,
        reactions: grouped,
        totalCount: reactions.length,
      );
    } catch (e, stackTrace) {
      ErrorHandler().handleError(
        e,
        stackTrace: stackTrace,
        category: ErrorCategory.chatRoom,
        severity: ErrorSeverity.medium,
        context: {
          'action': 'get_reaction_summary',
          'roomId': roomId,
          'messageId': messageId,
        },
      );

      // Return empty summary on error
      return MessageReactionSummary(
        messageId: messageId,
        reactions: {},
        totalCount: 0,
      );
    }
  }

  /// Toggle a reaction (add if not present, remove if present)
  Future<bool> toggleReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String userDisplayName,
    required ReactionType type,
    required String content,
    String? giphyId,
    String? lottieAsset,
  }) async {
    final hasReacted = await hasUserReacted(
      roomId: roomId,
      messageId: messageId,
      userId: userId,
      content: content,
    );

    if (hasReacted) {
      return await removeReaction(
        roomId: roomId,
        messageId: messageId,
        userId: userId,
        content: content,
      );
    } else {
      return await addReaction(
        roomId: roomId,
        messageId: messageId,
        userId: userId,
        userDisplayName: userDisplayName,
        type: type,
        content: content,
        giphyId: giphyId,
        lottieAsset: lottieAsset,
      );
    }
  }

  /// Get available Lottie reaction assets
  List<String> getLottieAssets() {
    return [
      'assets/reactions/like.json',
      'assets/reactions/love.json',
      'assets/reactions/laugh.json',
      'assets/reactions/wow.json',
      'assets/reactions/sad.json',
      'assets/reactions/angry.json',
      'assets/reactions/celebrate.json',
      'assets/reactions/applause.json',
    ];
  }

  /// Get popular emoji reactions
  List<String> getPopularEmojis() {
    return [
      '👍',
      '❤️',
      '😂',
      '😮',
      '😢',
      '😡',
      '🎉',
      '👏',
      '🔥',
      '💯',
      '⭐',
      '✨',
      '💪',
      '🙌',
      '👌',
      '✅',
      '❌',
      '🤔',
    ];
  }
}

/// Provider for ReactionService
final reactionServiceProvider = Provider<ReactionService>((ref) {
  return ReactionService();
});
