// ignore_for_file: unused_import, unused_element

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/mesh_message.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/database_provider.dart';
import '../database/app_database.dart';
import '../security/security_providers.dart';
import '../utils/log_service.dart';
import '../network/mesh_service.dart';
import '../services/auth_service.dart';
import '../services/notification_provider.dart';
import '../services/metrics_service.dart';
import '../../features/chat/data/mappers/message_mapper.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/domain/models/message_model.dart';

/// Provider لمعالجة الرسائل الواردة وحفظها في قاعدة البيانات
final incomingMessageHandlerProvider = Provider<IncomingMessageHandler>((ref) {
  final handler = IncomingMessageHandler(ref);
  ref.onDispose(handler.dispose);
  return handler;
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
    final isMeshMessage =
        json.containsKey('originalSenderId') &&
        json.containsKey('finalDestinationId');

    if (isMeshMessage) {
      // MeshMessage requires: messageId, originalSenderId, finalDestinationId, encryptedContent
      final requiredFields = [
        'messageId',
        'originalSenderId',
        'finalDestinationId',
        'encryptedContent',
      ];
      return requiredFields.every(
        (field) => json.containsKey(field) && json[field] != null,
      );
    } else {
      // Legacy format requires: senderId/peerId and content/message
      final hasSender =
          json.containsKey('senderId') || json.containsKey('peerId');
      final hasContent =
          json.containsKey('content') || json.containsKey('message');
      return hasSender && hasContent;
    }
  }

  Future<void> _handleIncomingMessage(String messageJson) async {
    try {
      LogService.info(
        'معالجة رسالة واردة: ${messageJson.substring(0, messageJson.length > 50 ? 50 : messageJson.length)}...',
      );

      // Parse JSON with error handling
      final Map<String, dynamic> messageData;
      try {
        final decoded = jsonDecode(messageJson);
        if (decoded is! Map<String, dynamic>) {
          LogService.warning('⚠️ Invalid message format: not a JSON object');
          return;
        }
        messageData = decoded;

        final metricsService = _ref.read(metricsServiceProvider);
        metricsService.recordMessageReceived();
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
      final isMeshMessage =
          messageData.containsKey('originalSenderId') &&
          messageData.containsKey('finalDestinationId');

      // التحقق من أن الرسالة ليست ACK (سنعالجها هنا الآن لدعم التشفير)
      final isAck = messageData['type'] == MeshMessage.typeAck;

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

        if (myDeviceId != null &&
            messageData['finalDestinationId'] != myDeviceId) {
          LogService.info(
            '⏭️ هذه الرسالة ليست موجهة لي - تم التعامل معها في MeshService',
          );
          return; // تم التعامل معها في MeshService.handleIncomingMeshMessage()
        }
      } else {
        // Legacy format
        senderId = (messageData['senderId'] ?? messageData['peerId']) as String;
        encryptedContent =
            (messageData['content'] ?? messageData['message']) as String;
      }

      final database = await _ref.read(appDatabaseProvider.future);

      // ==================== CONTACT EXCHANGE BYPASS ====================
      // CONTACT_EXCHANGE from a new friend must bypass the whitelist,
      // otherwise the other device can never auto-add us.
      if (isMeshMessage) {
        final msgType = messageData['type']?.toString();
        if (msgType == MeshMessage.typeContactExchange) {
          LogService.info('🔄 CONTACT_EXCHANGE detected – bypassing whitelist');
          await _handleContactExchange(
            senderId: senderId,
            content: isMeshMessage
                ? (messageData['encryptedContent'] as String)
                : encryptedContent,
            database: database,
          );
          return;
        }
      }

      // ==================== SECURITY: Contact Whitelisting ====================
      // التحقق من أن المرسل هو جهة اتصال معروفة قبل معالجة الرسالة
      final contact = await database.getContactById(senderId);
      if (contact == null) {
        // المرسل ليس في جهات الاتصال - رفض الرسالة (Anti-Spam)
        LogService.warning('🚫 تم رفض رسالة من مرسل غير معروف: $senderId');
        return;
      }

      if (contact.isBlocked) {
        LogService.warning('🚫 تم رفض رسالة من مرسل محظور: $senderId');
        return;
      }

      // فك التشفير
      String decryptedMessage;
      try {
        final encryptionService = _ref.read(encryptionServiceProvider);
        if (contact.publicKey != null) {
          try {
            final remotePublicKeyBytes = base64Decode(contact.publicKey!);
            final sharedKey = await encryptionService.calculateSharedSecret(
              remotePublicKeyBytes,
            );
            decryptedMessage = encryptionService.decryptMessage(
              encryptedContent,
              sharedKey,
            );
          } catch (e) {
            LogService.error('خطأ في فك تشفير الرسالة', e);
            decryptedMessage = encryptedContent;
          }
        } else {
          decryptedMessage = encryptedContent;
        }
      } catch (e) {
        decryptedMessage = encryptedContent;
      }

      // ==================== ACK HANDLING ====================
      if (isAck) {
        try {
          LogService.info('🔍 Decoding ACK: $decryptedMessage');
          final payload = jsonDecode(decryptedMessage);
          final originalMessageId = payload['originalMessageId'] as String?;

          if (originalMessageId != null) {
            await database.updateMessageStatus(originalMessageId, 'delivered');
            LogService.info(
              '✅ ACK آمن تم استلامه وتحديث الرسالة: $originalMessageId',
            );
          } else {
            // Fallback: Check metadata if payload fails (Legacy support)
            // Note: Metadata is in raw messageData, handled by MeshService mostly,
            // but we can check here if needed. For now, rely on payload.
            LogService.warning('⚠️ ACK فارغ أو غير صالح');
          }
        } catch (e) {
          LogService.error('خطأ في معالجة محتوى ACK', e);
        }

        final metricsService = _ref.read(metricsServiceProvider);
        metricsService.recordAckReceived();
        return; // انتهى معالجة ACK
      }

      // ==================== NORMAL MESSAGE HANDLING ====================

      // 6. Normal message processing
      await _processDecryptedMessage(
        senderId,
        decryptedMessage,
        encryptedContent,
        meshMessageId,
        originalSenderId,
        isMeshMessage,
        database,
      );
    } catch (e) {
      LogService.error('خطأ', e);
    }
  }

  // Helper method to keep _handleIncomingMessage clean
  Future<void> _processDecryptedMessage(
    String senderId,
    String decryptedMessage,
    String encryptedContent,
    String? meshMessageId,
    String? originalSenderId,
    bool isMeshMessage,
    AppDatabase database,
  ) async {
    // 1. Deduplication
    if (isMeshMessage && meshMessageId != null) {
      final existing = await database.getMessageById(meshMessageId);
      if (existing != null) {
        LogService.info('⚠️ رسالة مكررة تم تجاهلها: $meshMessageId');
        // Send ACK anyway as confirmation
        if (originalSenderId != null) {
          await _sendAckForMessage(originalSenderId, meshMessageId);
        }
        final metricsService = _ref.read(metricsServiceProvider);
        metricsService.recordDuplicateIgnored();
        return;
      }
    }

    // 2. Get or Create Chat
    var chat = await database.getChatByPeerId(senderId);

    if (chat == null) {
      // Create new chat
      final chatUuid = const Uuid().v4();
      final contact = await database.getContactById(senderId);
      final name = contact?.name ?? 'Unknown';

      await database.insertChat(
        ChatsTableCompanion.insert(
          id: chatUuid,
          peerId: Value(senderId),
          lastUpdated: Value(DateTime.now()),
          isGroup: const Value(false),
          avatarColor: Value(_generateAvatarColor(name)),
        ),
      );
      // Retrieve properly
      chat = await database.getChatByPeerId(senderId);
    }

    if (chat == null) {
      LogService.error('فشل العثور على محادثة للمرسل: $senderId');
      return;
    }

    // 3. Insert Message
    final messageId = meshMessageId ?? const Uuid().v4();
    final timestamp = DateTime.now();

    await database.insertMessage(
      MessagesTableCompanion.insert(
        id: messageId,
        chatId: chat.id,
        senderId: senderId,
        content: encryptedContent, // Store ENCRYPTED content at rest
        type: const Value('text'),
        status: const Value('received'),
        timestamp: Value(timestamp),
        isFromMe: const Value(false),
      ),
    );

    LogService.info('📥 تم استلام وحفظ رسالة جديدة: $messageId');

    // 4. Update UI & Notify
    _ref.invalidate(chatRepositoryProvider);

    final notificationService = _ref.read(notificationServiceProvider);
    // Get sender name
    final contact = await database.getContactById(senderId);
    final senderName = contact?.name ?? 'Unknown';

    await notificationService.showChatNotification(
      id: senderId.hashCode,
      title: senderName,
      body: decryptedMessage,
      payload: jsonEncode({
        'type': 'chat_message',
        'chatId': chat.id,
        'peerId': senderId,
      }),
    );

    // 5. Send ACK
    if (isMeshMessage && meshMessageId != null && originalSenderId != null) {
      await _sendAckForMessage(originalSenderId, meshMessageId);
    }
  }

  /// إرسال ACK مشفر وآمن
  Future<void> _sendAckForMessage(
    String originalSenderId,
    String originalMessageId,
  ) async {
    try {
      final authService = _ref.read(authServiceProvider.notifier);
      final currentUser = authService.currentUser;
      final myId = currentUser?.userId;

      if (myId == null) return;

      final meshService = _ref.read(meshServiceProvider);
      final encryptionService = _ref.read(encryptionServiceProvider);
      final database = await _ref.read(appDatabaseProvider.future);

      // تجهيز Payload
      final ackPayload = jsonEncode({
        'originalMessageId': originalMessageId,
        'ackSenderId': myId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // تشفير Payload
      String encryptedAck = ackPayload;
      final contact = await database.getContactById(originalSenderId);
      if (contact?.publicKey != null) {
        try {
          final remoteKey = base64Decode(contact!.publicKey!);
          final sharedKey = await encryptionService.calculateSharedSecret(
            remoteKey,
          );
          encryptedAck = encryptionService.encryptMessage(
            ackPayload,
            sharedKey,
          );
        } catch (e) {
          LogService.warning('فشل تشفير ACK', e);
        }
      }

      // Metadata for legacy/routing optimizations (optional)
      final ackMetadata = {
        'originalMessageId':
            originalMessageId, // For routing priority if needed
      };

      await meshService.sendMeshMessage(
        originalSenderId,
        encryptedAck,
        senderId: myId,
        maxHops: 10,
        type: MeshMessage.typeAck,
        metadata: ackMetadata,
      );

      LogService.info('📨 تم إرسال ACK مشفر للرسالة: $originalMessageId');

      final metricsService = _ref.read(metricsServiceProvider);
      metricsService.recordAckSent();
    } catch (e) {
      LogService.error('فشل إرسال ACK', e);
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
        LogService.info(
          'جهة الاتصال موجودة بالفعل: $senderId. تحديث البيانات...',
        );
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
          payload: jsonEncode({'type': 'new_contact', 'contactId': senderId}),
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
