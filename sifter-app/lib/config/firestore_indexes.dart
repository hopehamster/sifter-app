import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore indexes configuration for optimizing query performance
class FirestoreIndexes {
  /// Initialize all required indexes
  static Future<void> initializeIndexes() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Create composite indexes for common queries
      await _createCompositeIndex(
        firestore,
        collection: 'messages',
        fields: [
          {'fieldPath': 'roomId', 'order': 'ASCENDING'},
          {'fieldPath': 'timestamp', 'order': 'DESCENDING'},
        ],
      );

      await _createCompositeIndex(
        firestore,
        collection: 'users',
        fields: [
          {'fieldPath': 'lastActive', 'order': 'DESCENDING'},
          {'fieldPath': 'status', 'order': 'ASCENDING'},
        ],
      );

      await _createCompositeIndex(
        firestore,
        collection: 'chat_rooms',
        fields: [
          {'fieldPath': 'lastMessageAt', 'order': 'DESCENDING'},
          {'fieldPath': 'type', 'order': 'ASCENDING'},
        ],
      );

      // Messages collection indexes
      await _createMessageIndexes(firestore);

      // Chat rooms collection indexes
      await _createChatRoomIndexes(firestore);

      // Users collection indexes
      await _createUserIndexes(firestore);

      // Point transactions collection indexes
      await _createPointTransactionIndexes(firestore);
    } catch (e) {
      debugPrint('Error initializing Firestore indexes: $e');
    }
  }

  /// Create indexes for messages collection
  static Future<void> _createMessageIndexes(FirebaseFirestore firestore) async {
    try {
      // Index for querying messages by chat room and timestamp
      await firestore.collection('messages').doc('_indexes').set({
        'chatRoomId_timestamp': {
          'fields': {
            'chatRoomId': 'ASCENDING',
            'timestamp': 'DESCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });

      // Index for querying messages by sender and timestamp
      await firestore.collection('messages').doc('_indexes').set({
        'senderId_timestamp': {
          'fields': {
            'senderId': 'ASCENDING',
            'timestamp': 'DESCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });

      // Index for querying messages by type and timestamp
      await firestore.collection('messages').doc('_indexes').set({
        'type_timestamp': {
          'fields': {
            'type': 'ASCENDING',
            'timestamp': 'DESCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });
    } catch (e) {
      debugPrint('Error creating message indexes: $e');
    }
  }

  /// Create indexes for chat rooms collection
  static Future<void> _createChatRoomIndexes(
      FirebaseFirestore firestore) async {
    try {
      // Index for querying chat rooms by participants and last message
      await firestore.collection('chatRooms').doc('_indexes').set({
        'participants_lastMessageAt': {
          'fields': {
            'participants': 'ARRAY_CONTAINS',
            'lastMessageAt': 'DESCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });

      // Index for querying chat rooms by type and status
      await firestore.collection('chatRooms').doc('_indexes').set({
        'type_isActive': {
          'fields': {
            'type': 'ASCENDING',
            'isActive': 'ASCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });
    } catch (e) {
      debugPrint('Error creating chat room indexes: $e');
    }
  }

  /// Create indexes for users collection
  static Future<void> _createUserIndexes(FirebaseFirestore firestore) async {
    try {
      // Index for querying users by display name (for search)
      await firestore.collection('users').doc('_indexes').set({
        'displayName': {
          'fields': {
            'displayName': 'ASCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });

      // Index for querying users by points (for leaderboard)
      await firestore.collection('users').doc('_indexes').set({
        'points': {
          'fields': {
            'points': 'DESCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });
    } catch (e) {
      debugPrint('Error creating user indexes: $e');
    }
  }

  /// Create indexes for point transactions collection
  static Future<void> _createPointTransactionIndexes(
      FirebaseFirestore firestore) async {
    try {
      // Index for querying transactions by user and timestamp
      await firestore.collection('pointTransactions').doc('_indexes').set({
        'userId_timestamp': {
          'fields': {
            'userId': 'ASCENDING',
            'timestamp': 'DESCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });

      // Index for querying transactions by chat room and timestamp
      await firestore.collection('pointTransactions').doc('_indexes').set({
        'chatRoomId_timestamp': {
          'fields': {
            'chatRoomId': 'ASCENDING',
            'timestamp': 'DESCENDING',
          },
          'queryScope': 'COLLECTION',
        },
      });
    } catch (e) {
      debugPrint('Error creating point transaction indexes: $e');
    }
  }

  static Future<void> _createCompositeIndex(
    FirebaseFirestore firestore, {
    required String collection,
    required List<Map<String, String>> fields,
  }) async {
    try {
      // Note: In a real app, you would use the Firebase Console or CLI to create indexes
      // This is just a placeholder for the index creation logic
      debugPrint('Creating index for $collection with fields: $fields');
    } catch (e) {
      debugPrint('Error creating composite index for $collection: $e');
    }
  }
}
