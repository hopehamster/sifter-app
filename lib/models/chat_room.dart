import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

enum ChatRoomType {
  direct,
  group,
  channel,
}

enum ChatRoomRole {
  owner,
  admin,
  member,
}

@freezed
@JsonSerializable(explicitToJson: true)
class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    required String id,
    required String name,
    required ChatRoomType type,
    required List<String> memberIds,
    required String createdBy,
    @Default({}) Map<String, ChatRoomRole> memberRoles,
    String? photoUrl,
    String? description,
    @Default(false) bool isPrivate,
    @Default(false) bool isPinned,
    @Default({}) Map<String, bool> mutedBy,
    @Default({}) Map<String, bool> archivedBy,
    @Default({}) Map<String, DateTime> readBy,
    DateTime? lastMessageAt,
    String? lastMessageId,
    int? lastMessageTimestamp,
    String? lastMessageSenderId,
    String? lastMessage,
    String? lastMessageType,
    @Default({}) Map<String, dynamic> metadata,
    @Default([]) List<String> admins,
    @Default([]) List<String> bannedUsers,
    @Default(false) bool isPasswordProtected,
    String? password,
    @Default(100) int maxMembers,
    @Default([]) List<String> participants,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isGroup,
    bool? requireApproval,
  }) = _ChatRoom;

  // Private constructor needed by Freezed for getter implementations
  const ChatRoom._();

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);
}

extension ChatRoomX on ChatRoom {
  bool isDirectChat() => type == ChatRoomType.direct;
  bool isGroupChat() => type == ChatRoomType.group;
  bool isChannel() => type == ChatRoomType.channel;
  
  String getDisplayName(String currentUserId) {
    if (type == ChatRoomType.direct) {
      final otherMemberId = memberIds.firstWhere((id) => id != currentUserId);
      // You would typically get the user's name from a user service
      return 'User $otherMemberId';
    }
    return name;
  }

  bool isAdmin(String userId) => admins.contains(userId);
  bool isOwner(String userId) => createdBy == userId;
  bool isBanned(String userId) => bannedUsers.contains(userId);
  
  ChatRoomRole getMemberRole(String userId) {
    return memberRoles[userId] ?? ChatRoomRole.member;
  }

  bool canJoin(String userId) {
    return !isBanned(userId) && !memberIds.contains(userId);
  }

  bool canPromoteToAdmin(String userId) {
    return isOwner(userId);
  }

  bool canDemoteAdmin(String userId, String targetUserId) {
    if (isOwner(userId)) return true;
    if (isAdmin(userId)) {
      final targetRole = getMemberRole(targetUserId);
      return targetRole == ChatRoomRole.admin;
    }
    return false;
  }

  bool canBanUser(String userId, String targetUserId) {
    if (isOwner(userId)) return true;
    if (isAdmin(userId)) {
      final targetRole = getMemberRole(targetUserId);
      return targetRole != ChatRoomRole.owner && targetRole != ChatRoomRole.admin;
    }
    return false;
  }

  bool canUnbanUser(String userId) {
    return isOwner(userId) || isAdmin(userId);
  }

  bool canEditGroupInfo(String userId) {
    return isOwner(userId) || isAdmin(userId);
  }

  bool canDeleteGroup(String userId) {
    return isOwner(userId);
  }

  bool canLeaveGroup(String userId) {
    if (isOwner(userId)) return memberIds.length > 1;
    return true;
  }

  bool isMutedForUser(String userId) => mutedBy[userId] ?? false;
  bool isArchivedForUser(String userId) => archivedBy[userId] ?? false;
  
  bool hasUnreadMessages(String userId) {
    if (readBy[userId] == null || lastMessageAt == null) return false;
    return readBy[userId]!.isBefore(lastMessageAt!);
  }

  int get unreadCount {
    if (lastMessageAt == null) return 0;
    return readBy.values.where((timestamp) => 
      timestamp.isBefore(lastMessageAt!)
    ).length;
  }

  String get lastMessagePreview {
    if (lastMessageId == null) return 'No messages yet';
    return lastMessage ?? 'New message'; // Use actual message if available
  }

  DateTime? get lastMessageDate => lastMessageAt;
  
  String get lastMessageTime {
    if (lastMessageAt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(lastMessageAt!.year, lastMessageAt!.month, lastMessageAt!.day);

    if (messageDate == today) {
      return '${lastMessageAt!.hour.toString().padLeft(2, '0')}:${lastMessageAt!.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${lastMessageAt!.day.toString().padLeft(2, '0')}/${lastMessageAt!.month.toString().padLeft(2, '0')}/${lastMessageAt!.year}';
    }
  }
  
  // Getter for displayName used in chat_list.dart
  String? get displayName => name;
}

extension ChatRoomTypeExtension on ChatRoomType {
  String get displayName {
    switch (this) {
      case ChatRoomType.direct:
        return 'Direct Message';
      case ChatRoomType.group:
        return 'Group Chat';
      case ChatRoomType.channel:
        return 'Channel';
    }
  }

  bool get isDirect {
    return this == ChatRoomType.direct;
  }

  bool get isGroup {
    return this == ChatRoomType.group;
  }

  bool get isChannel {
    return this == ChatRoomType.channel;
  }
} 