import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ChatList extends ConsumerWidget {
  final List<ChatRoom> chatRooms;
  final Function(ChatRoom) onChatRoomTap;
  final Function(ChatRoom) onChatRoomLongPress;

  const ChatList({
    super.key,
    required this.chatRooms,
    required this.onChatRoomTap,
    required this.onChatRoomLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        return _ChatRoomTile(
          chatRoom: chatRoom,
          onTap: () => onChatRoomTap(chatRoom),
          onLongPress: () => onChatRoomLongPress(chatRoom),
        );
      },
    );
  }
}

class _ChatRoomTile extends ConsumerWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatRoomTile({
    required this.chatRoom,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userService = ref.read(userServiceProvider);
    final currentUserId = userService.currentUserId;
    
    // Check if there are unread messages for the current user
    final hasUnreadMessages = chatRoom.hasUnreadMessages(currentUserId);
    
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: _buildAvatar(ref, context),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chatRoom.displayName ?? chatRoom.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chatRoom.isPinned)
            const Icon(
              Icons.push_pin,
              size: 16,
              color: Colors.grey,
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (chatRoom.isMutedForUser(currentUserId))
            const Icon(
              Icons.volume_off,
              size: 16,
              color: Colors.grey,
            ),
          Expanded(
            child: Text(
              chatRoom.lastMessagePreview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnreadMessages
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chatRoom.lastMessageTime,
            style: TextStyle(
              fontSize: 12,
              color: hasUnreadMessages
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ),
          if (hasUnreadMessages)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                chatRoom.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(WidgetRef ref, BuildContext context) {
    final userService = ref.read(userServiceProvider);
    final currentUserId = userService.currentUserId;
    
    if (chatRoom.type == ChatRoomType.direct) {
      // Use memberIds for consistency, with fallback to participants
      final members = chatRoom.memberIds.isNotEmpty ? chatRoom.memberIds : chatRoom.participants;
      final otherUserId = members.firstWhere(
        (id) => id != currentUserId,
        orElse: () => members.isNotEmpty ? members[0] : '',
      );
      
      return StreamBuilder<AppUser>(
        stream: userService.streamUser(otherUserId),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user?.photoUrl != null
                    ? CachedNetworkImageProvider(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Text(user?.initials ?? '?')
                    : null,
              ),
              if (user?.isOnline ?? false)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        chatRoom.name.isNotEmpty ? chatRoom.name.characters.first.toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 