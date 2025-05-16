import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sifter/services/search_service.dart';

class SearchProvider with ChangeNotifier {
  final SearchService _searchService = SearchService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<QuerySnapshot> searchUsers(String query) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchUsers(query);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> searchMessages(String roomId, String query) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchMessages(roomId, query);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> searchRooms(String query) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchRooms(query);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> searchMessagesByType(String roomId, String type) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchMessagesByType(roomId, type);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> searchMessagesByDateRange(String roomId, DateTime start, DateTime end) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchMessagesByDateRange(roomId, start, end);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> searchMessagesBySender(String roomId, String senderId) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchMessagesBySender(roomId, senderId);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> searchMessagesWithMedia(String roomId) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchMessagesWithMedia(roomId);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> searchMessagesWithLinks(String roomId) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchMessagesWithLinks(roomId);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<QuerySnapshot> searchMessagesWithMentions(String roomId, String userId) async {
    _setLoading(true);
    try {
      final result = await _searchService.searchMessagesWithMentions(roomId, userId);
      _setError(null);
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
} 