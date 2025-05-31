import 'package:flutter/material.dart';

/// Quick reaction bar that appears below messages
class QuickReactionBar extends StatelessWidget {
  final Function(String emoji) onEmojiTap;
  final Function() onMoreTap;

  const QuickReactionBar({
    super.key,
    required this.onEmojiTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    const popularEmojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ...popularEmojis.map((emoji) => _buildEmojiButton(context, emoji)),
          const SizedBox(width: 8),
          _buildMoreButton(context),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(BuildContext context, String emoji) {
    return GestureDetector(
      onTap: () => onEmojiTap(emoji),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return GestureDetector(
      onTap: onMoreTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
