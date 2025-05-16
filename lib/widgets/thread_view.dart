import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/models/message.dart';
import 'package:sifter/models/user.dart';
import 'package:sifter/providers/app_providers.dart';
import 'package:sifter/services/message_service.dart';
import 'package:sifter/services/user_service.dart';
import 'package:sifter/widgets/chat_bubble.dart';

class ThreadView extends ConsumerStatefulWidget {
  final Message parentMessage;
  final String roomId;

  const ThreadView({
    super.key,
    required this.parentMessage,
    required this.roomId,
  });

  @override
  ConsumerState<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends ConsumerState<ThreadView> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  List<Message> _replies = [];
  bool _isLoading = true;
  late final TextEditingController _replyController;
  AppUser? _sender;
  
  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
    _loadSender();
    _loadReplies();
  }
  
  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSender() async {
    try {
      _sender = await _userService.getUserById(widget.parentMessage.senderId);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _loadReplies() async {
    late ScaffoldMessengerState messenger;
    if (mounted) {
      messenger = ScaffoldMessenger.of(context);
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final replies = await _messageService.getMessageReplies(widget.parentMessage.id);
      if (mounted) {
        setState(() {
          _replies = replies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        messenger.showSnackBar(
          SnackBar(content: Text('Error loading replies: $e')),
        );
      }
    }
  }
  
  Future<void> _sendReply() async {
    late ScaffoldMessengerState messenger;
    if (mounted) {
      messenger = ScaffoldMessenger.of(context);
    }
    
    if (_replyController.text.trim().isEmpty) return;
    
    final currentUser = ref.read(userProvider).value;
    if (currentUser == null) return;
    
    final replyText = _replyController.text.trim();
    _replyController.clear();
    
    try {
      await _messageService.sendTextMessage(
        roomId: widget.roomId,
        senderId: currentUser.id,
        text: replyText,
        replyToMessageId: widget.parentMessage.id,
      );
      
      // Reload replies
      _loadReplies();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error sending reply: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thread'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Original message
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(76),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: _sender?.photoUrl != null && _sender!.photoUrl!.isNotEmpty
                          ? NetworkImage(_sender!.photoUrl!)
                          : null,
                      child: _sender?.photoUrl == null || _sender!.photoUrl!.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _sender?.displayName ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ChatBubble(
                  message: widget.parentMessage,
                  isCurrentUser: ref.read(userProvider).value?.id == widget.parentMessage.senderId,
                  showOptions: false,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_replies.length} ${_replies.length == 1 ? 'reply' : 'replies'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Replies
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _replies.isEmpty
                    ? const Center(
                        child: Text('No replies yet. Be the first to reply!'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _replies.length,
                        itemBuilder: (context, index) {
                          final reply = _replies[index];
                          final isCurrentUser = ref.read(userProvider).value?.id == reply.senderId;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ChatBubble(
                              message: reply,
                              isCurrentUser: isCurrentUser,
                              showReactions: true,
                            ),
                          );
                        },
                      ),
          ),
          // Reply input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: const InputDecoration(
                        hintText: 'Reply to thread...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendReply,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 