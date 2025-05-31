import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required String username,
    @Default(false) bool isEmailVerified,
    DateTime? birthDate,
    @Default(0) int points,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<String>? blockedUsers,
    Map<String, dynamic>? preferences,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      isEmailVerified: data['isEmailVerified'] ?? false,
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      points: data['points'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      blockedUsers: data['blockedUsers'] != null
          ? List<String>.from(data['blockedUsers'])
          : null,
      preferences: data['preferences'] != null
          ? Map<String, dynamic>.from(data['preferences'])
          : null,
    );
  }
}

extension AppUserExtensions on AppUser {
  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'isEmailVerified': isEmailVerified,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'points': points,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'blockedUsers': blockedUsers,
      'preferences': preferences,
    };
  }

  /// Check if user is of legal age (18+)
  bool get isOfLegalAge {
    if (birthDate == null) return false;
    final age = DateTime.now().difference(birthDate!).inDays / 365;
    return age >= 18;
  }

  /// Get user's age
  int? get age {
    if (birthDate == null) return null;
    return DateTime.now().difference(birthDate!).inDays ~/ 365;
  }

  /// Check if a user is blocked
  bool isUserBlocked(String userId) {
    return blockedUsers?.contains(userId) ?? false;
  }

  /// Get user preference value
  T? getPreference<T>(String key) {
    return preferences?[key] as T?;
  }

  /// Update points (for scoring system)
  AppUser addPoints(int pointsToAdd) {
    return copyWith(
      points: points + pointsToAdd,
      updatedAt: DateTime.now(),
    );
  }

  /// Block a user
  AppUser blockUser(String userId) {
    final currentBlocked = blockedUsers ?? [];
    if (currentBlocked.contains(userId)) return this;

    return copyWith(
      blockedUsers: [...currentBlocked, userId],
      updatedAt: DateTime.now(),
    );
  }

  /// Unblock a user
  AppUser unblockUser(String userId) {
    final currentBlocked = blockedUsers ?? [];
    if (!currentBlocked.contains(userId)) return this;

    return copyWith(
      blockedUsers: currentBlocked.where((id) => id != userId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update preference
  AppUser updatePreference(String key, dynamic value) {
    final currentPrefs = preferences ?? {};
    return copyWith(
      preferences: {...currentPrefs, key: value},
      updatedAt: DateTime.now(),
    );
  }
}
