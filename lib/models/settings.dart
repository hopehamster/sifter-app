import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class Settings with _$Settings {
  const factory Settings({
    @Default(false) bool darkMode,
    @Default(true) bool notifications,
    @Default(true) bool sound,
    @Default(true) bool vibration,
    @Default('en') String language,
    @Default(false) bool readReceipts,
    @Default(false) bool typingIndicator,
    @Default(false) bool enterToSend,
    @Default(true) bool mediaAutoDownload,
    @Default(false) bool locationSharing,
    @Default({}) Map<String, dynamic> customSettings,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
} 