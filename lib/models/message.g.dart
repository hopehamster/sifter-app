// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as String,
      chatRoomId: json['chatRoomId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      metadata: json['metadata'] as Map<String, dynamic>?,
      reactions: (json['reactions'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      replyToMessageId: json['replyToMessageId'] as String?,
      status: $enumDecode(_$MessageStatusEnumMap, json['status']),
      timestamp: (json['timestamp'] as num).toInt(),
      edited: json['edited'] as bool,
      editedAt: (json['editedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'chatRoomId': instance.chatRoomId,
      'senderId': instance.senderId,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'metadata': instance.metadata,
      'reactions': instance.reactions,
      'replyToMessageId': instance.replyToMessageId,
      'status': _$MessageStatusEnumMap[instance.status]!,
      'timestamp': instance.timestamp,
      'edited': instance.edited,
      'editedAt': instance.editedAt,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.video: 'video',
  MessageType.audio: 'audio',
  MessageType.file: 'file',
  MessageType.location: 'location',
  MessageType.contact: 'contact',
  MessageType.gif: 'gif',
  MessageType.sticker: 'sticker',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
  MessageStatus.read: 'read',
  MessageStatus.failed: 'failed',
};
