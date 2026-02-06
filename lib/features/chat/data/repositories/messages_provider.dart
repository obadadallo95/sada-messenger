import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/message_model.dart';
import '../../../../core/database/database_provider.dart';
import '../mappers/message_mapper.dart';

part 'messages_provider.g.dart';

/// Provider للحصول على رسائل محادثة معينة (Stream)
/// يعيد تحديث تلقائي عند إضافة رسائل جديدة
@riverpod
Stream<List<MessageModel>> chatMessages(
  Ref ref,
  String chatId,
) async* {
  final database = await ref.watch(appDatabaseProvider.future);
  
  // مراقبة الرسائل في المحادثة
  await for (final messages in database.watchMessagesForChat(chatId)) {
    // تحويل MessagesTableData إلى MessageModel
    yield messages.map((msg) => MessageMapper.toDomain(msg)).toList();
  }
}

