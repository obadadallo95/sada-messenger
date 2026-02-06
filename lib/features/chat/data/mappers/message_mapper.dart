import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/message_model.dart';

/// Mapper لتحويل MessagesTableData إلى MessageModel
class MessageMapper {
  /// تحويل MessagesTableData إلى MessageModel
  static MessageModel toDomain(MessagesTableData data) {
    // تحويل status string إلى MessageStatus enum
    MessageStatus status;
    switch (data.status) {
      case 'sent':
        status = MessageStatus.sent;
        break;
      case 'delivered':
        status = MessageStatus.delivered;
        break;
      case 'read':
        status = MessageStatus.read;
        break;
      default:
        status = MessageStatus.sent;
    }

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
    String statusString;
    switch (model.status) {
      case MessageStatus.sending:
        statusString = 'sending';
        break;
      case MessageStatus.sent:
        statusString = 'sent';
        break;
      case MessageStatus.delivered:
        statusString = 'delivered';
        break;
      case MessageStatus.read:
        statusString = 'read';
        break;
      case MessageStatus.failed:
        statusString = 'failed';
        break;
    }

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
}

