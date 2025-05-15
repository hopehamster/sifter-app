import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  bool isAdmin = false;

  User? get user => _user;
  String? userId;
  String? userEmail;
  bool get isLoggedIn => _user != null;
  String? _userId;

  AuthProvider() {
    // login();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      // if (user != null) {
      user = user;
      userId = user!.uid;
      userEmail = user.email;
      if (_userId != null) {
        _checkAdminStatus();
      }
      notifyListeners();
    });
    // Initialize auth state listener
    // _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // void _onAuthStateChanged(User? user) {
  //   _auth.authStateChanges().listen(_onAuthStateChanged);

  //   _user = user;
  //   print('object $user');
  //   notifyListeners();
  // }
  Future<void> _checkAdminStatus() async {
    final snapshot = await _db.child('admins/$_userId').get();
    isAdmin = snapshot.exists;
    notifyListeners();
  }

  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  Future<User?> signup(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Signup failed: ${e.toString()}');
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
      // No need to set persistence to NONE - this actually prevents automatic login
    } catch (e) {
      throw AuthException('Logout failed: ${e.toString()}');
    }
  }

  Future<String?> getValidToken() async {
    try {
      if (_user != null) {
        return await _user!.getIdToken(true);
      }
      return null;
    } catch (e) {
      // await logout(context);
      throw AuthException('Session expired. Please log in again.');
    }
  }

  Future<void> signInWithPhone(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Phone sign-in failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      await _auth.signInWithProvider(googleProvider);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signInWithApple() async {
    try {
      final AppleAuthProvider appleProvider = AppleAuthProvider();
      await _auth.signInWithProvider(appleProvider);
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An unknown error occurred.';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
