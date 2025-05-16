import 'package:flutter/material.dart';
import 'package:sifter/services/cache_service.dart';

class CacheProvider with ChangeNotifier {
  final CacheService _cacheService = CacheService();

  bool _isInitialized = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> init() async {
    try {
      await _cacheService.init();
      _isInitialized = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveData(String key, dynamic value) async {
    try {
      await _cacheService.saveData(key, value);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  T? getData<T>(String key) {
    try {
      return _cacheService.getData<T>(key);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> removeData(String key) async {
    try {
      await _cacheService.removeData(key);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    try {
      await _cacheService.clearCache();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool hasKey(String key) {
    return _cacheService.hasKey(key);
  }

  Set<String> getKeys() {
    return _cacheService.getKeys();
  }

  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    await saveData('user_preferences', preferences);
  }

  Map<String, dynamic>? getUserPreferences() {
    return getData<Map<String, dynamic>>('user_preferences');
  }

  Future<void> saveRoomData(String roomId, Map<String, dynamic> data) async {
    await saveData('room_$roomId', data);
  }

  Map<String, dynamic>? getRoomData(String roomId) {
    return getData<Map<String, dynamic>>('room_$roomId');
  }

  Future<void> saveMessageData(String messageId, Map<String, dynamic> data) async {
    await saveData('message_$messageId', data);
  }

  Map<String, dynamic>? getMessageData(String messageId) {
    return getData<Map<String, dynamic>>('message_$messageId');
  }

  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    await saveData('user_$userId', data);
  }

  Map<String, dynamic>? getUserData(String userId) {
    return getData<Map<String, dynamic>>('user_$userId');
  }

  Future<void> saveSearchHistory(List<String> searches) async {
    await saveData('search_history', searches);
  }

  List<String>? getSearchHistory() {
    return getData<List<String>>('search_history');
  }

  Future<void> clearSearchHistory() async {
    await removeData('search_history');
  }
} 