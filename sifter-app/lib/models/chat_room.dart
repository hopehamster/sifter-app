import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

@freezed
class ChatRoom with _$ChatRoom {
  const ChatRoom._();

  const factory ChatRoom({
    required String id,
    required String name,
    required String description,
    required String creatorId,
    required String creatorName,

    // Geofencing data
    required double latitude,
    required double longitude,
    required double radiusInMeters,

    // Chat settings
    @Default(false) bool isPasswordProtected,
    String? password,
    @Default(false) bool isNsfw,
    @Default(false) bool allowAnonymous,
    @Default(50) int maxMembers,

    // Timestamps
    required DateTime createdAt,
    required DateTime updatedAt,

    // Participant tracking
    @Default(<String>[]) List<String> participantIds,
    @Default(<String>[]) List<String> bannedUserIds,

    // Chat state
    @Default(true) bool isActive,
    DateTime? expiresAt,

    // Moderation
    @Default(<String, String>{})
    Map<String, String> userRoles, // userId -> role
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);

  // Convert to Flyer Chat SDK Room format
  types.Room toFlyerRoom() {
    return types.Room(
      id: id,
      type: types.RoomType.group,
      users: const [], // Will be populated separately
      name: name,
      imageUrl: null,
      metadata: {
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'radiusInMeters': radiusInMeters,
        'isNsfw': isNsfw,
        'allowAnonymous': allowAnonymous,
        'isPasswordProtected': isPasswordProtected,
        'creatorId': creatorId,
        'maxMembers': maxMembers,
      },
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: updatedAt.millisecondsSinceEpoch,
    );
  }

  // Create from Flyer Chat SDK Room
  static ChatRoom fromFlyerRoom(types.Room room) {
    final metadata = room.metadata ?? <String, dynamic>{};

    return ChatRoom(
      id: room.id,
      name: room.name ?? 'Unnamed Room',
      description: metadata['description'] ?? '',
      creatorId: metadata['creatorId'] ?? '',
      creatorName: '', // Will need to be populated separately
      latitude: (metadata['latitude'] ?? 0.0).toDouble(),
      longitude: (metadata['longitude'] ?? 0.0).toDouble(),
      radiusInMeters: (metadata['radiusInMeters'] ?? 100.0).toDouble(),
      isPasswordProtected: metadata['isPasswordProtected'] ?? false,
      isNsfw: metadata['isNsfw'] ?? false,
      allowAnonymous: metadata['allowAnonymous'] ?? false,
      maxMembers: metadata['maxMembers'] ?? 50,
      createdAt: DateTime.fromMillisecondsSinceEpoch(room.createdAt ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(room.updatedAt ?? 0),
      participantIds: room.users.map((u) => u.id).toList(),
    );
  }
}

// Extension methods for ChatRoom
extension ChatRoomExtensions on ChatRoom {
  /// Check if user is creator
  bool isCreator(String userId) => creatorId == userId;

  /// Check if user is banned
  bool isUserBanned(String userId) => bannedUserIds.contains(userId);

  /// Check if user is participant
  bool isParticipant(String userId) => participantIds.contains(userId);

  /// Check if room is full
  bool get isFull => participantIds.length >= maxMembers;

  /// Check if room has expired
  bool get hasExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Get user role
  String getUserRole(String userId) => userRoles[userId] ?? 'member';

  /// Check if user can moderate
  bool canUserModerate(String userId) {
    final role = getUserRole(userId);
    return isCreator(userId) || role == 'admin' || role == 'moderator';
  }

  /// Create Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'isPasswordProtected': isPasswordProtected,
      'password': password,
      'isNsfw': isNsfw,
      'allowAnonymous': allowAnonymous,
      'maxMembers': maxMembers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'participantIds': participantIds,
      'bannedUserIds': bannedUserIds,
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'userRoles': userRoles,
    };
  }

  /// Create from Firestore document
  static ChatRoom fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      radiusInMeters: (data['radiusInMeters'] ?? 100.0).toDouble(),
      isPasswordProtected: data['isPasswordProtected'] ?? false,
      password: data['password'],
      isNsfw: data['isNsfw'] ?? false,
      allowAnonymous: data['allowAnonymous'] ?? false,
      maxMembers: data['maxMembers'] ?? 50,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      bannedUserIds: List<String>.from(data['bannedUserIds'] ?? []),
      isActive: data['isActive'] ?? true,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      userRoles: Map<String, String>.from(data['userRoles'] ?? {}),
    );
  }
}
