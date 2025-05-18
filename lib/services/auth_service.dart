import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:sifter/utils/error_handler.dart';
import 'package:sifter/services/mock_auth_service.dart';

// Mock user class to replace Firebase User
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;

  User({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.isAnonymous = false,
  });
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final MockAuthService _mockAuth = MockAuthService();
  final AnalyticsService _analytics = AnalyticsService();

  // Auth state changes stream
  Stream<User?> authStateChanges() {
    return _mockAuth.authStateChanges.listenable().map((userId) {
      if (userId == null) return null;
      return User(uid: userId);
    });
  }
  
  // Dispose stream subscription if needed
  void disposeAuthStateChanges() {
    // Nothing to dispose in this implementation
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final userId = _mockAuth.currentUserId;
    if (userId == null) return null;
    
    final email = await _mockAuth.getCurrentUserEmail();
    return User(
      uid: userId,
      email: email,
    );
  }

  // Sign in with email and password
  Future<User> signInWithEmailPassword(String email, String password) async {
    try {
      final userId = await _mockAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logLogin(method: 'email');
      return User(
        uid: userId,
        email: email,
      );
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Email sign in error');
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign up with email and password
  Future<User> signUpWithEmailPassword(String email, String password) async {
    try {
      final userId = await _mockAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logSignUp(method: 'email');
      return User(
        uid: userId,
        email: email,
      );
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Email sign up error');
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with Google
  Future<User> signInWithGoogle() async {
    try {
      // Mock implementation - in a real app, we'd use Google Sign In
      final email = "google_${DateTime.now().millisecondsSinceEpoch}@example.com";
      final userId = await _mockAuth.createUserWithEmailAndPassword(
        email: email,
        password: "google_auth",
      );
      
      await _analytics.logLogin(method: 'google');
      return User(
        uid: userId,
        email: email,
        displayName: "Google User",
        photoURL: "https://ui-avatars.com/api/?name=Google+User",
      );
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Google sign in error');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _mockAuth.signOut();
      await _analytics.logEvent('user_signed_out');
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Sign out error');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Mock implementation - just log the event
      await _analytics.logEvent('password_reset_requested', parameters: {
        'email': email,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Password reset error');
      throw Exception('Failed to reset password: $e');
    }
  }

  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      // Mock implementation - just log the event
      await _analytics.logEvent('password_updated');
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Update password error');
      throw Exception('Failed to update password: $e');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      // Mock implementation - just log the event
      await _analytics.logEvent('email_updated', parameters: {
        'new_email': newEmail,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Update email error');
      throw Exception('Failed to update email: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      await _mockAuth.deleteAccount();
      await _analytics.logEvent('account_deleted');
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Delete account error');
      throw Exception('Failed to delete account: $e');
    }
  }

  // Get user token
  Future<String?> getToken() async {
    try {
      // Mock implementation - return user ID as token
      return _mockAuth.currentUserId;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Get token error');
      throw Exception('Failed to get token: $e');
    }
  }

  // Check if user is anonymous
  bool isAnonymous() {
    return false; // Mock implementation - all users are non-anonymous
  }
} 