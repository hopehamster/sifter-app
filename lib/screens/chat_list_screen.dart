import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/chat_list.dart';
import 'chat_screen.dart';
import 'new_chat_dialog.dart';

final chatListScreenProvider = StateNotifierProvider<ChatListScreenNotifier, ChatListScreenState>((ref) {
  return ChatListScreenNotifier(
    ref.read(chatServiceProvider),
    ref.read(userServiceProvider),
  );
});

class ChatListScreenState {
  final List<ChatRoom> chatRooms;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final bool isSearching;

  ChatListScreenState({
    this.chatRooms = const [],
    this.isLoading = true,
    this.error,
    this.searchQuery,
    this.isSearching = false,
  });

  ChatListScreenState copyWith({
    List<ChatRoom>? chatRooms,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool? isSearching,
  }) {
    return ChatListScreenState(
      chatRooms: chatRooms ?? this.chatRooms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class ChatListScreenNotifier extends StateNotifier<ChatListScreenState> {
  final ChatService _chatService;
  final UserService _userService;
  StreamSubscription? _chatRoomsSubscription;

  ChatListScreenNotifier(
    this._chatService,
    this._userService,
  ) : super(ChatListScreenState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _chatRoomsSubscription = _chatService
          .streamUserChats(_userService.currentUserId)
          .listen((chatRooms) {
        state = state.copyWith(
          chatRooms: chatRooms,
          isLoading: false,
        );
      });
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      isSearching: query != null && query.isNotEmpty,
    );
  }

  List<ChatRoom> get filteredChatRooms {
    if (state.searchQuery == null || state.searchQuery!.isEmpty) {
      return state.chatRooms;
    }

    final query = state.searchQuery!.toLowerCase();
    return state.chatRooms.where((chatRoom) {
      return chatRoom.displayName.toLowerCase().contains(query) ||
          chatRoom.lastMessageContent.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> createNewChat(String userId) async {
    try {
      final chatRoom = await _chatService.createChatRoom(
        participants: [_userService.currentUserId, userId],
        type: ChatRoomType.direct,
      );
      // TODO: Navigate to chat screen
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      await _chatService.deleteChatRoom(chatRoomId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> archiveChatRoom(String chatRoomId) async {
    try {
      await _chatService.archiveChatRoom(chatRoomId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pinChatRoom(String chatRoomId) async {
    try {
      await _chatService.pinChatRoom(chatRoomId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> muteChatRoom(String chatRoomId) async {
    try {
      await _chatService.muteChatRoom(chatRoomId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    super.dispose();
  }
}

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleChatRoomTap(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: chatRoom),
      ),
    );
  }

  void _handleChatRoomLongPress(ChatRoom chatRoom) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.pin_drop),
            title: Text(chatRoom.isPinned ? 'Unpin Chat' : 'Pin Chat'),
            onTap: () {
              Navigator.pop(context);
              ref.read(chatListScreenProvider.notifier).pinChatRoom(chatRoom.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_off),
            title: Text(chatRoom.isMuted ? 'Unmute Chat' : 'Mute Chat'),
            onTap: () {
              Navigator.pop(context);
              ref.read(chatListScreenProvider.notifier).muteChatRoom(chatRoom.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive),
            title: Text(chatRoom.isArchived ? 'Unarchive Chat' : 'Archive Chat'),
            onTap: () {
              Navigator.pop(context);
              ref.read(chatListScreenProvider.notifier).archiveChatRoom(chatRoom.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Chat'),
                  content: const Text('Are you sure you want to delete this chat?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(chatListScreenProvider.notifier).deleteChatRoom(chatRoom.id);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => NewChatDialog(
        onUserSelected: (userId) {
          ref.read(chatListScreenProvider.notifier).createNewChat(userId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatListScreenProvider);
    final notifier = ref.read(chatListScreenProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: state.isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
                  border: InputBorder.none,
                ),
                onChanged: notifier.setSearchQuery,
              )
            : const Text('Chats'),
        actions: [
          IconButton(
            icon: Icon(state.isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (state.isSearching) {
                _searchController.clear();
                notifier.setSearchQuery(null);
              } else {
                notifier.setSearchQuery('');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showNewChatDialog,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : state.filteredChatRooms.isEmpty
                  ? Center(
                      child: Text(
                        state.isSearching
                            ? 'No chats found'
                            : 'No chats yet. Start a new conversation!',
                      ),
                    )
                  : ChatList(
                      chatRooms: state.filteredChatRooms,
                      onChatRoomTap: _handleChatRoomTap,
                      onChatRoomLongPress: _handleChatRoomLongPress,
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        child: const Icon(Icons.chat),
      ),
    );
  }
} 