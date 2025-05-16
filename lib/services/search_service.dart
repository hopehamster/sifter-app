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
      final results = await _database.searchUsers(query);
      await _analytics.logSearch(query);
      return results;
    } catch (e) {
      await _analytics.logError(
        error: 'search_users_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Search messages in a room
  Future<QuerySnapshot> searchMessages(String roomId, String query) async {
    try {
      final results = await _database.searchMessages(roomId, query);
      await _analytics.logSearch(query);
      return results;
    } catch (e) {
      await _analytics.logError(
        error: 'search_messages_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Search rooms
  Future<QuerySnapshot> searchRooms(String query) async {
    try {
      final results = await _database.rooms
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      await _analytics.logSearch(query);
      return results;
    } catch (e) {
      await _analytics.logError(
        error: 'search_rooms_error',
        errorMessage: e.toString(),
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
      await _analytics.logError(
        error: 'search_messages_by_type_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'search_messages_by_date_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'search_messages_by_sender_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'search_messages_with_media_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'search_messages_with_links_error',
        errorMessage: e.toString(),
      );
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
      await _analytics.logError(
        error: 'search_messages_with_mentions_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
} 