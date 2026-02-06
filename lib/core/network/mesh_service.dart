import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/log_service.dart';
import '../security/security_providers.dart';
import '../security/encryption_service.dart';
import '../services/notification_provider.dart';
import '../services/notification_service.dart';
import '../database/database_provider.dart';

/// خدمة Mesh لإدارة الاتصالات والرسائل
class MeshService {
  static const EventChannel _messageChannel = EventChannel('org.sada.messenger/messageReceived');
  static const EventChannel _socketStatusChannel = EventChannel('org.sada.messenger/socketStatus');
  static const MethodChannel _methodChannel = MethodChannel('org.sada.messenger/mesh');

  Stream<String>? _messageStream;
  Stream<Map<String, dynamic>>? _socketStatusStream;

  /// Stream للرسائل المستلمة
  Stream<String> get onMessageReceived {
    _messageStream ??= _messageChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          try {
            if (event == null) return '';
            return event as String;
          } catch (e) {
            LogService.error('خطأ في معالجة الرسالة المستلمة', e);
            return '';
          }
        })
        .asBroadcastStream();

    return _messageStream!;
  }

  /// Stream لحالة Socket
  Stream<Map<String, dynamic>> get onSocketStatus {
    _socketStatusStream ??= _socketStatusChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          try {
            if (event == null) {
              return {
                'status': 'unknown',
                'message': '',
                'isConnected': false,
                'isServer': false,
              };
            }
            final Map<String, dynamic> statusJson = jsonDecode(event as String);
            return statusJson;
          } catch (e) {
            LogService.error('خطأ في معالجة حالة Socket', e);
            return {
              'status': 'error',
              'message': e.toString(),
              'isConnected': false,
              'isServer': false,
            };
          }
        })
        .asBroadcastStream();

    return _socketStatusStream!;
  }

  /// إرسال رسالة عبر Socket
  /// [peerId]: معرف الطرف المستقبل
  /// [encryptedContent]: المحتوى المشفر (Base64)
  Future<bool> sendMessage(String peerId, String encryptedContent) async {
    try {
      // إنشاء JSON payload
      final payload = jsonEncode({
        'peerId': peerId,
        'content': encryptedContent,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      final result = await _methodChannel.invokeMethod<bool>(
        'socket_write',
        {
          'peerId': peerId,
          'message': payload,
        },
      );
      LogService.info('تم إرسال الرسالة إلى $peerId');
      return result ?? false;
    } catch (e) {
      LogService.error('خطأ في إرسال الرسالة', e);
      return false;
    }
  }
  
  /// إرسال رسالة (Legacy method - للتوافق مع الكود القديم)
  @Deprecated('Use sendMessage(peerId, encryptedContent) instead')
  Future<bool> sendMessageLegacy(String message) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendMessage',
        {'message': message},
      );
      LogService.info('تم إرسال الرسالة: $message');
      return result ?? false;
    } catch (e) {
      LogService.error('خطأ في إرسال الرسالة', e);
      return false;
    }
  }

  /// إغلاق اتصال Socket
  Future<bool> closeSocket() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('closeSocket');
      LogService.info('تم إغلاق اتصال Socket');
      return result ?? false;
    } catch (e) {
      LogService.error('خطأ في إغلاق Socket', e);
      return false;
    }
  }
}

/// Provider لـ MeshService
final meshServiceProvider = Provider<MeshService>((ref) => MeshService());

/// Provider لمعالجة الرسائل المستلمة
final messageHandlerProvider = Provider<MessageHandler>((ref) {
  final meshService = ref.watch(meshServiceProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  
  return MessageHandler(
    meshService: meshService,
    encryptionService: encryptionService,
    notificationService: notificationService,
    ref: ref,
  );
});

/// معالج الرسائل المستلمة
class MessageHandler {
  final MeshService meshService;
  final EncryptionService encryptionService;
  final NotificationService notificationService;
  final Ref ref;
  
  StreamSubscription<String>? _messageSubscription;

  MessageHandler({
    required this.meshService,
    required this.encryptionService,
    required this.notificationService,
    required this.ref,
  }) {
    _startListening();
  }

  void _startListening() {
    _messageSubscription?.cancel();
    
    _messageSubscription = meshService.onMessageReceived.listen(
      (message) async {
        await _handleMessage(message);
      },
      onError: (error) {
        LogService.error('خطأ في استقبال الرسائل', error);
      },
    );
  }

  Future<void> _handleMessage(String messageJson) async {
    try {
      LogService.info('تم استقبال رسالة: ${messageJson.substring(0, messageJson.length > 50 ? 50 : messageJson.length)}...');
      
      // تحليل JSON
      final Map<String, dynamic> messageData = jsonDecode(messageJson);
      final String? senderId = messageData['senderId'] as String?;
      final String? encryptedContent = messageData['content'] as String?;
      final String? chatId = messageData['chatId'] as String?;
      
      if (senderId == null || encryptedContent == null) {
        LogService.error('رسالة غير صحيحة: senderId أو content مفقود');
        return;
      }
      
      // فك التشفير
      String decryptedMessage;
      try {
        // الحصول على قاعدة البيانات
        final database = await ref.read(appDatabaseProvider.future);
        
        // الحصول على المفتاح العام للمرسل من قاعدة البيانات
        final contact = await database.getContactById(senderId);
        if (contact?.publicKey != null) {
          try {
            // تحويل المفتاح العام من Base64 إلى Uint8List
            final remotePublicKeyBytes = base64Decode(contact!.publicKey!);
            
            // حساب Shared Secret
            final sharedKey = await encryptionService.calculateSharedSecret(remotePublicKeyBytes);
            
            // فك التشفير
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
      
      // حفظ الرسالة في قاعدة البيانات
      // سيتم تنفيذها في MessageHandlerProvider
      // await _saveIncomingMessage(senderId, chatId, decryptedMessage);
      
      // إظهار إشعار محلي
      await notificationService.showChatNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'رسالة جديدة',
        body: decryptedMessage.length > 50 
            ? '${decryptedMessage.substring(0, 50)}...' 
            : decryptedMessage,
        payload: jsonEncode({
          'type': 'message',
          'senderId': senderId,
          'chatId': chatId,
          'text': decryptedMessage,
        }),
      );
      
      LogService.info('تم معالجة الرسالة بنجاح');
    } catch (e) {
      LogService.error('خطأ في معالجة الرسالة المستلمة', e);
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}

