import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database_provider.dart';
import '../database/app_database.dart';
import '../security/security_providers.dart';
import '../utils/log_service.dart';
import '../network/mesh_service.dart';
import 'models/mesh_message.dart';
import '../services/auth_service.dart';
import '../services/notification_provider.dart';
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
        // استخدام MeshService.handleIncomingMeshMessage() للتعامل مع Routing
        await meshService.handleIncomingMeshMessage(messageJson);
        // ثم معالجة الرسالة المحلية
        await _handleIncomingMessage(messageJson);
      },
      onError: (error) {
        LogService.error('خطأ في استقبال الرسائل', error);
      },
    );
  }

  /// Validate message structure before processing
  bool _validateMessageStructure(Map<String, dynamic> json) {
    // Check for MeshMessage format
    final isMeshMessage = json.containsKey('originalSenderId') && 
                          json.containsKey('finalDestinationId');
    
    if (isMeshMessage) {
      // MeshMessage requires: messageId, originalSenderId, finalDestinationId, encryptedContent
      final requiredFields = ['messageId', 'originalSenderId', 'finalDestinationId', 'encryptedContent'];
      return requiredFields.every((field) => json.containsKey(field) && json[field] != null);
    } else {
      // Legacy format requires: senderId/peerId and content/message
      final hasSender = json.containsKey('senderId') || json.containsKey('peerId');
      final hasContent = json.containsKey('content') || json.containsKey('message');
      return hasSender && hasContent;
    }
  }

  Future<void> _handleIncomingMessage(String messageJson) async {
    try {
      LogService.info('معالجة رسالة واردة: ${messageJson.substring(0, messageJson.length > 50 ? 50 : messageJson.length)}...');
      
      // Parse JSON with error handling
      final Map<String, dynamic> messageData;
      try {
        final decoded = jsonDecode(messageJson);
        if (decoded is! Map<String, dynamic>) {
          LogService.warning('⚠️ Invalid message format: not a JSON object');
          return;
        }
        messageData = decoded;
      } catch (e) {
        LogService.warning('⚠️ Failed to parse JSON payload', e);
        return; // Drop malformed message
      }
      
      // Validate message structure
      if (!_validateMessageStructure(messageData)) {
        LogService.warning('⚠️ Message missing required fields');
        return;
      }
      
      // التحقق من نوع الرسالة (MeshMessage أو Legacy)
      final isMeshMessage = messageData.containsKey('originalSenderId') && 
                            messageData.containsKey('finalDestinationId');
      
      // التحقق من أن الرسالة ليست ACK (لا نعالجها هنا)
      final isAck = messageData['type'] == MeshMessage.typeAck;
      if (isAck) {
        LogService.info('📨 ACK message received - سيتم معالجتها في MeshService');
        return; // ACKs are handled by MeshService._handleAck
      }
      
      // استخراج البيانات الأساسية (now guaranteed to be non-null by validation)
      String senderId;
      String encryptedContent;
      String? meshMessageId;
      String? originalSenderId;
      
      if (isMeshMessage) {
        // MeshMessage format
        senderId = messageData['originalSenderId'] as String;
        encryptedContent = messageData['encryptedContent'] as String;
        meshMessageId = messageData['messageId'] as String;
        originalSenderId = messageData['originalSenderId'] as String;
        
        // التحقق من أن الرسالة موجهة لي
        final authService = _ref.read(authServiceProvider.notifier);
        final currentUser = authService.currentUser;
        final myDeviceId = currentUser?.userId;
        
        if (myDeviceId != null && messageData['finalDestinationId'] != myDeviceId) {
          LogService.info('⏭️ هذه الرسالة ليست موجهة لي - تم التعامل معها في MeshService');
          return; // تم التعامل معها في MeshService.handleIncomingMeshMessage()
        }
      } else {
        // Legacy format
        senderId = (messageData['senderId'] ?? messageData['peerId']) as String;
        encryptedContent = (messageData['content'] ?? messageData['message']) as String;
      }

      final database = await _ref.read(appDatabaseProvider.future);

      // ==================== MUTUAL CONTACT EXCHANGE ====================
      // التحقق من نوع الرسالة
      // إذا كانت CONTACT_EXCHANGE، نتجاوز فحص القائمة البيضاء
      final isContactExchange = messageData['type'] == MeshMessage.typeContactExchange;
      
      if (isContactExchange) {
         await _handleContactExchange(
           senderId: senderId, 
           content: encryptedContent, 
           database: database
         );
         return;
      }
      // ===============================================================
      
      // ==================== SECURITY: Contact Whitelisting ====================
      // التحقق من أن المرسل هو جهة اتصال معروفة قبل معالجة الرسالة
      // database defined above
      
      // التحقق من وجود المرسل في جهات الاتصال
      final contact = await database.getContactById(senderId);
      if (contact == null) {
        // المرسل ليس في جهات الاتصال - رفض الرسالة (Anti-Spam)
        LogService.warning('🚫 تم رفض رسالة من مرسل غير معروف: $senderId');
        LogService.info('   - المرسل ليس في جهات الاتصال');
        LogService.info('   - الرسالة تم تجاهلها لحماية الخصوصية (Anti-Spam)');
        return; // Silently drop the message
      }
      
      // التحقق من أن المرسل غير محظور
      if (contact.isBlocked) {
        LogService.warning('🚫 تم رفض رسالة من مرسل محظور: $senderId');
        return; // Silently drop the message
      }
      
      LogService.info('✅ المرسل معروف - متابعة معالجة الرسالة');
      
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
        
        // الحصول على المفتاح العام للمرسل (contact موجود بالفعل من التحقق السابق)
        if (contact.publicKey != null) {
          try {
            final remotePublicKeyBytes = base64Decode(contact.publicKey!);
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
      
      // التحقق من نوع الرسالة - هل هي إشعار إضافة صديق؟
      try {
        final messageData = jsonDecode(decryptedMessage);
        if (messageData['type'] == 'friend_added') {
          // معالجة إشعار إضافة صديق
          await _handleFriendAddedNotification(
            senderId: senderId,
            senderName: messageData['senderName'] as String? ?? 'Friend',
            database: database,
          );
          return; // لا نحفظ هذه الرسالة كرسالة عادية
        }
      } catch (e) {
        // ليست JSON أو ليست إشعار - نتابع كرسالة عادية
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

      // ==================== إرسال ACK للمرسل الأصلي ====================
      // يتم إرسال ACK فقط لرسائل MeshMessage (ليست CONTACT_EXCHANGE أو system-only).
      if (isMeshMessage && meshMessageId != null && originalSenderId != null) {
        final authService = _ref.read(authServiceProvider.notifier);
        final currentUser = authService.currentUser;
        final myId = currentUser?.userId;

        if (myId != null) {
          final meshService = _ref.read(meshServiceProvider);

          // نستخدم metadata لحمل originalMessageId بدون تضمينه في payload.
          final ackMetadata = <String, dynamic>{
            'originalMessageId': meshMessageId,
          };

          await meshService.sendMeshMessage(
            originalSenderId,
            '', // لا نحتاج payload فعلي - الميتاداتا تكفي
            senderId: myId,
            maxHops: 10,
            type: MeshMessage.typeAck,
            metadata: ackMetadata,
          );

          LogService.info('📨 تم إرسال ACK للرسالة: $meshMessageId إلى $originalSenderId');
        }
      }
      
    } catch (e) {
      LogService.error('خطأ في معالجة الرسالة الواردة', e);
    }
  }

  /// معالجة إشعار إضافة صديق
  Future<void> _handleFriendAddedNotification({
    required String senderId,
    required String senderName,
    required dynamic database,
  }) async {
    try {
      LogService.info('معالجة إشعار إضافة صديق من: $senderId');
      
      // التحقق من أن جهة الاتصال غير موجودة بالفعل
      final existingContact = await database.getContactById(senderId);
      
      if (existingContact != null) {
        LogService.info('جهة الاتصال موجودة بالفعل: $senderId');
        return;
      }
      
      // الحصول على المفتاح العام للمرسل (من QR Code أو من إشعار سابق)
      // في الوقت الحالي، سنضيفه بدون publicKey (سيتم الحصول عليه لاحقاً)
      
      // إضافة جهة الاتصال إلى قاعدة البيانات
      await database.insertContact(
        ContactsTableCompanion.insert(
          id: senderId,
          name: senderName,
          publicKey: const Value.absent(), // سيتم الحصول عليه لاحقاً
          avatar: const Value.absent(),
          isBlocked: const Value(false),
        ),
      );
      
      LogService.info('تم إضافة جهة الاتصال تلقائياً: $senderId');
      
      // التحقق من وجود محادثة
      var chat = await database.getChatByPeerId(senderId);
      
      if (chat == null) {
        // إنشاء محادثة جديدة
        const uuid = Uuid();
        final chatId = uuid.v4();
        await database.insertChat(
          ChatsTableCompanion.insert(
            id: chatId,
            peerId: Value(senderId),
            name: const Value.absent(),
            lastMessage: const Value.absent(),
            lastUpdated: Value(DateTime.now()),
            isGroup: const Value(false),
            memberCount: const Value.absent(),
            avatarColor: Value(_generateAvatarColor(senderName)),
          ),
        );
        LogService.info('تم إنشاء محادثة جديدة تلقائياً: $chatId');
      }
      
      // إعادة بناء المحادثات
      _ref.invalidate(chatRepositoryProvider);
      
    } catch (e) {
      LogService.error('خطأ في معالجة إشعار إضافة صديق', e);
    }
  }
  
  /// توليد لون للصورة الشخصية
  int _generateAvatarColor(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return (0xFF000000 | (hash & 0x00FFFFFF)).abs();
  }

  /// معالجة رسالة تبادل جهات الاتصال (Mutual Contact Exchange)
  Future<void> _handleContactExchange({
    required String senderId,
    required String content,
    required AppDatabase database,
  }) async {
    try {
      LogService.info('🔄 معالجة رسالة Contact Exchange من: $senderId');
      
      // Parse Profile Data
      // Content could be encrypted or clear text.
      // For now assuming clear text JSON as per implementation plan.
      
      Map<String, dynamic> profileData;
      try {
        profileData = jsonDecode(content);
      } catch (e) {
        LogService.error('فشل في قراءة بيانات الملف الشخصي', e);
        return;
      }
      
      final String? name = profileData['name'] as String?;
      final String? publicKey = profileData['publicKey'] as String?;
      
      if (name == null || publicKey == null) {
        LogService.warning('بيانات الملف الشخصي غير مكتملة');
        return;
      }
      
      // التحقق مما إذا كانت جهة الاتصال موجودة بالفعل
      final existingContact = await database.getContactById(senderId);
      
      if (existingContact != null) {
        LogService.info('جهة الاتصال موجودة بالفعل: $senderId. تحديث البيانات...');
        // تحديث البيانات إذا لزم الأمر (مثلاً PublicKey)
        await database.updateContact(
          senderId,
          ContactsTableCompanion(
            name: Value(name),
            publicKey: Value(publicKey),
          ),
        );
      } else {
        LogService.info('➕ إضافة جهة اتصال جديدة تلقائياً: $name ($senderId)');
        // إضافة جهة الاتصال
        await database.insertContact(
          ContactsTableCompanion.insert(
            id: senderId,
            name: name,
            publicKey: Value(publicKey),
            avatar: const Value.absent(),
            isBlocked: const Value(false),
          ),
        );
        
        // إنشاء محادثة
        const uuid = Uuid();
        final chatId = uuid.v4();
        await database.insertChat(
          ChatsTableCompanion.insert(
            id: chatId,
            peerId: Value(senderId),
            lastUpdated: Value(DateTime.now()),
            isGroup: const Value(false),
            avatarColor: Value(_generateAvatarColor(name)),
          ),
        );
        
        // إشعار المستخدم
        final notificationService = _ref.read(notificationServiceProvider);
        await notificationService.showChatNotification(
          id: senderId.hashCode,
          title: 'New Connection',
          body: 'You are now connected with $name',
          payload: jsonEncode({
             'type': 'new_contact',
             'contactId': senderId,
          }),
        );
      }
      
      // إعادة بناء UI
      _ref.invalidate(chatRepositoryProvider);
      
    } catch (e) {
      LogService.error('خطأ في معالجة Contact Exchange', e);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}


