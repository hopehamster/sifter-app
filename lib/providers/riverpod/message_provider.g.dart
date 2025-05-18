// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageServiceHash() => r'17cb7cf318f1040fd8362e6f9892818f3b1db5aa';

/// See also [messageService].
@ProviderFor(messageService)
final messageServiceProvider = AutoDisposeProvider<MessageService>.internal(
  messageService,
  name: r'messageServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessageServiceRef = AutoDisposeProviderRef<MessageService>;
String _$storageServiceHash() => r'b9eb09cfea0c265efa80435bdffda55cb5e6d8ba';

/// See also [storageService].
@ProviderFor(storageService)
final storageServiceProvider = AutoDisposeProvider<StorageService>.internal(
  storageService,
  name: r'storageServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storageServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StorageServiceRef = AutoDisposeProviderRef<StorageService>;
String _$roomMessagesNotifierHash() =>
    r'a72988c51c2fcb33050dac83fb0a76a97da2962b';

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

abstract class _$RoomMessagesNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Message>> {
  late final String roomId;

  FutureOr<List<Message>> build(
    String roomId,
  );
}

/// See also [RoomMessagesNotifier].
@ProviderFor(RoomMessagesNotifier)
const roomMessagesNotifierProvider = RoomMessagesNotifierFamily();

/// See also [RoomMessagesNotifier].
class RoomMessagesNotifierFamily extends Family<AsyncValue<List<Message>>> {
  /// See also [RoomMessagesNotifier].
  const RoomMessagesNotifierFamily();

  /// See also [RoomMessagesNotifier].
  RoomMessagesNotifierProvider call(
    String roomId,
  ) {
    return RoomMessagesNotifierProvider(
      roomId,
    );
  }

  @override
  RoomMessagesNotifierProvider getProviderOverride(
    covariant RoomMessagesNotifierProvider provider,
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
  String? get name => r'roomMessagesNotifierProvider';
}

/// See also [RoomMessagesNotifier].
class RoomMessagesNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RoomMessagesNotifier, List<Message>> {
  /// See also [RoomMessagesNotifier].
  RoomMessagesNotifierProvider(
    String roomId,
  ) : this._internal(
          () => RoomMessagesNotifier()..roomId = roomId,
          from: roomMessagesNotifierProvider,
          name: r'roomMessagesNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$roomMessagesNotifierHash,
          dependencies: RoomMessagesNotifierFamily._dependencies,
          allTransitiveDependencies:
              RoomMessagesNotifierFamily._allTransitiveDependencies,
          roomId: roomId,
        );

  RoomMessagesNotifierProvider._internal(
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
  FutureOr<List<Message>> runNotifierBuild(
    covariant RoomMessagesNotifier notifier,
  ) {
    return notifier.build(
      roomId,
    );
  }

  @override
  Override overrideWith(RoomMessagesNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RoomMessagesNotifierProvider._internal(
        () => create()..roomId = roomId,
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
  AutoDisposeAsyncNotifierProviderElement<RoomMessagesNotifier, List<Message>>
      createElement() {
    return _RoomMessagesNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomMessagesNotifierProvider && other.roomId == roomId;
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
mixin RoomMessagesNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<Message>> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _RoomMessagesNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RoomMessagesNotifier,
        List<Message>> with RoomMessagesNotifierRef {
  _RoomMessagesNotifierProviderElement(super.provider);

  @override
  String get roomId => (origin as RoomMessagesNotifierProvider).roomId;
}

String _$messageCacheHash() => r'819b9acb50a0101aade98f37f4b48b619c29a48a';

/// See also [MessageCache].
@ProviderFor(MessageCache)
final messageCacheProvider = AutoDisposeNotifierProvider<MessageCache,
    Map<String, List<Message>>>.internal(
  MessageCache.new,
  name: r'messageCacheProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$messageCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MessageCache = AutoDisposeNotifier<Map<String, List<Message>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
