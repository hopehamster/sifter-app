import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool isTyping;
  final String typingText;

  const TypingIndicator({
    super.key,
    required this.isTyping,
    this.typingText = 'is typing...',
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = IntTween(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTyping) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.typingText),
            Text('.', style: TextStyle(fontWeight: _animation.value >= 1 ? FontWeight.bold : FontWeight.normal)),
            Text('.', style: TextStyle(fontWeight: _animation.value >= 2 ? FontWeight.bold : FontWeight.normal)),
            Text('.', style: TextStyle(fontWeight: _animation.value >= 3 ? FontWeight.bold : FontWeight.normal)),
          ],
        );
      },
    );
  }
} 