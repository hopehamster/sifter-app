import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../providers/riverpod/auth_provider.dart';
import '../services/chat_cache.dart';
import '../widgets/audio_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input.dart';

final chatScreenProvider = StateNotifierProvider.family<ChatScreenNotifier, ChatScreenState, String>((ref, chatRoomId) {
  return ChatScreenNotifier(
    ref.read(chatServiceProvider),
    ref.read(userServiceProvider),
    ref.read(storageServiceProvider),
    chatRoomId,
  );
});

class ChatScreenState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isTyping;
  final Set<String> typingUsers;
  final bool isRecording;
  final bool isEmojiPickerVisible;
  final String? recordingPath;
  final bool isUploading;
  final double uploadProgress;

  ChatScreenState({
    this.messages = const [],
    this.isLoading = true,
    this.error,
    this.isTyping = false,
    this.typingUsers = const {},
    this.isRecording = false,
    this.isEmojiPickerVisible = false,
    this.recordingPath,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  ChatScreenState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isTyping,
    Set<String>? typingUsers,
    bool? isRecording,
    bool? isEmojiPickerVisible,
    String? recordingPath,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return ChatScreenState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTyping: isTyping ?? this.isTyping,
      typingUsers: typingUsers ?? this.typingUsers,
      isRecording: isRecording ?? this.isRecording,
      isEmojiPickerVisible: isEmojiPickerVisible ?? this.isEmojiPickerVisible,
      recordingPath: recordingPath ?? this.recordingPath,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class ChatScreenNotifier extends StateNotifier<ChatScreenState> {
  final ChatService _chatService;
  final UserService _userService;
  final StorageService _storageService;
  final String _chatRoomId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _typingTimer;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;

  ChatScreenNotifier(
    this._chatService,
    this._userService,
    this._storageService,
    this._chatRoomId,
  ) : super(ChatScreenState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _messagesSubscription = _chatService
          .streamMessages(_chatRoomId)
          .listen((messages) {
        state = state.copyWith(
          messages: messages,
          isLoading: false,
        );
      });

      _typingSubscription = _chatService
          .streamTypingUsers(_chatRoomId)
          .listen((typingUsers) {
        state = state.copyWith(
          typingUsers: typingUsers,
        );
      });
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> sendMessage(String content) async {
    try {
      await _chatService.sendMessage(
        _chatRoomId,
        content,
        MessageType.text,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendImage(File file) async {
    try {
      final path = 'chat_images/${_chatRoomId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final downloadUrl = await _storageService.uploadFile(
        file,
        path,
        metadata: {'contentType': 'image/jpeg'},
      );
      
      await _chatService.sendMessage(
        _chatRoomId,
        downloadUrl,
        MessageType.image,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendFile(File file) async {
    try {
      final path = 'chat_files/${_chatRoomId}/${DateTime.now().millisecondsSinceEpoch}';
      final downloadUrl = await _storageService.uploadFile(
        file,
        path,
        metadata: {'contentType': 'application/octet-stream'},
      );
      
      await _chatService.sendMessage(
        _chatRoomId,
        downloadUrl,
        MessageType.file,
        metadata: {
          'fileName': file.path.split('/').last,
          'fileSize': file.lengthSync().toString(),
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendAudio(File file) async {
    try {
      final path = 'chat_audio/${_chatRoomId}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      final downloadUrl = await _storageService.uploadFile(
        file,
        path,
        metadata: {'contentType': 'audio/m4a'},
      );
      
      await _chatService.sendMessage(
        _chatRoomId,
        downloadUrl,
        MessageType.audio,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendLocation(String location) async {
    try {
      await _chatService.sendMessage(
        _chatRoomId,
        location,
        MessageType.location,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendContact(Map<String, dynamic> contact) async {
    try {
      await _chatService.sendMessage(
        _chatRoomId,
        contact['phone'],
        MessageType.contact,
        metadata: contact,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setTyping(bool isTyping) {
    _chatService.setTyping(_chatRoomId, isTyping);
  }

  void toggleEmojiPicker() {
    state = state.copyWith(isEmojiPickerVisible: !state.isEmojiPickerVisible);
  }

  void onEmojiSelected(Emoji emoji) {
    _messageController.text += emoji.emoji;
  }

  void onTypingChanged(String text) {
    if (_typingTimer?.isActive ?? false) {
      _typingTimer!.cancel();
    }
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(isTyping: text.isNotEmpty);
    });
  }

  void startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start();
        state = state.copyWith(isRecording: true);
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to start recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      state = state.copyWith(
        isRecording: false,
        recordingPath: path,
      );

      if (path != null) {
        await _chatService.sendMediaMessage(
          _chatRoomId,
          _userService.currentUserId,
          path,
          MessageType.audio,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop recording: $e');
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

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
  final ScrollController _scrollController = ScrollController();
  bool _isVisible = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatScreenProvider(widget.chatRoom.id));
    final notifier = ref.read(chatScreenProvider(widget.chatRoom.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<User>(
          stream: ref.read(userServiceProvider).streamUser(
            widget.chatRoom.participants.firstWhere(
              (id) => id != ref.read(userServiceProvider).currentUserId,
            ),
          ),
          builder: (context, snapshot) {
            final user = snapshot.data;
            return Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: user?.photoUrl != null
                      ? CachedNetworkImageProvider(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(user?.initials ?? '?')
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.chatRoom.displayName),
                    if (user?.isOnline ?? false)
                      const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement voice call
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Text('Chat Info'),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Text('Mute Notifications'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text('Block User'),
              ),
            ],
            onSelected: (value) {
              // TODO: Handle menu actions
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.typingUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).cardColor,
              child: Text(
                '${state.typingUsers.length} ${state.typingUsers.length == 1 ? 'person' : 'people'} typing...',
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Expanded(
            child: VisibilityDetector(
              key: Key(widget.chatRoom.id),
              onVisibilityChanged: (info) {
                setState(() => _isVisible = info.visibleFraction > 0);
                if (_isVisible) {
                  notifier.setTyping(false);
                }
              },
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text(state.error!))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            return MessageBubble(
                              message: message,
                              isMe: message.senderId ==
                                  ref.read(userServiceProvider).currentUserId,
                              onTap: () {
                                // TODO: Handle message tap
                              },
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.reply),
                                        title: const Text('Reply'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Implement reply
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.copy),
                                        title: const Text('Copy'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Implement copy
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.edit),
                                        title: const Text('Edit'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Implement edit
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete),
                                        title: const Text('Delete'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Implement delete
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
          ChatInput(
            onSendMessage: notifier.sendMessage,
            onSendImage: notifier.sendImage,
            onSendFile: notifier.sendFile,
            onSendAudio: notifier.sendAudio,
            onSendLocation: notifier.sendLocation,
            onSendContact: notifier.sendContact,
            isTyping: state.isTyping,
            onTypingStarted: () => notifier.setTyping(true),
            onTypingStopped: () => notifier.setTyping(false),
          ),
        ],
      ),
    );
  }
}