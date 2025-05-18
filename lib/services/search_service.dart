import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:sifter/services/database_service.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final DatabaseService _database = DatabaseService();
  final AnalyticsService _analytics = AnalyticsService();

  // Search users
  Future<QuerySnapshot> searchUsers(String query) async {
    try {
      await _analytics.logEvent('search', parameters: {'query': query});
      
      final results = await _database.searchUsers(query);
      return results;
    } catch (e) {
      await _analytics.logEvent(
        'error',
        parameters: {
          'location': 'search_service.searchUsers',
          'error': e.toString()
        }
      );
      rethrow;
    }
  }

  // Search messages in a room
  Future<QuerySnapshot> searchMessages(String roomId, String query) async {
    try {
      final results = await _database.searchMessages(roomId, query);
      await _analytics.logSearch(searchTerm: query);
      return results;
    } catch (e) {
      await _analytics.logEvent(
        'error',
        parameters: {
          'location': 'search_service.searchMessages',
          'error': e.toString()
        }
      );
      rethrow;
    }
  }

  // Search rooms
  Future<QuerySnapshot> searchRooms(String query) async {
    try {
      await _analytics.logEvent('search', parameters: {'query': query});
      
      final results = await _database.rooms
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      await _analytics.logSearch(searchTerm: query);
      return results;
    } catch (e) {
      await _analytics.logEvent(
        'error',
        parameters: {
          'location': 'search_service.searchRooms',
          'error': e.toString()
        }
      );
      rethrow;
    }
  }

  // Search messages by type
  Future<QuerySnapshot> searchMessagesByType(String roomId, String type) async {
    try {
      final results = await _database.messages
          .where('roomId', isEqualTo: roomId)
          .where('type', isEqualTo: type)
          .orderBy('timestamp', descending: true)
          .get();

      await _analytics.logEvent('search_messages_by_type', parameters: {
        'room_id': roomId,
        'type': type,
      });

      return results;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchMessagesByType',
        'error': e.toString()
      });
      rethrow;
    }
  }

  // Search messages by date range
  Future<QuerySnapshot> searchMessagesByDateRange(
    String roomId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final results = await _database.messages
          .where('roomId', isEqualTo: roomId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .get();

      await _analytics.logEvent('search_messages_by_date', parameters: {
        'room_id': roomId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });

      return results;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchMessagesByDateRange',
        'error': e.toString()
      });
      rethrow;
    }
  }

  // Search messages by sender
  Future<QuerySnapshot> searchMessagesBySender(String roomId, String senderId) async {
    try {
      final results = await _database.messages
          .where('roomId', isEqualTo: roomId)
          .where('senderId', isEqualTo: senderId)
          .orderBy('timestamp', descending: true)
          .get();

      await _analytics.logEvent('search_messages_by_sender', parameters: {
        'room_id': roomId,
        'sender_id': senderId,
      });

      return results;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchMessagesBySender',
        'error': e.toString()
      });
      rethrow;
    }
  }

  // Search messages with media
  Future<QuerySnapshot> searchMessagesWithMedia(String roomId) async {
    try {
      final results = await _database.messages
          .where('roomId', isEqualTo: roomId)
          .where('type', whereIn: ['image', 'file'])
          .orderBy('timestamp', descending: true)
          .get();

      await _analytics.logEvent('search_messages_with_media', parameters: {
        'room_id': roomId,
      });

      return results;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchMessagesWithMedia',
        'error': e.toString()
      });
      rethrow;
    }
  }

  // Search messages with links
  Future<QuerySnapshot> searchMessagesWithLinks(String roomId) async {
    try {
      final results = await _database.messages
          .where('roomId', isEqualTo: roomId)
          .where('text', isGreaterThanOrEqualTo: 'http')
          .where('text', isLessThanOrEqualTo: 'http\uf8ff')
          .orderBy('timestamp', descending: true)
          .get();

      await _analytics.logEvent('search_messages_with_links', parameters: {
        'room_id': roomId,
      });

      return results;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchMessagesWithLinks',
        'error': e.toString()
      });
      rethrow;
    }
  }

  // Search messages with mentions
  Future<QuerySnapshot> searchMessagesWithMentions(String roomId, String userId) async {
    try {
      final results = await _database.messages
          .where('roomId', isEqualTo: roomId)
          .where('mentions', arrayContains: userId)
          .orderBy('timestamp', descending: true)
          .get();

      await _analytics.logEvent('search_messages_with_mentions', parameters: {
        'room_id': roomId,
        'user_id': userId,
      });

      return results;
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchMessagesWithMentions',
        'error': e.toString()
      });
      rethrow;
    }
  }

  // Additional search methods
  Future<List<dynamic>> searchNearby(double latitude, double longitude, double radius) async {
    try {
      // Search logic here
      await _analytics.logEvent('search_nearby', parameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius
      });
      return [];
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchNearby',
        'error': e.toString()
      });
      rethrow;
    }
  }

  Future<List<dynamic>> searchByTags(List<String> tags) async {
    try {
      // Search logic here
      await _analytics.logEvent('search_by_tags', parameters: {
        'tags': tags.join(',')
      });
      return [];
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchByTags',
        'error': e.toString()
      });
      rethrow;
    }
  }

  Future<List<dynamic>> searchByCategory(String category) async {
    try {
      // Search logic here
      await _analytics.logEvent('search_by_category', parameters: {
        'category': category
      });
      return [];
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.searchByCategory',
        'error': e.toString()
      });
      rethrow;
    }
  }

  Future<List<dynamic>> advancedSearch(Map<String, dynamic> filters) async {
    try {
      // Search logic here
      await _analytics.logEvent('advanced_search', parameters: filters);
      return [];
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.advancedSearch',
        'error': e.toString()
      });
      return [];
    }
  }

  Future<List<dynamic>> recentSearches() async {
    try {
      // Search logic here
      await _analytics.logEvent('recent_searches', parameters: {});
      return [];
    } catch (e) {
      await _analytics.logEvent('error', parameters: {
        'location': 'search_service.recentSearches',
        'error': e.toString()
      });
      return [];
    }
  }
} 