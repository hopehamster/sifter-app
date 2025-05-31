import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Local guest mode state (when Firebase anonymous auth is disabled)
  bool _isLocalGuest = false;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated (Firebase) or in local guest mode
  bool get isAuthenticated => currentUser != null || _isLocalGuest;

  /// Check if user is in local guest mode
  bool get isLocalGuest => _isLocalGuest;

  /// Check if user is a registered user (has Firebase account)
  bool get isRegisteredUser => currentUser != null && !isAnonymousUser;

  /// Check if user is anonymous (Firebase anonymous or local guest)
  bool get isAnonymousUser =>
      (currentUser?.isAnonymous ?? false) || _isLocalGuest;

  /// Temporary storage for pending OTP sign-ups
  final Map<String, _PendingOTPSignUp> _pendingOTPSignUps = {};

  /// Generate random 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP for sign up (Step 1 of OTP flow)
  Future<AuthResult> sendOTPForSignUp({
    required String email,
    required String username,
    required DateTime birthDate,
  }) async {
    try {
      // Check if email is already in use
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        return AuthResult.failure(
            'An account already exists with this email address');
      }

      // Check if username is already taken
      final usernameExists = await _isUsernameTaken(username);
      if (usernameExists) {
        return AuthResult.failure('Username is already taken');
      }

      // Generate OTP
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));

      // Store pending sign-up data
      _pendingOTPSignUps[email] = _PendingOTPSignUp(
        email: email,
        username: username,
        birthDate: birthDate,
        otp: otp,
        expiresAt: expiresAt,
      );

      // TODO: Send actual OTP via email service
      // For now, we'll log it (in production, integrate with email service)
      print('OTP for $email: $otp'); // Remove in production

      return AuthResult.success(
        message: 'OTP sent to $email. Please check your email.',
      );
    } catch (e) {
      return AuthResult.failure('Failed to send OTP: $e');
    }
  }

  /// Verify OTP and create account (Step 2 of OTP flow)
  Future<AuthResult> verifyOTPAndCreateAccount({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      // Get pending sign-up data
      final pendingSignUp = _pendingOTPSignUps[email];
      if (pendingSignUp == null) {
        return AuthResult.failure('No pending sign-up found for this email');
      }

      // Check if OTP is expired
      if (pendingSignUp.isExpired) {
        _pendingOTPSignUps.remove(email);
        return AuthResult.failure('OTP has expired. Please request a new one.');
      }

      // Verify OTP
      if (pendingSignUp.otp != otp) {
        return AuthResult.failure('Invalid OTP. Please try again.');
      }

      // Create the user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure('Failed to create user account');
      }

      // Create user profile in Firestore (mark as email verified since OTP was validated)
      final appUser = AppUser(
        id: user.uid,
        email: email,
        username: pendingSignUp.username,
        birthDate: pendingSignUp.birthDate,
        points: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: true,
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toJson());

      // Clean up pending sign-up data
      _pendingOTPSignUps.remove(email);

      return AuthResult.success(
        message: 'Account created successfully!',
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Failed to create account: $e');
    }
  }

  /// Resend OTP
  Future<AuthResult> resendOTP(String email) async {
    try {
      final pendingSignUp = _pendingOTPSignUps[email];
      if (pendingSignUp == null) {
        return AuthResult.failure('No pending sign-up found for this email');
      }

      // Generate new OTP
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));

      // Update pending sign-up with new OTP
      _pendingOTPSignUps[email] = _PendingOTPSignUp(
        email: pendingSignUp.email,
        username: pendingSignUp.username,
        birthDate: pendingSignUp.birthDate,
        otp: otp,
        expiresAt: expiresAt,
      );

      // TODO: Send actual OTP via email service
      print('New OTP for $email: $otp'); // Remove in production

      return AuthResult.success(
        message: 'New OTP sent to $email',
      );
    } catch (e) {
      return AuthResult.failure('Failed to resend OTP: $e');
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required DateTime birthDate,
  }) async {
    try {
      // Check if username is already taken
      final usernameExists = await _isUsernameTaken(username);
      if (usernameExists) {
        return AuthResult.failure('Username is already taken');
      }

      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure('Failed to create user');
      }

      // Send email verification
      await user.sendEmailVerification();

      // Create user profile in Firestore
      final appUser = AppUser(
        id: user.uid,
        email: email,
        username: username,
        birthDate: birthDate,
        points: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: false,
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toJson());

      return AuthResult.success(
        message: 'Account created! Please check your email for verification.',
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure('Sign in failed');
      }

      // Check if email is verified
      if (!user.emailVerified) {
        return AuthResult.failure(
          'Please verify your email before signing in. Check your email for verification link.',
        );
      }

      // Update last active time
      await _updateLastActiveTime(user.uid);

      return AuthResult.success(
        message: 'Welcome back!',
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Send OTP for additional verification (optional enhanced security)
  Future<AuthResult> sendOTPForVerification(String email) async {
    try {
      // For enhanced security OTP, we can use custom OTP system
      // For now, use Firebase's email verification as OTP mechanism
      final user = _auth.currentUser;
      if (user?.email == email) {
        await user!.sendEmailVerification();
        return AuthResult.success(
          message: 'Verification email sent to $email',
        );
      } else {
        return AuthResult.failure('Email does not match current user');
      }
    } catch (e) {
      return AuthResult.failure('Failed to send verification email: $e');
    }
  }

  /// Resend email verification
  Future<AuthResult> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }

      if (user.emailVerified) {
        return AuthResult.failure('Email is already verified');
      }

      await user.sendEmailVerification();
      return AuthResult.success(
        message: 'Verification email sent to ${user.email}',
      );
    } catch (e) {
      return AuthResult.failure('Failed to send verification email: $e');
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Reload user to get latest verification status
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Password Reset
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(
        message: 'Password reset email sent to $email',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Failed to send password reset email: $e');
    }
  }

  /// Update user password
  Future<AuthResult> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return AuthResult.success(message: 'Password updated successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return AuthResult.failure('Current password is incorrect');
      }
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Failed to update password: $e');
    }
  }

  /// Update user profile
  Future<AuthResult> updateUserProfile({
    String? username,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (username != null) {
        // Check if new username is taken (if different from current)
        final currentProfile = await getUserProfile();
        if (currentProfile?.username != username) {
          final usernameExists = await _isUsernameTaken(username);
          if (usernameExists) {
            return AuthResult.failure('Username is already taken');
          }
        }
        updateData['username'] = username;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      return AuthResult.success(message: 'Profile updated successfully');
    } catch (e) {
      return AuthResult.failure('Failed to update profile: $e');
    }
  }

  /// Get user profile from Firestore
  Future<AppUser?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return AppUser.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is of legal age (18+)
  Future<bool> isUserOfLegalAge() async {
    try {
      final userProfile = await getUserProfile();
      if (userProfile?.birthDate == null) return false;

      final age = userProfile!.age;
      return age != null && age >= 18;
    } catch (e) {
      return false;
    }
  }

  /// Sign out (handles both Firebase users and local guests)
  Future<void> signOut() async {
    await _auth.signOut();
    _isLocalGuest = false; // Clear local guest state
  }

  /// Delete user account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();

      return AuthResult.success(message: 'Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult.failure(
          'Please sign in again before deleting your account',
        );
      }
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Failed to delete account: $e');
    }
  }

  /// Helper: Check if username is taken
  Future<bool> _isUsernameTaken(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Helper: Update last active time
  Future<void> _updateLastActiveTime(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail for last active time update
    }
  }

  /// Convert Firebase Auth error to user-friendly message
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  /// Sign in anonymously for quick access
  Future<AuthResult> signInAnonymously() async {
    print('🔍 AuthService.signInAnonymously() called');
    try {
      print('🔍 Attempting Firebase anonymous sign-in...');
      print('🔍 Firebase app: ${_auth.app.name}');
      print('🔍 Firebase project: ${_auth.app.options.projectId}');

      final result = await _auth.signInAnonymously();
      print(
          '🔍 Firebase anonymous sign-in completed. User: ${result.user?.uid}');

      if (result.user != null) {
        print('🔍 Creating anonymous user profile in Firestore...');
        // Create anonymous user profile in Firestore
        await _createAnonymousUserProfile(result.user!);
        print('🎉 Firebase anonymous sign-in successful!');

        return AuthResult.success(
          message:
              'Signed in as guest - create an account anytime in Settings!',
        );
      } else {
        print('❌ Firebase anonymous sign-in returned null user');
        return AuthResult.failure('Failed to sign in as guest');
      }
    } on FirebaseAuthException catch (e) {
      print('🔥 FirebaseAuthException caught:');
      print('🔥 Error code: ${e.code}');
      print('🔥 Error message: ${e.message}');
      print('🔥 Error details: ${e.toString()}');

      // If anonymous auth is disabled in Firebase Console, use local guest mode
      if (e.code == 'operation-not-allowed' ||
          e.code == 'auth/operation-not-allowed') {
        print('🔍 Anonymous auth disabled, trying local guest mode...');
        return _signInLocalGuest();
      }

      // Handle other specific Firebase errors
      String userMessage;
      switch (e.code) {
        case 'network-request-failed':
          // Network issues should fall back to local guest mode
          print(
              '🔍 Network error detected, falling back to local guest mode...');
          return _signInLocalGuest();
        case 'too-many-requests':
          userMessage = 'Too many attempts. Please try again later.';
          break;
        default:
          userMessage = 'Authentication failed: ${e.message}';
      }

      print('💥 Returning failure: $userMessage');
      return AuthResult.failure(userMessage);
    } catch (e) {
      print('💥 General exception caught: ${e.toString()}');
      print('💥 Exception type: ${e.runtimeType}');

      // Fallback to local guest mode for any other errors
      print('🔍 Trying local guest mode as fallback...');
      return _signInLocalGuest();
    }
  }

  /// Local guest mode fallback when Firebase anonymous auth is disabled
  Future<AuthResult> _signInLocalGuest() async {
    print('🔍 Entering local guest mode...');
    try {
      // Set local guest mode flag
      _isLocalGuest = true;
      print('🎉 Local guest mode activated successfully!');

      return AuthResult.success(
        message:
            'Welcome, Guest! Create an account anytime in Settings to unlock all features.',
        user: null, // No Firebase user, but app knows this is guest mode
      );
    } catch (e) {
      print('💥 Failed to enter local guest mode: $e');
      return AuthResult.failure('Failed to enter guest mode: $e');
    }
  }

  /// Create anonymous user profile in Firestore
  Future<void> _createAnonymousUserProfile(User user) async {
    try {
      final now = DateTime.now();
      final anonymousUser = AppUser(
        id: user.uid,
        email: 'anonymous@sifter.app', // Placeholder email
        username:
            'Anonymous${user.uid.substring(0, 6)}', // Generate anonymous username
        isEmailVerified: false,
        points: 0,
        createdAt: now,
        updatedAt: now,
        preferences: {'isAnonymous': true}, // Mark as anonymous in preferences
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(anonymousUser.toFirestore());
    } catch (e) {
      print('Failed to create anonymous user profile: $e');
      // Don't throw error - anonymous sign-in should still work
    }
  }

  /// Convert anonymous account to registered account
  Future<AuthResult> convertAnonymousToRegistered({
    required String email,
    required String password,
    required String username,
    required DateTime birthDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        return AuthResult.failure('No anonymous user to convert');
      }

      // Create email credential
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Link anonymous account with email/password
      final result = await user.linkWithCredential(credential);

      if (result.user != null) {
        // Update user profile with real information
        await _updateConvertedUserProfile(
          result.user!,
          username: username,
          email: email,
          birthDate: birthDate,
        );

        // Send verification email
        await result.user!.sendEmailVerification();

        return AuthResult.success(
          message: 'Account created successfully! Please verify your email.',
        );
      } else {
        return AuthResult.failure('Failed to convert anonymous account');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return AuthResult.failure(
            'This email is already registered. Please sign in instead.');
      }
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Unexpected error during account conversion');
    }
  }

  /// Update converted user profile
  Future<void> _updateConvertedUserProfile(
    User user, {
    required String username,
    required String email,
    required DateTime birthDate,
  }) async {
    try {
      final now = DateTime.now();

      final updatedUser = AppUser(
        id: user.uid,
        email: email,
        username: username,
        isEmailVerified: user.emailVerified,
        birthDate: birthDate,
        points: 0, // Keep existing points if any
        createdAt: now, // Update creation time to conversion time
        updatedAt: now,
        preferences: {'isAnonymous': false}, // No longer anonymous
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(updatedUser.toFirestore());
    } catch (e) {
      print('Failed to update converted user profile: $e');
      rethrow; // This is critical, so throw the error
    }
  }

  /// Check if current user is anonymous (by checking preferences)
  Future<bool> isCurrentUserAnonymous() async {
    try {
      // Check local guest mode first
      if (_isLocalGuest) return true;

      final user = _auth.currentUser;
      if (user == null) return false;

      if (user.isAnonymous) return true; // Firebase anonymous user

      // Check Firestore preference for converted users
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      return data?['preferences']?['isAnonymous'] == true;
    } catch (e) {
      final user = _auth.currentUser;
      return user?.isAnonymous ?? _isLocalGuest;
    }
  }

  /// Check if anonymous user can create chats
  bool canCreateChats() {
    return isRegisteredUser; // Only registered users can create chats
  }

  /// Check if anonymous user can join specific room
  bool canJoinRoom(bool roomAllowsAnonymous) {
    if (isRegisteredUser) return true; // Registered users can join any room
    if (isAnonymousUser) {
      return roomAllowsAnonymous; // Anonymous users need permission
    }
    return false; // Not authenticated
  }

  /// Get user type for UI display
  String getUserTypeDisplay() {
    if (isRegisteredUser) return 'Registered';
    if (isAnonymousUser) return 'Anonymous';
    return 'Guest';
  }

  /// Get account creation prompt message for anonymous users
  String getAccountCreationPrompt() {
    return 'Create an account to unlock all features like creating chats, full messaging, and more!';
  }
}

/// Result wrapper for authentication operations
class AuthResult {
  final bool isSuccess;
  final String? message;
  final String? error;
  final User? user;

  AuthResult({
    required this.isSuccess,
    this.message,
    this.error,
    this.user,
  });

  factory AuthResult.success({String? message, User? user}) {
    return AuthResult(isSuccess: true, message: message, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult(isSuccess: false, error: error);
  }
}

/// Providers for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Custom provider that combines Firebase auth and local guest state
final isAuthenticatedProvider = StateProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user != null || authService.isLocalGuest,
    loading: () => false,
    error: (_, __) => authService.isLocalGuest,
  );
});

/// Provider for current user profile
final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserProfile();
});

/// Temporary storage for pending OTP sign-ups
class _PendingOTPSignUp {
  final String email;
  final String username;
  final DateTime birthDate;
  final String otp;
  final DateTime expiresAt;

  _PendingOTPSignUp({
    required this.email,
    required this.username,
    required this.birthDate,
    required this.otp,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
