import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/chat_room.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Service for handling moderation actions like blocking users and reporting
class ModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  final NotificationService _notificationService;

  ModerationService({
    required AuthService authService,
    required NotificationService notificationService,
  })  : _authService = authService,
        _notificationService = notificationService;

  /// Block a user
  Future<ModerationResult> blockUser({
    required String userIdToBlock,
    required String reason,
    String? roomId,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ModerationResult.failure('User not authenticated');
      }

      // Get current user profile
      final userProfile = await _authService.getUserProfile();
      if (userProfile == null) {
        return ModerationResult.failure('User profile not found');
      }

      // Update user's blocked list
      final updatedUser = userProfile.blockUser(userIdToBlock);
      await _firestore.collection('users').doc(currentUser.uid).update({
        'blockedUsers': updatedUser.blockedUsers,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record the block action
      await _recordModerationAction(
        action: ModerationAction.block,
        targetUserId: userIdToBlock,
        reason: reason,
        roomId: roomId,
      );

      // Send notification to moderators if this is a public block
      if (roomId != null) {
        await _notificationService.showModerationNotification(
          title: 'User Blocked',
          message: 'A user has been blocked in a chat room',
          type: ModerationType.blocked,
          roomId: roomId,
        );
      }

      return ModerationResult.success('User blocked successfully');
    } catch (e) {
      if (kDebugMode) {
        print('Error blocking user: $e');
      }
      return ModerationResult.failure('Failed to block user: $e');
    }
  }

  /// Unblock a user
  Future<ModerationResult> unblockUser(String userIdToUnblock) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ModerationResult.failure('User not authenticated');
      }

      // Get current user profile
      final userProfile = await _authService.getUserProfile();
      if (userProfile == null) {
        return ModerationResult.failure('User profile not found');
      }

      // Update user's blocked list
      final updatedUser = userProfile.unblockUser(userIdToUnblock);
      await _firestore.collection('users').doc(currentUser.uid).update({
        'blockedUsers': updatedUser.blockedUsers,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ModerationResult.success('User unblocked successfully');
    } catch (e) {
      if (kDebugMode) {
        print('Error unblocking user: $e');
      }
      return ModerationResult.failure('Failed to unblock user: $e');
    }
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers() async {
    try {
      final userProfile = await _authService.getUserProfile();
      return userProfile?.blockedUsers ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting blocked users: $e');
      }
      return [];
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final userProfile = await _authService.getUserProfile();
      return userProfile?.isUserBlocked(userId) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user is blocked: $e');
      }
      return false;
    }
  }

  /// Report a user
  Future<ModerationResult> reportUser({
    required String userIdToReport,
    required String reason,
    required ReportCategory category,
    String? description,
    String? roomId,
    String? messageId,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ModerationResult.failure('User not authenticated');
      }

      // Create report document
      final reportData = {
        'reporterId': currentUser.uid,
        'reportedUserId': userIdToReport,
        'reason': reason,
        'category': category.name,
        'description': description,
        'roomId': roomId,
        'messageId': messageId,
        'status': ReportStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final reportRef = await _firestore.collection('reports').add(reportData);

      // Record the moderation action
      await _recordModerationAction(
        action: ModerationAction.report,
        targetUserId: userIdToReport,
        reason: reason,
        roomId: roomId,
        additionalData: {
          'reportId': reportRef.id,
          'category': category.name,
          'description': description,
        },
      );

      // Notify moderators
      await _notificationService.showModerationNotification(
        title: 'New Report Submitted',
        message: 'A user has been reported: ${category.displayName}',
        type: ModerationType.reported,
        roomId: roomId,
      );

      return ModerationResult.success('Report submitted successfully');
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting user: $e');
      }
      return ModerationResult.failure('Failed to submit report: $e');
    }
  }

  /// Report a chat room
  Future<ModerationResult> reportRoom({
    required String roomId,
    required String reason,
    required ReportCategory category,
    String? description,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ModerationResult.failure('User not authenticated');
      }

      // Create room report document
      final reportData = {
        'reporterId': currentUser.uid,
        'roomId': roomId,
        'reason': reason,
        'category': category.name,
        'description': description,
        'status': ReportStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final reportRef =
          await _firestore.collection('room_reports').add(reportData);

      // Record the moderation action
      await _recordModerationAction(
        action: ModerationAction.reportRoom,
        reason: reason,
        roomId: roomId,
        additionalData: {
          'reportId': reportRef.id,
          'category': category.name,
          'description': description,
        },
      );

      // Notify moderators
      await _notificationService.showModerationNotification(
        title: 'Chat Room Reported',
        message: 'A chat room has been reported: ${category.displayName}',
        type: ModerationType.reported,
        roomId: roomId,
      );

      return ModerationResult.success('Room report submitted successfully');
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting room: $e');
      }
      return ModerationResult.failure('Failed to submit room report: $e');
    }
  }

  /// Get user's report history
  Future<List<UserReport>> getUserReports() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      final snapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => UserReport.fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user reports: $e');
      }
      return [];
    }
  }

  /// Ban user from a specific room (for room creators/moderators)
  Future<ModerationResult> banUserFromRoom({
    required String roomId,
    required String userIdToBan,
    required String reason,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ModerationResult.failure('User not authenticated');
      }

      // Check if current user has permission to ban (room creator or moderator)
      final roomDoc =
          await _firestore.collection('chatRooms').doc(roomId).get();
      if (!roomDoc.exists) {
        return ModerationResult.failure('Room not found');
      }

      final room = ChatRoomExtensions.fromFirestore(roomDoc);
      if (!room.canUserModerate(currentUser.uid)) {
        return ModerationResult.failure(
            'You do not have permission to ban users');
      }

      // Add user to banned list and remove from participants
      await _firestore.collection('chatRooms').doc(roomId).update({
        'bannedUserIds': FieldValue.arrayUnion([userIdToBan]),
        'participantIds': FieldValue.arrayRemove([userIdToBan]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record the ban action
      await _recordModerationAction(
        action: ModerationAction.ban,
        targetUserId: userIdToBan,
        reason: reason,
        roomId: roomId,
      );

      // Notify the banned user
      await _notificationService.showModerationNotification(
        title: 'Banned from Chat Room',
        message: 'You have been banned from ${room.name}',
        type: ModerationType.banned,
        roomId: roomId,
      );

      return ModerationResult.success('User banned from room successfully');
    } catch (e) {
      if (kDebugMode) {
        print('Error banning user from room: $e');
      }
      return ModerationResult.failure('Failed to ban user: $e');
    }
  }

  /// Record moderation action for audit trail
  Future<void> _recordModerationAction({
    required ModerationAction action,
    required String reason,
    String? targetUserId,
    String? roomId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final actionData = {
        'moderatorId': currentUser.uid,
        'action': action.name,
        'targetUserId': targetUserId,
        'roomId': roomId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'additionalData': additionalData,
      };

      await _firestore.collection('moderation_log').add(actionData);
    } catch (e) {
      if (kDebugMode) {
        print('Error recording moderation action: $e');
      }
    }
  }

  /// Filter messages to hide blocked users' content
  List<T> filterBlockedContent<T>(
    List<T> items,
    String Function(T) getUserId,
    List<String> blockedUsers,
  ) {
    return items
        .where((item) => !blockedUsers.contains(getUserId(item)))
        .toList();
  }

  /// Check if content should be hidden based on user blocks
  bool shouldHideContent(String authorId, List<String> blockedUsers) {
    return blockedUsers.contains(authorId);
  }
}

/// Result wrapper for moderation operations
class ModerationResult {
  final bool isSuccess;
  final String message;

  ModerationResult._({required this.isSuccess, required this.message});

  factory ModerationResult.success(String message) =>
      ModerationResult._(isSuccess: true, message: message);

  factory ModerationResult.failure(String message) =>
      ModerationResult._(isSuccess: false, message: message);
}

/// User report data class
class UserReport {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? roomId;
  final String reason;
  final ReportCategory category;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  UserReport({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.roomId,
    required this.reason,
    required this.category,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory UserReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'],
      roomId: data['roomId'],
      reason: data['reason'] ?? '',
      category: ReportCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ReportCategory.other,
      ),
      description: data['description'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Types of moderation actions
enum ModerationAction {
  block,
  unblock,
  report,
  reportRoom,
  ban,
  warn,
}

/// Report categories
enum ReportCategory {
  spam('Spam or harassment'),
  inappropriate('Inappropriate content'),
  harassment('Harassment or bullying'),
  violence('Violence or threats'),
  illegal('Illegal activities'),
  impersonation('Impersonation'),
  misinformation('False information'),
  other('Other');

  const ReportCategory(this.displayName);
  final String displayName;
}

/// Report status
enum ReportStatus {
  pending,
  reviewed,
  resolved,
  dismissed,
}

/// Provider for moderation service
final moderationServiceProvider = Provider<ModerationService>((ref) {
  final authService = ref.read(authServiceProvider);
  final notificationService = ref.read(notificationServiceProvider);
  return ModerationService(
    authService: authService,
    notificationService: notificationService,
  );
});

/// Provider for blocked users list
final blockedUsersProvider = FutureProvider<List<String>>((ref) async {
  final moderationService = ref.read(moderationServiceProvider);
  return moderationService.getBlockedUsers();
});

/// Provider for user reports
final userReportsProvider = FutureProvider<List<UserReport>>((ref) async {
  final moderationService = ref.read(moderationServiceProvider);
  return moderationService.getUserReports();
});
