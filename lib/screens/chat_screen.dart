import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/chat_cache.dart';
import '../widgets/audio_message.dart';

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
  final ScrollController _scrollController = ScrollController();
  int _reactionCount = 0;
  bool _isOnline = true;
  Map<String, dynamic>? _roomData;
  bool _isCreator = false;
  bool _isActive = true;
  bool _isRecording = false;
  bool _isBanned = false;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.subscribeToTopic('room_${widget.roomId}');
    ChatCache.init();
    _checkConnectivity();
    _fetchRoomData();
    _listenForBan();
  }

  Future<void> _fetchRoomData() async {
    final snapshot = await _db.child('rooms/${widget.roomId}').get();
    if (snapshot.exists) {
      setState(() {
        _roomData = Map<String, dynamic>.from(snapshot.value as Map);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        _isCreator = authProvider.userId == _roomData?['creatorId'];
        _isActive = _roomData?['isActive'] ?? false;
      });
    }
    if (!_isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This chat is closed.')),
      );
    }
  }

  void _listenForBan() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _db.child('rooms/${widget.roomId}/bannedUsers/${authProvider.userId}').onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _isBanned = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have been banned from this chat.')),
        );
        FirebaseMessaging.instance.sendMessage(
          to: authProvider.userId,
          data: {
            'title': 'Banned from Chat',
            'body': 'You have been banned from the chat: ${widget.roomId}',
          },
        );
        Navigator.pop(context);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    // Placeholder for connectivity check
    setState(() => _isOnline = true); // Assume online for now
  }

  Future<void> _sendMessage(String content, {String? audioUrl}) async {
    if (!_isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot send message: This chat is closed.')),
      );
      return;
    }
    if (_isBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot send message: You have been banned.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final message = {
      'content': content,
      if (audioUrl != null) 'audioUrl': audioUrl,
      'userId': authProvider.userId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    final batch = _db.batch();
    final messageRef = _db.child('messages/${widget.roomId}').push();
    batch.set(messageRef, message);
    await batch.commit();
    await ChatCache.cacheMessage(widget.roomId, message);
    await FirebaseFunctions.instance.httpsCallable('sendNotification').call({
      'roomId': widget.roomId,
      'message': content.length > 20 ? content.substring(0, 20) + '...' : content,
    });
    _scrollToBottom();
  }

  Future<void> _closeChat() async {
    await _db.child('rooms/${widget.roomId}/isActive').set(false);
    await _db.child('messages/${widget.roomId}').remove();
    setState(() {
      _isActive = false;
    });
    Navigator.pop(context); // Return to previous screen
  }

  Future<void> _banUser(String userId) async {
    await _db.child('rooms/${widget.roomId}/bannedUsers/$userId').set(true);
    // Remove the user's messages
    final snapshot = await _db.child('messages/${widget.roomId}').get();
    if (snapshot.exists) {
      final messages = Map<String, dynamic>.from(snapshot.value as Map);
      final batch = _db.batch();
      messages.forEach((messageId, message) {
        if (message['userId'] == userId) {
          batch.remove(_db.child('messages/${widget.roomId}/$messageId'));
        }
      });
      await batch.commit();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User has been banned from the chat.')),
    );
  }

  void _addFloatingReaction(String gifUrl) {
    if (_reactionCount >= 2) return;
    setState(() {
      _reactionCount++;
      final controller = AnimationController(vsync: this, duration: Duration(seconds: 3));
      _floatingReactions.add(FloatingReaction(gifUrl: gifUrl, controller: controller));
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
    if (_roomData == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_roomData!['name']),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _db.child('messages/${widget.roomId}').onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (!_isOnline) {
                      return FutureBuilder(
                        future: ChatCache.getCachedMessages(widget.roomId),
                        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> cacheSnapshot) {
                          if (!cacheSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (cacheSnapshot.hasError) {
                            return Center(child: Text('Error loading cached messages: ${cacheSnapshot.error}'));
                          }
                          return _buildMessageList(cacheSnapshot.data!);
                        },
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading messages: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final messages = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map? ?? {});
                    final messageList = messages.entries
                        .map((e) => {...e.value, 'id': e.key})
                        .toList();
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    return _buildMessageList(messageList);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
          ..._floatingReactions.map(_buildFloatingReaction),
        ],
      ),
      floatingActionButton: _isCreator
          ? Padding(
              padding: EdgeInsets.only(bottom: 16), // Add padding for better spacing
              child: FloatingActionButton(
                backgroundColor: Color(0xFF2196F3),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.close, color: Colors.red),
                          title: Text('Close Chat'),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Close Chat'),
                                content: Text('Are you sure you want to close this chat? All messages will be deleted.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _closeChat();
                                      Navigator.pop(context);
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.block, color: Colors.red),
                          title: Text('Manage Participants'),
                          onTap: () {
                            Navigator.pop(context);
                            // Placeholder for managing participants
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Manage participants feature coming soon!')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(Icons.settings),
              ),
            )
          : null,
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      cacheExtent: 1000.0, // Optimize performance by limiting cached items
      itemBuilder: (context, index) {
        final message = messages[index];
        return GestureDetector(
          onLongPress: () {
            if (_isCreator && message['userId'] != Provider.of<AuthProvider>(context, listen: false).userId) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Ban User'),
                  content: Text('Ban this user from the chat? Their messages will be removed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _banUser(message['userId']);
                        Navigator.pop(context);
                      },
                      child: Text('Ban'),
                    ),
                  ],
                ),
              );
            } else {
              _showReactionPicker(context, message['id']);
            }
          },
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
          LinkPreview(
            url: content,
            previewHeight: 100,
            borderRadius: 12,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)],
          ),
        ],
      );
    } else if (url != null) {
      return LinkPreview(
        url: url,
        previewHeight: 100,
        borderRadius: 12,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)],
      );
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width * 0.9, // Responsive width
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
            icon: Icon(
              _isRecording ? Icons.mic_off : Icons.mic,
              color: _isRecording ? Colors.red : Color(0xFF2196F3),
            ),
            onPressed: () async {
              if (_isRecording) return;
              final audioFile = await AudioMessage.record(context, (recording) {
                setState(() {
                  _isRecording = recording;
                });
              });
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
                  'userId': Provider.of<AuthProvider>(context, listen: false).userId,
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
    final slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, -1)).animate(reaction.controller);
    final opacityAnimation = Tween<double>(begin: 1, end: 0).animate(reaction.controller);
    final scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(reaction.controller);

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