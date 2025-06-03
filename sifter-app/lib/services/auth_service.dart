import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';

import '../models/app_user.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProviderRef _ref;

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

  /// Temporary storage for phone verification
  String? _pendingVerificationId;
  String? _pendingPhoneNumber;
  String? _simulatedOTP; // For development mode
  Map<String, dynamic>?
      _pendingPhoneSignUpData; // Store data between OTP and password steps

  AuthService(this._ref);

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
      Logger.debug('Checking if username is taken: $username',
          component: 'AUTH');

      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      final isTaken = query.docs.isNotEmpty;
      Logger.debug('Username check result: $isTaken', component: 'AUTH');
      return isTaken;
    } on FirebaseException catch (e) {
      Logger.error('FirebaseException in username check: ${e.code}',
          component: 'AUTH', error: e);

      // If permission denied, assume username is available for now
      // This prevents blocking account creation due to Firestore rules
      if (e.code == 'permission-denied') {
        Logger.debug('Permission denied for username check - allowing signup',
            component: 'AUTH');
        return false; // Assume username is available
      }

      // For other Firebase errors, also assume available
      return false;
    } catch (e) {
      Logger.error('General error in username check',
          component: 'AUTH', error: e);
      // For any other error, assume username is available to not block signup
      return false;
    }
  }

  /// Helper: Normalize phone number for Firebase
  String _normalizePhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If it doesn't start with +, assume US number and add +1
    if (!cleaned.startsWith('+')) {
      // If it's 10 digits, assume US number
      if (cleaned.length == 10) {
        cleaned = '+1$cleaned';
      } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
        // If it's 11 digits starting with 1, add + prefix
        cleaned = '+$cleaned';
      } else {
        // For other lengths, just add + prefix (international)
        cleaned = '+$cleaned';
      }
    }

    Logger.debug(
        'Normalized phone: ${Logger.sanitizePhone(phone)} → ${Logger.sanitizePhone(cleaned)}',
        component: 'AUTH');
    return cleaned;
  }

  /// Helper: Validate phone number format
  bool _isValidPhoneNumber(String phone) {
    // Clean the phone number of all non-digit characters except +
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Accept various formats:
    // - International format with +: +1234567890 (minimum 10 digits after +)
    // - US format without +: 1234567890 (exactly 10 digits for US)
    // - International without +: 1234567890... (minimum 10 digits)

    if (cleanPhone.startsWith('+')) {
      // International format with +
      final digits = cleanPhone.substring(1);
      return digits.length >= 10 && digits.length <= 15;
    } else {
      // Format without +
      return cleanPhone.length >= 10 && cleanPhone.length <= 15;
    }
  }

  /// Helper: Create user profile for phone-authenticated users
  Future<void> _createPhoneUserProfile(User user, String phone) async {
    try {
      print('🔍 Creating phone user profile for UID: ${user.uid}');

      final userDoc = _firestore.collection('users').doc(user.uid);

      // Check if user profile already exists
      final existingDoc = await userDoc.get();
      if (existingDoc.exists) {
        print('🔍 User profile already exists, updating...');
        await userDoc.update({
          'phoneNumber': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        print('🔍 Creating new user profile...');
        await userDoc.set({
          'uid': user.uid,
          'phoneNumber': phone,
          'username':
              'User${user.uid.substring(0, 6)}', // Generate default username
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      }

      print('🎉 Phone user profile created/updated successfully');
    } catch (e) {
      print('💥 Error creating phone user profile: $e');
      rethrow;
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
        print('🔍 Creating guest user profile in Firestore...');
        // Create guest user profile in Firestore
        await _createAnonymousUserProfile(result.user!);
        print('🎉 Firebase guest sign-in successful!');

        return AuthResult.success(
          message:
              'Signed in as guest - create an account anytime in Settings!',
        );
      } else {
        print('❌ Firebase guest sign-in returned null user');
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

      // Invalidate the local guest state provider to trigger UI updates
      _ref.invalidate(localGuestStateProvider);

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
      final guestUser = AppUser(
        id: user.uid,
        email: 'guest@sifter.app', // Placeholder email
        username: 'Guest${user.uid.substring(0, 6)}', // Generate guest username
        isEmailVerified: false,
        points: 0,
        createdAt: now,
        updatedAt: now,
        preferences: {
          'isAnonymous': true
        }, // Mark as guest in preferences (keep internal flag)
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(guestUser.toFirestore());
    } catch (e) {
      print('Failed to create guest user profile: $e');
      // Don't throw error - guest sign-in should still work
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
        return AuthResult.failure('No guest user to convert');
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
        return AuthResult.failure('Failed to convert guest account');
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

  /// Check if guest user can create chats
  bool canCreateChats() {
    return isRegisteredUser; // Only registered users can create chats
  }

  /// Check if guest user can join specific room
  bool canJoinRoom(bool roomAllowsGuests) {
    if (isRegisteredUser) return true; // Registered users can join any room
    if (isAnonymousUser) {
      return roomAllowsGuests; // Guest users need permission
    }
    return false; // Not authenticated
  }

  /// Get user type for UI display
  String getUserTypeDisplay() {
    if (isRegisteredUser) return 'Registered';
    if (isAnonymousUser) return 'Guest';
    return 'Guest';
  }

  /// Get account creation prompt message for guest users
  String getAccountCreationPrompt() {
    return 'Create an account to unlock all features like creating chats, full messaging, and more!';
  }

  /// Sign up with phone number
  Future<AuthResult> signUpWithPhone({
    required String phone,
  }) async {
    Logger.debug(
        'signUpWithPhone() called with phone: ${Logger.sanitizePhone(phone)}',
        component: 'AUTH');

    try {
      Logger.debug('Starting phone verification process...', component: 'AUTH');

      // Validate phone number format
      Logger.debug('Validating phone number format...', component: 'AUTH');
      if (!_isValidPhoneNumber(phone)) {
        Logger.debug('Phone number validation failed', component: 'AUTH');
        return AuthResult.failure('Please enter a valid phone number');
      }
      Logger.debug('Phone number validation passed', component: 'AUTH');

      // Normalize phone number for Firebase
      Logger.debug('Normalizing phone number...', component: 'AUTH');
      final normalizedPhone = _normalizePhoneNumber(phone);
      Logger.debug('Phone number normalized', component: 'AUTH');

      // TEMPORARY: Use simulation instead of Firebase phone auth to prevent freezing
      // This is a development fallback until Firebase phone auth is properly configured
      Logger.debug('Using OTP simulation for development...',
          component: 'AUTH');

      // Simulate OTP generation and storage
      final simulatedOTP = '123456'; // Fixed OTP for testing
      _pendingVerificationId = 'sim_${DateTime.now().millisecondsSinceEpoch}';
      _pendingPhoneNumber = normalizedPhone;

      // Store simulated OTP temporarily (in production, this would be sent via SMS)
      _simulatedOTP = simulatedOTP;

      Logger.debug('Simulated OTP generated and stored', component: 'AUTH');
      print(
          '📱 DEVELOPMENT MODE: OTP for ${Logger.sanitizePhone(normalizedPhone)} is: $simulatedOTP');

      return AuthResult.success(
        message: 'Verification code sent to $phone (DEV MODE: check console)',
      );

      /* 
      // COMMENTED OUT: Real Firebase phone authentication
      // Uncomment and remove simulation when Firebase is properly configured
      
      Logger.debug('Calling Firebase verifyPhoneNumber...', component: 'AUTH');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          Logger.debug('Phone verification completed automatically', component: 'AUTH');
          try {
            final result = await _auth.signInWithCredential(credential);
            if (result.user != null) {
              await _createPhoneUserProfile(result.user!, normalizedPhone);
              Logger.auth('Phone sign-up successful');
            }
          } catch (e) {
            Logger.error('Error in verificationCompleted', component: 'AUTH', error: e);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          Logger.error('Phone verification failed', component: 'AUTH', error: e);
        },
        codeSent: (String verificationId, int? resendToken) {
          Logger.debug('OTP sent to phone: ${Logger.sanitizePhone(normalizedPhone)}', component: 'AUTH');
          // Store verification ID for later use
          _pendingVerificationId = verificationId;
          _pendingPhoneNumber = normalizedPhone;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          Logger.debug('Auto-retrieval timeout for verification: ${Logger.sanitize(verificationId)}', component: 'AUTH');
        },
      );

      Logger.debug('Firebase verifyPhoneNumber call completed', component: 'AUTH');

      return AuthResult.success(
        message: 'Verification code sent to $phone',
      );
      */
    } on FirebaseAuthException catch (e) {
      Logger.error('FirebaseAuthException in signUpWithPhone: ${e.code}',
          component: 'AUTH', error: e);
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      Logger.error('General exception in signUpWithPhone',
          component: 'AUTH', error: e);
      return AuthResult.failure('Failed to send verification code: $e');
    }
  }

  /// Verify phone OTP and complete sign-up (now just OTP verification step)
  Future<AuthResult> verifyPhoneOTP({
    required String otp,
  }) async {
    Logger.debug('verifyPhoneOTP() called with OTP: ${Logger.sanitize(otp)}',
        component: 'AUTH');
    try {
      if (_pendingVerificationId == null) {
        return AuthResult.failure('No verification in progress');
      }

      // Check if this is a simulated verification (development mode)
      if (_pendingVerificationId!.startsWith('sim_') && _simulatedOTP != null) {
        Logger.debug('Using simulated OTP verification...', component: 'AUTH');

        if (otp != _simulatedOTP) {
          return AuthResult.failure(
              'Invalid verification code. Please try again.');
        }

        // Store phone data for password creation step
        _pendingPhoneSignUpData = {
          'phoneNumber': _pendingPhoneNumber!,
          'verificationId': _pendingVerificationId!,
          'verifiedAt': DateTime.now(),
        };

        Logger.auth(
            'Simulated OTP verification successful - ready for password');
        return AuthResult.success(
          message: 'Phone verified! Create your password.',
        );
      }

      // Real Firebase phone verification (commented out for now)
      /*
      final credential = PhoneAuthProvider.credential(
        verificationId: _pendingVerificationId!,
        smsCode: otp,
      );

      // Just verify the OTP, don't create account yet
      // Store verification data for password creation step
      _pendingPhoneSignUpData = {
        'phoneNumber': _pendingPhoneNumber!,
        'verificationId': _pendingVerificationId!,
        'credential': credential,
        'verifiedAt': DateTime.now(),
      };
      
      Logger.auth('Phone OTP verification successful - ready for password');
      return AuthResult.success(
        message: 'Phone verified! Create your password.',
      );
      */

      return AuthResult.failure('Phone verification temporarily disabled');
    } on FirebaseAuthException catch (e) {
      Logger.error('FirebaseAuthException in verifyPhoneOTP: ${e.code}',
          component: 'AUTH', error: e);
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      Logger.error('General exception in verifyPhoneOTP',
          component: 'AUTH', error: e);
      return AuthResult.failure('Failed to verify code: $e');
    }
  }

  /// Complete phone sign-up with password (Step 3 of phone sign-up)
  Future<AuthResult> completePhoneSignUpWithPassword({
    required String password,
    required String username,
    required DateTime birthDate,
  }) async {
    Logger.debug('completePhoneSignUpWithPassword() called', component: 'AUTH');

    if (_pendingPhoneSignUpData == null) {
      return AuthResult.failure(
          'No verified phone number found. Please start over.');
    }

    try {
      final phoneNumber = _pendingPhoneSignUpData!['phoneNumber'] as String;

      // Check if username is already taken
      final usernameExists = await _isUsernameTaken(username);
      if (usernameExists) {
        return AuthResult.failure('Username is already taken');
      }

      // Create a proper email/password account using phone number as email base
      final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final email = '$normalizedPhone@phone.sifter.app';

      Logger.debug('Creating email/password account with email: $email',
          component: 'AUTH');

      // Create user with email and password (this makes them non-anonymous)
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        Logger.error('Failed to create Firebase user', component: 'AUTH');
        return AuthResult.failure('Failed to create account');
      }

      Logger.debug('Firebase user created successfully: ${user.uid}',
          component: 'AUTH');

      // Create user profile with phone and password
      final appUser = AppUser(
        id: user.uid,
        email: email,
        username: username,
        birthDate: birthDate,
        points: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: {
          'phoneNumber': phoneNumber,
          'isPhoneVerified': true,
          'authMethod': 'phone',
        },
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toJson());

      Logger.debug('User profile created in Firestore', component: 'AUTH');

      // Store phone number separately for lookups
      await _firestore.collection('phone_users').doc(normalizedPhone).set({
        'userId': user.uid,
        'phoneNumber': phoneNumber,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      });

      Logger.debug('Phone lookup record created', component: 'AUTH');

      // Clear pending data
      _pendingPhoneSignUpData = null;
      _pendingVerificationId = null;
      _pendingPhoneNumber = null;
      _simulatedOTP = null;

      Logger.auth('Phone sign-up with password completed successfully');
      return AuthResult.success(
        message: 'Account created successfully!',
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      Logger.error(
          'FirebaseAuthException in completePhoneSignUpWithPassword: ${e.code}',
          component: 'AUTH',
          error: e);
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      Logger.error('Error completing phone sign-up with password',
          component: 'AUTH', error: e);
      return AuthResult.failure('Failed to complete account creation: $e');
    }
  }

  /// Sign in with phone and password
  Future<AuthResult> signInWithPhoneAndPassword({
    required String phone,
    required String password,
  }) async {
    Logger.debug('signInWithPhoneAndPassword() called', component: 'AUTH');

    try {
      final normalizedPhone = _normalizePhoneNumber(phone);
      final normalizedPhoneDigits =
          normalizedPhone.replaceAll(RegExp(r'[^\d]'), '');

      Logger.debug('Looking up phone user record...', component: 'AUTH');

      // Look up the email associated with this phone number
      final phoneUserDoc = await _firestore
          .collection('phone_users')
          .doc(normalizedPhoneDigits)
          .get();

      if (!phoneUserDoc.exists) {
        Logger.debug('No phone user record found', component: 'AUTH');
        return AuthResult.failure('No account found with this phone number');
      }

      final phoneData = phoneUserDoc.data()!;
      final email = phoneData['email'] as String;

      Logger.debug('Found email for phone: $email', component: 'AUTH');

      // Sign in with the email and password
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        Logger.auth('Phone + password sign-in successful');
        return AuthResult.success(
          message: 'Welcome back!',
          user: credential.user,
        );
      } else {
        return AuthResult.failure('Failed to sign in');
      }
    } on FirebaseException catch (e) {
      Logger.error('FirebaseException in phone lookup: ${e.code}',
          component: 'AUTH', error: e);

      if (e.code == 'permission-denied') {
        return AuthResult.failure(
            'Unable to access account data. Please update the app or contact support.');
      }

      return AuthResult.failure('Database error: ${e.message}');
    } on FirebaseAuthException catch (e) {
      Logger.error(
          'FirebaseAuthException in signInWithPhoneAndPassword: ${e.code}',
          component: 'AUTH',
          error: e);

      if (e.code == 'wrong-password') {
        return AuthResult.failure('Invalid password');
      } else if (e.code == 'user-not-found') {
        return AuthResult.failure('No account found with this phone number');
      } else {
        return AuthResult.failure(_getAuthErrorMessage(e.code));
      }
    } catch (e) {
      Logger.error('Error in phone + password sign-in',
          component: 'AUTH', error: e);
      return AuthResult.failure('Failed to sign in: $e');
    }
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
  return AuthService(ref);
});

/// Provider for local guest state changes
final localGuestStateProvider = StateProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isLocalGuest;
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
  final localGuestState = ref.watch(localGuestStateProvider);

  return authState.when(
    data: (user) => user != null || localGuestState,
    loading: () => localGuestState,
    error: (_, __) => localGuestState,
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
