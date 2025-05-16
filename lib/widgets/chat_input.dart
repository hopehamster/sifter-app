import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/message.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(File) onSendImage;
  final Function(File) onSendFile;
  final Function(File) onSendAudio;
  final Function(String) onSendLocation;
  final Function(Map<String, dynamic>) onSendContact;
  final Function(String, String)? onSendReply;
  final Message? replyToMessage;
  final VoidCallback? onCancelReply;
  final bool isTyping;
  final VoidCallback onTypingStarted;
  final VoidCallback onTypingStopped;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onSendFile,
    required this.onSendAudio,
    required this.onSendLocation,
    required this.onSendContact,
    this.onSendReply,
    this.replyToMessage,
    this.onCancelReply,
    this.isTyping = false,
    required this.onTypingStarted,
    required this.onTypingStopped,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  final _audioRecorder = Record();
  String? _recordingPath;
  final UserService _userService = UserService();
  AppUser? _replyUser;

  @override
  void initState() {
    super.initState();
    _loadReplyUserInfo();
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyToMessage?.id != oldWidget.replyToMessage?.id) {
      _loadReplyUserInfo();
    }
  }

  Future<void> _loadReplyUserInfo() async {
    if (widget.replyToMessage != null) {
      try {
        final user = await _userService.getUserById(widget.replyToMessage!.senderId);
        setState(() {
          _replyUser = user;
        });
      } catch (e) {
        debugPrint('Error loading reply user: $e');
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onSendImage(File(image.path));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null) {
      widget.onSendFile(File(result.files.single.path!));
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          path: _recordingPath!,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (_recordingPath != null) {
        widget.onSendAudio(File(_recordingPath!));
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    if (widget.replyToMessage != null && widget.onSendReply != null) {
      widget.onSendReply!(text, widget.replyToMessage!.id);
      
      if (widget.onCancelReply != null) {
        widget.onCancelReply!();
      }
    } else {
      widget.onSendMessage(text);
    }
    
    _textController.clear();
    widget.onTypingStopped();
  }

  void _handleTyping(String text) {
    if (text.isNotEmpty && !widget.isTyping) {
      widget.onTypingStarted();
    } else if (text.isEmpty && widget.isTyping) {
      widget.onTypingStopped();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyToMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(127),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.reply, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Reply to ${_replyUser?.displayName ?? 'User'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.replyToMessage!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancelReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),

        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _textController.text += emoji.emoji;
                _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.image),
                            title: const Text('Image'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: const Text('File'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickFile();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text('Location'),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSendLocation('Current Location');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Contact'),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSendContact({
                                'name': 'John Doe',
                                'phone': '+1234567890',
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions),
                  onPressed: () {
                    setState(() {
                      _showEmojiPicker = !_showEmojiPicker;
                    });
                    if (_showEmojiPicker) {
                      FocusScope.of(context).unfocus();
                    } else {
                      _focusNode.requestFocus();
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: widget.replyToMessage != null 
                          ? 'Reply to ${_replyUser?.displayName ?? 'message'}...' 
                          : 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(76),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _handleTyping,
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                _isRecording
                    ? IconButton(
                        icon: const Icon(Icons.stop, color: Colors.red),
                        onPressed: _stopRecording,
                      )
                    : _textController.text.trim().isEmpty
                        ? IconButton(
                            icon: const Icon(Icons.mic),
                            onPressed: _startRecording,
                          )
                        : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () => _handleSubmitted(_textController.text),
                            color: Theme.of(context).colorScheme.primary,
                          ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 