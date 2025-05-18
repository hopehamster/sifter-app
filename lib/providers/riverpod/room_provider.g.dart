// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$roomHash() => r'4c34c6a23ef0f1508de4e7b6935ce196b09681eb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [room].
@ProviderFor(room)
const roomProvider = RoomFamily();

/// See also [room].
class RoomFamily extends Family<AsyncValue<ChatRoom>> {
  /// See also [room].
  const RoomFamily();

  /// See also [room].
  RoomProvider call(
    String roomId,
  ) {
    return RoomProvider(
      roomId,
    );
  }

  @override
  RoomProvider getProviderOverride(
    covariant RoomProvider provider,
  ) {
    return call(
      provider.roomId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'roomProvider';
}

/// See also [room].
class RoomProvider extends AutoDisposeFutureProvider<ChatRoom> {
  /// See also [room].
  RoomProvider(
    String roomId,
  ) : this._internal(
          (ref) => room(
            ref as RoomRef,
            roomId,
          ),
          from: roomProvider,
          name: r'roomProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$roomHash,
          dependencies: RoomFamily._dependencies,
          allTransitiveDependencies: RoomFamily._allTransitiveDependencies,
          roomId: roomId,
        );

  RoomProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.roomId,
  }) : super.internal();

  final String roomId;

  @override
  Override overrideWith(
    FutureOr<ChatRoom> Function(RoomRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RoomProvider._internal(
        (ref) => create(ref as RoomRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        roomId: roomId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChatRoom> createElement() {
    return _RoomProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomProvider && other.roomId == roomId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, roomId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RoomRef on AutoDisposeFutureProviderRef<ChatRoom> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _RoomProviderElement extends AutoDisposeFutureProviderElement<ChatRoom>
    with RoomRef {
  _RoomProviderElement(super.provider);

  @override
  String get roomId => (origin as RoomProvider).roomId;
}

String _$roomServiceHash() => r'94818342849760bf1338a0e4c5fe4db075f2f5ec';

/// See also [roomService].
@ProviderFor(roomService)
final roomServiceProvider = AutoDisposeProvider<RoomService>.internal(
  roomService,
  name: r'roomServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$roomServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RoomServiceRef = AutoDisposeProviderRef<RoomService>;
String _$roomNotifierHash() => r'2d3b383fcb94492174a284c6e16da8e2e35419f8';

/// See also [RoomNotifier].
@ProviderFor(RoomNotifier)
final roomNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RoomNotifier, List<ChatRoom>>.internal(
  RoomNotifier.new,
  name: r'roomNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$roomNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RoomNotifier = AutoDisposeAsyncNotifier<List<ChatRoom>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
