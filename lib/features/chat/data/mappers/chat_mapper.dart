import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/chat_model.dart';

/// Mapper لتحويل ChatsTableData إلى ChatModel
class ChatMapper {
  /// تحويل ChatsTableData إلى ChatModel
  static ChatModel toDomain(ChatsTableData data, {ContactsTableData? contact}) {
    // تحديد اسم المحادثة
    String chatName;
    if (data.isGroup) {
      chatName = data.name ?? 'Group';
    } else {
      chatName = contact?.name ?? data.peerId ?? 'Unknown';
    }

    return ChatModel(
      id: data.id,
      name: chatName,
      lastMessage: data.lastMessage,
      time: data.lastUpdated,
      unreadCount: 0, // سيتم حسابه لاحقاً
      avatarColor: data.avatarColor,
      avatarUrl: contact?.avatar,
      publicKey: contact?.publicKey,
      isGroup: data.isGroup,
      groupName: data.isGroup ? data.name : null,
      memberCount: data.memberCount,
    );
  }

  /// تحويل ChatModel إلى ChatsTableCompanion
  static ChatsTableCompanion toCompanion(ChatModel model, {String? peerId}) {
    return ChatsTableCompanion.insert(
      id: model.id,
      peerId: model.isGroup ? const Value.absent() : Value(peerId ?? model.id),
      name: model.isGroup ? Value(model.groupName ?? model.name) : const Value.absent(),
      lastMessage: Value(model.lastMessage),
      lastUpdated: Value(model.time),
      isGroup: Value(model.isGroup),
      memberCount: model.isGroup ? Value(model.memberCount) : const Value.absent(),
      avatarColor: Value(model.avatarColor),
    );
  }
}

