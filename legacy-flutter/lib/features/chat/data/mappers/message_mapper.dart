import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/message_model.dart';

/// Mapper لتحويل MessagesTableData إلى MessageModel
class MessageMapper {
  /// تحويل MessagesTableData إلى MessageModel
  static MessageModel toDomain(MessagesTableData data) {
    // تحويل status string إلى MessageStatus enum
    final status = _fromStatusString(data.status);

    return MessageModel(
      id: data.id,
      text: data.content, // في المستقبل، سيتم فك التشفير هنا
      encryptedText: data.content, // المحتوى المشفر
      isMe: data.isFromMe,
      timestamp: data.timestamp,
      status: status,
    );
  }

  /// تحويل MessageModel إلى MessagesTableCompanion
  static MessagesTableCompanion toCompanion(
    MessageModel model,
    String chatId,
    String senderId,
  ) {
    // تحويل MessageStatus إلى string
    final statusString = _toStatusString(model.status);

    return MessagesTableCompanion.insert(
      id: model.id,
      chatId: chatId,
      senderId: senderId,
      content: model.encryptedText ?? model.text, // استخدام النص المشفر إذا كان موجوداً
      type: const Value('text'),
      status: Value(statusString),
      timestamp: Value(model.timestamp),
      isFromMe: Value(model.isMe),
      replyToId: const Value.absent(),
    );
  }

  /// تحويل string من قاعدة البيانات إلى MessageStatus آمن
  static MessageStatus _fromStatusString(String raw) {
    switch (raw) {
      case 'draft':
        return MessageStatus.draft;
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        // fallback معقول للحالات غير المعروفة أو القديمة
        return MessageStatus.sent;
    }
  }

  /// تحويل MessageStatus إلى string لقاعدة البيانات
  static String _toStatusString(MessageStatus status) {
    switch (status) {
      case MessageStatus.draft:
        return 'draft';
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }
}

