import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/models/message.dart';
import 'package:sifter/models/user.dart';
import 'package:sifter/providers/app_providers.dart';
import 'package:sifter/services/message_service.dart';
import 'package:sifter/services/user_service.dart';
import 'package:sifter/widgets/reaction_widget.dart';
import 'package:sifter/widgets/thread_view.dart';
import 'package:intl/intl.dart';

// class ChatBubble extends StatelessWidget {
//   final Map<String, dynamic> message;
//   final VoidCallback onLongPress;

//   const ChatBubble({required this.message, required this.onLongPress});

//   @override
//   Widget build(BuildContext context) {
//     final content = message['content'] ?? '';
//     final gifUrl = message['gifUrl'];
//     final audioUrl = message['audioUrl'];
//     final youtubeId = _extractYoutubeId(content);
//     final url = _extractUrl(content);
//     final isUnsupportedPlatform = _isUnsupportedPlatform(url);

//     Widget body;
//     if (gifUrl != null) {
//       body = Image.network(gifUrl, width: 100, height: 100);
//     } else if (audioUrl != null) {
//       body = AudioMessage(audioUrl: audioUrl);
//     } else if (youtubeId != null) {
//       body = Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           YoutubePlayer(
//             controller: YoutubePlayerController(
//               initialVideoId: youtubeId,
//               flags: YoutubePlayerFlags(autoPlay: false, mute: false),
//             ),
//             width: 300,
//           ),
//           SizedBox(height: 8),
//           LinkPreviewGenerator(
//             borderRadius: 12,
//             boxShadow: [
//               BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)
//             ],
//             titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             link: content,
//           ),
//         ],
//       );
//     } else if (url != null && !isUnsupportedPlatform) {
//       body = LinkPreviewGenerator(
//         borderRadius: 12,
//         boxShadow: [
//           BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)
//         ],
//         titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         link: content,
//       );
//     } else if (url != null && isUnsupportedPlatform) {
//       body = VisibilityDetector(
//         key: Key(message['id']),
//         onVisibilityChanged: (info) {
//           if (info.visibleFraction > 0) {}
//         },
//         child: Container(
//           height: 200,
//           margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//           child: InAppWebView(
//             initialUrlRequest: URLRequest(url: WebUri(url)),
//             initialOptions: InAppWebViewGroupOptions(
//               crossPlatform: InAppWebViewOptions(
//                 javaScriptEnabled: true,
//                 useShouldOverrideUrlLoading: true,
//               ),
//             ),
//             onWebViewCreated: (controller) {},
//           ),
//         ),
//       );
//     } else {
//       body = Text(content);
//     }

//     return GestureDetector(
//       onLongPress: onLongPress,
//       child: Container(
//         margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         padding: EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: body,
//       ),
//     );
//   }

//   String? _extractYoutubeId(String text) {
//     final regex = RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([\w-]+)');
//     final match = regex.firstMatch(text);
//     return match?.group(1);
//   }

//   String? _extractUrl(String text) {
//     final regex = RegExp(r'(https?://[^\s]+)');
//     final match = regex.firstMatch(text);
//     return match?.group(0);
//   }

//   bool _isUnsupportedPlatform(String? url) {
//     if (url == null) return false;
//     return url.contains('twitch.tv') || url.contains('tiktok.com');
//   }
// }
class ChatBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final bool showReactions;
  final bool showOptions;
  final VoidCallback? onLongPress;
  final Function(Message)? onReply;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.showReactions = true,
    this.showOptions = true,
    this.onLongPress,
    this.onReply,
  }) : super(key: key);

  @override
  ConsumerState<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends ConsumerState<ChatBubble> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  AppUser? _sender;
  Message? _parentMessage;
  int _replyCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadSender();
    _loadReplyInfo();
  }
  
  Future<void> _loadSender() async {
    try {
      _sender = await _userService.getUserById(widget.message.senderId);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _loadReplyInfo() async {
    if (widget.message.replyToMessageId != null) {
      try {
        // Load the parent message if this is a reply
        final doc = await _messageService.getMessage(widget.message.replyToMessageId!);
        if (doc.exists) {
          setState(() {
            _parentMessage = Message.fromJson(doc.data() as Map<String, dynamic>);
          });
        }
      } catch (e) {
        // Handle error
      }
    }
    
    // Get reply count
    try {
      final count = await _messageService.getMessageReplyCount(widget.message.id);
      
      setState(() {
        _replyCount = count;
      });
    } catch (e) {
      // Handle error
    }
  }
  
  void _navigateToThread() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThreadView(
          parentMessage: widget.message,
          roomId: widget.message.chatRoomId,
        ),
      ),
    ).then((_) {
      // Refresh reply count when returning from thread view
      _loadReplyInfo();
    });
  }
  
  void _replyToMessage() {
    if (widget.onReply != null) {
      widget.onReply!(widget.message);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Show parent message info if this is a reply
        if (_parentMessage != null)
          GestureDetector(
            onTap: () {
              // Navigate to the parent message thread
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ThreadView(
                    parentMessage: _parentMessage!,
                    roomId: _parentMessage!.chatRoomId,
                  ),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(
                left: widget.isCurrentUser ? 40 : 8,
                right: widget.isCurrentUser ? 8 : 40,
                bottom: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(76),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(76),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reply to ${_sender?.displayName ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        // Main message bubble
        GestureDetector(
          onLongPress: widget.onLongPress,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: EdgeInsets.only(
              left: widget.isCurrentUser ? 40 : 8,
              right: widget.isCurrentUser ? 8 : 40,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isCurrentUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isCurrentUser && _sender != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _sender!.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: widget.isCurrentUser 
                            ? Theme.of(context).colorScheme.onPrimary.withAlpha(204)
                            : Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                Text(
                  widget.message.content,
                  style: TextStyle(
                    color: widget.isCurrentUser
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(widget.message.timestamp),
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isCurrentUser
                            ? Theme.of(context).colorScheme.onPrimary.withAlpha(178)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(178),
                      ),
                    ),
                    if (widget.message.edited)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '(edited)',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: widget.isCurrentUser
                                ? Theme.of(context).colorScheme.onPrimary.withAlpha(178)
                                : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(178),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Message reactions
        if (widget.showReactions && widget.message.hasReactions)
          Padding(
            padding: EdgeInsets.only(
              left: widget.isCurrentUser ? 40 : 8,
              right: widget.isCurrentUser ? 8 : 40,
              top: 2,
            ),
            child: ReactionWidget(
              message: widget.message,
              currentUserId: ref.read(userProvider).value?.id ?? '',
            ),
          ),
          
        // Thread indicator
        if (_replyCount > 0 || widget.showOptions)
          Padding(
            padding: EdgeInsets.only(
              left: widget.isCurrentUser ? 40 : 12,
              right: widget.isCurrentUser ? 12 : 40,
              top: 2,
              bottom: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyCount > 0)
                  GestureDetector(
                    onTap: _navigateToThread,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(127),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.forum, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$_replyCount ${_replyCount == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_replyCount > 0 && widget.showOptions)
                  const SizedBox(width: 8),
                if (widget.showOptions)
                  GestureDetector(
                    onTap: _replyToMessage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(127),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.reply, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
