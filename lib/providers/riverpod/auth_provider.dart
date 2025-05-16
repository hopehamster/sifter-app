import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sifter/models/user.dart';
import 'package:sifter/services/auth_service.dart';
import 'package:sifter/services/user_service.dart';
import 'package:sifter/utils/error_handler.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthService _authService;
  late final UserService _userService;
  
  @override
  FutureOr<User?> build() {
    _authService = ref.watch(authServiceProvider);
    _userService = ref.watch(userServiceProvider);
    
    // Listen to auth state changes
    ref.onDispose(() {
      _authService.disposeAuthStateChanges();
    });
    
    return _authService.getCurrentUser();
  }
  
  // Sign in with email and password
  Future<User> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.signInWithEmailPassword(email, password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }
  
  // Sign up with email and password
  Future<User> signUpWithEmailPassword(String email, String password, String username) async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.signUpWithEmailPassword(email, password);
      
      // Create user profile
      await _userService.createUserProfile(
        AppUser(
          id: user.uid,
          username: username,
          email: email,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
        ),
      );
      
      state = AsyncValue.data(user);
      return user;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }
  
  // Sign in with Google
  Future<User> signInWithGoogle() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.signInWithGoogle();
      
      // Check if user profile exists, if not create one
      final userExists = await _userService.checkUserExists(user.uid);
      if (!userExists) {
        await _userService.createUserProfile(
          AppUser(
            id: user.uid,
            username: user.displayName ?? 'User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastSeen: DateTime.now(),
          ),
        );
      }
      
      state = AsyncValue.data(user);
      return user;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }
  
  // Sign in with Apple
  Future<User> signInWithApple() async {
    state = const AsyncValue.loading();
    
    try {
      // For now, just a placeholder since AuthService doesn't have Apple sign-in yet
      // This should be implemented in the auth_service.dart file
      throw Exception('Apple Sign-In not implemented yet');
      
      // When implemented, it would look similar to Google sign-in:
      // final user = await _authService.signInWithApple();
      // state = AsyncValue.data(user);
      // return user;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      state = AsyncError(e, stack);
      throw Exception('Failed to sign in with Apple: ${e.toString()}');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }
  
  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      await _authService.updatePassword(currentPassword, newPassword);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }
  
  // Update email
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      await _authService.updateEmail(newEmail, password);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }
  
  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      await _authService.deleteAccount(password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}

// Auth Service Provider
@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

// Stream of auth state changes
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges();
} 