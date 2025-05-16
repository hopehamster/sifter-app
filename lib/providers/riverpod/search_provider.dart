import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sifter/models/chat_room.dart';
import 'package:sifter/models/message.dart';
import 'package:sifter/models/user.dart';
import 'package:sifter/services/search_service.dart';
import 'package:sifter/utils/error_handler.dart';

part 'search_provider.g.dart';

// Search result class to hold different types of search results
class SearchResults {
  final List<ChatRoom> rooms;
  final List<AppUser> users;
  final List<Message> messages;
  
  SearchResults({
    this.rooms = const [],
    this.users = const [],
    this.messages = const [],
  });
  
  bool get isEmpty => rooms.isEmpty && users.isEmpty && messages.isEmpty;
  
  SearchResults copyWith({
    List<ChatRoom>? rooms,
    List<AppUser>? users,
    List<Message>? messages,
  }) {
    return SearchResults(
      rooms: rooms ?? this.rooms,
      users: users ?? this.users,
      messages: messages ?? this.messages,
    );
  }
}

@riverpod
class SearchNotifier extends _$SearchNotifier {
  late final SearchService _searchService;
  String _lastQuery = '';
  
  @override
  FutureOr<SearchResults> build() {
    _searchService = ref.watch(searchServiceProvider);
    return SearchResults();
  }
  
  // Search for rooms, messages, and users
  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data(SearchResults());
      return;
    }
    
    // Don't search for the same query twice
    if (query == _lastQuery) return;
    _lastQuery = query;
    
    state = const AsyncValue.loading();
    
    try {
      // Perform searching in parallel
      final results = await Future.wait([
        _searchService.searchRooms(query),
        _searchService.searchUsers(query),
        _searchService.searchMessages(query),
      ]);
      
      final searchResults = SearchResults(
        rooms: results[0] as List<ChatRoom>,
        users: results[1] as List<AppUser>,
        messages: results[2] as List<Message>,
      );
      
      state = AsyncValue.data(searchResults);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
    }
  }
  
  // Search for rooms only
  Future<void> searchRooms(String query) async {
    state = const AsyncValue.loading();
    
    try {
      final rooms = await _searchService.searchRooms(query);
      
      // Preserve other results if they exist
      final currentResults = state.value ?? SearchResults();
      state = AsyncValue.data(currentResults.copyWith(rooms: rooms));
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
    }
  }
  
  // Search for users only
  Future<void> searchUsers(String query) async {
    state = const AsyncValue.loading();
    
    try {
      final users = await _searchService.searchUsers(query);
      
      // Preserve other results if they exist
      final currentResults = state.value ?? SearchResults();
      state = AsyncValue.data(currentResults.copyWith(users: users));
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
    }
  }
  
  // Search for messages only
  Future<void> searchMessages(String query) async {
    state = const AsyncValue.loading();
    
    try {
      final messages = await _searchService.searchMessages(query);
      
      // Preserve other results if they exist
      final currentResults = state.value ?? SearchResults();
      state = AsyncValue.data(currentResults.copyWith(messages: messages));
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
    }
  }
  
  // Clear search results
  void clearSearch() {
    _lastQuery = '';
    state = const AsyncValue.data(SearchResults());
  }
}

// Search history provider
@riverpod
class SearchHistoryNotifier extends _$SearchHistoryNotifier {
  late final SearchService _searchService;
  
  @override
  FutureOr<List<String>> build() {
    _searchService = ref.watch(searchServiceProvider);
    return _fetchSearchHistory();
  }
  
  Future<List<String>> _fetchSearchHistory() async {
    try {
      return await _searchService.getSearchHistory();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to fetch search history: ${e.toString()}');
    }
  }
  
  // Add a search query to history
  Future<void> addToHistory(String query) async {
    try {
      await _searchService.addToSearchHistory(query);
      
      // Update local state
      final currentHistory = state.value ?? [];
      if (!currentHistory.contains(query)) {
        state = AsyncValue.data([query, ...currentHistory]);
      }
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to add to search history: ${e.toString()}');
    }
  }
  
  // Clear search history
  Future<void> clearHistory() async {
    try {
      await _searchService.clearSearchHistory();
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to clear search history: ${e.toString()}');
    }
  }
}

// Search Service Provider
@riverpod
SearchService searchService(SearchServiceRef ref) {
  return SearchService();
} 