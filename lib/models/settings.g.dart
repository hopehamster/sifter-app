// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      darkMode: json['darkMode'] as bool? ?? false,
      notifications: json['notifications'] as bool? ?? true,
      sound: json['sound'] as bool? ?? true,
      vibration: json['vibration'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      readReceipts: json['readReceipts'] as bool? ?? false,
      typingIndicator: json['typingIndicator'] as bool? ?? false,
      enterToSend: json['enterToSend'] as bool? ?? false,
      mediaAutoDownload: json['mediaAutoDownload'] as bool? ?? true,
      locationSharing: json['locationSharing'] as bool? ?? false,
      customSettings:
          json['customSettings'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'darkMode': instance.darkMode,
      'notifications': instance.notifications,
      'sound': instance.sound,
      'vibration': instance.vibration,
      'language': instance.language,
      'readReceipts': instance.readReceipts,
      'typingIndicator': instance.typingIndicator,
      'enterToSend': instance.enterToSend,
      'mediaAutoDownload': instance.mediaAutoDownload,
      'locationSharing': instance.locationSharing,
      'customSettings': instance.customSettings,
    };
