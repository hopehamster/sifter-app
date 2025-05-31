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
  String get description => throw _privateConstructorUsedError;
  String get creatorId => throw _privateConstructorUsedError;
  String get creatorName =>
      throw _privateConstructorUsedError; // Geofencing data
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double get radiusInMeters =>
      throw _privateConstructorUsedError; // Chat settings
  bool get isPasswordProtected => throw _privateConstructorUsedError;
  String? get password => throw _privateConstructorUsedError;
  bool get isNsfw => throw _privateConstructorUsedError;
  bool get allowAnonymous => throw _privateConstructorUsedError;
  int get maxMembers => throw _privateConstructorUsedError; // Timestamps
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // Participant tracking
  List<String> get participantIds => throw _privateConstructorUsedError;
  List<String> get bannedUserIds =>
      throw _privateConstructorUsedError; // Chat state
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError; // Moderation
  Map<String, String> get userRoles => throw _privateConstructorUsedError;

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
      String description,
      String creatorId,
      String creatorName,
      double latitude,
      double longitude,
      double radiusInMeters,
      bool isPasswordProtected,
      String? password,
      bool isNsfw,
      bool allowAnonymous,
      int maxMembers,
      DateTime createdAt,
      DateTime updatedAt,
      List<String> participantIds,
      List<String> bannedUserIds,
      bool isActive,
      DateTime? expiresAt,
      Map<String, String> userRoles});
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
    Object? description = null,
    Object? creatorId = null,
    Object? creatorName = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? radiusInMeters = null,
    Object? isPasswordProtected = null,
    Object? password = freezed,
    Object? isNsfw = null,
    Object? allowAnonymous = null,
    Object? maxMembers = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? participantIds = null,
    Object? bannedUserIds = null,
    Object? isActive = null,
    Object? expiresAt = freezed,
    Object? userRoles = null,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      creatorId: null == creatorId
          ? _value.creatorId
          : creatorId // ignore: cast_nullable_to_non_nullable
              as String,
      creatorName: null == creatorName
          ? _value.creatorName
          : creatorName // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      radiusInMeters: null == radiusInMeters
          ? _value.radiusInMeters
          : radiusInMeters // ignore: cast_nullable_to_non_nullable
              as double,
      isPasswordProtected: null == isPasswordProtected
          ? _value.isPasswordProtected
          : isPasswordProtected // ignore: cast_nullable_to_non_nullable
              as bool,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      isNsfw: null == isNsfw
          ? _value.isNsfw
          : isNsfw // ignore: cast_nullable_to_non_nullable
              as bool,
      allowAnonymous: null == allowAnonymous
          ? _value.allowAnonymous
          : allowAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      participantIds: null == participantIds
          ? _value.participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bannedUserIds: null == bannedUserIds
          ? _value.bannedUserIds
          : bannedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userRoles: null == userRoles
          ? _value.userRoles
          : userRoles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
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
      String description,
      String creatorId,
      String creatorName,
      double latitude,
      double longitude,
      double radiusInMeters,
      bool isPasswordProtected,
      String? password,
      bool isNsfw,
      bool allowAnonymous,
      int maxMembers,
      DateTime createdAt,
      DateTime updatedAt,
      List<String> participantIds,
      List<String> bannedUserIds,
      bool isActive,
      DateTime? expiresAt,
      Map<String, String> userRoles});
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
    Object? description = null,
    Object? creatorId = null,
    Object? creatorName = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? radiusInMeters = null,
    Object? isPasswordProtected = null,
    Object? password = freezed,
    Object? isNsfw = null,
    Object? allowAnonymous = null,
    Object? maxMembers = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? participantIds = null,
    Object? bannedUserIds = null,
    Object? isActive = null,
    Object? expiresAt = freezed,
    Object? userRoles = null,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      creatorId: null == creatorId
          ? _value.creatorId
          : creatorId // ignore: cast_nullable_to_non_nullable
              as String,
      creatorName: null == creatorName
          ? _value.creatorName
          : creatorName // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      radiusInMeters: null == radiusInMeters
          ? _value.radiusInMeters
          : radiusInMeters // ignore: cast_nullable_to_non_nullable
              as double,
      isPasswordProtected: null == isPasswordProtected
          ? _value.isPasswordProtected
          : isPasswordProtected // ignore: cast_nullable_to_non_nullable
              as bool,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      isNsfw: null == isNsfw
          ? _value.isNsfw
          : isNsfw // ignore: cast_nullable_to_non_nullable
              as bool,
      allowAnonymous: null == allowAnonymous
          ? _value.allowAnonymous
          : allowAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      participantIds: null == participantIds
          ? _value._participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bannedUserIds: null == bannedUserIds
          ? _value._bannedUserIds
          : bannedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userRoles: null == userRoles
          ? _value._userRoles
          : userRoles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatRoomImpl extends _ChatRoom {
  const _$ChatRoomImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.creatorId,
      required this.creatorName,
      required this.latitude,
      required this.longitude,
      required this.radiusInMeters,
      this.isPasswordProtected = false,
      this.password,
      this.isNsfw = false,
      this.allowAnonymous = false,
      this.maxMembers = 50,
      required this.createdAt,
      required this.updatedAt,
      final List<String> participantIds = const <String>[],
      final List<String> bannedUserIds = const <String>[],
      this.isActive = true,
      this.expiresAt,
      final Map<String, String> userRoles = const <String, String>{}})
      : _participantIds = participantIds,
        _bannedUserIds = bannedUserIds,
        _userRoles = userRoles,
        super._();

  factory _$ChatRoomImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatRoomImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String creatorId;
  @override
  final String creatorName;
// Geofencing data
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double radiusInMeters;
// Chat settings
  @override
  @JsonKey()
  final bool isPasswordProtected;
  @override
  final String? password;
  @override
  @JsonKey()
  final bool isNsfw;
  @override
  @JsonKey()
  final bool allowAnonymous;
  @override
  @JsonKey()
  final int maxMembers;
// Timestamps
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
// Participant tracking
  final List<String> _participantIds;
// Participant tracking
  @override
  @JsonKey()
  List<String> get participantIds {
    if (_participantIds is EqualUnmodifiableListView) return _participantIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantIds);
  }

  final List<String> _bannedUserIds;
  @override
  @JsonKey()
  List<String> get bannedUserIds {
    if (_bannedUserIds is EqualUnmodifiableListView) return _bannedUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bannedUserIds);
  }

// Chat state
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? expiresAt;
// Moderation
  final Map<String, String> _userRoles;
// Moderation
  @override
  @JsonKey()
  Map<String, String> get userRoles {
    if (_userRoles is EqualUnmodifiableMapView) return _userRoles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_userRoles);
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, name: $name, description: $description, creatorId: $creatorId, creatorName: $creatorName, latitude: $latitude, longitude: $longitude, radiusInMeters: $radiusInMeters, isPasswordProtected: $isPasswordProtected, password: $password, isNsfw: $isNsfw, allowAnonymous: $allowAnonymous, maxMembers: $maxMembers, createdAt: $createdAt, updatedAt: $updatedAt, participantIds: $participantIds, bannedUserIds: $bannedUserIds, isActive: $isActive, expiresAt: $expiresAt, userRoles: $userRoles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatRoomImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId) &&
            (identical(other.creatorName, creatorName) ||
                other.creatorName == creatorName) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.radiusInMeters, radiusInMeters) ||
                other.radiusInMeters == radiusInMeters) &&
            (identical(other.isPasswordProtected, isPasswordProtected) ||
                other.isPasswordProtected == isPasswordProtected) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.isNsfw, isNsfw) || other.isNsfw == isNsfw) &&
            (identical(other.allowAnonymous, allowAnonymous) ||
                other.allowAnonymous == allowAnonymous) &&
            (identical(other.maxMembers, maxMembers) ||
                other.maxMembers == maxMembers) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality()
                .equals(other._participantIds, _participantIds) &&
            const DeepCollectionEquality()
                .equals(other._bannedUserIds, _bannedUserIds) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            const DeepCollectionEquality()
                .equals(other._userRoles, _userRoles));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        description,
        creatorId,
        creatorName,
        latitude,
        longitude,
        radiusInMeters,
        isPasswordProtected,
        password,
        isNsfw,
        allowAnonymous,
        maxMembers,
        createdAt,
        updatedAt,
        const DeepCollectionEquality().hash(_participantIds),
        const DeepCollectionEquality().hash(_bannedUserIds),
        isActive,
        expiresAt,
        const DeepCollectionEquality().hash(_userRoles)
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
      required final String description,
      required final String creatorId,
      required final String creatorName,
      required final double latitude,
      required final double longitude,
      required final double radiusInMeters,
      final bool isPasswordProtected,
      final String? password,
      final bool isNsfw,
      final bool allowAnonymous,
      final int maxMembers,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final List<String> participantIds,
      final List<String> bannedUserIds,
      final bool isActive,
      final DateTime? expiresAt,
      final Map<String, String> userRoles}) = _$ChatRoomImpl;
  const _ChatRoom._() : super._();

  factory _ChatRoom.fromJson(Map<String, dynamic> json) =
      _$ChatRoomImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get creatorId;
  @override
  String get creatorName; // Geofencing data
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double get radiusInMeters; // Chat settings
  @override
  bool get isPasswordProtected;
  @override
  String? get password;
  @override
  bool get isNsfw;
  @override
  bool get allowAnonymous;
  @override
  int get maxMembers; // Timestamps
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt; // Participant tracking
  @override
  List<String> get participantIds;
  @override
  List<String> get bannedUserIds; // Chat state
  @override
  bool get isActive;
  @override
  DateTime? get expiresAt; // Moderation
  @override
  Map<String, String> get userRoles;

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatRoomImplCopyWith<_$ChatRoomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
