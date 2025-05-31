// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatRoomImpl _$$ChatRoomImplFromJson(Map<String, dynamic> json) =>
    _$ChatRoomImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusInMeters: (json['radiusInMeters'] as num).toDouble(),
      isPasswordProtected: json['isPasswordProtected'] as bool? ?? false,
      password: json['password'] as String?,
      isNsfw: json['isNsfw'] as bool? ?? false,
      allowAnonymous: json['allowAnonymous'] as bool? ?? false,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 50,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      participantIds: (json['participantIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      bannedUserIds: (json['bannedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      isActive: json['isActive'] as bool? ?? true,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      userRoles: (json['userRoles'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
    );

Map<String, dynamic> _$$ChatRoomImplToJson(_$ChatRoomImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'creatorId': instance.creatorId,
      'creatorName': instance.creatorName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radiusInMeters': instance.radiusInMeters,
      'isPasswordProtected': instance.isPasswordProtected,
      'password': instance.password,
      'isNsfw': instance.isNsfw,
      'allowAnonymous': instance.allowAnonymous,
      'maxMembers': instance.maxMembers,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'participantIds': instance.participantIds,
      'bannedUserIds': instance.bannedUserIds,
      'isActive': instance.isActive,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'userRoles': instance.userRoles,
    };
