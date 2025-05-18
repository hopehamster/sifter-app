import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'mock_storage_service.dart';

part 'user_service.g.dart';

@riverpod
UserService userService(UserServiceRef ref) {
  return UserService();
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  AppUser? get currentUser {
    final authUser = auth.FirebaseAuth.instance.currentUser;
    if (authUser == null) return null;
    return AppUser(
      id: authUser.uid,
      email: authUser.email!,
      displayName: authUser.displayName ?? '',
      photoUrl: authUser.photoURL,
      isOnline: true,
    );
  }

  String get currentUserId {
    return auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<AppUser> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }
      return AppUser.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<AppUser> getUserById(String userId) async {
    return getUser(userId);
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update online status: $e');
    }
  }

  Stream<AppUser> streamUser(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) => AppUser.fromJson(doc.data()!));
  }

  Future<List<AppUser>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<String> uploadProfilePicture(String userId, File file) async {
    try {
      final storageService = StorageService();
      return await storageService.uploadFile(file, 'profile_pictures/$userId', metadata: {
        'userId': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<void> updateProfilePicture(String userId, String photoUrl) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'photoUrl': photoUrl,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'displayName': displayName,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }

  Future<void> updateBio(String userId, String bio) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'bio': bio,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update bio: $e');
    }
  }

  Future<void> updatePhoneNumber(String userId, String phoneNumber) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'phoneNumber': phoneNumber,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update phone number: $e');
    }
  }

  Future<void> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'preferences': preferences,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  Future<void> updateLastSeen(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update last seen: $e');
    }
  }

  Future<List<AppUser>> getOnlineUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isOnline', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get online users: $e');
    }
  }

  Future<void> blockUser(String currentUserId, String blockUserId) async {
    try {
      await _firestore.collection(_collection).doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([blockUserId]),
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    try {
      await _firestore.collection(_collection).doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  Future<bool> isUserBlocked(String currentUserId, String otherUserId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(currentUserId).get();
      final blockedUsers = doc.data()?['blockedUsers'] as List<dynamic>?;
      return blockedUsers?.contains(otherUserId) == true;
    } catch (e) {
      throw Exception('Failed to check if user is blocked: $e');
    }
  }

  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      final blockedUsers = <String>[];
      final data = doc.data()?['blockedUsers'] as List<dynamic>?;
      if (data != null) {
        for (var item in data) {
          if (item is String) {
            blockedUsers.add(item);
          }
        }
      }
      return blockedUsers;
    } catch (e) {
      throw Exception('Failed to get blocked users: $e');
    }
  }

  Future<void> muteUser(String currentUserId, String muteUserId, {Duration? duration}) async {
    try {
      final expirationTime = duration != null 
          ? DateTime.now().add(duration).millisecondsSinceEpoch 
          : null;
      
      await _firestore.collection(_collection).doc(currentUserId).update({
        'mutedUsers': FieldValue.arrayUnion([{
          'userId': muteUserId,
          'mutedUntil': expirationTime,
        }]),
      });
    } catch (e) {
      throw Exception('Failed to mute user: $e');
    }
  }

  Future<void> unmuteUser(String currentUserId, String mutedUserId) async {
    try {
      await _firestore.collection(_collection).doc(currentUserId).update({
        'mutedUsers': FieldValue.arrayRemove([{
          'userId': mutedUserId,
        }]),
      });
    } catch (e) {
      throw Exception('Failed to unmute user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMutedUsers(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      final mutedUsers = <Map<String, dynamic>>[];
      final data = doc.data()?['mutedUsers'] as List<dynamic>?;
      if (data != null) {
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            mutedUsers.add(item);
          }
        }
      }
      return mutedUsers;
    } catch (e) {
      throw Exception('Failed to get muted users: $e');
    }
  }

  Future<bool> isUserMuted(String currentUserId, String otherUserId) async {
    try {
      final mutedUsers = await getMutedUsers(currentUserId);
      return mutedUsers.any((user) => user['userId'] == otherUserId);
    } catch (e) {
      throw Exception('Failed to check if user is muted: $e');
    }
  }
} 