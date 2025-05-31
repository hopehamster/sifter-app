// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageReactionImpl _$$MessageReactionImplFromJson(
        Map<String, dynamic> json) =>
    _$MessageReactionImpl(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      type: $enumDecode(_$ReactionTypeEnumMap, json['type']),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      giphyId: json['giphyId'] as String?,
      lottieAsset: json['lottieAsset'] as String?,
    );

Map<String, dynamic> _$$MessageReactionImplToJson(
        _$MessageReactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messageId': instance.messageId,
      'userId': instance.userId,
      'userDisplayName': instance.userDisplayName,
      'type': _$ReactionTypeEnumMap[instance.type]!,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'giphyId': instance.giphyId,
      'lottieAsset': instance.lottieAsset,
    };

const _$ReactionTypeEnumMap = {
  ReactionType.emoji: 'emoji',
  ReactionType.lottie: 'lottie',
  ReactionType.giphy: 'giphy',
};
