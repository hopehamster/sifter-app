import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'points_service.g.dart';

@riverpod
PointsService pointsService(PointsServiceRef ref) {
  return PointsService();
}

class PointsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  final String _pointsHistoryCollection = 'points_history';

  Future<int> getUserPoints(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      return doc.data()?['points'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get user points: $e');
    }
  }

  Future<void> addPoints(String userId, int points, String reason) async {
    try {
      final batch = _firestore.batch();
      
      // Update user's total points
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'points': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add points history record
      final historyRef = _firestore.collection(_pointsHistoryCollection).doc();
      batch.set(historyRef, {
        'userId': userId,
        'points': points,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add points: $e');
    }
  }

  Future<void> deductPoints(String userId, int points, String reason) async {
    try {
      final userPoints = await getUserPoints(userId);
      if (userPoints < points) {
        throw Exception('Insufficient points');
      }

      final batch = _firestore.batch();
      
      // Update user's total points
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'points': FieldValue.increment(-points),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add points history record
      final historyRef = _firestore.collection(_pointsHistoryCollection).doc();
      batch.set(historyRef, {
        'userId': userId,
        'points': -points,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to deduct points: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getPointsHistory(String userId) {
    return _firestore
        .collection(_pointsHistoryCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  Future<void> rewardForAd(String userId) async {
    const points = 10; // Points rewarded for watching an ad
    await addPoints(userId, points, 'Watched rewarded ad');
  }

  Future<void> rewardForGroupCreation(String userId) async {
    const points = 50; // Points rewarded for creating a group
    await addPoints(userId, points, 'Created new group');
  }

  Future<void> rewardForJoiningGroup(String userId) async {
    const points = 5; // Points rewarded for joining a group
    await addPoints(userId, points, 'Joined group');
  }
} 