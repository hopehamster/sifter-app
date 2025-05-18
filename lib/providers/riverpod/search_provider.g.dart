// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchServiceHash() => r'9ca078480a21f7ca8d46f22fb7a6c3659dda912a';

/// See also [searchService].
@ProviderFor(searchService)
final searchServiceProvider = AutoDisposeProvider<SearchService>.internal(
  searchService,
  name: r'searchServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchServiceRef = AutoDisposeProviderRef<SearchService>;
String _$searchNotifierHash() => r'147cfa5c024919a909bd447c59027621284d031c';

/// See also [SearchNotifier].
@ProviderFor(SearchNotifier)
final searchNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SearchNotifier, SearchResults>.internal(
  SearchNotifier.new,
  name: r'searchNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchNotifier = AutoDisposeAsyncNotifier<SearchResults>;
String _$searchHistoryNotifierHash() =>
    r'ac65e4a3600b518e9bd2843f9b07a242100eedd9';

/// See also [SearchHistoryNotifier].
@ProviderFor(SearchHistoryNotifier)
final searchHistoryNotifierProvider = AutoDisposeAsyncNotifierProvider<
    SearchHistoryNotifier, List<String>>.internal(
  SearchHistoryNotifier.new,
  name: r'searchHistoryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchHistoryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchHistoryNotifier = AutoDisposeAsyncNotifier<List<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
