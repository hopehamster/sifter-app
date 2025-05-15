import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sifter/screens/chat/chat_cache.dart';
import 'package:sifter/widgets/audio_message.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:sifter/providers/auth_provider.dart' as s;

class ChatScreen extends StatefulWidget {
  final String roomId;
  ChatScreen({required this.roomId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final _controller = TextEditingController();
  final _floatingReactions = <FloatingReaction>[];
  final _youtubeControllers = <String, YoutubePlayerController>{};
  int _reactionCount = 0;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.subscribeToTopic('room_${widget.roomId}');
    ChatCache.init();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    // Placeholder for connectivity check
    setState(() => _isOnline = true); // Assume online for now
  }

  // Future<void> _sendMessage(String content, {String? audioUrl}) async {
  //   final authProvider = Provider.of<s.AuthProvider>(context, listen: false);
  //   final message = {
  //     'content': content,
  //     if (audioUrl != null) 'audioUrl': audioUrl,
  //     'userId': authProvider.userId,
  //     'createdAt': DateTime.now().toIso8601String(),
  //   };
  //   final batch = _db.batch();
  //   final messageRef = _db.child('messages/${widget.roomId}').push();
  //   batch.set(messageRef, message);
  //   await batch.commit();
  //   await ChatCache.cacheMessage(widget.roomId, message);
  //   await FirebaseFunctions.instance.httpsCallable('sendNotification').call({
  //     'roomId': widget.roomId,
  //     'message':
  //         content.length > 20 ? content.substring(0, 20) + '...' : content,
  //   });
  // }
  Future<void> _sendMessage(String content, {String? audioUrl}) async {
    final authProvider = Provider.of<s.AuthProvider>(context, listen: false);
    final message = {
      'content': content,
      if (audioUrl != null) 'audioUrl': audioUrl,
      'userId': authProvider.userId,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Use push() to generate a new message reference
    final messageRef = _db.child('messages/${widget.roomId}').push();

    // Directly set the message without using a batch
    await messageRef.set(message);

    // Optional: cache locally
    await ChatCache.cacheMessage(widget.roomId, message);

    // Trigger Firebase Function for notifications
    await FirebaseFunctions.instance.httpsCallable('sendNotification').call({
      'roomId': widget.roomId,
      'message':
          content.length > 20 ? content.substring(0, 20) + '...' : content,
    });
  }

  void _addFloatingReaction(String gifUrl) {
    if (_reactionCount >= 2) return;
    setState(() {
      _reactionCount++;
      final controller =
          AnimationController(vsync: this, duration: Duration(seconds: 3));
      _floatingReactions
          .add(FloatingReaction(gifUrl: gifUrl, controller: controller));
      controller.forward().then((_) {
        setState(() {
          _floatingReactions.removeWhere((r) => r.controller == controller);
          _reactionCount--;
          controller.dispose();
          CachedNetworkImage.evictFromCache(gifUrl);
        });
      });
    });
  }

  String? _extractYoutubeId(String text) {
    final regex = RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([\w-]+)');
    final match = regex.firstMatch(text);
    return match?.group(1);
  }

  String? _extractUrl(String text) {
    final regex = RegExp(r'(https?://[^\s]+)');
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Room')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _db.child('messages/${widget.roomId}').onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (!_isOnline) {
                      return FutureBuilder<List<dynamic>>(
                        future: ChatCache.getCachedMessages(widget.roomId),
                        builder: (context, cacheSnapshot) {
                          if (!cacheSnapshot.hasData)
                            return Center(child: CircularProgressIndicator());
                          final messagesMap = snapshot.data!.snapshot.value
                              as Map<dynamic, dynamic>;
                          final messages = messagesMap.values
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList();
                          return _buildMessageList(messages);
                        },
                      );
                    }
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());
                    final rawData = snapshot.data!.snapshot.value;
                    if (rawData == null || rawData is! Map) {
                      return const Center(child: Text("No messages found"));
                    }

                    final messagesMap =
                        Map<String, dynamic>.from(rawData as Map);
                    final messages = messagesMap.entries.map((entry) {
                      final message =
                          Map<String, dynamic>.from(entry.value as Map);
                      message['id'] =
                          entry.key; // optionally keep the message ID
                      return message;
                    }).toList();

                    return _buildMessageList(messages);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
          ..._floatingReactions.map(_buildFloatingReaction),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return GestureDetector(
          onLongPress: () => _showReactionPicker(context, message['id']),
          child: _buildMessage(message),
        );
      },
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final content = message['content'] ?? '';
    final audioUrl = message['audioUrl'];
    final gifUrl = message['gifUrl'];
    final youtubeId = _extractYoutubeId(content);
    final url = _extractUrl(content);

    if (audioUrl != null) {
      return AudioMessage(audioUrl: audioUrl);
    } else if (gifUrl != null) {
      return CachedNetworkImage(
        imageUrl: gifUrl,
        width: 100,
        height: 100,
        memCacheHeight: 50,
        memCacheWidth: 50,
        fadeInDuration: Duration(milliseconds: 200),
      );
    } else if (youtubeId != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VisibilityDetector(
            key: Key(youtubeId),
            onVisibilityChanged: (info) {
              if (info.visibleFraction == 0) {
                _youtubeControllers[youtubeId]?.dispose();
                _youtubeControllers.remove(youtubeId);
              }
            },
            child: YoutubePlayer(
              controller: _youtubeControllers.putIfAbsent(
                youtubeId,
                () => YoutubePlayerController(
                  initialVideoId: youtubeId,
                  flags: YoutubePlayerFlags(autoPlay: false, mute: false),
                ),
              ),
              width: 300,
            ),
          ),
          SizedBox(height: 8),
          LinkPreviewGenerator(link: content)
          // LinkPreview(
          //       url: content,
          //       previewHeight: 100,
          //       borderRadius: 12,
          //       boxShadow: [
          //         BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)
          //       ],
          //     ),
        ],
      );
    } else if (url != null) {
      return LinkPreviewGenerator(link: content);
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF2196F3)),
      ),
      child: Text(content),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _controller)),
          IconButton(
            icon: Icon(Icons.mic, color: Color(0xFF2196F3)),
            onPressed: () async {
              final audioFile = await AudioMessage.record();
              if (audioFile != null) {
                await _sendMessage('', audioUrl: audioFile);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.gif),
            onPressed: () async {
              final gif = await GiphyGet.getGif(
                context: context,
                apiKey: 'YOUR_GIPHY_API_KEY',
                lang: GiphyLanguage.english,
                rating: GiphyRating.g,
              );
              if (gif != null) {
                await _sendMessage('', audioUrl: null);
                await _db.child('messages/${widget.roomId}').push().set({
                  'gifUrl': gif.url,
                  'userId': Provider.of<s.AuthProvider>(context, listen: false)
                      .userId,
                  'createdAt': DateTime.now().toIso8601String(),
                });
                _addFloatingReaction(gif.url!);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              if (_controller.text.isNotEmpty) {
                await _sendMessage(_controller.text);
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingReaction(FloatingReaction reaction) {
    final slideAnimation =
        Tween<Offset>(begin: Offset(0, 1), end: Offset(0, -1))
            .animate(reaction.controller);
    final opacityAnimation =
        Tween<double>(begin: 1, end: 0).animate(reaction.controller);
    final scaleAnimation =
        Tween<double>(begin: 0.8, end: 1.2).animate(reaction.controller);

    return Positioned(
      bottom: 0,
      left: MediaQuery.of(context).size.width * 0.4,
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: opacityAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: CachedNetworkImage(
              imageUrl: reaction.gifUrl,
              width: 50,
              height: 50,
              memCacheHeight: 50,
              memCacheWidth: 50,
              fadeInDuration: Duration(milliseconds: 200),
            ),
          ),
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context, String messageId) {
    // Placeholder for reaction picker
  }
}

class FloatingReaction {
  final String gifUrl;
  final AnimationController controller;

  FloatingReaction({required this.gifUrl, required this.controller});
}
