import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sifter/services/analytics_service.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sifter/utils/error_handler.dart';

part 'database_service.g.dart';

/// Database service provider
/// 
/// This provider is responsible for creating and providing the DatabaseService
/// instance to the rest of the application.
@riverpod
DatabaseService databaseService(DatabaseServiceRef ref) {
  return DatabaseService();
}

/// Service for working with Firebase Firestore and Realtime Database
/// 
/// This service provides methods for CRUD operations on both Firestore
/// and Realtime Database, as well as transaction support, batch operations,
/// and specialized queries.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final rtdb.FirebaseDatabase _rtDatabase = rtdb.FirebaseDatabase.instance;

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get messages => _firestore.collection('messages');
  CollectionReference get rooms => _firestore.collection('rooms');
  CollectionReference get settings => _firestore.collection('settings');
  CollectionReference get chatRooms => _firestore.collection('chatRooms');
  CollectionReference get userSettings => _firestore.collection('userSettings');
  CollectionReference get userStats => _firestore.collection('userStats');
  CollectionReference get feedback => _firestore.collection('feedback');

  // RTDB references
  rtdb.DatabaseReference get onlineStatus => _rtDatabase.ref('status');
  rtdb.DatabaseReference get typing => _rtDatabase.ref('typing');
  rtdb.DatabaseReference get lastSeen => _rtDatabase.ref('lastSeen');

  // User operations
  Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    try {
      await users.doc(userId).set(userData);
      await _analytics.logEvent('user_created', parameters: {
        'user_id': userId,
        'user_data': userData,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'create_user_error');
      rethrow;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await users.doc(userId).update(userData);
      await _analytics.logEvent('user_updated', parameters: {
        'user_id': userId,
        'user_data': userData,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'update_user_error');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getUser(String userId) async {
    try {
      return await users.doc(userId).get();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'get_user_error');
      rethrow;
    }
  }

  // Message operations
  Future<String> createMessage(Map<String, dynamic> messageData) async {
    try {
      final docRef = await messages.add(messageData);
      await _analytics.logEvent('message_created', parameters: {
        'message_id': docRef.id,
        'message_data': messageData,
      });
      return docRef.id;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'create_message_error');
      rethrow;
    }
  }

  Future<void> updateMessage(String messageId, Map<String, dynamic> messageData) async {
    try {
      await messages.doc(messageId).update(messageData);
      await _analytics.logEvent('message_updated', parameters: {
        'message_id': messageId,
        'message_data': messageData,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'update_message_error');
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await messages.doc(messageId).delete();
      await _analytics.logEvent('message_deleted', parameters: {
        'message_id': messageId,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'delete_message_error');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMessages(String roomId, {int limit = 20, DocumentSnapshot? startAfter}) {
    Query query = messages
        .where('roomId', isEqualTo: roomId)
        .orderBy('timestamp', descending: true)
        .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    return query.snapshots();
  }

  Future<QuerySnapshot> loadMoreMessages(String roomId, DocumentSnapshot lastDoc, {int limit = 20}) async {
    return await messages
        .where('roomId', isEqualTo: roomId)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();
  }

  Stream<QuerySnapshot> getMessagesInTimeRange(
    String roomId, 
    DateTime startTime, 
    DateTime endTime
  ) {
    return messages
        .where('roomId', isEqualTo: roomId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Room operations
  Future<String> createRoom(Map<String, dynamic> roomData) async {
    try {
      final docRef = await rooms.add(roomData);
      await _analytics.logEvent('room_created', parameters: {
        'room_id': docRef.id,
        'room_data': roomData,
      });
      return docRef.id;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'create_room_error');
      rethrow;
    }
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> roomData) async {
    try {
      await rooms.doc(roomId).update(roomData);
      await _analytics.logEvent('room_updated', parameters: {
        'room_id': roomId,
        'room_data': roomData,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'update_room_error');
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await rooms.doc(roomId).delete();
      await _analytics.logEvent('room_deleted', parameters: {
        'room_id': roomId,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'delete_room_error');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getRooms() {
    return rooms.orderBy('lastMessageTime', descending: true).snapshots();
  }

  // Settings operations
  Future<void> updateSettings(String userId, Map<String, dynamic> settingsData) async {
    try {
      await settings.doc(userId).set(settingsData, SetOptions(merge: true));
      await _analytics.logEvent('settings_updated', parameters: {
        'user_id': userId,
        'settings': settingsData,
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'update_settings_error');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getSettings(String userId) async {
    try {
      return await settings.doc(userId).get();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'get_settings_error');
      rethrow;
    }
  }

  // Search operations
  Future<QuerySnapshot> searchUsers(String query) async {
    try {
      return await users
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'search_users_error');
      rethrow;
    }
  }

  Future<QuerySnapshot> searchMessages(String roomId, String query) async {
    try {
      return await messages
          .where('roomId', isEqualTo: roomId)
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'search_messages_error');
      rethrow;
    }
  }

  Future<void> setData({
    required String path,
    required dynamic data,
    bool merge = false,
  }) async {
    try {
      final ref = _rtDatabase.ref(path);
      if (merge) {
        await ref.update(data);
      } else {
        await ref.set(data);
      }
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error setting data');
      throw Exception('Failed to set data: $e');
    }
  }

  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _rtDatabase.ref(path).update(data);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error updating data');
      throw Exception('Failed to update data: $e');
    }
  }

  Future<void> deleteData(String path) async {
    try {
      await _rtDatabase.ref(path).remove();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error deleting data');
      throw Exception('Failed to delete data: $e');
    }
  }

  Future<dynamic> getData(String path) async {
    try {
      final snapshot = await _rtDatabase.ref(path).get();
      return snapshot.value;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error getting data');
      throw Exception('Failed to get data: $e');
    }
  }

  Stream<rtdb.DatabaseEvent> streamData(String path) {
    return _rtDatabase.ref(path).onValue;
  }

  Stream<rtdb.DatabaseEvent> streamChildAdded(String path) {
    return _rtDatabase.ref(path).onChildAdded;
  }

  Stream<rtdb.DatabaseEvent> streamChildChanged(String path) {
    return _rtDatabase.ref(path).onChildChanged;
  }

  Stream<rtdb.DatabaseEvent> streamChildRemoved(String path) {
    return _rtDatabase.ref(path).onChildRemoved;
  }

  Future<void> pushData({
    required String path,
    required dynamic data,
  }) async {
    try {
      await _rtDatabase.ref(path).push().set(data);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error pushing data');
      throw Exception('Failed to push data: $e');
    }
  }

  Future<void> setWithPriority({
    required String path,
    required dynamic data,
    required dynamic priority,
  }) async {
    try {
      await _rtDatabase.ref(path).setWithPriority(data, priority);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error setting data with priority');
      throw Exception('Failed to set data with priority: $e');
    }
  }

  Future<void> setServerTimestamp(String path) async {
    try {
      await _rtDatabase.ref(path).set(rtdb.ServerValue.timestamp);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error setting server timestamp');
      throw Exception('Failed to set server timestamp: $e');
    }
  }

  Future<void> incrementValue({
    required String path,
    required int increment,
  }) async {
    try {
      await _rtDatabase.ref(path).set(rtdb.ServerValue.increment(increment));
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error incrementing value');
      throw Exception('Failed to increment value: $e');
    }
  }

  Future<List<dynamic>> getOrderedData({
    required String path,
    required String orderBy,
    int? limitToFirst,
    int? limitToLast,
    dynamic startAt,
    dynamic endAt,
    dynamic equalTo,
  }) async {
    try {
      rtdb.Query query = _rtDatabase.ref(path).orderByChild(orderBy);

      if (limitToFirst != null) {
        query = query.limitToFirst(limitToFirst);
      }
      if (limitToLast != null) {
        query = query.limitToLast(limitToLast);
      }
      if (startAt != null) {
        query = query.startAt(startAt);
      }
      if (endAt != null) {
        query = query.endAt(endAt);
      }
      if (equalTo != null) {
        query = query.equalTo(equalTo);
      }

      final snapshot = await query.get();
      final List<dynamic> results = [];
      snapshot.children.forEach((child) {
        results.add(child.value);
      });
      return results;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error getting ordered data');
      throw Exception('Failed to get ordered data: $e');
    }
  }

  Future<void> runRtdbTransaction({
    required String path,
    required rtdb.TransactionHandler transactionHandler,
  }) async {
    try {
      await _rtDatabase.ref(path).runTransaction(transactionHandler);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error running RTDB transaction');
      throw Exception('Failed to run transaction: $e');
    }
  }

  Future<void> setOfflineCapability(bool enabled) async {
    try {
      _rtDatabase.setPersistenceEnabled(enabled);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error setting offline capability');
      throw Exception('Failed to set offline capability: $e');
    }
  }

  Future<void> keepSynced(String path, bool synced) async {
    try {
      await _rtDatabase.ref(path).keepSynced(synced);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error setting keep synced');
      throw Exception('Failed to set keep synced: $e');
    }
  }

  Future<void> goOffline() async {
    try {
      await _rtDatabase.goOffline();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error going offline');
      throw Exception('Failed to go offline: $e');
    }
  }

  Future<void> goOnline() async {
    try {
      _rtDatabase.goOnline();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error going online');
      throw Exception('Failed to go online: $e');
    }
  }

  Future<void> purgeOutstandingWrites() async {
    try {
      _rtDatabase.purgeOutstandingWrites();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error purging outstanding writes');
      throw Exception('Failed to purge outstanding writes: $e');
    }
  }

  // Delete user data
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user document
      await users.doc(userId).delete();
      
      // Delete user settings
      await userSettings.doc(userId).delete();
      
      // Delete user stats
      await userStats.doc(userId).delete();
      
      // Delete user status in RTDB
      await onlineStatus.child(userId).remove();
      await lastSeen.child(userId).remove();
      
      // You might want to delete user messages and other data too
      // This would require more complex queries
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error deleting user data');
      throw Exception('Failed to delete user data: $e');
    }
  }

  // Check if document exists
  Future<bool> documentExists(String collection, String documentId) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error checking document existence');
      throw Exception('Failed to check if document exists: $e');
    }
  }

  // Get document reference
  DocumentReference getDocumentRef(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId);
  }

  // Query collection with complex query
  Future<QuerySnapshot> queryCollectionAdvanced(
    String collection,
    List<Map<String, dynamic>> queryParams,
  ) async {
    try {
      Query query = _firestore.collection(collection);
      
      for (var param in queryParams) {
        String field = param['field'] as String;
        dynamic value = param['value'];
        String operator = param['operator'] as String? ?? '==';
        
        switch (operator) {
          case '==':
            query = query.where(field, isEqualTo: value);
            break;
          case '>':
            query = query.where(field, isGreaterThan: value);
            break;
          case '>=':
            query = query.where(field, isGreaterThanOrEqualTo: value);
            break;
          case '<':
            query = query.where(field, isLessThan: value);
            break;
          case '<=':
            query = query.where(field, isLessThanOrEqualTo: value);
            break;
          case 'array-contains':
            query = query.where(field, arrayContains: value);
            break;
          case 'array-contains-any':
            query = query.where(field, arrayContainsAny: value as List);
            break;
          case 'in':
            query = query.where(field, whereIn: value as List);
            break;
          case 'not-in':
            query = query.where(field, whereNotIn: value as List);
            break;
        }
      }
      
      return await query.get();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error executing advanced query');
      throw Exception('Failed to execute advanced query: $e');
    }
  }

  // Batch operations
  Future<void> batchOperation(List<BatchOperation> operations) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var operation in operations) {
        DocumentReference docRef = _firestore
            .collection(operation.collection)
            .doc(operation.documentId);
            
        switch (operation.type) {
          case BatchOperationType.set:
            batch.set(docRef, operation.data!, SetOptions(merge: operation.merge));
            break;
          case BatchOperationType.update:
            batch.update(docRef, operation.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(docRef);
            break;
        }
      }
      
      await batch.commit();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error executing batch operation');
      throw Exception('Failed to execute batch operation: $e');
    }
  }

  // Transaction
  Future<T> runTransaction<T>(Future<T> Function(Transaction) transaction) async {
    try {
      return await _firestore.runTransaction((txn) => transaction(txn));
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error executing transaction');
      throw Exception('Failed to execute transaction: $e');
    }
  }

  // Configure persistence (offline support)
  Future<void> enablePersistence() async {
    try {
      await _firestore.enablePersistence(const PersistenceSettings(synchronizeTabs: true));
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error enabling persistence');
      // Don't throw here, just log as this might be a limitation on the platform
    }
  }

  // RTDB operations
  Future<void> setRTDBValue(String path, dynamic value) async {
    try {
      await _rtDatabase.ref(path).set(value);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error setting RTDB value');
      throw Exception('Failed to set RTDB value: $e');
    }
  }

  Future<void> updateRTDBValue(String path, Map<String, dynamic> value) async {
    try {
      await _rtDatabase.ref(path).update(value);
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error updating RTDB value');
      throw Exception('Failed to update RTDB value: $e');
    }
  }

  Future<void> removeRTDBValue(String path) async {
    try {
      await _rtDatabase.ref(path).remove();
    } catch (e, stack) {
      ErrorHandler.logError(e, stack, message: 'Error removing RTDB value');
      throw Exception('Failed to remove RTDB value: $e');
    }
  }

  Stream<rtdb.DatabaseEvent> streamRTDBValue(String path) {
    return _rtDatabase.ref(path).onValue;
  }
}

// Query constraints
abstract class QueryConstraint {}

class WhereConstraint extends QueryConstraint {
  final String field;
  final dynamic value;
  
  WhereConstraint(this.field, this.value);
}

class OrderByConstraint extends QueryConstraint {
  final String field;
  final bool descending;
  
  OrderByConstraint(this.field, {this.descending = false});
}

class LimitConstraint extends QueryConstraint {
  final int limit;
  
  LimitConstraint(this.limit);
}

// Batch operations
class BatchOperation {
  final String collection;
  final String documentId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;
  final bool merge;
  
  BatchOperation.set(this.collection, this.documentId, this.data, {this.merge = false})
      : type = BatchOperationType.set;
      
  BatchOperation.update(this.collection, this.documentId, this.data)
      : type = BatchOperationType.update,
        merge = false;
        
  BatchOperation.delete(this.collection, this.documentId)
      : type = BatchOperationType.delete,
        data = null,
        merge = false;
}

enum BatchOperationType {
  set,
  update,
  delete,
} 