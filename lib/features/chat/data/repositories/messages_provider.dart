import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/message_model.dart';
import 'chat_repository.dart';

part 'messages_provider.g.dart';

/// Provider للحصول على رسائل محادثة معينة
@riverpod
Future<List<MessageModel>> chatMessages(
  ChatMessagesRef ref,
  String chatId,
) async {
  final repository = ref.read(chatRepositoryProvider.notifier);
  return repository.getMessages(chatId);
}

