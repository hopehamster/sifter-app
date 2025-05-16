import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sifter/models/user.dart';
import 'package:sifter/services/user_service.dart';
import 'package:sifter/utils/error_handler.dart';

part 'user_provider.g.dart';

@riverpod
class UserNotifier extends _$UserNotifier {
  late final UserService _userService;
  
  @override
  FutureOr<AppUser?> build() {
    _userService = ref.watch(userServiceProvider);
    return _fetchCurrentUser();
  }
  
  Future<AppUser?> _fetchCurrentUser() async {
    try {
      return await _userService.getCurrentUser();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to fetch current user: ${e.toString()}');
    }
  }
  
  // Create or update user profile
  Future<AppUser> updateUserProfile(AppUser user) async {
    state = const AsyncValue.loading();
    
    try {
      final updatedUser = await _userService.updateUser(user);
      state = AsyncValue.data(updatedUser);
      return updatedUser;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }
  
  // Update user status
  Future<void> updateStatus(String status) async {
    if (state.value == null) {
      throw Exception('User must be logged in to update status');
    }
    
    try {
      final updatedUser = state.value!.copyWith(status: status);
      await _userService.updateUserStatus(updatedUser.id, status);
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to update status: ${e.toString()}');
    }
  }
  
  // Update user location
  Future<void> updateLocation(double latitude, double longitude) async {
    if (state.value == null) {
      throw Exception('User must be logged in to update location');
    }
    
    try {
      final updatedUser = state.value!.copyWith(
        location: UserLocation(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
        ),
      );
      
      await _userService.updateUserLocation(
        updatedUser.id, 
        latitude, 
        longitude,
      );
      
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to update location: ${e.toString()}');
    }
  }
  
  // Update user settings
  Future<void> updateSettings(UserSettings settings) async {
    if (state.value == null) {
      throw Exception('User must be logged in to update settings');
    }
    
    try {
      final updatedUser = state.value!.copyWith(settings: settings);
      await _userService.updateUserSettings(updatedUser.id, settings);
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to update settings: ${e.toString()}');
    }
  }
  
  // Fetch user by ID
  Future<AppUser> getUserById(String userId) async {
    try {
      return await _userService.getUserById(userId);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to fetch user by ID: ${e.toString()}');
    }
  }
  
  // Refresh current user
  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _fetchCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
    }
  }
}

// Provider for fetching a specific user by ID
@riverpod
Future<AppUser> userById(UserByIdRef ref, String userId) async {
  final userService = ref.watch(userServiceProvider);
  try {
    return await userService.getUserById(userId);
  } catch (e, stack) {
    ErrorHandler.logError(e, stack);
    throw Exception('Failed to fetch user by ID: ${e.toString()}');
  }
}

// List of nearby users
@riverpod
Future<List<AppUser>> nearbyUsers(NearbyUsersRef ref) async {
  final userService = ref.watch(userServiceProvider);
  try {
    final currentUser = await userService.getCurrentUser();
    if (currentUser == null || currentUser.location == null) {
      return [];
    }
    
    return await userService.getNearbyUsers(
      currentUser.location!.latitude,
      currentUser.location!.longitude,
      10, // 10 km radius
    );
  } catch (e, stack) {
    ErrorHandler.logError(e, stack);
    throw Exception('Failed to fetch nearby users: ${e.toString()}');
  }
}

// User Service Provider
@riverpod
UserService userService(UserServiceRef ref) {
  return UserService();
} 