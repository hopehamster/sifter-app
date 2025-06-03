import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_room.dart';
import 'location_service.dart';
import 'password_service.dart';
import 'auth_service.dart';

class ChatRoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  final LocationService _locationService;

  ChatRoomService({
    required AuthService authService,
    required LocationService locationService,
  })  : _authService = authService,
        _locationService = locationService;

  /// Get chat rooms that user is currently eligible for (within geofence)
  Stream<List<ChatRoom>> getEligibleChatRooms() {
    return _locationService.positionStream.asyncMap((position) async {
      try {
        // Get all active chat rooms
        final querySnapshot = await _firestore
            .collection('chatRooms')
            .where('isActive', isEqualTo: true)
            .get();

        final eligibleRooms = <ChatRoom>[];

        // Check user's age verification status for NSFW filtering
        final isUserOfLegalAge = await _authService.isUserOfLegalAge();
        final isAnonymousUser = _authService.isAnonymousUser;

        for (final doc in querySnapshot.docs) {
          final chatRoom = ChatRoomExtensions.fromFirestore(doc);

          // Check if user is within this room's geofence
          if (_locationService.isWithinGeofence(
            chatLat: chatRoom.latitude,
            chatLng: chatRoom.longitude,
            radiusInMeters: chatRoom.radiusInMeters,
          )) {
            // ✅ NSFW Age Verification Filter
            if (chatRoom.isNsfw) {
              // Anonymous users cannot access NSFW content
              if (isAnonymousUser) {
                if (kDebugMode) {
                  print('NSFW room ${chatRoom.id} hidden from anonymous user');
                }
                continue;
              }

              // Underage users cannot access NSFW content
              if (!isUserOfLegalAge) {
                if (kDebugMode) {
                  print('NSFW room ${chatRoom.id} hidden from underage user');
                }
                continue;
              }
            }

            // ✅ Anonymous User Access Filter
            if (isAnonymousUser && !chatRoom.allowAnonymous) {
              if (kDebugMode) {
                print(
                    'Room ${chatRoom.id} hidden from anonymous user (not allowed)');
              }
              continue;
            }

            eligibleRooms.add(chatRoom);
          }
        }

        return eligibleRooms;
      } catch (e) {
        if (kDebugMode) {
          print('Error getting eligible chat rooms: $e');
        }
        return <ChatRoom>[];
      }
    });
  }

  /// Create a new chat room
  Future<String?> createChatRoom({
    required String name,
    required String description,
    required String creatorId,
    required String creatorName,
    required double latitude,
    required double longitude,
    required double radiusInMeters,
    bool isPasswordProtected = false,
    String? password,
    bool isNsfw = false,
    bool allowAnonymous = true,
    int maxMembers = 50,
    DateTime? expiresAt,
  }) async {
    try {
      // Hash password if provided
      String? hashedPassword;
      if (isPasswordProtected && password != null) {
        hashedPassword = PasswordService.hashPassword(password);
      }

      final chatRoom = ChatRoom(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName,
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
        participantIds: [creatorId],
        isPasswordProtected: isPasswordProtected,
        password: hashedPassword,
        isNsfw: isNsfw,
        allowAnonymous: allowAnonymous,
        maxMembers: maxMembers,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      final docRef =
          await _firestore.collection('chatRooms').add(chatRoom.toFirestore());

      // Create corresponding Flyer Chat room
      final flyerRoom = chatRoom.copyWith(id: docRef.id).toFlyerRoom();

      // Note: FirebaseChatCore.instance.createRoom expects different parameters
      // We'll handle Flyer Chat room creation separately when needed
      // await FirebaseChatCore.instance.createRoom(flyerRoom);

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating chat room: $e');
      }
      return null;
    }
  }

  /// Join a chat room
  Future<bool> joinChatRoom({
    required String roomId,
    required String userId,
    String? password,
  }) async {
    try {
      final roomDoc =
          await _firestore.collection('chatRooms').doc(roomId).get();
      if (!roomDoc.exists) return false;

      final room = ChatRoomExtensions.fromFirestore(roomDoc);

      // Check if user is already in the room
      if (room.participantIds.contains(userId)) return true;

      // Check if room is full
      if (room.participantIds.length >= room.maxMembers) return false;

      // ✅ NSFW Age Verification
      if (room.isNsfw) {
        final isOfLegalAge = await _authService.isUserOfLegalAge();
        if (!isOfLegalAge || _authService.isAnonymousUser) {
          return false; // NSFW content requires verified 18+ user
        }
      }

      // Check password if required
      if (room.isPasswordProtected) {
        if (password == null) return false;

        final isValidPassword = PasswordService.verifyPassword(
          password,
          room.password ?? '',
        );
        if (!isValidPassword) return false;
      }

      // Check location requirement
      final isWithinGeofence = _locationService.isWithinGeofence(
        chatLat: room.latitude,
        chatLng: room.longitude,
        radiusInMeters: room.radiusInMeters,
      );
      if (!isWithinGeofence) return false;

      // Add user to room participants
      await _firestore.collection('chatRooms').doc(roomId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error joining chat room: $e');
      }
      return false;
    }
  }

  /// Leave a chat room
  Future<bool> leaveChatRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      final docSnapshot =
          await _firestore.collection('chatRooms').doc(roomId).get();

      if (!docSnapshot.exists) return false;

      final chatRoom = ChatRoomExtensions.fromFirestore(docSnapshot);

      // Remove user from participants
      await _firestore.collection('chatRooms').doc(roomId).update({
        'participantIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });

      // If creator left, delete the room
      if (chatRoom.isCreator(userId)) {
        await deleteChatRoom(roomId);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error leaving chat room: $e');
      }
      return false;
    }
  }

  /// Delete a chat room
  Future<bool> deleteChatRoom(String roomId) async {
    try {
      // Mark as inactive in Firestore
      await _firestore.collection('chatRooms').doc(roomId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      // TODO: Clean up Flyer Chat room and messages

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting chat room: $e');
      }
      return false;
    }
  }

  /// Ban user from room
  Future<bool> banUser({
    required String roomId,
    required String userId,
    required String moderatorId,
  }) async {
    try {
      final docSnapshot =
          await _firestore.collection('chatRooms').doc(roomId).get();

      if (!docSnapshot.exists) return false;

      final chatRoom = ChatRoomExtensions.fromFirestore(docSnapshot);

      // Check if moderator has permission
      if (!chatRoom.canUserModerate(moderatorId)) return false;

      // Add to banned list and remove from participants
      await _firestore.collection('chatRooms').doc(roomId).update({
        'bannedUserIds': FieldValue.arrayUnion([userId]),
        'participantIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error banning user: $e');
      }
      return false;
    }
  }

  /// Check for geofence exits and remove users
  Future<void> processGeofenceExits(List<String> activeRoomIds) async {
    try {
      final exitedRooms = <ChatRoomGeofence>[];

      // Build geofence list from active rooms
      for (final roomId in activeRoomIds) {
        final docSnapshot =
            await _firestore.collection('chatRooms').doc(roomId).get();

        if (docSnapshot.exists) {
          final chatRoom = ChatRoomExtensions.fromFirestore(docSnapshot);
          exitedRooms.add(ChatRoomGeofence(
            roomId: roomId,
            latitude: chatRoom.latitude,
            longitude: chatRoom.longitude,
            radiusInMeters: chatRoom.radiusInMeters,
          ));
        }
      }

      // Check which rooms user has exited
      final exitedRoomIds =
          await _locationService.checkGeofenceExits(exitedRooms);

      // Remove user from exited rooms
      for (final roomId in exitedRoomIds) {
        // This would need to be called with actual user ID
        // await leaveChatRoom(roomId: roomId, userId: currentUserId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing geofence exits: $e');
      }
    }
  }
}

/// Provider for ChatRoomService
final chatRoomServiceProvider = Provider<ChatRoomService>((ref) {
  final locationService = ref.read(locationServiceProvider);
  final authService = ref.read(authServiceProvider);
  return ChatRoomService(
      authService: authService, locationService: locationService);
});

/// Provider for eligible chat rooms stream
final eligibleChatRoomsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final chatRoomService = ref.read(chatRoomServiceProvider);
  return chatRoomService.getEligibleChatRooms();
});

/// Create a provider for password service
final passwordServiceProvider = Provider<PasswordService>((ref) {
  return PasswordService();
});
