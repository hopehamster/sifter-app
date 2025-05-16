import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sifter/services/analytics_service.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final AnalyticsService _analytics = AnalyticsService();
  
  Map<String, dynamic>? _userData;
  List<String> _blockedUsers = [];
  List<String> _mutedUsers = [];
  bool _isOnline = false;
  
  Map<String, dynamic>? get userData => _userData;
  List<String> get blockedUsers => _blockedUsers;
  List<String> get mutedUsers => _mutedUsers;
  bool get isOnline => _isOnline;
  
  UserProvider() {
    _init();
  }
  
  Future<void> _init() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
      await _loadBlockedUsers(user.uid);
      await _loadMutedUsers(user.uid);
      _setOnlineStatus(true);
    }
  }
  
  Future<void> _loadUserData(String userId) async {
    final snapshot = await _db.child('users/$userId').once();
    if (snapshot.snapshot.value != null) {
      _userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      notifyListeners();
    }
  }
  
  Future<void> _loadBlockedUsers(String userId) async {
    final snapshot = await _db.child('users/$userId/blocked').once();
    if (snapshot.snapshot.value != null) {
      _blockedUsers = List<String>.from(snapshot.snapshot.value as List);
      notifyListeners();
    }
  }
  
  Future<void> _loadMutedUsers(String userId) async {
    final snapshot = await _db.child('users/$userId/muted').once();
    if (snapshot.snapshot.value != null) {
      _mutedUsers = List<String>.from(snapshot.snapshot.value as List);
      notifyListeners();
    }
  }
  
  Future<void> _setOnlineStatus(bool online) async {
    final user = _auth.currentUser;
    if (user != null) {
      _isOnline = online;
      await _db.child('users/${user.uid}/online').set(online);
      await _db.child('users/${user.uid}/lastSeen').set(ServerValue.timestamp);
      notifyListeners();
    }
  }
  
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && !_blockedUsers.contains(userId)) {
      _blockedUsers.add(userId);
      await _db.child('users/${currentUser.uid}/blocked').set(_blockedUsers);
      await _analytics.logEvent('user_blocked', parameters: {'blocked_user_id': userId});
      notifyListeners();
    }
  }
  
  Future<void> unblockUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _blockedUsers.remove(userId);
      await _db.child('users/${currentUser.uid}/blocked').set(_blockedUsers);
      await _analytics.logEvent('user_unblocked', parameters: {'unblocked_user_id': userId});
      notifyListeners();
    }
  }
  
  Future<void> muteUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && !_mutedUsers.contains(userId)) {
      _mutedUsers.add(userId);
      await _db.child('users/${currentUser.uid}/muted').set(_mutedUsers);
      await _analytics.logEvent('user_muted', parameters: {'muted_user_id': userId});
      notifyListeners();
    }
  }
  
  Future<void> unmuteUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _mutedUsers.remove(userId);
      await _db.child('users/${currentUser.uid}/muted').set(_mutedUsers);
      await _analytics.logEvent('user_unmuted', parameters: {'unmuted_user_id': userId});
      notifyListeners();
    }
  }
  
  Future<void> updateUserStatus(String status) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _db.child('users/${currentUser.uid}/status').set(status);
      await _analytics.logEvent('status_updated', parameters: {'status': status});
      notifyListeners();
    }
  }
  
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _db.child('users/${currentUser.uid}').update(updates);
      await _loadUserData(currentUser.uid);
      await _analytics.logEvent('profile_updated', parameters: updates);
    }
  }
  
  @override
  void dispose() {
    _setOnlineStatus(false);
    super.dispose();
  }
} 