import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:sifter/services/database_service.dart';
import 'package:sifter/utils/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _database = DatabaseService();

  // Auth state changes stream
  Stream<User?> authStateChanges() => _auth.authStateChanges();
  
  // Dispose stream subscription if needed
  void disposeAuthStateChanges() {
    // Nothing to dispose in this implementation
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Sign in with email and password
  Future<User> signInWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logLogin(method: 'email');
      return userCredential.user!;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Email sign in error');
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign up with email and password
  Future<User> signUpWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logSignUp(method: 'email');
      return userCredential.user!;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Email sign up error');
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with Google
  Future<User> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in aborted');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _analytics.logLogin(method: 'google');
      return userCredential.user!;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Google sign in error');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      await _analytics.logEvent('user_signed_out');
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Sign out error');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
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
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      // Reauthenticate the user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      await _analytics.logEvent('password_updated');
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Update password error');
      throw Exception('Failed to update password: $e');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      // Reauthenticate the user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update email
      await user.updateEmail(newEmail);
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
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      // Reauthenticate the user first if they're not using OAuth
      if (user.providerData.any((info) => info.providerId == 'password')) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
      
      // Delete user data from Firestore
      await _database.deleteUser(user.uid);
      
      // Delete user authentication
      await user.delete();
      await _analytics.logEvent('account_deleted');
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Delete account error');
      throw Exception('Failed to delete account: $e');
    }
  }

  // Get user token
  Future<String?> getToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Get token error');
      throw Exception('Failed to get token: $e');
    }
  }

  // Check if user is anonymous
  bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? false;
  }
  
  // Sign in with phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Phone verification error');
      throw Exception('Failed to verify phone number: $e');
    }
  }
  
  // Sign in with phone credential
  Future<User> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      await _analytics.logLogin(method: 'phone');
      return userCredential.user!;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Phone sign in error');
      throw Exception('Failed to sign in with phone: $e');
    }
  }
} 