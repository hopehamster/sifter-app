import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_reaction.freezed.dart';
part 'message_reaction.g.dart';

/// Types of reactions available in Sifter Chat
enum ReactionType {
  emoji,
  lottie,
  giphy,
}

/// A reaction to a message
@freezed
class MessageReaction with _$MessageReaction {
  const factory MessageReaction({
    required String id,
    required String messageId,
    required String userId,
    required String userDisplayName,
    required ReactionType type,
    required String content, // emoji unicode, lottie asset path, or giphy URL
    required DateTime createdAt,
    String? giphyId, // For Giphy reactions
    String? lottieAsset, // For Lottie reactions
  }) = _MessageReaction;

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionFromJson(json);

  /// Create an emoji reaction
  factory MessageReaction.emoji({
    required String messageId,
    required String userId,
    required String userDisplayName,
    required String emoji,
  }) {
    return MessageReaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: messageId,
      userId: userId,
      userDisplayName: userDisplayName,
      type: ReactionType.emoji,
      content: emoji,
      createdAt: DateTime.now(),
    );
  }

  /// Create a Lottie animation reaction
  factory MessageReaction.lottie({
    required String messageId,
    required String userId,
    required String userDisplayName,
    required String assetPath,
  }) {
    return MessageReaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: messageId,
      userId: userId,
      userDisplayName: userDisplayName,
      type: ReactionType.lottie,
      content: assetPath,
      createdAt: DateTime.now(),
      lottieAsset: assetPath,
    );
  }

  /// Create a Giphy GIF reaction
  factory MessageReaction.giphy({
    required String messageId,
    required String userId,
    required String userDisplayName,
    required String giphyUrl,
    required String giphyId,
  }) {
    return MessageReaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: messageId,
      userId: userId,
      userDisplayName: userDisplayName,
      type: ReactionType.giphy,
      content: giphyUrl,
      createdAt: DateTime.now(),
      giphyId: giphyId,
    );
  }
}

/// Grouped reactions for a message (simplified)
class MessageReactionSummary {
  final String messageId;
  final Map<String, List<MessageReaction>> reactions;
  final int totalCount;

  MessageReactionSummary({
    required this.messageId,
    required this.reactions,
    required this.totalCount,
  });

  /// Get reactions grouped by content (emoji, lottie, giphy)
  Map<String, List<MessageReaction>> get reactionsByContent {
    final grouped = <String, List<MessageReaction>>{};
    for (final reactionList in reactions.values) {
      for (final reaction in reactionList) {
        grouped.putIfAbsent(reaction.content, () => []).add(reaction);
      }
    }
    return grouped;
  }

  /// Get most popular reactions (limit to top 6)
  List<MapEntry<String, List<MessageReaction>>> get topReactions {
    final sorted = reactionsByContent.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return sorted.take(6).toList();
  }
}
