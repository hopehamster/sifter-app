import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sifter/services/analytics_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Connectivity status
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  // Queues for pending operations when offline
  final List<Map<String, dynamic>> _messageQueue = [];
  final List<Map<String, dynamic>> _roomQueue = [];
  final List<Map<String, dynamic>> _userQueue = [];

  final AnalyticsService _analytics = AnalyticsService();
  late SharedPreferences _prefs;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'sifter_cache.db');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Messages cache
        await db.execute(
          'CREATE TABLE messages(id TEXT PRIMARY KEY, data TEXT, roomId TEXT, timestamp INTEGER, status TEXT, syncStatus TEXT)',
        );
        
        // Rooms cache
        await db.execute(
          'CREATE TABLE rooms(id TEXT PRIMARY KEY, data TEXT, lastUpdated INTEGER, syncStatus TEXT)',
        );
        
        // User profiles cache
        await db.execute(
          'CREATE TABLE users(id TEXT PRIMARY KEY, data TEXT, lastUpdated INTEGER, syncStatus TEXT)',
        );
        
        // Create indexes for faster queries
        await db.execute('CREATE INDEX message_room_idx ON messages(roomId)');
        await db.execute('CREATE INDEX message_timestamp_idx ON messages(timestamp)');
        await db.execute('CREATE INDEX message_sync_idx ON messages(syncStatus)');
        await db.execute('CREATE INDEX room_updated_idx ON rooms(lastUpdated)');
        await db.execute('CREATE INDEX user_updated_idx ON users(lastUpdated)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new columns for sync status and conflict resolution in version 2
          await db.execute('ALTER TABLE messages ADD COLUMN syncStatus TEXT');
          await db.execute('ALTER TABLE rooms ADD COLUMN syncStatus TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN syncStatus TEXT');
          await db.execute('CREATE INDEX message_sync_idx ON messages(syncStatus)');
        }
      },
    );
  }

  // Initialize service and setup connectivity monitoring
  Future<void> init() async {
    await database;
    
    // Setup connectivity monitoring
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      // If we just came back online, sync pending changes
      if (wasOffline && _isOnline) {
        syncPendingChanges();
      }
    });
    
    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
  }

  // Initialize cache
  Future<void> initCache() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _analytics.logEvent('cache_initialized');
    } catch (e) {
      await _analytics.logError(
        error: 'cache_init_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Save data to cache
  Future<void> saveData(String key, dynamic value) async {
    try {
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is List<String>) {
        await _prefs.setStringList(key, value);
      } else {
        await _prefs.setString(key, jsonEncode(value));
      }

      await _analytics.logEvent('data_cached', parameters: {
        'key': key,
        'value_type': value.runtimeType.toString(),
      });
    } catch (e) {
      await _analytics.logError(
        error: 'save_data_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Get data from cache
  T? getData<T>(String key) {
    try {
      if (T == String) {
        return _prefs.getString(key) as T?;
      } else if (T == bool) {
        return _prefs.getBool(key) as T?;
      } else if (T == int) {
        return _prefs.getInt(key) as T?;
      } else if (T == double) {
        return _prefs.getDouble(key) as T?;
      } else if (T == List<String>) {
        return _prefs.getStringList(key) as T?;
      } else {
        final value = _prefs.getString(key);
        return value != null ? jsonDecode(value) as T : null;
      }
    } catch (e) {
      _analytics.logError(
        error: 'get_data_error',
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Remove data from cache
  Future<void> removeData(String key) async {
    try {
      await _prefs.remove(key);
      await _analytics.logEvent('data_removed_from_cache', parameters: {
        'key': key,
      });
    } catch (e) {
      await _analytics.logError(
        error: 'remove_data_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Clear all cache
  Future<void> clearCache() async {
    try {
      await _prefs.clear();
      await _analytics.logEvent('cache_cleared');
    } catch (e) {
      await _analytics.logError(
        error: 'clear_cache_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Check if key exists in cache
  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }

  // Get all keys in cache
  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  // Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await saveData('user_preferences', preferences);
      await _analytics.logEvent('user_preferences_saved');
    } catch (e) {
      await _analytics.logError(
        error: 'save_preferences_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Get user preferences
  Map<String, dynamic>? getUserPreferences() {
    return getData<Map<String, dynamic>>('user_preferences');
  }

  // Save room data
  Future<void> saveRoomData(String roomId, Map<String, dynamic> data) async {
    try {
      await saveData('room_$roomId', data);
      await _analytics.logEvent('room_data_cached', parameters: {
        'room_id': roomId,
      });
    } catch (e) {
      await _analytics.logError(
        error: 'save_room_data_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Get room data
  Map<String, dynamic>? getRoomData(String roomId) {
    return getData<Map<String, dynamic>>('room_$roomId');
  }

  // Save message data
  Future<void> saveMessageData(String messageId, Map<String, dynamic> data) async {
    try {
      await saveData('message_$messageId', data);
      await _analytics.logEvent('message_data_cached', parameters: {
        'message_id': messageId,
      });
    } catch (e) {
      await _analytics.logError(
        error: 'save_message_data_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Get message data
  Map<String, dynamic>? getMessageData(String messageId) {
    return getData<Map<String, dynamic>>('message_$messageId');
  }

  // Save user data
  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    try {
      await saveData('user_$userId', data);
      await _analytics.logEvent('user_data_cached', parameters: {
        'user_id': userId,
      });
    } catch (e) {
      await _analytics.logError(
        error: 'save_user_data_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Get user data
  Map<String, dynamic>? getUserData(String userId) {
    return getData<Map<String, dynamic>>('user_$userId');
  }

  // Save search history
  Future<void> saveSearchHistory(List<String> searches) async {
    try {
      await saveData('search_history', searches);
      await _analytics.logEvent('search_history_saved');
    } catch (e) {
      await _analytics.logError(
        error: 'save_search_history_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Get search history
  List<String>? getSearchHistory() {
    return getData<List<String>>('search_history');
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    try {
      await removeData('search_history');
      await _analytics.logEvent('search_history_cleared');
    } catch (e) {
      await _analytics.logError(
        error: 'clear_search_history_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Cache a message locally
  Future<void> cacheMessage(Map<String, dynamic> message) async {
    final db = await database;
    final data = jsonEncode(message);
    
    await db.insert(
      'messages',
      {
        'id': message['id'],
        'data': data,
        'roomId': message['roomId'],
        'timestamp': message['timestamp'] is Timestamp 
            ? message['timestamp'].millisecondsSinceEpoch 
            : DateTime.parse(message['timestamp'] as String).millisecondsSinceEpoch,
        'status': message['status'] ?? 'sent',
        'syncStatus': 'synced',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get cached messages for a room
  Future<List<Map<String, dynamic>>> getCachedMessages(String roomId, {int limit = 50, int offset = 0}) async {
    final db = await database;
    
    final results = await db.query(
      'messages',
      where: 'roomId = ?',
      whereArgs: [roomId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    
    return results.map((e) => {
      ...jsonDecode(e['data'] as String) as Map<String, dynamic>,
      'cachedAt': e['timestamp'],
      'syncStatus': e['syncStatus'],
    }).toList();
  }

  // Cache a room
  Future<void> cacheRoom(Map<String, dynamic> room) async {
    final db = await database;
    final data = jsonEncode(room);
    
    await db.insert(
      'rooms',
      {
        'id': room['id'],
        'data': data,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'syncStatus': 'synced',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get cached rooms
  Future<List<Map<String, dynamic>>> getCachedRooms() async {
    final db = await database;
    
    final results = await db.query(
      'rooms',
      orderBy: 'lastUpdated DESC',
    );
    
    return results.map((e) => {
      ...jsonDecode(e['data'] as String) as Map<String, dynamic>,
      'cachedAt': e['lastUpdated'],
      'syncStatus': e['syncStatus'],
    }).toList();
  }

  // Cache a user profile
  Future<void> cacheUser(Map<String, dynamic> user) async {
    final db = await database;
    final data = jsonEncode(user);
    
    await db.insert(
      'users',
      {
        'id': user['id'],
        'data': data,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'syncStatus': 'synced',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get a cached user profile
  Future<Map<String, dynamic>?> getCachedUser(String userId) async {
    final db = await database;
    
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (results.isEmpty) return null;
    
    return {
      ...jsonDecode(results.first['data'] as String) as Map<String, dynamic>,
      'cachedAt': results.first['lastUpdated'],
      'syncStatus': results.first['syncStatus'],
    };
  }
  
  // Cache last visited rooms for quick access
  Future<void> cacheRecentRooms(List<Map<String, dynamic>> rooms) async {
    for (final room in rooms) {
      await cacheRoom(room);
    }
  }
  
  // Create a message when offline
  Future<String> createOfflineMessage({
    required String roomId,
    required String text,
    required String userId,
    String? replyToId,
  }) async {
    final db = await database;
    
    // Generate a temporary ID that will be replaced when synced
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 5)}';
    
    final message = {
      'id': tempId,
      'roomId': roomId,
      'senderId': userId,
      'text': text,
      'type': 'text',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
      'replyToMessageId': replyToId,
    };
    
    // Save to local cache with pending status
    await db.insert(
      'messages',
      {
        'id': tempId,
        'data': jsonEncode(message),
        'roomId': roomId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
        'syncStatus': 'pending',
      },
    );
    
    // Add to sync queue
    _messageQueue.add(message);
    
    return tempId;
  }
  
  // Sync pending changes when back online
  Future<void> syncPendingChanges() async {
    if (!_isOnline) return;
    
    final db = await database;
    
    // Sync pending messages
    final pendingMessages = await db.query(
      'messages',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
    );
    
    for (final message in pendingMessages) {
      try {
        final messageData = jsonDecode(message['data'] as String) as Map<String, dynamic>;
        
        // Send to Firestore
        final docRef = await _firestore.collection('messages').add(messageData);
        
        // Update local cache with synced status and real ID
        await db.update(
          'messages',
          {
            'id': docRef.id,
            'syncStatus': 'synced',
            'status': 'sent',
          },
          where: 'id = ?',
          whereArgs: [message['id']],
        );
      } catch (e) {
        print('Error syncing message: $e');
        // Retry later
      }
    }
    
    // Sync other pending changes (rooms, user profiles, etc.)
    // Similar implementation for other tables...
    
    // Clear queues
    _messageQueue.clear();
    _roomQueue.clear();
    _userQueue.clear();
  }
  
  // Check if we have newer data locally than on the server
  Future<bool> hasNewerData(String documentId, String collection, int serverTimestamp) async {
    final db = await database;
    
    String tableName;
    switch (collection) {
      case 'messages':
        tableName = 'messages';
        break;
      case 'rooms':
        tableName = 'rooms';
        break;
      case 'users':
        tableName = 'users';
        break;
      default:
        return false;
    }
    
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [documentId],
    );
    
    if (results.isEmpty) return false;
    
    final localTimestamp = results.first['timestamp'] as int? ?? 
                          results.first['lastUpdated'] as int? ?? 0;
    
    return localTimestamp > serverTimestamp;
  }
  
  // Clear all caches
  Future<void> clearAllCaches() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('rooms');
    await db.delete('users');
  }
  
  // Clear cache for a specific room
  Future<void> clearRoomCache(String roomId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'roomId = ?',
      whereArgs: [roomId],
    );
    await db.delete(
      'rooms',
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }
  
  // Get all pending operations that need to be synced
  Future<Map<String, List<Map<String, dynamic>>>> getPendingOperations() async {
    final db = await database;
    
    final pendingMessages = await db.query(
      'messages',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
    );
    
    final pendingRooms = await db.query(
      'rooms',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
    );
    
    final pendingUsers = await db.query(
      'users',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
    );
    
    return {
      'messages': pendingMessages.map((e) => jsonDecode(e['data'] as String) as Map<String, dynamic>).toList(),
      'rooms': pendingRooms.map((e) => jsonDecode(e['data'] as String) as Map<String, dynamic>).toList(),
      'users': pendingUsers.map((e) => jsonDecode(e['data'] as String) as Map<String, dynamic>).toList(),
    };
  }
  
  // Resolves conflicts between local and server data
  Future<Map<String, dynamic>> resolveConflict(
    Map<String, dynamic> localData, 
    Map<String, dynamic> serverData,
    String entityType
  ) async {
    // Default strategy: server wins except for specific fields
    switch (entityType) {
      case 'message':
        // For messages, keep local edits if timestamp is newer
        if (localData['editedAt'] != null && serverData['editedAt'] != null) {
          final localTime = _getTimestamp(localData['editedAt']);
          final serverTime = _getTimestamp(serverData['editedAt']);
          
          if (localTime > serverTime) {
            return {
              ...serverData,
              'text': localData['text'],
              'editedAt': localData['editedAt'],
            };
          }
        }
        break;
        
      case 'user':
        // For user profiles, merge preferences but take server data for critical fields
        return {
          ...serverData,
          'preferences': {
            ...(serverData['preferences'] as Map<String, dynamic>? ?? {}),
            ...(localData['preferences'] as Map<String, dynamic>? ?? {}),
          },
        };
        
      case 'room':
        // For rooms, take server data but preserve local room settings
        if (localData['settings'] != null && serverData['settings'] != null) {
          return {
            ...serverData,
            'settings': {
              ...(serverData['settings'] as Map<String, dynamic>),
              // Only override specific user preferences
              'notifications': localData['settings']['notifications'],
              'theme': localData['settings']['theme'],
            },
          };
        }
        break;
    }
    
    // Default: server wins
    return serverData;
  }
  
  // Helper to get timestamp in milliseconds from various formats
  int _getTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.millisecondsSinceEpoch;
    } else if (timestamp is int) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.parse(timestamp).millisecondsSinceEpoch;
    }
    return 0;
  }
} 