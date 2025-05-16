// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoom _$ChatRoomFromJson(Map<String, dynamic> json) => ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$ChatRoomTypeEnumMap, json['type']),
      memberIds:
          (json['memberIds'] as List<dynamic>).map((e) => e as String).toList(),
      createdBy: json['createdBy'] as String,
      memberRoles: (json['memberRoles'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, $enumDecode(_$ChatRoomRoleEnumMap, e)),
      ),
      photoUrl: json['photoUrl'] as String?,
      description: json['description'] as String?,
      isPrivate: json['isPrivate'] as bool,
      isPinned: json['isPinned'] as bool,
      mutedBy: Map<String, bool>.from(json['mutedBy'] as Map),
      archivedBy: Map<String, bool>.from(json['archivedBy'] as Map),
      readBy: (json['readBy'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, DateTime.parse(e as String)),
      ),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      lastMessageId: json['lastMessageId'] as String?,
      lastMessageTimestamp: (json['lastMessageTimestamp'] as num?)?.toInt(),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageType: json['lastMessageType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>,
      admins:
          (json['admins'] as List<dynamic>).map((e) => e as String).toList(),
      bannedUsers: (json['bannedUsers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isPasswordProtected: json['isPasswordProtected'] as bool,
      password: json['password'] as String?,
      maxMembers: (json['maxMembers'] as num).toInt(),
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isGroup: json['isGroup'] as bool?,
      requireApproval: json['requireApproval'] as bool?,
    );

Map<String, dynamic> _$ChatRoomToJson(ChatRoom instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ChatRoomTypeEnumMap[instance.type]!,
      'memberIds': instance.memberIds,
      'createdBy': instance.createdBy,
      'memberRoles': instance.memberRoles
          .map((k, e) => MapEntry(k, _$ChatRoomRoleEnumMap[e]!)),
      'photoUrl': instance.photoUrl,
      'description': instance.description,
      'isPrivate': instance.isPrivate,
      'isPinned': instance.isPinned,
      'mutedBy': instance.mutedBy,
      'archivedBy': instance.archivedBy,
      'readBy': instance.readBy.map((k, e) => MapEntry(k, e.toIso8601String())),
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'lastMessageId': instance.lastMessageId,
      'lastMessageTimestamp': instance.lastMessageTimestamp,
      'lastMessageSenderId': instance.lastMessageSenderId,
      'lastMessage': instance.lastMessage,
      'lastMessageType': instance.lastMessageType,
      'metadata': instance.metadata,
      'admins': instance.admins,
      'bannedUsers': instance.bannedUsers,
      'isPasswordProtected': instance.isPasswordProtected,
      'password': instance.password,
      'maxMembers': instance.maxMembers,
      'participants': instance.participants,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isGroup': instance.isGroup,
      'requireApproval': instance.requireApproval,
    };

const _$ChatRoomTypeEnumMap = {
  ChatRoomType.direct: 'direct',
  ChatRoomType.group: 'group',
  ChatRoomType.channel: 'channel',
};

const _$ChatRoomRoleEnumMap = {
  ChatRoomRole.owner: 'owner',
  ChatRoomRole.admin: 'admin',
  ChatRoomRole.member: 'member',
};

_$ChatRoomImpl _$$ChatRoomImplFromJson(Map<String, dynamic> json) =>
    _$ChatRoomImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$ChatRoomTypeEnumMap, json['type']),
      memberIds:
          (json['memberIds'] as List<dynamic>).map((e) => e as String).toList(),
      createdBy: json['createdBy'] as String,
      memberRoles: (json['memberRoles'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, $enumDecode(_$ChatRoomRoleEnumMap, e)),
          ) ??
          const {},
      photoUrl: json['photoUrl'] as String?,
      description: json['description'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      mutedBy: (json['mutedBy'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {},
      archivedBy: (json['archivedBy'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {},
      readBy: (json['readBy'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, DateTime.parse(e as String)),
          ) ??
          const {},
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      lastMessageId: json['lastMessageId'] as String?,
      lastMessageTimestamp: (json['lastMessageTimestamp'] as num?)?.toInt(),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageType: json['lastMessageType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      admins: (json['admins'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      bannedUsers: (json['bannedUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isPasswordProtected: json['isPasswordProtected'] as bool? ?? false,
      password: json['password'] as String?,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 100,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isGroup: json['isGroup'] as bool?,
      requireApproval: json['requireApproval'] as bool?,
    );

Map<String, dynamic> _$$ChatRoomImplToJson(_$ChatRoomImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ChatRoomTypeEnumMap[instance.type]!,
      'memberIds': instance.memberIds,
      'createdBy': instance.createdBy,
      'memberRoles': instance.memberRoles
          .map((k, e) => MapEntry(k, _$ChatRoomRoleEnumMap[e]!)),
      'photoUrl': instance.photoUrl,
      'description': instance.description,
      'isPrivate': instance.isPrivate,
      'isPinned': instance.isPinned,
      'mutedBy': instance.mutedBy,
      'archivedBy': instance.archivedBy,
      'readBy': instance.readBy.map((k, e) => MapEntry(k, e.toIso8601String())),
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'lastMessageId': instance.lastMessageId,
      'lastMessageTimestamp': instance.lastMessageTimestamp,
      'lastMessageSenderId': instance.lastMessageSenderId,
      'lastMessage': instance.lastMessage,
      'lastMessageType': instance.lastMessageType,
      'metadata': instance.metadata,
      'admins': instance.admins,
      'bannedUsers': instance.bannedUsers,
      'isPasswordProtected': instance.isPasswordProtected,
      'password': instance.password,
      'maxMembers': instance.maxMembers,
      'participants': instance.participants,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isGroup': instance.isGroup,
      'requireApproval': instance.requireApproval,
    };
