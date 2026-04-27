// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatRepositoryHash() => r'9b5a5764e07e68e62dd3ce42fef4b1f8b6501b3f';

/// Repository للمحادثات
/// يحصل على المحادثات من قاعدة البيانات المحلية
///
/// Copied from [ChatRepository].
@ProviderFor(ChatRepository)
final chatRepositoryProvider =
    AutoDisposeAsyncNotifierProvider<ChatRepository, List<ChatModel>>.internal(
      ChatRepository.new,
      name: r'chatRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chatRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ChatRepository = AutoDisposeAsyncNotifier<List<ChatModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
