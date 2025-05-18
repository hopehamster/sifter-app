// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatRoom _$ChatRoomFromJson(Map<String, dynamic> json) {
  return _ChatRoom.fromJson(json);
}

/// @nodoc
mixin _$ChatRoom {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  ChatRoomType get type => throw _privateConstructorUsedError;
  List<String> get memberIds => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  Map<String, ChatRoomRole> get memberRoles =>
      throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  bool get isPrivate => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  Map<String, bool> get mutedBy => throw _privateConstructorUsedError;
  Map<String, bool> get archivedBy => throw _privateConstructorUsedError;
  Map<String, DateTime> get readBy => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  String? get lastMessageId => throw _privateConstructorUsedError;
  int? get lastMessageTimestamp => throw _privateConstructorUsedError;
  String? get lastMessageSenderId => throw _privateConstructorUsedError;
  String? get lastMessage => throw _privateConstructorUsedError;
  String? get lastMessageType => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;
  List<String> get admins => throw _privateConstructorUsedError;
  List<String> get bannedUsers => throw _privateConstructorUsedError;
  bool get isPasswordProtected => throw _privateConstructorUsedError;
  String? get password => throw _privateConstructorUsedError;
  int get maxMembers => throw _privateConstructorUsedError;
  List<String> get participants => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  bool? get isGroup => throw _privateConstructorUsedError;
  bool? get requireApproval =>
      throw _privateConstructorUsedError; // Location-based properties
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double get radius =>
      throw _privateConstructorUsedError; // Default radius in km
  bool get isActive => throw _privateConstructorUsedError;
  int get participantCount =>
      throw _privateConstructorUsedError; // New properties for expiration and customization
  DateTime? get expiresAt =>
      throw _privateConstructorUsedError; // Auto-expiration timestamp (24 hours from creation/last activity)
  DateTime? get lastActivityAt =>
      throw _privateConstructorUsedError; // Timestamp of last activity in the room
  bool get isNsfw =>
      throw _privateConstructorUsedError; // Flag for NSFW content
  String? get rules =>
      throw _privateConstructorUsedError; // Optional rules for the chat room
  int get themeColor =>
      throw _privateConstructorUsedError; // Theme color for the chat room UI (default blue)
  bool get allowAnonymous =>
      throw _privateConstructorUsedError; // Whether to allow anonymous users to join
  Map<String, dynamic> get activityLog => throw _privateConstructorUsedError;

  /// Serializes this ChatRoom to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatRoomCopyWith<ChatRoom> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatRoomCopyWith<$Res> {
  factory $ChatRoomCopyWith(ChatRoom value, $Res Function(ChatRoom) then) =
      _$ChatRoomCopyWithImpl<$Res, ChatRoom>;
  @useResult
  $Res call(
      {String id,
      String name,
      ChatRoomType type,
      List<String> memberIds,
      String createdBy,
      Map<String, ChatRoomRole> memberRoles,
      String? photoUrl,
      String? description,
      bool isPrivate,
      bool isPinned,
      Map<String, bool> mutedBy,
      Map<String, bool> archivedBy,
      Map<String, DateTime> readBy,
      DateTime? lastMessageAt,
      String? lastMessageId,
      int? lastMessageTimestamp,
      String? lastMessageSenderId,
      String? lastMessage,
      String? lastMessageType,
      Map<String, dynamic> metadata,
      List<String> admins,
      List<String> bannedUsers,
      bool isPasswordProtected,
      String? password,
      int maxMembers,
      List<String> participants,
      DateTime? createdAt,
      DateTime? updatedAt,
      bool? isGroup,
      bool? requireApproval,
      double latitude,
      double longitude,
      double radius,
      bool isActive,
      int participantCount,
      DateTime? expiresAt,
      DateTime? lastActivityAt,
      bool isNsfw,
      String? rules,
      int themeColor,
      bool allowAnonymous,
      Map<String, dynamic> activityLog});
}

/// @nodoc
class _$ChatRoomCopyWithImpl<$Res, $Val extends ChatRoom>
    implements $ChatRoomCopyWith<$Res> {
  _$ChatRoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? memberIds = null,
    Object? createdBy = null,
    Object? memberRoles = null,
    Object? photoUrl = freezed,
    Object? description = freezed,
    Object? isPrivate = null,
    Object? isPinned = null,
    Object? mutedBy = null,
    Object? archivedBy = null,
    Object? readBy = null,
    Object? lastMessageAt = freezed,
    Object? lastMessageId = freezed,
    Object? lastMessageTimestamp = freezed,
    Object? lastMessageSenderId = freezed,
    Object? lastMessage = freezed,
    Object? lastMessageType = freezed,
    Object? metadata = null,
    Object? admins = null,
    Object? bannedUsers = null,
    Object? isPasswordProtected = null,
    Object? password = freezed,
    Object? maxMembers = null,
    Object? participants = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? isGroup = freezed,
    Object? requireApproval = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? radius = null,
    Object? isActive = null,
    Object? participantCount = null,
    Object? expiresAt = freezed,
    Object? lastActivityAt = freezed,
    Object? isNsfw = null,
    Object? rules = freezed,
    Object? themeColor = null,
    Object? allowAnonymous = null,
    Object? activityLog = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ChatRoomType,
      memberIds: null == memberIds
          ? _value.memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      memberRoles: null == memberRoles
          ? _value.memberRoles
          : memberRoles // ignore: cast_nullable_to_non_nullable
              as Map<String, ChatRoomRole>,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      mutedBy: null == mutedBy
          ? _value.mutedBy
          : mutedBy // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      archivedBy: null == archivedBy
          ? _value.archivedBy
          : archivedBy // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      readBy: null == readBy
          ? _value.readBy
          : readBy // ignore: cast_nullable_to_non_nullable
              as Map<String, DateTime>,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageId: freezed == lastMessageId
          ? _value.lastMessageId
          : lastMessageId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageTimestamp: freezed == lastMessageTimestamp
          ? _value.lastMessageTimestamp
          : lastMessageTimestamp // ignore: cast_nullable_to_non_nullable
              as int?,
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageType: freezed == lastMessageType
          ? _value.lastMessageType
          : lastMessageType // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      admins: null == admins
          ? _value.admins
          : admins // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bannedUsers: null == bannedUsers
          ? _value.bannedUsers
          : bannedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isPasswordProtected: null == isPasswordProtected
          ? _value.isPasswordProtected
          : isPasswordProtected // ignore: cast_nullable_to_non_nullable
              as bool,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
      participants: null == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isGroup: freezed == isGroup
          ? _value.isGroup
          : isGroup // ignore: cast_nullable_to_non_nullable
              as bool?,
      requireApproval: freezed == requireApproval
          ? _value.requireApproval
          : requireApproval // ignore: cast_nullable_to_non_nullable
              as bool?,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      radius: null == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      participantCount: null == participantCount
          ? _value.participantCount
          : participantCount // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActivityAt: freezed == lastActivityAt
          ? _value.lastActivityAt
          : lastActivityAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isNsfw: null == isNsfw
          ? _value.isNsfw
          : isNsfw // ignore: cast_nullable_to_non_nullable
              as bool,
      rules: freezed == rules
          ? _value.rules
          : rules // ignore: cast_nullable_to_non_nullable
              as String?,
      themeColor: null == themeColor
          ? _value.themeColor
          : themeColor // ignore: cast_nullable_to_non_nullable
              as int,
      allowAnonymous: null == allowAnonymous
          ? _value.allowAnonymous
          : allowAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      activityLog: null == activityLog
          ? _value.activityLog
          : activityLog // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatRoomImplCopyWith<$Res>
    implements $ChatRoomCopyWith<$Res> {
  factory _$$ChatRoomImplCopyWith(
          _$ChatRoomImpl value, $Res Function(_$ChatRoomImpl) then) =
      __$$ChatRoomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      ChatRoomType type,
      List<String> memberIds,
      String createdBy,
      Map<String, ChatRoomRole> memberRoles,
      String? photoUrl,
      String? description,
      bool isPrivate,
      bool isPinned,
      Map<String, bool> mutedBy,
      Map<String, bool> archivedBy,
      Map<String, DateTime> readBy,
      DateTime? lastMessageAt,
      String? lastMessageId,
      int? lastMessageTimestamp,
      String? lastMessageSenderId,
      String? lastMessage,
      String? lastMessageType,
      Map<String, dynamic> metadata,
      List<String> admins,
      List<String> bannedUsers,
      bool isPasswordProtected,
      String? password,
      int maxMembers,
      List<String> participants,
      DateTime? createdAt,
      DateTime? updatedAt,
      bool? isGroup,
      bool? requireApproval,
      double latitude,
      double longitude,
      double radius,
      bool isActive,
      int participantCount,
      DateTime? expiresAt,
      DateTime? lastActivityAt,
      bool isNsfw,
      String? rules,
      int themeColor,
      bool allowAnonymous,
      Map<String, dynamic> activityLog});
}

/// @nodoc
class __$$ChatRoomImplCopyWithImpl<$Res>
    extends _$ChatRoomCopyWithImpl<$Res, _$ChatRoomImpl>
    implements _$$ChatRoomImplCopyWith<$Res> {
  __$$ChatRoomImplCopyWithImpl(
      _$ChatRoomImpl _value, $Res Function(_$ChatRoomImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? memberIds = null,
    Object? createdBy = null,
    Object? memberRoles = null,
    Object? photoUrl = freezed,
    Object? description = freezed,
    Object? isPrivate = null,
    Object? isPinned = null,
    Object? mutedBy = null,
    Object? archivedBy = null,
    Object? readBy = null,
    Object? lastMessageAt = freezed,
    Object? lastMessageId = freezed,
    Object? lastMessageTimestamp = freezed,
    Object? lastMessageSenderId = freezed,
    Object? lastMessage = freezed,
    Object? lastMessageType = freezed,
    Object? metadata = null,
    Object? admins = null,
    Object? bannedUsers = null,
    Object? isPasswordProtected = null,
    Object? password = freezed,
    Object? maxMembers = null,
    Object? participants = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? isGroup = freezed,
    Object? requireApproval = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? radius = null,
    Object? isActive = null,
    Object? participantCount = null,
    Object? expiresAt = freezed,
    Object? lastActivityAt = freezed,
    Object? isNsfw = null,
    Object? rules = freezed,
    Object? themeColor = null,
    Object? allowAnonymous = null,
    Object? activityLog = null,
  }) {
    return _then(_$ChatRoomImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ChatRoomType,
      memberIds: null == memberIds
          ? _value._memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      memberRoles: null == memberRoles
          ? _value._memberRoles
          : memberRoles // ignore: cast_nullable_to_non_nullable
              as Map<String, ChatRoomRole>,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      mutedBy: null == mutedBy
          ? _value._mutedBy
          : mutedBy // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      archivedBy: null == archivedBy
          ? _value._archivedBy
          : archivedBy // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      readBy: null == readBy
          ? _value._readBy
          : readBy // ignore: cast_nullable_to_non_nullable
              as Map<String, DateTime>,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageId: freezed == lastMessageId
          ? _value.lastMessageId
          : lastMessageId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageTimestamp: freezed == lastMessageTimestamp
          ? _value.lastMessageTimestamp
          : lastMessageTimestamp // ignore: cast_nullable_to_non_nullable
              as int?,
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageType: freezed == lastMessageType
          ? _value.lastMessageType
          : lastMessageType // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      admins: null == admins
          ? _value._admins
          : admins // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bannedUsers: null == bannedUsers
          ? _value._bannedUsers
          : bannedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isPasswordProtected: null == isPasswordProtected
          ? _value.isPasswordProtected
          : isPasswordProtected // ignore: cast_nullable_to_non_nullable
              as bool,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
      participants: null == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isGroup: freezed == isGroup
          ? _value.isGroup
          : isGroup // ignore: cast_nullable_to_non_nullable
              as bool?,
      requireApproval: freezed == requireApproval
          ? _value.requireApproval
          : requireApproval // ignore: cast_nullable_to_non_nullable
              as bool?,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      radius: null == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      participantCount: null == participantCount
          ? _value.participantCount
          : participantCount // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActivityAt: freezed == lastActivityAt
          ? _value.lastActivityAt
          : lastActivityAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isNsfw: null == isNsfw
          ? _value.isNsfw
          : isNsfw // ignore: cast_nullable_to_non_nullable
              as bool,
      rules: freezed == rules
          ? _value.rules
          : rules // ignore: cast_nullable_to_non_nullable
              as String?,
      themeColor: null == themeColor
          ? _value.themeColor
          : themeColor // ignore: cast_nullable_to_non_nullable
              as int,
      allowAnonymous: null == allowAnonymous
          ? _value.allowAnonymous
          : allowAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      activityLog: null == activityLog
          ? _value._activityLog
          : activityLog // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatRoomImpl extends _ChatRoom {
  const _$ChatRoomImpl(
      {required this.id,
      required this.name,
      required this.type,
      required final List<String> memberIds,
      required this.createdBy,
      final Map<String, ChatRoomRole> memberRoles = const {},
      this.photoUrl,
      this.description,
      this.isPrivate = false,
      this.isPinned = false,
      final Map<String, bool> mutedBy = const {},
      final Map<String, bool> archivedBy = const {},
      final Map<String, DateTime> readBy = const {},
      this.lastMessageAt,
      this.lastMessageId,
      this.lastMessageTimestamp,
      this.lastMessageSenderId,
      this.lastMessage,
      this.lastMessageType,
      final Map<String, dynamic> metadata = const {},
      final List<String> admins = const [],
      final List<String> bannedUsers = const [],
      this.isPasswordProtected = false,
      this.password,
      this.maxMembers = 100,
      final List<String> participants = const [],
      this.createdAt,
      this.updatedAt,
      this.isGroup,
      this.requireApproval,
      required this.latitude,
      required this.longitude,
      this.radius = 5.0,
      this.isActive = true,
      this.participantCount = 0,
      this.expiresAt,
      this.lastActivityAt,
      this.isNsfw = false,
      this.rules,
      this.themeColor = 0xFF2196F3,
      this.allowAnonymous = false,
      final Map<String, dynamic> activityLog = const {}})
      : _memberIds = memberIds,
        _memberRoles = memberRoles,
        _mutedBy = mutedBy,
        _archivedBy = archivedBy,
        _readBy = readBy,
        _metadata = metadata,
        _admins = admins,
        _bannedUsers = bannedUsers,
        _participants = participants,
        _activityLog = activityLog,
        super._();

  factory _$ChatRoomImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatRoomImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final ChatRoomType type;
  final List<String> _memberIds;
  @override
  List<String> get memberIds {
    if (_memberIds is EqualUnmodifiableListView) return _memberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memberIds);
  }

  @override
  final String createdBy;
  final Map<String, ChatRoomRole> _memberRoles;
  @override
  @JsonKey()
  Map<String, ChatRoomRole> get memberRoles {
    if (_memberRoles is EqualUnmodifiableMapView) return _memberRoles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_memberRoles);
  }

  @override
  final String? photoUrl;
  @override
  final String? description;
  @override
  @JsonKey()
  final bool isPrivate;
  @override
  @JsonKey()
  final bool isPinned;
  final Map<String, bool> _mutedBy;
  @override
  @JsonKey()
  Map<String, bool> get mutedBy {
    if (_mutedBy is EqualUnmodifiableMapView) return _mutedBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_mutedBy);
  }

  final Map<String, bool> _archivedBy;
  @override
  @JsonKey()
  Map<String, bool> get archivedBy {
    if (_archivedBy is EqualUnmodifiableMapView) return _archivedBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_archivedBy);
  }

  final Map<String, DateTime> _readBy;
  @override
  @JsonKey()
  Map<String, DateTime> get readBy {
    if (_readBy is EqualUnmodifiableMapView) return _readBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_readBy);
  }

  @override
  final DateTime? lastMessageAt;
  @override
  final String? lastMessageId;
  @override
  final int? lastMessageTimestamp;
  @override
  final String? lastMessageSenderId;
  @override
  final String? lastMessage;
  @override
  final String? lastMessageType;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  final List<String> _admins;
  @override
  @JsonKey()
  List<String> get admins {
    if (_admins is EqualUnmodifiableListView) return _admins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_admins);
  }

  final List<String> _bannedUsers;
  @override
  @JsonKey()
  List<String> get bannedUsers {
    if (_bannedUsers is EqualUnmodifiableListView) return _bannedUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bannedUsers);
  }

  @override
  @JsonKey()
  final bool isPasswordProtected;
  @override
  final String? password;
  @override
  @JsonKey()
  final int maxMembers;
  final List<String> _participants;
  @override
  @JsonKey()
  List<String> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final bool? isGroup;
  @override
  final bool? requireApproval;
// Location-based properties
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey()
  final double radius;
// Default radius in km
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final int participantCount;
// New properties for expiration and customization
  @override
  final DateTime? expiresAt;
// Auto-expiration timestamp (24 hours from creation/last activity)
  @override
  final DateTime? lastActivityAt;
// Timestamp of last activity in the room
  @override
  @JsonKey()
  final bool isNsfw;
// Flag for NSFW content
  @override
  final String? rules;
// Optional rules for the chat room
  @override
  @JsonKey()
  final int themeColor;
// Theme color for the chat room UI (default blue)
  @override
  @JsonKey()
  final bool allowAnonymous;
// Whether to allow anonymous users to join
  final Map<String, dynamic> _activityLog;
// Whether to allow anonymous users to join
  @override
  @JsonKey()
  Map<String, dynamic> get activityLog {
    if (_activityLog is EqualUnmodifiableMapView) return _activityLog;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_activityLog);
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, name: $name, type: $type, memberIds: $memberIds, createdBy: $createdBy, memberRoles: $memberRoles, photoUrl: $photoUrl, description: $description, isPrivate: $isPrivate, isPinned: $isPinned, mutedBy: $mutedBy, archivedBy: $archivedBy, readBy: $readBy, lastMessageAt: $lastMessageAt, lastMessageId: $lastMessageId, lastMessageTimestamp: $lastMessageTimestamp, lastMessageSenderId: $lastMessageSenderId, lastMessage: $lastMessage, lastMessageType: $lastMessageType, metadata: $metadata, admins: $admins, bannedUsers: $bannedUsers, isPasswordProtected: $isPasswordProtected, password: $password, maxMembers: $maxMembers, participants: $participants, createdAt: $createdAt, updatedAt: $updatedAt, isGroup: $isGroup, requireApproval: $requireApproval, latitude: $latitude, longitude: $longitude, radius: $radius, isActive: $isActive, participantCount: $participantCount, expiresAt: $expiresAt, lastActivityAt: $lastActivityAt, isNsfw: $isNsfw, rules: $rules, themeColor: $themeColor, allowAnonymous: $allowAnonymous, activityLog: $activityLog)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatRoomImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other._memberIds, _memberIds) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            const DeepCollectionEquality()
                .equals(other._memberRoles, _memberRoles) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            const DeepCollectionEquality().equals(other._mutedBy, _mutedBy) &&
            const DeepCollectionEquality()
                .equals(other._archivedBy, _archivedBy) &&
            const DeepCollectionEquality().equals(other._readBy, _readBy) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.lastMessageId, lastMessageId) ||
                other.lastMessageId == lastMessageId) &&
            (identical(other.lastMessageTimestamp, lastMessageTimestamp) ||
                other.lastMessageTimestamp == lastMessageTimestamp) &&
            (identical(other.lastMessageSenderId, lastMessageSenderId) ||
                other.lastMessageSenderId == lastMessageSenderId) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageType, lastMessageType) ||
                other.lastMessageType == lastMessageType) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            const DeepCollectionEquality().equals(other._admins, _admins) &&
            const DeepCollectionEquality()
                .equals(other._bannedUsers, _bannedUsers) &&
            (identical(other.isPasswordProtected, isPasswordProtected) ||
                other.isPasswordProtected == isPasswordProtected) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.maxMembers, maxMembers) ||
                other.maxMembers == maxMembers) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isGroup, isGroup) || other.isGroup == isGroup) &&
            (identical(other.requireApproval, requireApproval) ||
                other.requireApproval == requireApproval) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.radius, radius) || other.radius == radius) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.participantCount, participantCount) ||
                other.participantCount == participantCount) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.lastActivityAt, lastActivityAt) ||
                other.lastActivityAt == lastActivityAt) &&
            (identical(other.isNsfw, isNsfw) || other.isNsfw == isNsfw) &&
            (identical(other.rules, rules) || other.rules == rules) &&
            (identical(other.themeColor, themeColor) ||
                other.themeColor == themeColor) &&
            (identical(other.allowAnonymous, allowAnonymous) ||
                other.allowAnonymous == allowAnonymous) &&
            const DeepCollectionEquality()
                .equals(other._activityLog, _activityLog));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        type,
        const DeepCollectionEquality().hash(_memberIds),
        createdBy,
        const DeepCollectionEquality().hash(_memberRoles),
        photoUrl,
        description,
        isPrivate,
        isPinned,
        const DeepCollectionEquality().hash(_mutedBy),
        const DeepCollectionEquality().hash(_archivedBy),
        const DeepCollectionEquality().hash(_readBy),
        lastMessageAt,
        lastMessageId,
        lastMessageTimestamp,
        lastMessageSenderId,
        lastMessage,
        lastMessageType,
        const DeepCollectionEquality().hash(_metadata),
        const DeepCollectionEquality().hash(_admins),
        const DeepCollectionEquality().hash(_bannedUsers),
        isPasswordProtected,
        password,
        maxMembers,
        const DeepCollectionEquality().hash(_participants),
        createdAt,
        updatedAt,
        isGroup,
        requireApproval,
        latitude,
        longitude,
        radius,
        isActive,
        participantCount,
        expiresAt,
        lastActivityAt,
        isNsfw,
        rules,
        themeColor,
        allowAnonymous,
        const DeepCollectionEquality().hash(_activityLog)
      ]);

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatRoomImplCopyWith<_$ChatRoomImpl> get copyWith =>
      __$$ChatRoomImplCopyWithImpl<_$ChatRoomImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatRoomImplToJson(
      this,
    );
  }
}

abstract class _ChatRoom extends ChatRoom {
  const factory _ChatRoom(
      {required final String id,
      required final String name,
      required final ChatRoomType type,
      required final List<String> memberIds,
      required final String createdBy,
      final Map<String, ChatRoomRole> memberRoles,
      final String? photoUrl,
      final String? description,
      final bool isPrivate,
      final bool isPinned,
      final Map<String, bool> mutedBy,
      final Map<String, bool> archivedBy,
      final Map<String, DateTime> readBy,
      final DateTime? lastMessageAt,
      final String? lastMessageId,
      final int? lastMessageTimestamp,
      final String? lastMessageSenderId,
      final String? lastMessage,
      final String? lastMessageType,
      final Map<String, dynamic> metadata,
      final List<String> admins,
      final List<String> bannedUsers,
      final bool isPasswordProtected,
      final String? password,
      final int maxMembers,
      final List<String> participants,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final bool? isGroup,
      final bool? requireApproval,
      required final double latitude,
      required final double longitude,
      final double radius,
      final bool isActive,
      final int participantCount,
      final DateTime? expiresAt,
      final DateTime? lastActivityAt,
      final bool isNsfw,
      final String? rules,
      final int themeColor,
      final bool allowAnonymous,
      final Map<String, dynamic> activityLog}) = _$ChatRoomImpl;
  const _ChatRoom._() : super._();

  factory _ChatRoom.fromJson(Map<String, dynamic> json) =
      _$ChatRoomImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  ChatRoomType get type;
  @override
  List<String> get memberIds;
  @override
  String get createdBy;
  @override
  Map<String, ChatRoomRole> get memberRoles;
  @override
  String? get photoUrl;
  @override
  String? get description;
  @override
  bool get isPrivate;
  @override
  bool get isPinned;
  @override
  Map<String, bool> get mutedBy;
  @override
  Map<String, bool> get archivedBy;
  @override
  Map<String, DateTime> get readBy;
  @override
  DateTime? get lastMessageAt;
  @override
  String? get lastMessageId;
  @override
  int? get lastMessageTimestamp;
  @override
  String? get lastMessageSenderId;
  @override
  String? get lastMessage;
  @override
  String? get lastMessageType;
  @override
  Map<String, dynamic> get metadata;
  @override
  List<String> get admins;
  @override
  List<String> get bannedUsers;
  @override
  bool get isPasswordProtected;
  @override
  String? get password;
  @override
  int get maxMembers;
  @override
  List<String> get participants;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  bool? get isGroup;
  @override
  bool? get requireApproval; // Location-based properties
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double get radius; // Default radius in km
  @override
  bool get isActive;
  @override
  int get participantCount; // New properties for expiration and customization
  @override
  DateTime?
      get expiresAt; // Auto-expiration timestamp (24 hours from creation/last activity)
  @override
  DateTime? get lastActivityAt; // Timestamp of last activity in the room
  @override
  bool get isNsfw; // Flag for NSFW content
  @override
  String? get rules; // Optional rules for the chat room
  @override
  int get themeColor; // Theme color for the chat room UI (default blue)
  @override
  bool get allowAnonymous; // Whether to allow anonymous users to join
  @override
  Map<String, dynamic> get activityLog;

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatRoomImplCopyWith<_$ChatRoomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
