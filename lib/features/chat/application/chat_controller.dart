import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/mesh_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/security/security_providers.dart';
import '../../../features/chat/domain/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import '../data/mappers/message_mapper.dart';
import '../../../../core/utils/log_service.dart';

part 'chat_controller.g.dart';

/// Controller لإدارة منطق إرسال واستقبال الرسائل
@riverpod
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {
    // تهيئة Controller
  }

  /// إرسال رسالة
  /// [chatId]: معرف المحادثة
  /// [content]: محتوى الرسالة (نص عادي)
  /// [peerId]: معرف الطرف المستقبل (اختياري - سيتم الحصول عليه من Chat إذا لم يتم توفيره)
  Future<void> sendMessage(
    String chatId,
    String content, {
    String? peerId,
  }) async {
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final meshService = ref.read(meshServiceProvider);
      final encryptionService = ref.read(encryptionServiceProvider);
      final authService = ref.read(authServiceProvider.notifier);
      
      // التحقق من Duress Mode
      final authType = ref.read(currentAuthTypeProvider);
      if (authType == AuthType.duress) {
        LogService.info('Duress Mode active - simulating message send');
        
        // في Duress Mode، نحفظ الرسالة في قاعدة البيانات الوهمية فقط
        // ونحاكي الإرسال الناجح بدون إرسال فعلي عبر الشبكة
        
        // الحصول على معرف المستخدم الحالي
        final currentUser = authService.currentUser;
        if (currentUser == null) {
          throw Exception('المستخدم غير مسجل الدخول');
        }
        final senderId = currentUser.userId;
        
        // توليد معرف فريد للرسالة
        const uuid = Uuid();
        final messageId = uuid.v4();
        
        // إنشاء MessageModel مع status = sending
        final message = MessageModel(
          id: messageId,
          text: content,
          encryptedText: content, // في Duress Mode نستخدم النص العادي
          isMe: true,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
        );
        
        // حفظ الرسالة في قاعدة البيانات الوهمية
        final companion = MessageMapper.toCompanion(message, chatId, senderId);
        await database.insertMessage(companion);
        
        // محاكاة الإرسال الناجح بعد تأخير قصير
        Future.delayed(Duration(milliseconds: 500), () async {
          await database.updateMessageStatus(messageId, 'sent');
        });
        
        // محاكاة التسليم بعد تأخير أطول
        Future.delayed(Duration(seconds: 2), () async {
          await database.updateMessageStatus(messageId, 'delivered');
        });
        
        // تحديث آخر رسالة في المحادثة
        await database.updateLastMessage(chatId, content);
        
        // إعادة بناء المحادثات
        ref.invalidate(chatRepositoryProvider);
        
        LogService.info('Duress Mode: رسالة وهمية تم حفظها بنجاح');
        return; // لا نرسل عبر الشبكة الفعلية
      }
      
      // الحصول على معرف المستخدم الحالي
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      final senderId = currentUser.userId;
      
      // الحصول على معلومات المحادثة
      final chat = await database.getChatById(chatId);
      if (chat == null) {
        throw Exception('المحادثة غير موجودة');
      }
      
      // تحديد peerId إذا لم يتم توفيره
      final targetPeerId = peerId ?? chat.peerId;
      if (targetPeerId == null && !chat.isGroup) {
        throw Exception('لا يمكن تحديد الطرف المستقبل');
      }
      
      // الحصول على المفتاح العام للطرف المستقبل (للتشفير)
      String? remotePublicKey;
      if (!chat.isGroup && targetPeerId != null) {
        final contact = await database.getContactById(targetPeerId);
        remotePublicKey = contact?.publicKey;
      }
      
      // توليد معرف فريد للرسالة
      const uuid = Uuid();
      final messageId = uuid.v4();

      // تشفير الرسالة أولاً حتى لا يتم حفظ نص عادي في قاعدة البيانات
      String encryptedContent;
      if (remotePublicKey != null) {
        try {
          // تحويل المفتاح العام من String إلى Uint8List
          final remotePublicKeyBytes = base64Decode(remotePublicKey);
          
          // حساب Shared Secret
          final sharedKey = await encryptionService.calculateSharedSecret(remotePublicKeyBytes);
          
          // تشفير الرسالة
          encryptedContent = encryptionService.encryptMessage(content, sharedKey);
          
          LogService.info('تم تشفير الرسالة بنجاح');
        } catch (e) {
          LogService.error('خطأ في تشفير الرسالة', e);
          // 🔒 SECURITY HARDENING: لا نرسل نص عادي في حال فشل التشفير
          throw Exception('فشل تشفير الرسالة - تم إلغاء الإرسال لحماية الخصوصية');
        }
      } else {
        // لا يوجد مفتاح عام - استخدام النص العادي (للتطوير فقط - يجب منعه في الإنتاج)
        LogService.warning('لا يوجد مفتاح عام للطرف المستقبل - إرسال نص عادي');
        encryptedContent = content;
      }

      // إنشاء MessageModel مع status = sending وتضمين النص المشفر
      final message = MessageModel(
        id: messageId,
        text: content,
        encryptedText: encryptedContent,
        isMe: true,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );

      // حفظ الرسالة في قاعدة البيانات مع status = sending
      final companion = MessageMapper.toCompanion(
        message,
        chatId,
        senderId,
      );
      await database.insertMessage(companion);
      
      LogService.info('تم حفظ الرسالة في قاعدة البيانات: $messageId');
      
      // إرسال الرسالة عبر Mesh Network مع Store-Carry-Forward Routing
      bool sendSuccess = false;
      if (targetPeerId != null) {
        try {
          // استخدام sendMeshMessage() بدلاً من sendMessage() لدعم Mesh Routing
          sendSuccess = await meshService.sendMeshMessage(
            targetPeerId, 
            encryptedContent,
            senderId: senderId,
            maxHops: 10, // TTL: 10 hops
            type: 'message',
            messageId: messageId,
          );
          
          if (sendSuccess) {
            // تحديث حالة الرسالة إلى sent
            await database.updateMessageStatus(messageId, 'sent');
            LogService.info('✅ تم إرسال MeshMessage بنجاح: $messageId');
          } else {
            // تحديث حالة الرسالة إلى failed
            await database.updateMessageStatus(messageId, 'failed');
            LogService.error('❌ فشل إرسال MeshMessage: $messageId - Socket قد لا يكون متصل');
            throw Exception('فشل إرسال الرسالة - Socket غير متصل');
          }
        } catch (e) {
          // تحديث حالة الرسالة إلى failed
          await database.updateMessageStatus(messageId, 'failed');
          LogService.error('خطأ في إرسال MeshMessage', e);
          rethrow;
        }
      } else {
        // محادثة جماعية - سيتم تنفيذها لاحقاً
        LogService.warning('إرسال رسائل المجموعات غير مدعوم حالياً');
        sendSuccess = true; // مؤقت
      }
      
      // تحديث آخر رسالة في المحادثة
      await database.updateLastMessage(chatId, content);
      
      // إعادة بناء المحادثات
      ref.invalidate(chatRepositoryProvider);
      
    } catch (e) {
      LogService.error('خطأ في إرسال الرسالة', e);
      rethrow;
    }
  }
}

