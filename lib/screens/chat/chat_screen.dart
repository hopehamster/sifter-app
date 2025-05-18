import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/models/message.dart';
import 'package:sifter/services/message_service.dart';
import 'package:sifter/providers/riverpod/message_provider.dart';
import 'package:sifter/providers/riverpod/room_provider.dart' as room_provider;
import 'package:sifter/providers/riverpod/user_provider.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  
  const ChatScreen({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  DocumentSnapshot? _lastMessageDoc;
  static const int _messagesPerPage = 20;
  
  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialMessages() async {
    try {
      final querySnapshot = await _messageService.getInitialMessages(widget.roomId, _messagesPerPage);
      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _lastMessageDoc = querySnapshot.docs.last;
          }
          _hasMoreMessages = querySnapshot.docs.length >= _messagesPerPage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }
  
  Future<void> _loadMoreMessages() async {
    if (!_hasMoreMessages || _isLoadingMore || _lastMessageDoc == null) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final querySnapshot = await _messageService.getMoreMessages(
        widget.roomId,
        _lastMessageDoc!,
        _messagesPerPage,
      );
      
      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _lastMessageDoc = querySnapshot.docs.last;
          }
          _hasMoreMessages = querySnapshot.docs.length >= _messagesPerPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more messages: $e')),
        );
      }
    }
  }
  
  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange) {
      _loadMoreMessages();
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final currentUser = ref.read(userNotifierProvider).value;
    if (currentUser == null) return;
    
    try {
      _messageController.clear();
      
      // This will trigger a state update through the stream listener
      await ref.read(roomMessagesNotifierProvider(widget.roomId).notifier)
          .sendTextMessage(
        widget.roomId,
        text,
        currentUser.id,
      );
      
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(room_provider.roomProvider(widget.roomId));
    final messagesAsync = ref.watch(roomMessagesNotifierProvider(widget.roomId));
    final currentUserAsync = ref.watch(userNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: roomAsync.when(
          data: (room) => Text(room.name),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show room info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start a conversation!'),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = currentUserAsync.value?.id == message.senderId;
                    
                    return _buildMessageItem(message, isCurrentUser);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading messages: $error'),
                  ],
                ),
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
  
  Widget _buildMessageItem(Message message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withAlpha(26),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // Handle file attachment
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(dynamic timestamp) {
    final DateTime dateTime;
    
    if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return ''; // Unknown timestamp format
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
    
    if (messageDate == today) {
      return DateFormat.jm().format(dateTime); // 3:30 PM
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat.yMMMd().add_jm().format(dateTime); // Apr 27, 2023, 3:30 PM
    }
  }
}
