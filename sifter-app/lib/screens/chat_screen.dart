import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../models/chat_room.dart';
import '../models/message_reaction.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/chat_room_service.dart';
import '../services/moderation_service.dart';
import '../services/content_filter_service.dart';
import '../services/reaction_service.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/quick_reaction_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late types.Room _room;
  types.User? _currentUser;
  final List<types.Message> _messages = [];
  bool _isLoading = true;
  bool _isWithinGeofence = true;
  List<String> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _startLocationMonitoring();
    _loadBlockedUsers();
  }

  Future<void> _initializeChat() async {
    try {
      // Get current user
      final authService = ref.read(authServiceProvider);
      final userProfile = await authService.getUserProfile();
      final firebaseUser = authService.currentUser;

      if (userProfile == null || firebaseUser == null) {
        throw Exception('User not authenticated');
      }

      // Create current user for chat
      _currentUser = types.User(
        id: firebaseUser.uid,
        firstName: userProfile.username,
        metadata: {
          'email': userProfile.email,
          'username': userProfile.username,
        },
      );

      // Convert chat room to Flutter Chat SDK room
      _room = widget.chatRoom.toFlyerRoom();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to initialize chat: $e');
    }
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      final blockedUsers = await moderationService.getBlockedUsers();
      setState(() {
        _blockedUsers = blockedUsers;
      });
    } catch (e) {
      // Silent fail for blocked users loading
    }
  }

  void _startLocationMonitoring() {
    // Monitor user's location to ensure they remain within geofence
    final locationService = ref.read(locationServiceProvider);

    // Check every 30 seconds if user is still within geofence
    Stream.periodic(const Duration(seconds: 30)).listen((_) async {
      try {
        final isWithin = locationService.isWithinGeofence(
          chatLat: widget.chatRoom.latitude,
          chatLng: widget.chatRoom.longitude,
          radiusInMeters: widget.chatRoom.radiusInMeters,
        );

        if (_isWithinGeofence && !isWithin) {
          setState(() {
            _isWithinGeofence = false;
          });
          _handleGeofenceExit();
        } else if (!_isWithinGeofence && isWithin) {
          setState(() {
            _isWithinGeofence = true;
          });
        }
      } catch (e) {
        // Silent fail for location monitoring
      }
    });
  }

  void _handleGeofenceExit() {
    // Show dialog and remove user from chat
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Left Chat Area'),
        content: const Text(
          'You have left the chat area and will be removed from this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit chat screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Remove user from chat room
    final authService = ref.read(authServiceProvider);
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId != null) {
      ref.read(chatRoomServiceProvider).leaveChatRoom(
            roomId: widget.chatRoom.id,
            userId: currentUserId,
          );
    }
  }

  void _handleSendPressed(types.PartialText message) {
    if (!_isWithinGeofence) {
      _showError('You must be within the chat area to send messages');
      return;
    }

    if (_currentUser == null) return;

    // ✅ Content Validation
    final contentFilterService = ref.read(contentFilterServiceProvider);
    final messageValidation = contentFilterService.validateMessage(
      message.text,
      isNSFWRoom: widget.chatRoom.isNsfw,
    );

    if (!messageValidation.isValid) {
      _showError('Message not sent: ${messageValidation.reason}');
      return;
    }

    // Use cleaned text if profanity was filtered
    final messageText = messageValidation.cleanedText ?? message.text;
    final cleanedMessage = types.PartialText(text: messageText);

    // Add message using Firebase Chat Core
    FirebaseChatCore.instance.sendMessage(
      cleanedMessage,
      _room.id,
    );
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.TextMessage) {
      // Show quick reaction bar first, then options
      _showQuickReactionBar(message);
    }
  }

  void _showQuickReactionBar(types.TextMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions
            QuickReactionBar(
              onEmojiTap: (emoji) {
                Navigator.pop(context);
                _addReaction(message.id, ReactionType.emoji, emoji);
              },
              onMoreTap: () {
                Navigator.pop(context);
                _showFullReactionPicker(message);
              },
            ),
            const SizedBox(height: 16),
            // Additional options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMessageOptions(message);
                  },
                  icon: const Icon(Icons.more_horiz),
                  label: const Text('More Options'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullReactionPicker(types.TextMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReactionPicker(
        onEmojiSelected: (emoji) {
          _addReaction(message.id, ReactionType.emoji, emoji);
        },
        onGiphySelected: (giphyUrl, giphyId) {
          _addReaction(message.id, ReactionType.giphy, giphyUrl,
              giphyId: giphyId);
        },
        onLottieSelected: (lottieAsset) {
          _addReaction(message.id, ReactionType.lottie, lottieAsset);
        },
        giphyApiKey: ApiConfig.giphyApiKey,
      ),
    );
  }

  Future<void> _addReaction(
    String messageId,
    ReactionType type,
    String content, {
    String? giphyId,
    String? lottieAsset,
  }) async {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    final reactionService = ref.read(reactionServiceProvider);
    final success = await reactionService.toggleReaction(
      roomId: widget.chatRoom.id,
      messageId: messageId,
      userId: currentUser.uid,
      userDisplayName: currentUser.displayName ?? 'Anonymous',
      type: type,
      content: content,
      giphyId: giphyId,
      lottieAsset: lottieAsset,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Reaction ${type == ReactionType.emoji ? 'added' : 'updated'}!'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      _showError('Failed to add reaction');
    }
  }

  void _showMessageOptions(types.TextMessage message) {
    final authService = ref.read(authServiceProvider);
    final currentUserId = authService.currentUser?.uid;
    final isOwnMessage = message.author.id == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isOwnMessage) ...[
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(
                      message.author.id, message.author.firstName ?? 'Unknown');
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(message.author.id, message.text);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement copy to clipboard
                _showError('Copy feature coming soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _blockUser(String userIdToBlock, String userName) async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      final result = await moderationService.blockUser(
        userIdToBlock: userIdToBlock,
        reason: 'Blocked from chat',
        roomId: widget.chatRoom.id,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() {
          _blockedUsers.add(userIdToBlock);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName has been blocked')),
        );
      } else {
        _showError(result.message);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to block user: $e');
      }
    }
  }

  void _showReportDialog(String userIdToReport, String messageText) {
    final reportReasons = [
      ReportCategory.spam,
      ReportCategory.inappropriate,
      ReportCategory.harassment,
      ReportCategory.violence,
      ReportCategory.other,
    ];

    ReportCategory? selectedCategory;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Message: "${messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText}"'),
              const SizedBox(height: 16),
              const Text('Reason:'),
              const SizedBox(height: 8),
              ...reportReasons.map((category) => RadioListTile<ReportCategory>(
                    title: Text(category.displayName),
                    value: category,
                    groupValue: selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  )),
              if (selectedCategory == ReportCategory.other) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCategory != null
                  ? () async {
                      Navigator.of(context).pop();
                      await _reportUser(
                        userIdToReport,
                        selectedCategory!,
                        reasonController.text,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportUser(String userIdToReport, ReportCategory category,
      String description) async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      final result = await moderationService.reportUser(
        userIdToReport: userIdToReport,
        reason: category.displayName,
        category: category,
        description: description.isNotEmpty ? description : null,
        roomId: widget.chatRoom.id,
      );

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('Failed to submit report: $e');
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    // Update message with preview data
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) =>
            _buildChatInfoSheet(scrollController),
      ),
    );
  }

  Widget _buildChatInfoSheet(ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.chatRoom.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.chatRoom.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Creator', widget.chatRoom.creatorName),
                _buildInfoRow('Members',
                    '${widget.chatRoom.participantIds.length}/${widget.chatRoom.maxMembers}'),
                _buildInfoRow(
                    'Radius', '${widget.chatRoom.radiusInMeters.round()}m'),
                if (widget.chatRoom.isNsfw) _buildInfoRow('Content', 'NSFW'),
                if (widget.chatRoom.isPasswordProtected)
                  _buildInfoRow('Access', 'Password Protected'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _leaveChatRoom();
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Leave Chat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _leaveChatRoom() async {
    try {
      final authService = ref.read(authServiceProvider);
      final currentUserId = authService.currentUser?.uid;
      if (currentUserId == null) {
        _showError('User not authenticated');
        return;
      }

      await ref.read(chatRoomServiceProvider).leaveChatRoom(
            roomId: widget.chatRoom.id,
            userId: currentUserId,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to leave chat room: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.chatRoom.name),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.chatRoom.name),
        ),
        body: const Center(
          child: Text('Failed to load user information'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.name,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${widget.chatRoom.participantIds.length} members',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showChatInfo,
            icon: const Icon(Icons.info_outline),
          ),
        ],
        bottom: !_isWithinGeofence
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 16,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are outside the chat area',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: StreamBuilder<types.Room>(
        stream: FirebaseChatCore.instance.room(_room.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final room = snapshot.data!;

          return StreamBuilder<List<types.Message>>(
            stream: FirebaseChatCore.instance.messages(room),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading messages: ${snapshot.error}'),
                );
              }

              final allMessages = snapshot.data ?? [];

              // Filter out messages from blocked users
              final filteredMessages = allMessages.where((message) {
                return !_blockedUsers.contains(message.author.id);
              }).toList();

              return Chat(
                messages: filteredMessages,
                onMessageTap: _handleMessageTap,
                onPreviewDataFetched: _handlePreviewDataFetched,
                onSendPressed: _handleSendPressed,
                showUserAvatars: true,
                showUserNames: true,
                user: _currentUser!,
                theme: DefaultChatTheme(
                  primaryColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  inputBackgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  inputTextColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
