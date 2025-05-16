import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/settings_service.dart';
import '../services/location_service.dart';
import '../services/message_service.dart';
import '../services/room_service.dart';
import '../services/search_service.dart';
import '../services/cache_service.dart';

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<auth.User?>>((ref) {
  return AuthNotifier();
});

// User Provider
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<AppUser?>>((ref) {
  return UserNotifier();
});

// Chat Provider
final chatProvider = StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatRoom>>>((ref) {
  return ChatNotifier();
});

// Settings Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<Settings>>((ref) {
  return SettingsNotifier();
});

// Location Provider
final locationProvider = StateNotifierProvider<LocationNotifier, AsyncValue<LocationData>>((ref) {
  return LocationNotifier();
});

// Message Provider
final messageProvider = StateNotifierProvider<MessageNotifier, AsyncValue<List<Message>>>((ref) {
  return MessageNotifier();
});

// Room Provider
final roomProvider = StateNotifierProvider<RoomNotifier, AsyncValue<ChatRoom?>>((ref) {
  return RoomNotifier();
});

// Search Provider
final searchProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<dynamic>>>((ref) {
  return SearchNotifier();
});

// Cache Provider
final cacheProvider = StateNotifierProvider<CacheNotifier, AsyncValue<void>>((ref) {
  return CacheNotifier();
});

// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Message stream provider that filters out messages from blocked users
final filteredMessagesProvider = StreamProvider.family<List<Message>, String>((ref, roomId) {
  final chatService = ref.watch(chatServiceProvider);
  final currentUser = ref.watch(userProvider).value;
  
  if (currentUser == null) {
    return Stream.value([]); // Empty stream if not logged in
  }
  
  return chatService.streamMessagesFiltered(roomId, currentUser.id);
});

// Chat room stream provider that filters out rooms with blocked users for direct messages
final filteredChatRoomsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final currentUser = ref.watch(userProvider).value;
  
  if (currentUser == null) {
    return Stream.value([]); // Empty stream if not logged in
  }
  
  return chatService.streamChatRoomsFiltered(currentUser.id);
});

// Provider to check if a user is blocked
final isUserBlockedProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final userService = ref.watch(userServiceProvider);
  final currentUser = ref.watch(userProvider).value;
  
  if (currentUser == null) {
    return false;
  }
  
  return userService.isUserBlocked(currentUser.id, userId);
});

// Provider to check if a user is muted
final isUserMutedProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final userService = ref.watch(userServiceProvider);
  final currentUser = ref.watch(userProvider).value;
  
  if (currentUser == null) {
    return false;
  }
  
  return userService.isUserMuted(currentUser.id, userId);
}); 