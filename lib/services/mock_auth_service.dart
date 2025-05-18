import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'mock_auth_service.g.dart';

/// Mock implementation of the auth service that replaces Firebase Auth
/// This implementation uses flutter_secure_storage to persist user data
class MockAuthService {
  final FlutterSecureStorage _secureStorage;
  
  MockAuthService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();
  
  // Current user ID - null means not logged in
  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  
  // Stream controllers to notify about auth state changes
  final _authStateChanges = ValueNotifier<String?>(null);
  ValueListenable<String?> get authStateChanges => _authStateChanges;
  
  // Initialize the auth service
  Future<void> initialize() async {
    _currentUserId = await _secureStorage.read(key: 'userId');
    _authStateChanges.value = _currentUserId;
    debugPrint('MockAuthService initialized with user: $_currentUserId');
  }
  
  // Sign in with email and password
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // In a real app, you would validate against a backend
      // For this mock, we'll just check if the credentials are stored
      final storedPassword = await _secureStorage.read(key: 'password_$email');
      
      if (storedPassword == null) {
        throw Exception('User not found');
      }
      
      if (storedPassword != password) {
        throw Exception('Wrong password');
      }
      
      final userId = await _secureStorage.read(key: 'user_$email');
      
      if (userId == null) {
        throw Exception('User ID not found');
      }
      
      _currentUserId = userId;
      await _secureStorage.write(key: 'userId', value: userId);
      _authStateChanges.value = userId;
      
      return userId;
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw Exception('Authentication failed: $e');
    }
  }
  
  // Create account with email and password
  Future<String> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _secureStorage.read(key: 'user_$email');
      
      if (existingUser != null) {
        throw Exception('Email already in use');
      }
      
      // Generate a new user ID
      final userId = const Uuid().v4();
      
      // Store the user credentials
      await _secureStorage.write(key: 'user_$email', value: userId);
      await _secureStorage.write(key: 'password_$email', value: password);
      await _secureStorage.write(key: 'email_$userId', value: email);
      
      // Set as current user
      _currentUserId = userId;
      await _secureStorage.write(key: 'userId', value: userId);
      _authStateChanges.value = userId;
      
      return userId;
    } catch (e) {
      debugPrint('Create user error: $e');
      throw Exception('Failed to create account: $e');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _currentUserId = null;
    await _secureStorage.delete(key: 'userId');
    _authStateChanges.value = null;
  }
  
  // Delete account
  Future<void> deleteAccount() async {
    if (_currentUserId == null) {
      throw Exception('Not signed in');
    }
    
    final email = await _secureStorage.read(key: 'email_$_currentUserId');
    
    if (email != null) {
      await _secureStorage.delete(key: 'user_$email');
      await _secureStorage.delete(key: 'password_$email');
    }
    
    await _secureStorage.delete(key: 'email_$_currentUserId');
    await signOut();
  }
  
  // Get the current user's email
  Future<String?> getCurrentUserEmail() async {
    if (_currentUserId == null) return null;
    return await _secureStorage.read(key: 'email_$_currentUserId');
  }
}

@riverpod
MockAuthService mockAuthService(MockAuthServiceRef ref) {
  return MockAuthService();
} 