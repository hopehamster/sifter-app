import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import 'package:sifter/services/analytics_service.dart';

class SettingsProvider with ChangeNotifier {
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
  final AnalyticsService _analytics = AnalyticsService();
  
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _readReceiptsEnabled = true;
  bool _typingIndicatorEnabled = true;
  bool _messagePreviewEnabled = true;
  bool _autoPlayGifsEnabled = true;
  bool _autoPlayVideosEnabled = true;
  bool _saveMediaEnabled = true;
  bool _dataSaverEnabled = false;
  
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get readReceiptsEnabled => _readReceiptsEnabled;
  bool get typingIndicatorEnabled => _typingIndicatorEnabled;
  bool get messagePreviewEnabled => _messagePreviewEnabled;
  bool get autoPlayGifsEnabled => _autoPlayGifsEnabled;
  bool get autoPlayVideosEnabled => _autoPlayVideosEnabled;
  bool get saveMediaEnabled => _saveMediaEnabled;
  bool get dataSaverEnabled => _dataSaverEnabled;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = _prefs.getBool(_notificationsKey) ?? true;
    _soundEnabled = _prefs.getBool(_soundKey) ?? true;
    _vibrationEnabled = _prefs.getBool(_vibrationKey) ?? true;
    _readReceiptsEnabled = _prefs.getBool(_readReceiptsKey) ?? true;
    _typingIndicatorEnabled = _prefs.getBool(_typingIndicatorKey) ?? true;
    _messagePreviewEnabled = _prefs.getBool(_messagePreviewKey) ?? true;
    _autoPlayGifsEnabled = _prefs.getBool(_autoPlayGifsKey) ?? true;
    _autoPlayVideosEnabled = _prefs.getBool(_autoPlayVideosKey) ?? true;
    _saveMediaEnabled = _prefs.getBool(_saveMediaKey) ?? true;
    _dataSaverEnabled = _prefs.getBool(_dataSaverKey) ?? false;
    notifyListeners();
  }
  
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool(_notificationsKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'notifications',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool(_soundKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'sound',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _prefs.setBool(_vibrationKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'vibration',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setReadReceiptsEnabled(bool value) async {
    _readReceiptsEnabled = value;
    await _prefs.setBool(_readReceiptsKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'read_receipts',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setTypingIndicatorEnabled(bool value) async {
    _typingIndicatorEnabled = value;
    await _prefs.setBool(_typingIndicatorKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'typing_indicator',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setMessagePreviewEnabled(bool value) async {
    _messagePreviewEnabled = value;
    await _prefs.setBool(_messagePreviewKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'message_preview',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setAutoPlayGifsEnabled(bool value) async {
    _autoPlayGifsEnabled = value;
    await _prefs.setBool(_autoPlayGifsKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'auto_play_gifs',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setAutoPlayVideosEnabled(bool value) async {
    _autoPlayVideosEnabled = value;
    await _prefs.setBool(_autoPlayVideosKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'auto_play_videos',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setSaveMediaEnabled(bool value) async {
    _saveMediaEnabled = value;
    await _prefs.setBool(_saveMediaKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'save_media',
      'value': value,
    });
    notifyListeners();
  }
  
  Future<void> setDataSaverEnabled(bool value) async {
    _dataSaverEnabled = value;
    await _prefs.setBool(_dataSaverKey, value);
    await _analytics.logEvent('setting_changed', parameters: {
      'setting': 'data_saver',
      'value': value,
    });
    notifyListeners();
  }
} 