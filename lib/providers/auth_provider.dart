import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  User? _user;
  String? _userId;
  bool _isAdmin = false;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      _userId = user?.uid;
      if (_userId != null) {
        _checkAdminStatus();
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  String? get userId => _userId;
  bool get isAdmin => _isAdmin;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Sign-up failed: $e');
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

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      throw Exception('Anonymous sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _checkAdminStatus() async {
    final snapshot = await _db.child('admins/$_userId').get();
    _isAdmin = snapshot.exists;
    notifyListeners();
  }
}