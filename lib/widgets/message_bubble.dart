import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/message_service.dart';
import 'reaction_widget.dart';
import '../providers/app_providers.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onTap,
    this.onLongPress,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == MessageType.audio) {
      _initAudioPlayer();
    } else if (widget.message.type == MessageType.video &&
        widget.message.content.contains('youtube.com')) {
      _initYoutubePlayer();
    }
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() => _position = p);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  void _initYoutubePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.message.content);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    }
  }

  Future<void> _playAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.message.content));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    final String currentUserId = currentUser.value?.id ?? '';
    
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isMe) ...[
                  StreamBuilder<User>(
                    stream: ref.read(userServiceProvider).streamUser(widget.message.senderId),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return CircleAvatar(
                        radius: 16,
                        backgroundImage: user?.photoUrl != null
                            ? CachedNetworkImageProvider(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(user?.initials ?? '?')
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(),
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 8),
                  _buildMessageStatus(),
                ],
              ],
            ),
          ),
          if (widget.message.hasReactions)
            Padding(
              padding: EdgeInsets.only(
                left: widget.isMe ? 0 : 40, 
                right: widget.isMe ? 40 : 0,
                bottom: 8
              ),
              child: ReactionWidget(
                message: widget.message,
                currentUserId: currentUserId,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.isMe ? Colors.white : null,
          ),
        );

      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: widget.message.content,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );

      case MessageType.video:
        if (widget.message.content.contains('youtube.com')) {
          return VisibilityDetector(
            key: Key(widget.message.id),
            onVisibilityChanged: (info) {
              if (info.visibleFraction == 0) {
                _youtubeController?.pause();
              }
            },
            child: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: true,
              progressColors: const ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
            ),
          );
        }
        return const Icon(Icons.video_library);

      case MessageType.audio:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _playAudio,
                ),
                const SizedBox(width: 8),
                Text(_formatDuration(_position)),
                const SizedBox(width: 8),
                Text(_formatDuration(_duration)),
              ],
            ),
            Slider(
              value: _position.inSeconds.toDouble(),
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) {
                _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
          ],
        );

      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.message.metadata?['fileName'] ?? 'File',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

      case MessageType.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.message.metadata?['address'] ?? 'Location',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

      case MessageType.contact:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.message.metadata?['name'] ?? 'Contact',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

      case MessageType.gif:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: widget.message.content,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );

      case MessageType.sticker:
        return CachedNetworkImage(
          imageUrl: widget.message.content,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
    }
  }

  Widget _buildMessageStatus() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.message.edited)
          const Text(
            'edited',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        Icon(
          widget.message.status == MessageStatus.read
              ? Icons.done_all
              : widget.message.status == MessageStatus.delivered
                  ? Icons.done_all
                  : Icons.done,
          size: 16,
          color: widget.message.status == MessageStatus.read
              ? Colors.blue
              : Colors.grey,
        ),
      ],
    );
  }
} 