// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$themeHash() => r'a3a3ee1a1ab63d70318a8393654a3f23b8c6189c';

/// Provider للحصول على الثيم الحالي
///
/// Copied from [theme].
@ProviderFor(theme)
final themeProvider = AutoDisposeProvider<ThemeData>.internal(
  theme,
  name: r'themeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ThemeRef = AutoDisposeProviderRef<ThemeData>;
String _$themeNotifierHash() => r'bb76663c1933cc320746be05c88469cf0eec6ebe';

/// Provider لإدارة وضع الثيم
/// يحفظ التفضيلات في SharedPreferences
///
/// Copied from [ThemeNotifier].
@ProviderFor(ThemeNotifier)
final themeNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ThemeNotifier, ThemeModeOption>.internal(
      ThemeNotifier.new,
      name: r'themeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeNotifier = AutoDisposeAsyncNotifier<ThemeModeOption>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
