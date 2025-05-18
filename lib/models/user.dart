import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
    String? bio,
    String? username,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
    @Default({}) Map<String, dynamic> settings,
  }) = _AppUser;
  
  // Private constructor needed by Freezed for getter implementations
  const AppUser._();

  // Use freezed-generated fromJson factory
  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

extension AppUserX on AppUser {
  String get initials {
    if (displayName.isEmpty) return '?';
    final parts = displayName.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get displayNameOrEmail {
    return displayName.isNotEmpty ? displayName : email.split('@')[0];
  }

  bool get hasProfilePicture {
    return photoUrl != null && photoUrl!.isNotEmpty;
  }

  String get lastSeenText {
    if (lastSeen == null) return 'Offline';
    if (isOnline) return 'Online';

    final now = DateTime.now();
    final lastSeenDate = lastSeen is int
        ? DateTime.fromMillisecondsSinceEpoch(lastSeen as int)
        : lastSeen is DateTime
            ? lastSeen as DateTime
            : DateTime.now();
    final difference = now.difference(lastSeenDate);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeenDate.day.toString().padLeft(2, '0')}/${lastSeenDate.month.toString().padLeft(2, '0')}/${lastSeenDate.year}';
    }
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    if (lastSeen != null) {
      json['lastSeen'] = lastSeen;
    }
    return json;
  }

  AppUser copyWithLastSeen(int timestamp) {
    return copyWith(
      lastSeen: DateTime.fromMillisecondsSinceEpoch(timestamp),
      isOnline: false,
    );
  }

  AppUser copyWithOnlineStatus(bool online) {
    return copyWith(
      isOnline: online,
      lastSeen: online ? null : DateTime.now(),
    );
  }
} 