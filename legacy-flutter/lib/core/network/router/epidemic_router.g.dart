// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epidemic_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$epidemicRouterHash() => r'6c096c32faeeecc19816635ce422377bf0324920';

/// Manages the "Epidemic Routing" strategy for the Delay-Tolerant Network.
/// Handles:
/// 1. Discovery of nearby peers (via Nearby Connections API).
/// 2. Handshake and Exchange of held packets (Bloom Filter / Vector Summary).
/// 3. Store-Carry-Forward logic (Blind Relaying).
///
/// Copied from [EpidemicRouter].
@ProviderFor(EpidemicRouter)
final epidemicRouterProvider =
    AsyncNotifierProvider<EpidemicRouter, void>.internal(
      EpidemicRouter.new,
      name: r'epidemicRouterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$epidemicRouterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EpidemicRouter = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
