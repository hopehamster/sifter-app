import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/message_reaction.dart';

/// Widget to display reactions under a message
class MessageReactionsDisplay extends StatelessWidget {
  final List<MessageReaction> reactions;
  final Function(String content, ReactionType type) onReactionTap;
  final String? currentUserId;

  const MessageReactionsDisplay({
    super.key,
    required this.reactions,
    required this.onReactionTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by content
    final grouped = <String, List<MessageReaction>>{};
    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.content, () => []).add(reaction);
    }

    // Sort by popularity and limit to top 6
    final sortedReactions = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topReactions = sortedReactions.take(6).toList();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: topReactions.map((entry) {
          final content = entry.key;
          final reactionList = entry.value;
          final count = reactionList.length;
          final firstReaction = reactionList.first;
          final hasUserReacted = currentUserId != null &&
              reactionList.any((r) => r.userId == currentUserId);

          return _buildReactionChip(
            context,
            content,
            count,
            firstReaction.type,
            hasUserReacted,
            reactionList,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReactionChip(
    BuildContext context,
    String content,
    int count,
    ReactionType type,
    bool hasUserReacted,
    List<MessageReaction> reactionList,
  ) {
    return GestureDetector(
      onTap: () => onReactionTap(content, type),
      onLongPress: () => _showReactionDetails(context, reactionList),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hasUserReacted
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUserReacted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: hasUserReacted ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReactionContent(context, content, type),
            if (count > 1) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hasUserReacted
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: hasUserReacted ? FontWeight.w600 : null,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReactionContent(
    BuildContext context,
    String content,
    ReactionType type,
  ) {
    switch (type) {
      case ReactionType.emoji:
        return Text(
          content,
          style: const TextStyle(fontSize: 16),
        );

      case ReactionType.lottie:
        return SizedBox(
          width: 20,
          height: 20,
          child: Lottie.asset(
            content,
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.animation,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );
            },
          ),
        );

      case ReactionType.giphy:
        return SizedBox(
          width: 20,
          height: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: content,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.gif,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.broken_image,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
    }
  }

  void _showReactionDetails(
    BuildContext context,
    List<MessageReaction> reactionList,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...reactionList.map((reaction) => ListTile(
                  dense: true,
                  leading: _buildReactionContent(
                    context,
                    reaction.content,
                    reaction.type,
                  ),
                  title: Text(reaction.userDisplayName),
                  subtitle: Text(
                    _formatTimestamp(reaction.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
