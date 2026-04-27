// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingRepositoryHash() =>
    r'ff6f3cb9afe3806058579218d0c94112674f74bc';

/// Repository لإدارة حالة Onboarding
/// يحفظ حالة إكمال Onboarding في SharedPreferences
///
/// Copied from [OnboardingRepository].
@ProviderFor(OnboardingRepository)
final onboardingRepositoryProvider =
    AutoDisposeAsyncNotifierProvider<OnboardingRepository, bool>.internal(
      OnboardingRepository.new,
      name: r'onboardingRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$onboardingRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnboardingRepository = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
