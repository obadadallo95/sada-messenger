import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database_provider.dart';
import '../security/security_providers.dart';
import '../utils/log_service.dart';
import '../network/mesh_service.dart';
import '../../features/chat/data/mappers/message_mapper.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/domain/models/message_model.dart';

/// Provider لمعالجة الرسائل الواردة وحفظها في قاعدة البيانات
final incomingMessageHandlerProvider = Provider<IncomingMessageHandler>((ref) {
  return IncomingMessageHandler(ref);
});

/// معالج الرسائل الواردة
class IncomingMessageHandler {
  final Ref _ref;
  StreamSubscription<String>? _subscription;

  IncomingMessageHandler(this._ref) {
    _startListening();
  }

  void _startListening() {
    final meshService = _ref.read(meshServiceProvider);
    
    _subscription?.cancel();
    _subscription = meshService.onMessageReceived.listen(
      (messageJson) async {
        await _handleIncomingMessage(messageJson);
      },
      onError: (error) {
        LogService.error('خطأ في استقبال الرسائل', error);
      },
    );
  }

  Future<void> _handleIncomingMessage(String messageJson) async {
    try {
      LogService.info('معالجة رسالة واردة: ${messageJson.substring(0, messageJson.length > 50 ? 50 : messageJson.length)}...');
      
      // تحليل JSON
      Map<String, dynamic> messageData;
      try {
        messageData = jsonDecode(messageJson);
      } catch (e) {
        // إذا لم يكن JSON، نتعامل معه كنص عادي
        messageData = {
          'content': messageJson,
          'senderId': 'unknown',
        };
      }
      
      final String? senderId = messageData['senderId'] as String? ?? messageData['peerId'] as String?;
      final String? encryptedContent = messageData['content'] as String? ?? messageData['message'] as String?;
      
      if (senderId == null || encryptedContent == null) {
        LogService.error('رسالة غير صحيحة: senderId أو content مفقود');
        return;
      }
      
      // الحصول على قاعدة البيانات
      final database = await _ref.read(appDatabaseProvider.future);
      
      // البحث عن المحادثة مع هذا المرسل
      final chat = await database.getChatByPeerId(senderId);
      if (chat == null) {
        LogService.warning('المحادثة غير موجودة للمرسل: $senderId');
        // يمكن إنشاء محادثة جديدة هنا إذا لزم الأمر
        return;
      }
      
      // فك التشفير
      String decryptedMessage;
      try {
        final encryptionService = _ref.read(encryptionServiceProvider);
        
        // الحصول على المفتاح العام للمرسل
        final contact = await database.getContactById(senderId);
        if (contact?.publicKey != null) {
          try {
            final remotePublicKeyBytes = base64Decode(contact!.publicKey!);
            final sharedKey = await encryptionService.calculateSharedSecret(remotePublicKeyBytes);
            decryptedMessage = encryptionService.decryptMessage(encryptedContent, sharedKey);
            LogService.info('تم فك تشفير الرسالة بنجاح');
          } catch (e) {
            LogService.error('خطأ في فك تشفير الرسالة', e);
            decryptedMessage = encryptedContent; // استخدام النص المشفر كنص عادي
          }
        } else {
          LogService.warning('لا يوجد مفتاح عام للمرسل - استخدام النص المشفر');
          decryptedMessage = encryptedContent;
        }
      } catch (e) {
        LogService.error('خطأ في فك تشفير الرسالة', e);
        decryptedMessage = encryptedContent; // استخدام النص المشفر كنص عادي
      }
      
      // توليد معرف فريد للرسالة
      const uuid = Uuid();
      final messageId = uuid.v4();
      
      // إنشاء MessageModel
      final message = MessageModel(
        id: messageId,
        text: decryptedMessage,
        encryptedText: encryptedContent,
        isMe: false,
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
      );
      
      // حفظ الرسالة في قاعدة البيانات
      final companion = MessageMapper.toCompanion(
        message,
        chat.id,
        senderId,
      );
      await database.insertMessage(companion);
      
      // تحديث آخر رسالة في المحادثة
      await database.updateLastMessage(chat.id, decryptedMessage);
      
      // إعادة بناء المحادثات
      _ref.invalidate(chatRepositoryProvider);
      
      LogService.info('تم حفظ الرسالة الواردة بنجاح: $messageId');
      
    } catch (e) {
      LogService.error('خطأ في معالجة الرسالة الواردة', e);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}


