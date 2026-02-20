import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/log_service.dart';
import '../mappers/chat_mapper.dart';
import '../mappers/message_mapper.dart';
import '../../../../core/security/security_providers.dart';
import 'dart:convert';
import 'dart:typed_data';

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
  /// الحصول على رسائل محادثة معينة
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final messages = await database.getMessagesForChat(chatId);
      final encryptionService = ref.read(encryptionServiceProvider);

      // 1. محاولة الحصول على Shared Key لفك التشفير
      Uint8List? sharedKey;
      try {
        // نحتاج معرفة peerId للحصول على PublicKey
        // بما أن getMessagesForChat لا تعيد Chat info، سنبحث عنها
        final chat = await database.getChatById(chatId);
        
        if (chat != null && chat.peerId != null) {
          final contact = await database.getContactById(chat.peerId!);
          if (contact != null && contact.publicKey != null) {
            final remoteKey = base64Decode(contact.publicKey!);
            sharedKey = await encryptionService.calculateSharedSecret(remoteKey);
          }
        }
      } catch (e) {
        LogService.warning('فشل في تحضير مفاتيح فك التشفير للمحادثة $chatId: $e');
        // سنستمر ونعرض الرسائل كما هي (مشفرة أو نصية حسب التخزين)
      }

      // 2. تحويل وفك تشفير الرسائل
      return messages.map((msg) {
        var domainMsg = MessageMapper.toDomain(msg);
        
        // إذا كان لدينا مفتاح مشترك، نحاول فك التشفير
        if (sharedKey != null) {
          try {
            // محاولة فك التشفير
            // نستخدم encryptedText إذا وجد، أو text كمحتوى مشفر محتمل
            final contentToDecrypt = domainMsg.encryptedText ?? domainMsg.text;
            
            // تحقق بسيط: هل النص يبدو كمشفّر (Base64)؟
            // لتجنب محاولة فك تشفير رسائل نصية قديمة
            // (هذا التحقق ليس مثالياً ولكن يقلل Exceptions)
            if (!_isLikelyEncrypted(contentToDecrypt)) {
               return domainMsg;
            }

            final decrypted = encryptionService.decryptMessage(
              contentToDecrypt, 
              sharedKey
            );
            
            // تحديث النص بعد فك التشفير
            return domainMsg.copyWith(text: decrypted);
          } catch (e) {
            // فشل فك التشفير (قد تكون رسالة نصية عادية أو مفتاح خطأ)
            // LogService.v('Decryption failed for msg ${msg.id}: $e'); 
            return domainMsg;
          }
        }
        
        return domainMsg;
      }).toList();
    } catch (e) {
      LogService.error('DATABASE ERROR (getMessages): $e - chatId: $chatId', e);
      return [];
    }
  }

  /// تحقق بسيط مما إذا كان النص يبدو مشفراً (ليس نصاً عادياً)
  bool _isLikelyEncrypted(String text) {
    if (text.isEmpty) return false;
    // الرسائل المشفرة لدينا تخزن كـ Base64
    // والنصوص العادية عادة تحتوي مسافات (إلا إذا كانت كلمة واحدة)
    // المشفر لا يحتوي مسافات عادة
    return !text.contains(' ');
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

