import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/log_service.dart';
import '../mappers/chat_mapper.dart';
import '../mappers/message_mapper.dart';

part 'chat_repository.g.dart';

/// Repository للمحادثات
/// يحصل على المحادثات من قاعدة البيانات المحلية
@riverpod
class ChatRepository extends _$ChatRepository {
  @override
  Future<List<ChatModel>> build() async {
    try {
      final database = await ref.watch(appDatabaseProvider.future);
      
      // محاولة الحصول على المحادثات مع معالجة الأخطاء
      List<ChatsTableData> chats;
      try {
        chats = await database.getAllChats();
      } catch (e) {
        LogService.error('DATABASE ERROR (getAllChats): $e', e);
        // إذا فشل الحصول على المحادثات، إرجاع قائمة فارغة
        return [];
      }
      
      // تحويل ChatsTableData إلى ChatModel
      final List<ChatModel> chatModels = [];
      
      for (final chat in chats) {
        try {
          // الحصول على جهة الاتصال إذا كانت المحادثة فردية
          ContactsTableData? contact;
          if (!chat.isGroup && chat.peerId != null) {
            try {
              contact = await database.getContactById(chat.peerId!);
            } catch (e) {
              LogService.warning('DATABASE ERROR (getContactById): $e - peerId: ${chat.peerId}');
              // المتابعة بدون contact
            }
          }
          
          // حساب عدد الرسائل غير المقروءة
          int unreadCount = 0;
          try {
            unreadCount = await database.getUnreadMessageCount(chat.id);
          } catch (e) {
            LogService.warning('DATABASE ERROR (getUnreadMessageCount): $e - chatId: ${chat.id}');
            // المتابعة مع unreadCount = 0
          }
          
          // تحويل إلى ChatModel
          final chatModel = ChatMapper.toDomain(chat, contact: contact);
          
          // تحديث unreadCount
          chatModels.add(chatModel.copyWith(unreadCount: unreadCount));
        } catch (e) {
          LogService.warning('DATABASE ERROR (processing chat): $e - chatId: ${chat.id}');
          // تخطي هذه المحادثة والمتابعة
          continue;
        }
      }
      
      return chatModels;
    } catch (e, stackTrace) {
      LogService.error('DATABASE ERROR (build): $e', e);
      LogService.error('Stack trace: $stackTrace', null);
      // إرجاع قائمة فارغة بدلاً من رمي خطأ
      return [];
    }
  }

  /// الحصول على رسائل محادثة معينة
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final messages = await database.getMessagesForChat(chatId);
      
      // تحويل MessagesTableData إلى MessageModel
      return messages.map((msg) => MessageMapper.toDomain(msg)).toList();
    } catch (e) {
      LogService.error('DATABASE ERROR (getMessages): $e - chatId: $chatId', e);
      // إرجاع قائمة فارغة بدلاً من رمي خطأ
      return [];
    }
  }
  
  /// إدراج رسالة جديدة
  Future<void> insertMessage(MessageModel message, String chatId, String senderId) async {
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final companion = MessageMapper.toCompanion(message, chatId, senderId);
      await database.insertMessage(companion);
      
      // تحديث آخر رسالة في المحادثة
      try {
        await database.updateLastMessage(chatId, message.text);
      } catch (e) {
        LogService.warning('DATABASE ERROR (updateLastMessage): $e - chatId: $chatId');
        // المتابعة بدون تحديث آخر رسالة
      }
      
      // إعادة بناء المحادثات
      ref.invalidateSelf();
    } catch (e) {
      LogService.error('DATABASE ERROR (insertMessage): $e', e);
      // لا نرمي الخطأ - فقط نسجله
    }
  }
  
  /// إدراج محادثة جديدة
  Future<void> insertChat(ChatModel chat, {String? peerId}) async {
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final companion = ChatMapper.toCompanion(chat, peerId: peerId);
      await database.insertChat(companion);
      
      // إعادة بناء المحادثات
      ref.invalidateSelf();
    } catch (e) {
      LogService.error('DATABASE ERROR (insertChat): $e', e);
      // لا نرمي الخطأ - فقط نسجله
    }
  }
}

