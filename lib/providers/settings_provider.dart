import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'settings_provider.g.dart';

class Settings {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool readReceiptsEnabled;
  final bool typingIndicatorEnabled;
  final bool messagePreviewEnabled;
  final bool autoPlayGifsEnabled;
  final bool autoPlayVideosEnabled;
  final bool saveMediaEnabled;
  final bool dataSaverEnabled;

  const Settings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.readReceiptsEnabled = true,
    this.typingIndicatorEnabled = true,
    this.messagePreviewEnabled = true,
    this.autoPlayGifsEnabled = true,
    this.autoPlayVideosEnabled = true,
    this.saveMediaEnabled = true,
    this.dataSaverEnabled = false,
  });

  Settings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? readReceiptsEnabled,
    bool? typingIndicatorEnabled,
    bool? messagePreviewEnabled,
    bool? autoPlayGifsEnabled,
    bool? autoPlayVideosEnabled,
    bool? saveMediaEnabled,
    bool? dataSaverEnabled,
  }) {
    return Settings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
      typingIndicatorEnabled: typingIndicatorEnabled ?? this.typingIndicatorEnabled,
      messagePreviewEnabled: messagePreviewEnabled ?? this.messagePreviewEnabled,
      autoPlayGifsEnabled: autoPlayGifsEnabled ?? this.autoPlayGifsEnabled,
      autoPlayVideosEnabled: autoPlayVideosEnabled ?? this.autoPlayVideosEnabled,
      saveMediaEnabled: saveMediaEnabled ?? this.saveMediaEnabled,
      dataSaverEnabled: dataSaverEnabled ?? this.dataSaverEnabled,
    );
  }
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _readReceiptsKey = 'read_receipts_enabled';
  static const String _typingIndicatorKey = 'typing_indicator_enabled';
  static const String _messagePreviewKey = 'message_preview_enabled';
  static const String _autoPlayGifsKey = 'auto_play_gifs_enabled';
  static const String _autoPlayVideosKey = 'auto_play_videos_enabled';
  static const String _saveMediaKey = 'save_media_enabled';
  static const String _dataSaverKey = 'data_saver_enabled';
  
  late SharedPreferences _prefs;
  
  @override
  Settings build() {
    _loadSettings();
    return const Settings();
  }
  
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = _prefs.getBool(_notificationsKey) ?? true;
    final soundEnabled = _prefs.getBool(_soundKey) ?? true;
    final vibrationEnabled = _prefs.getBool(_vibrationKey) ?? true;
    final readReceiptsEnabled = _prefs.getBool(_readReceiptsKey) ?? true;
    final typingIndicatorEnabled = _prefs.getBool(_typingIndicatorKey) ?? true;
    final messagePreviewEnabled = _prefs.getBool(_messagePreviewKey) ?? true;
    final autoPlayGifsEnabled = _prefs.getBool(_autoPlayGifsKey) ?? true;
    final autoPlayVideosEnabled = _prefs.getBool(_autoPlayVideosKey) ?? true;
    final saveMediaEnabled = _prefs.getBool(_saveMediaKey) ?? true;
    final dataSaverEnabled = _prefs.getBool(_dataSaverKey) ?? false;
    
    state = Settings(
      notificationsEnabled: notificationsEnabled,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      readReceiptsEnabled: readReceiptsEnabled,
      typingIndicatorEnabled: typingIndicatorEnabled,
      messagePreviewEnabled: messagePreviewEnabled,
      autoPlayGifsEnabled: autoPlayGifsEnabled,
      autoPlayVideosEnabled: autoPlayVideosEnabled,
      saveMediaEnabled: saveMediaEnabled,
      dataSaverEnabled: dataSaverEnabled,
    );
  }
  
  Future<void> setNotificationsEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_notificationsKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'notifications',
      'value': value,
    });
    state = state.copyWith(notificationsEnabled: value);
  }
  
  Future<void> setSoundEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_soundKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'sound',
      'value': value,
    });
    state = state.copyWith(soundEnabled: value);
  }
  
  Future<void> setVibrationEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_vibrationKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'vibration',
      'value': value,
    });
    state = state.copyWith(vibrationEnabled: value);
  }
  
  Future<void> setReadReceiptsEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_readReceiptsKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'read_receipts',
      'value': value,
    });
    state = state.copyWith(readReceiptsEnabled: value);
  }
  
  Future<void> setTypingIndicatorEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_typingIndicatorKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'typing_indicator',
      'value': value,
    });
    state = state.copyWith(typingIndicatorEnabled: value);
  }
  
  Future<void> setMessagePreviewEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_messagePreviewKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'message_preview',
      'value': value,
    });
    state = state.copyWith(messagePreviewEnabled: value);
  }
  
  Future<void> setAutoPlayGifsEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_autoPlayGifsKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'auto_play_gifs',
      'value': value,
    });
    state = state.copyWith(autoPlayGifsEnabled: value);
  }
  
  Future<void> setAutoPlayVideosEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_autoPlayVideosKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'auto_play_videos',
      'value': value,
    });
    state = state.copyWith(autoPlayVideosEnabled: value);
  }
  
  Future<void> setSaveMediaEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_saveMediaKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'save_media',
      'value': value,
    });
    state = state.copyWith(saveMediaEnabled: value);
  }
  
  Future<void> setDataSaverEnabled(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    await _prefs.setBool(_dataSaverKey, value);
    await analytics.logEvent('setting_changed', parameters: {
      'setting': 'data_saver',
      'value': value,
    });
    state = state.copyWith(dataSaverEnabled: value);
  }
} 