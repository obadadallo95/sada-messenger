import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/mesh_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/mesh_file_provider.dart';
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
  FutureOr<void> build() {}

  // ─────────────────────────────────────────────
  // Send Text Message
  // ─────────────────────────────────────────────
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

      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('المستخدم غير مسجل الدخول');
      final senderId = currentUser.userId;

      final chat = await database.getChatById(chatId);
      if (chat == null) throw Exception('المحادثة غير موجودة');

      final targetPeerId = peerId ?? chat.peerId;
      if (targetPeerId == null && !chat.isGroup) {
        throw Exception('لا يمكن تحديد الطرف المستقبل');
      }

      String? remotePublicKey;
      if (!chat.isGroup && targetPeerId != null) {
        final contact = await database.getContactById(targetPeerId);
        remotePublicKey = contact?.publicKey;
        if (remotePublicKey == null || remotePublicKey.isEmpty) {
          LogService.error('رفض إرسال الرسالة بدون مفتاح عام: $targetPeerId');
          throw Exception('لا يمكن إرسال الرسالة قبل تبادل المفاتيح');
        }
      }

      const uuid = Uuid();
      final messageId = uuid.v4();

      String encryptedContent;
      if (remotePublicKey != null) {
        try {
          final remotePublicKeyBytes = base64Decode(remotePublicKey);
          final sharedKey = await encryptionService.calculateSharedSecret(remotePublicKeyBytes);
          encryptedContent = encryptionService.encryptMessage(content, sharedKey);
          LogService.info('تم تشفير الرسالة بنجاح');
        } catch (e) {
          LogService.error('خطأ في تشفير الرسالة', e);
          throw Exception('فشل تشفير الرسالة - تم إلغاء الإرسال لحماية الخصوصية');
        }
      } else {
        throw Exception('فشل تشفير الرسالة - لا يوجد مفتاح عام للطرف المستقبل');
      }

      final message = MessageModel(
        id: messageId,
        text: content,
        encryptedText: encryptedContent,
        isMe: true,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );

      final companion = MessageMapper.toCompanion(message, chatId, senderId);
      await database.insertMessage(companion);
      LogService.info('تم حفظ الرسالة في قاعدة البيانات: $messageId');

      if (targetPeerId != null) {
        try {
          final sendSuccess = await meshService.sendMeshMessage(
            targetPeerId,
            encryptedContent,
            senderId: senderId,
            maxHops: 10,
            type: 'message',
            messageId: messageId,
          );

          if (sendSuccess) {
            await database.updateMessageStatus(messageId, 'sent');
            LogService.info('✅ تم إرسال MeshMessage بنجاح: $messageId');
          } else {
            await database.updateMessageStatus(messageId, 'failed');
            LogService.error('❌ فشل إرسال MeshMessage: $messageId');
            throw Exception('فشل إرسال الرسالة - Socket غير متصل');
          }
        } catch (e) {
          await database.updateMessageStatus(messageId, 'failed');
          LogService.error('خطأ في إرسال MeshMessage', e);
          rethrow;
        }
      } else {
        LogService.warning('إرسال رسائل المجموعات غير مدعوم حالياً');
      }

      await database.updateLastMessage(chatId, content);
      ref.invalidate(chatRepositoryProvider);
    } catch (e) {
      LogService.error('خطأ في إرسال الرسالة', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // Send Voice Message
  // ─────────────────────────────────────────────

  /// Sends an Opus voice note recorded at [filePath].
  /// Encrypts the file-reference JSON and stores in DB with type='voice'.
  /// The raw audio bytes are NOT stored in the database.
  Future<void> sendVoiceMessage(
    String chatId,
    String filePath, {
    String? peerId,
  }) async {
    try {
      final database = await ref.read(appDatabaseProvider.future);
      final meshService = ref.read(meshServiceProvider);
      final encryptionService = ref.read(encryptionServiceProvider);
      final authService = ref.read(authServiceProvider.notifier);

      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('المستخدم غير مسجل الدخول');
      final senderId = currentUser.userId;

      final chat = await database.getChatById(chatId);
      if (chat == null) throw Exception('المحادثة غير موجودة');

      final targetPeerId = peerId ?? chat.peerId;

      // Read the voice file bytes for hashing
      final audioBytes = Uint8List.fromList(await File(filePath).readAsBytes());
      final audioHash = MeshFileProvider.hashOf(audioBytes);

      // Build a file-reference JSON payload (not the raw bytes)
      final fileRefJson = jsonEncode(MeshFileProvider.fileRefJson(
        filePath: filePath,
        mimeType: 'audio/ogg',
        sizeBytes: audioBytes.length,
        sha256Hash: audioHash,
      ));

      // Encrypt the file reference
      String encryptedContent = fileRefJson;
      if (targetPeerId != null) {
        final contact = await database.getContactById(targetPeerId);
        final pubKey = contact?.publicKey;
        if (pubKey != null && pubKey.isNotEmpty) {
          try {
            final keyBytes = base64Decode(pubKey);
            final sharedKey = await encryptionService.calculateSharedSecret(keyBytes);
            encryptedContent = encryptionService.encryptMessage(fileRefJson, sharedKey);
          } catch (e) {
            LogService.warning('فشل تشفير file-ref للصوت: $e');
          }
        }
      }

      const uuid = Uuid();
      final messageId = uuid.v4();

      // Store the message with type='voice'; `content` = encrypted file-ref,
      // so the UI will later read the path from it for playback.
      await database.insertMessage(
        MessagesTableCompanion.insert(
          id: messageId,
          chatId: chatId,
          senderId: senderId,
          content: encryptedContent,
          type: const Value('voice'),
          status: const Value('sending'),
          timestamp: Value(DateTime.now()),
          isFromMe: const Value(true),
        ),
      );

      LogService.info('🎤 Voice message saved locally: $messageId');

      if (targetPeerId != null) {
        final success = await meshService.sendMeshMessage(
          targetPeerId,
          encryptedContent,
          senderId: senderId,
          maxHops: 10,
          type: 'voice',
          messageId: messageId,
          metadata: {
            'sha256': audioHash,
            'size': audioBytes.length,
            'mime': 'audio/ogg',
          },
        );

        await database.updateMessageStatus(messageId, success ? 'sent' : 'failed');
        LogService.info(success
            ? '✅ Voice MeshMessage sent: $messageId'
            : '❌ Voice MeshMessage failed: $messageId');
      }

      await database.updateLastMessage(chatId, '🎤 Voice message');
      ref.invalidate(chatRepositoryProvider);
    } catch (e) {
      LogService.error('خطأ في إرسال الرسالة الصوتية', e);
      rethrow;
    }
  }
}
