import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'auth_service.dart';

/// Service for managing user leaderboard and scoring system
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  LeaderboardService({required AuthService authService})
      : _authService = authService;

  /// Get top users for leaderboard
  Future<List<LeaderboardEntry>> getTopUsers({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('points', isGreaterThan: 0)
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      final entries = <LeaderboardEntry>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final user = AppUser.fromFirestore(doc);

        // Skip anonymous users from leaderboard
        if (user.getPreference<bool>('isAnonymous') == true) continue;

        entries.add(LeaderboardEntry(
          rank: entries.length + 1,
          user: user,
          points: user.points,
        ));
      }

      return entries;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting top users: $e');
      }
      return [];
    }
  }

  /// Get user's rank in leaderboard
  Future<int?> getUserRank(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final user = AppUser.fromFirestore(userDoc);

      // Skip anonymous users
      if (user.getPreference<bool>('isAnonymous') == true) return null;

      final higherRankedCount = await _firestore
          .collection('users')
          .where('points', isGreaterThan: user.points)
          .where('preferences.isAnonymous', isNotEqualTo: true)
          .count()
          .get();

      return higherRankedCount.count! + 1;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user rank: $e');
      }
      return null;
    }
  }

  /// Get leaderboard entry for current user
  Future<LeaderboardEntry?> getCurrentUserEntry() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final userProfile = await _authService.getUserProfile();
      if (userProfile == null) return null;

      // Skip anonymous users
      if (userProfile.getPreference<bool>('isAnonymous') == true) return null;

      final rank = await getUserRank(currentUser.uid);
      if (rank == null) return null;

      return LeaderboardEntry(
        rank: rank,
        user: userProfile,
        points: userProfile.points,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user entry: $e');
      }
      return null;
    }
  }

  /// Award points to user
  Future<bool> awardPoints(
      String userId, int points, PointsReason reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record the points transaction
      await _recordPointsTransaction(
        userId: userId,
        points: points,
        reason: reason,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error awarding points: $e');
      }
      return false;
    }
  }

  /// Award points to current user
  Future<bool> awardPointsToCurrentUser(int points, PointsReason reason) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    // Don't award points to anonymous users
    if (_authService.isAnonymousUser) return false;

    return await awardPoints(currentUser.uid, points, reason);
  }

  /// Record points transaction for history
  Future<void> _recordPointsTransaction({
    required String userId,
    required int points,
    required PointsReason reason,
  }) async {
    try {
      await _firestore.collection('points_transactions').add({
        'userId': userId,
        'points': points,
        'reason': reason.name,
        'reasonDescription': reason.description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error recording points transaction: $e');
      }
    }
  }

  /// Get user's points history
  Future<List<PointsTransaction>> getUserPointsHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('points_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => PointsTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting points history: $e');
      }
      return [];
    }
  }

  /// Get leaderboard statistics
  Future<LeaderboardStats> getLeaderboardStats() async {
    try {
      // Get total registered users (excluding anonymous)
      final totalUsersSnapshot = await _firestore
          .collection('users')
          .where('preferences.isAnonymous', isNotEqualTo: true)
          .count()
          .get();

      // Get users with points
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('points', isGreaterThan: 0)
          .where('preferences.isAnonymous', isNotEqualTo: true)
          .count()
          .get();

      // Get top user
      final topUserSnapshot = await _firestore
          .collection('users')
          .where('preferences.isAnonymous', isNotEqualTo: true)
          .orderBy('points', descending: true)
          .limit(1)
          .get();

      int? highestPoints;
      if (topUserSnapshot.docs.isNotEmpty) {
        final topUser = AppUser.fromFirestore(topUserSnapshot.docs.first);
        highestPoints = topUser.points;
      }

      return LeaderboardStats(
        totalUsers: totalUsersSnapshot.count ?? 0,
        activeUsers: activeUsersSnapshot.count ?? 0,
        highestPoints: highestPoints ?? 0,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting leaderboard stats: $e');
      }
      return LeaderboardStats(
        totalUsers: 0,
        activeUsers: 0,
        highestPoints: 0,
      );
    }
  }
}

/// Leaderboard entry representing a user's position
class LeaderboardEntry {
  final int rank;
  final AppUser user;
  final int points;

  LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.points,
  });
}

/// Points transaction record
class PointsTransaction {
  final String id;
  final String userId;
  final int points;
  final PointsReason reason;
  final DateTime timestamp;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.reason,
    required this.timestamp,
  });

  factory PointsTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PointsTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      points: data['points'] ?? 0,
      reason: PointsReason.values.firstWhere(
        (r) => r.name == data['reason'],
        orElse: () => PointsReason.other,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Leaderboard statistics
class LeaderboardStats {
  final int totalUsers;
  final int activeUsers;
  final int highestPoints;

  LeaderboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.highestPoints,
  });
}

/// Reasons for awarding points
enum PointsReason {
  chatRoomCreated(10, 'Created a chat room'),
  chatRoomJoined(2, 'Joined a chat room'),
  messagePosted(1, 'Posted a message'),
  videoAdWatched(5, 'Watched a video ad'),
  dailyLogin(3, 'Daily login bonus'),
  weeklyLogin(15, 'Weekly login bonus'),
  profileCompleted(20, 'Completed profile'),
  emailVerified(25, 'Verified email address'),
  accountCreated(50, 'Created account'),
  other(0, 'Other activity');

  const PointsReason(this.points, this.description);
  final int points;
  final String description;
}

/// Provider for LeaderboardService
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  final authService = ref.read(authServiceProvider);
  return LeaderboardService(authService: authService);
});

/// Provider for top users leaderboard
final topUsersProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return leaderboardService.getTopUsers();
});

/// Provider for current user's leaderboard entry
final currentUserLeaderboardProvider =
    FutureProvider<LeaderboardEntry?>((ref) async {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return leaderboardService.getCurrentUserEntry();
});

/// Provider for leaderboard stats
final leaderboardStatsProvider = FutureProvider<LeaderboardStats>((ref) async {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return leaderboardService.getLeaderboardStats();
});
