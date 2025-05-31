import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling user preferences, app configuration, and theme management
class SettingsService {
  static const String _darkModeKey = 'dark_mode';
  static const String _notificationEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _locationPermissionKey = 'location_permission_granted';
  static const String _appLanguageKey = 'app_language';
  static const String _videoAdsEnabledKey = 'video_ads_enabled';
  static const String _firstRunKey = 'first_run';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Default values
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _locationPermissionGranted = false;
  String _appLanguage = 'en';
  bool _videoAdsEnabled = true;
  bool _isFirstRun = true;

  /// Initialize the settings service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    _isInitialized = true;
  }

  /// Load all settings from SharedPreferences
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _isDarkMode = _prefs!.getBool(_darkModeKey) ?? false;
    _notificationsEnabled = _prefs!.getBool(_notificationEnabledKey) ?? true;
    _soundEnabled = _prefs!.getBool(_soundEnabledKey) ?? true;
    _vibrationEnabled = _prefs!.getBool(_vibrationEnabledKey) ?? true;
    _locationPermissionGranted =
        _prefs!.getBool(_locationPermissionKey) ?? false;
    _appLanguage = _prefs!.getString(_appLanguageKey) ?? 'en';
    _videoAdsEnabled = _prefs!.getBool(_videoAdsEnabledKey) ?? true;
    _isFirstRun = _prefs!.getBool(_firstRunKey) ?? true;
  }

  /// Dark Mode Management
  bool get isDarkMode => _isDarkMode;

  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _prefs?.setBool(_darkModeKey, enabled);
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Notification Settings
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs?.setBool(_notificationEnabledKey, enabled);
  }

  bool get soundEnabled => _soundEnabled;

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs?.setBool(_soundEnabledKey, enabled);
  }

  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _prefs?.setBool(_vibrationEnabledKey, enabled);
  }

  /// Location Settings
  bool get locationPermissionGranted => _locationPermissionGranted;

  Future<void> setLocationPermissionGranted(bool granted) async {
    _locationPermissionGranted = granted;
    await _prefs?.setBool(_locationPermissionKey, granted);
  }

  /// App Configuration
  String get appLanguage => _appLanguage;

  Future<void> setAppLanguage(String language) async {
    _appLanguage = language;
    await _prefs?.setString(_appLanguageKey, language);
  }

  bool get videoAdsEnabled => _videoAdsEnabled;

  Future<void> setVideoAdsEnabled(bool enabled) async {
    _videoAdsEnabled = enabled;
    await _prefs?.setBool(_videoAdsEnabledKey, enabled);
  }

  bool get isFirstRun => _isFirstRun;

  Future<void> setFirstRunCompleted() async {
    _isFirstRun = false;
    await _prefs?.setBool(_firstRunKey, false);
  }

  /// User Preference Management
  Future<T?> getUserPreference<T>(String key) async {
    if (_prefs == null) return null;

    if (T == bool) {
      return _prefs!.getBool(key) as T?;
    } else if (T == int) {
      return _prefs!.getInt(key) as T?;
    } else if (T == double) {
      return _prefs!.getDouble(key) as T?;
    } else if (T == String) {
      return _prefs!.getString(key) as T?;
    } else if (T == List<String>) {
      return _prefs!.getStringList(key) as T?;
    }

    return null;
  }

  Future<void> setUserPreference<T>(String key, T value) async {
    if (_prefs == null) return;

    if (value is bool) {
      await _prefs!.setBool(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is String) {
      await _prefs!.setString(key, value);
    } else if (value is List<String>) {
      await _prefs!.setStringList(key, value);
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    if (_prefs == null) return;

    await _prefs!.clear();
    await _loadSettings();
  }

  /// Export settings as JSON for backup
  Map<String, dynamic> exportSettings() {
    return {
      'darkMode': _isDarkMode,
      'notificationsEnabled': _notificationsEnabled,
      'soundEnabled': _soundEnabled,
      'vibrationEnabled': _vibrationEnabled,
      'locationPermissionGranted': _locationPermissionGranted,
      'appLanguage': _appLanguage,
      'videoAdsEnabled': _videoAdsEnabled,
      'isFirstRun': _isFirstRun,
    };
  }

  /// Import settings from JSON backup
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (_prefs == null) return;

    if (settings.containsKey('darkMode')) {
      await setDarkMode(settings['darkMode'] ?? false);
    }
    if (settings.containsKey('notificationsEnabled')) {
      await setNotificationsEnabled(settings['notificationsEnabled'] ?? true);
    }
    if (settings.containsKey('soundEnabled')) {
      await setSoundEnabled(settings['soundEnabled'] ?? true);
    }
    if (settings.containsKey('vibrationEnabled')) {
      await setVibrationEnabled(settings['vibrationEnabled'] ?? true);
    }
    if (settings.containsKey('locationPermissionGranted')) {
      await setLocationPermissionGranted(
          settings['locationPermissionGranted'] ?? false);
    }
    if (settings.containsKey('appLanguage')) {
      await setAppLanguage(settings['appLanguage'] ?? 'en');
    }
    if (settings.containsKey('videoAdsEnabled')) {
      await setVideoAdsEnabled(settings['videoAdsEnabled'] ?? true);
    }
  }

  /// Get app configuration for different environments
  Map<String, dynamic> getAppConfiguration() {
    return {
      'apiTimeout': 30000, // 30 seconds
      'maxRetryAttempts': 3,
      'cacheExpiration': 300000, // 5 minutes
      'videoAdInterval': 300000, // 5 minutes
      'geofenceAccuracy': 10.0, // 10 meters
      'maxChatRooms': 50,
      'maxMessageLength': 1000,
      'supportedLanguages': ['en', 'es', 'fr', 'de'],
      'minPasswordLength': 8,
      'maxUsernameLength': 30,
      'sessionTimeout': 3600000, // 1 hour
    };
  }
}

/// Providers for SettingsService
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService();
  // Initialize on first access
  service.initialize();
  return service;
});

/// Provider for theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.themeMode;
});

/// Provider for dark mode state
final darkModeProvider = Provider<bool>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.isDarkMode;
});

/// Provider for notification settings
final notificationSettingsProvider = Provider<Map<String, bool>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return {
    'notifications': settingsService.notificationsEnabled,
    'sound': settingsService.soundEnabled,
    'vibration': settingsService.vibrationEnabled,
  };
});

/// Provider for app configuration
final appConfigProvider = Provider<Map<String, dynamic>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.getAppConfiguration();
});
