import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/models/message.dart';
import 'package:sifter/providers/message_provider.dart';

class ReactionWidget extends ConsumerWidget {
  final Message message;
  final String currentUserId;

  const ReactionWidget({
    Key? key,
    required this.message,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.hasReactions) _buildReactionDisplay(context, ref),
        _buildReactionButton(context, ref),
      ],
    );
  }

  Widget _buildReactionDisplay(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 4,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        final hasUserReacted = users.contains(currentUserId);
        
        return InkWell(
          onTap: () => _toggleReaction(emoji, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasUserReacted ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  users.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasUserReacted ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReactionButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.emoji_emotions_outlined, size: 18),
      onPressed: () => _showReactionPicker(context, ref),
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _toggleReaction(String emoji, WidgetRef ref) {
    final messageProvider = ref.read(messageProvider.notifier);
    
    if (message.hasUserReacted(currentUserId, emoji)) {
      messageProvider.removeReaction(message.id, emoji, currentUserId);
    } else {
      messageProvider.addReaction(message.id, emoji, currentUserId);
    }
  }

  void _showReactionPicker(BuildContext context, WidgetRef ref) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '👏', '🔥', '🎉'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('React to message', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: emojis.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  return GestureDetector(
                    onTap: () {
                      _toggleReaction(emoji, ref);
                      Navigator.pop(context);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 