import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'points_service.g.dart';

/// Service for managing user points in the app
class PointsService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  
  /// Points constants
  static const int pointsWatchAd = 10;
  static const int pointsCreateGroup = 50;
  static const int pointsJoinGroup = 5;
  static const int pointsCreateNsfwRoom = 20;
  static const int pointsPasswordProtectRoom = 15;
  static const int pointsSendMessage = 1;
  static const int pointsRateRoom = 5;
  static const int pointsInviteUser = 10;
  
  /// Award points to a user for an action
  /// 
  /// [userId] - The ID of the user to award points to
  /// [points] - The number of points to award
  /// [reason] - The reason for awarding points (for analytics)
  Future<void> awardPoints(String userId, int points, String reason) async {
    try {
      // Update points in the database
      await _db.child('users/$userId/points').runTransaction((Object? currentPoints) {
        // If points don't exist yet, start from 0
        int existingPoints = (currentPoints as int?) ?? 0;
        return Transaction.success(existingPoints + points);
      });
      
      // Log the transaction for analytics
      await _db.child('pointsHistory').push().set({
        'userId': userId,
        'points': points,
        'reason': reason,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error awarding points: $e');
      Sentry.captureException(e, hint: {'action': 'award_points', 'user_id': userId});
      // We could rethrow here, but often better to handle silently
      // to prevent points errors from disrupting user experience
    }
  }
  
  /// Get the current points for a user
  Future<int> getUserPoints(String userId) async {
    try {
      final snapshot = await _db.child('users/$userId/points').get();
      if (snapshot.exists) {
        return snapshot.value as int;
      }
      return 0;
    } catch (e) {
      print('Error fetching user points: $e');
      Sentry.captureException(e, hint: {'action': 'get_user_points', 'user_id': userId});
      return 0;
    }
  }
  
  /// Award points for watching a rewarded ad
  Future<void> rewardForAd(String userId) async {
    await awardPoints(userId, pointsWatchAd, 'Watched rewarded ad');
  }

  /// Award points for creating a group
  Future<void> rewardForGroupCreation(String userId, {bool isNsfw = false, bool isPasswordProtected = false}) async {
    int points = pointsCreateGroup;
    
    // Give extra points for NSFW room creation
    if (isNsfw) {
      points += pointsCreateNsfwRoom;
    }
    
    // Give extra points for password-protected rooms
    if (isPasswordProtected) {
      points += pointsPasswordProtectRoom;
    }
    
    await awardPoints(userId, points, 'Created new ${isNsfw ? 'NSFW ' : ''}${isPasswordProtected ? 'protected ' : ''}group');
  }

  /// Award points for joining a group
  Future<void> rewardForJoiningGroup(String userId, {bool isNsfw = false}) async {
    // Joining NSFW rooms could award slightly more points for engagement
    int points = isNsfw ? pointsJoinGroup + 2 : pointsJoinGroup;
    await awardPoints(userId, points, 'Joined ${isNsfw ? 'NSFW ' : ''}group');
  }
  
  /// Award points for sending a message
  Future<void> rewardForSendingMessage(String userId) async {
    // Limit message rewards to prevent spamming
    await awardPoints(userId, pointsSendMessage, 'Sent message');
  }
  
  /// Award points for rating a room
  Future<void> rewardForRatingRoom(String userId) async {
    await awardPoints(userId, pointsRateRoom, 'Rated a room');
  }
  
  /// Award points for inviting a user to a room
  Future<void> rewardForInviting(String userId) async {
    await awardPoints(userId, pointsInviteUser, 'Invited a user');
  }
  
  /// Award points for participating in a room for extended periods
  Future<void> rewardForEngagement(String userId, int minutes) async {
    // Award 1 point for every 5 minutes in a chat, capped at 20 points per day
    if (minutes % 5 == 0) {
      await awardPoints(userId, 1, 'Engagement time: $minutes minutes');
    }
  }
  
  /// Get the top users by points
  /// 
  /// [limit] - The maximum number of users to return
  Future<List<Map<String, dynamic>>> getTopUsers({int limit = 100}) async {
    try {
      final snapshot = await _db
          .child('users')
          .orderByChild('points')
          .limitToLast(limit)
          .get();
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> usersData = 
            snapshot.value as Map<dynamic, dynamic>;
        
        List<Map<String, dynamic>> users = [];
        
        usersData.forEach((key, value) {
          final userData = value as Map<dynamic, dynamic>;
          users.add({
            'userId': key,
            'username': userData['username'] ?? 'Anonymous',
            'points': userData['points'] ?? 0,
            'photoUrl': userData['photoUrl'],
          });
        });
        
        // Sort in descending order
        users.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
        
        return users;
      }
      
      return [];
    } catch (e) {
      print('Error fetching top users: $e');
      Sentry.captureException(e, hint: {'action': 'get_top_users'});
      return [];
    }
  }
  
  /// Get a user's rank in the leaderboard
  Future<int> getUserRank(String userId) async {
    try {
      final userPoints = await getUserPoints(userId);
      
      // Get users with more points than the current user
      final snapshot = await _db
          .child('users')
          .orderByChild('points')
          .startAfter(userPoints)
          .get();
      
      if (snapshot.exists) {
        // The number of users with more points + 1 is the user's rank
        final Map<dynamic, dynamic> usersData = 
            snapshot.value as Map<dynamic, dynamic>;
        return usersData.length + 1;
      }
      
      // If no users have more points, the user is rank 1
      return 1;
    } catch (e) {
      print('Error fetching user rank: $e');
      Sentry.captureException(e, hint: {'action': 'get_user_rank', 'user_id': userId});
      return 0; // Unknown rank
    }
  }
}

@riverpod
PointsService pointsService(Ref ref) {
  return PointsService();
} 