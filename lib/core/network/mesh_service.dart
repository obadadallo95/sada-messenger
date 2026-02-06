import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/log_service.dart';
import '../security/security_providers.dart';
import '../security/encryption_service.dart';
import '../services/notification_provider.dart';
import '../services/notification_service.dart';

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
  Future<bool> sendMessage(String message) async {
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
  );
});

/// معالج الرسائل المستلمة
class MessageHandler {
  final MeshService meshService;
  final EncryptionService encryptionService;
  final NotificationService notificationService;
  
  StreamSubscription<String>? _messageSubscription;

  MessageHandler({
    required this.meshService,
    required this.encryptionService,
    required this.notificationService,
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

  Future<void> _handleMessage(String encryptedMessage) async {
    try {
      LogService.info('تم استقبال رسالة مشفرة: ${encryptedMessage.substring(0, encryptedMessage.length > 50 ? 50 : encryptedMessage.length)}...');
      
      // TODO: فك التشفير باستخدام EncryptionService
      // حالياً نتعامل مع الرسالة كنص عادي للاختبار
      String decryptedMessage = encryptedMessage;
      
      // TODO: حفظ الرسالة في قاعدة البيانات
      // await chatRepository.saveMessage(...);
      
      // إظهار إشعار محلي
      await notificationService.showChatNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'رسالة جديدة',
        body: decryptedMessage.length > 50 
            ? '${decryptedMessage.substring(0, 50)}...' 
            : decryptedMessage,
        payload: jsonEncode({'type': 'message', 'text': decryptedMessage}),
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

