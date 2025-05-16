import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../models/settings.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import '../services/location_service.dart';
import '../services/message_service.dart';
import '../services/room_service.dart';
import '../services/search_service.dart';
import '../services/cache_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier() : _authService = AuthService(), super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _authService.currentUser;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signIn(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final UserService _userService;

  UserNotifier() : _userService = UserService(), super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _userService.currentUser;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _userService.updateUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final ChatService _chatService;

  ChatNotifier() : _chatService = ChatService(), super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final rooms = await _chatService.getChatRooms();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createChatRoom(ChatRoom room) async {
    try {
      await _chatService.createChatRoom(room);
      final rooms = await _chatService.getChatRooms();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class SettingsNotifier extends StateNotifier<AsyncValue<Settings>> {
  final SettingsService _settingsService;

  SettingsNotifier() : _settingsService = SettingsService(), super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final settings = await _settingsService.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(Settings settings) async {
    try {
      await _settingsService.updateSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class MessageNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final MessageService _messageService;

  MessageNotifier() : _messageService = MessageService(), super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final messages = await _messageService.getMessages();
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      await _messageService.sendMessage(message);
      final messages = await _messageService.getMessages();
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
} 