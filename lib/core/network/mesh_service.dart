import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../utils/log_service.dart';
import '../security/security_providers.dart';
import '../security/encryption_service.dart';
import '../services/notification_provider.dart';
import '../services/notification_service.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';
import '../services/auth_service.dart';
import 'models/mesh_message.dart';
import 'discovery/udp_broadcast_service.dart';
import '../power/discovery_strategy.dart';
import 'protocols/handshake_protocol.dart';

/// خدمة Mesh لإدارة الاتصالات والرسائل
/// تدعم Store-Carry-Forward Mesh Routing Protocol
class MeshService {
  static const EventChannel _messageChannel = EventChannel('org.sada.messenger/messageReceived');
  static const EventChannel _socketStatusChannel = EventChannel('org.sada.messenger/socketStatus');
  static const MethodChannel _methodChannel = MethodChannel('org.sada.messenger/mesh');

  Stream<String>? _messageStream;
  Stream<Map<String, dynamic>>? _socketStatusStream;
  
  /// Set لتتبع الرسائل المعالجة (Deduplication)
  /// يمنع معالجة نفس الرسالة مرتين
  final Set<String> _processedMessages = {};
  
  /// Set لتتبع الأجهزة المتصلة التي أكملت Handshake
  final Set<String> _connectedPeers = {};
  
  /// Ref للوصول إلى Providers
  final Ref _ref;
  
  /// معرف الجهاز الحالي
  String? _myDeviceId;
  
  /// UDP Broadcast Service
  UdpBroadcastService? _udpBroadcastService;
  
  /// Discovery Strategy
  DiscoveryStrategy? _discoveryStrategy;
  
  /// Handshake Protocol
  HandshakeProtocol? _handshakeProtocol;
  
  MeshService(this._ref);

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

  /// الحصول على معرف الجهاز الحالي
  Future<String> _getMyDeviceId() async {
    if (_myDeviceId != null) return _myDeviceId!;
    
    final authService = _ref.read(authServiceProvider.notifier);
    final currentUser = authService.currentUser;
    _myDeviceId = currentUser?.userId ?? 'unknown';
    return _myDeviceId!;
  }

  /// إرسال رسالة عبر Mesh Network مع Store-Carry-Forward Routing
  /// [peerId]: معرف الطرف المستقبل
  /// [encryptedContent]: المحتوى المشفر (Base64)
  /// [senderId]: معرف المرسل (اختياري)
  /// [maxHops]: الحد الأقصى للقفزات (TTL) - Default: 10
  Future<bool> sendMeshMessage(
    String peerId,
    String encryptedContent, {
    String? senderId,
    int maxHops = 10,
    String? type,
    String? messageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final myDeviceId = await _getMyDeviceId();
      final finalSenderId = senderId ?? myDeviceId;
      
      // إنشاء MeshMessage
      final effectiveMessageId = messageId ?? const Uuid().v4();
      
      final meshMessage = MeshMessage(
        messageId: effectiveMessageId,
        originalSenderId: finalSenderId,
        finalDestinationId: peerId,
        encryptedContent: encryptedContent,
        hopCount: 0,
        maxHops: maxHops,
        trace: [],
        timestamp: DateTime.now(),
        type: type,
        metadata: metadata,
      );
      
      // إرسال الرسالة
      // 1. Store in RelayQueue (Store-Carry-Forward)
      // Even if we are the sender, we store it to carry it until we meet a peer.
      await _storeAndForward(meshMessage);
      
      return true;
    } catch (e) {
      LogService.error('خطأ في إرسال MeshMessage', e);
      return false;
    }
  }

  /// إرسال رسالة عبر Socket (Legacy - للتوافق مع الكود القديم)
  /// [peerId]: معرف الطرف المستقبل
  /// [encryptedContent]: المحتوى المشفر (Base64)
  /// [senderId]: معرف المرسل (اختياري)
  Future<bool> sendMessage(String peerId, String encryptedContent, {String? senderId}) async {
    try {
      // التحقق من حالة الاتصال أولاً
      var isConnected = await _methodChannel.invokeMethod<bool>('isSocketConnected') ?? false;
      
      LogService.info('🔍 حالة Socket قبل الإرسال: $isConnected');
      
      if (!isConnected) {
        LogService.warning('⚠️ Socket غير متصل - محاولة بدء الخادم...');
        // محاولة بدء الخادم
        try {
          await _methodChannel.invokeMethod('startServer');
          // انتظار قليل للاتصال
          await Future.delayed(const Duration(milliseconds: 2000));
          
          // التحقق مرة أخرى
          isConnected = await _methodChannel.invokeMethod<bool>('isSocketConnected') ?? false;
          LogService.info('🔍 حالة Socket بعد بدء الخادم: $isConnected');
        } catch (e) {
          LogService.warning('فشل بدء الخادم: $e');
        }
      }
      
      // إذا كان Socket لا يزال غير متصل، نحاول إرسال الرسالة على أي حال
      // (قد يكون الاتصال موجوداً لكن لم يتم اكتشافه بعد)
      if (!isConnected) {
        LogService.warning('⚠️ Socket لا يزال غير متصل - سيتم محاولة الإرسال على أي حال');
      }
      
      // إنشاء JSON payload مع senderId
      final finalSenderId = senderId ?? 'unknown';
      
      final payload = jsonEncode({
        'senderId': finalSenderId,
        'peerId': peerId,
        'content': encryptedContent,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      LogService.info('📤 محاولة إرسال رسالة إلى $peerId');
      LogService.info('   - senderId: $finalSenderId');
      LogService.info('   - Socket متصل: $isConnected');
      LogService.info('   - حجم الرسالة: ${payload.length} bytes');
      
      final result = await _methodChannel.invokeMethod<bool>(
        'socket_write',
        {
          'peerId': peerId,
          'message': payload,
        },
      );
      
      if (result == true) {
        LogService.info('✅ تم إرسال الرسالة بنجاح إلى $peerId');
      } else {
        LogService.error('❌ فشل إرسال الرسالة إلى $peerId');
        LogService.error('   - Socket متصل: $isConnected');
        LogService.error('   - قد تحتاج الأجهزة إلى الاتصال عبر WiFi P2P أولاً');
      }
      
      return result ?? false;
    } catch (e, stackTrace) {
      LogService.error('خطأ في إرسال الرسالة', e);
      LogService.error('تفاصيل الخطأ: ${e.toString()}');
      LogService.error('Stack trace: $stackTrace');
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

  // ==================== Store-Carry-Forward Routing Logic ====================

  /// معالجة الرسالة الواردة (Routing Logic)
  /// هذا هو "الدماغ" الذي يقرر: هل أنا الهدف؟ أم أنا Relay؟
  Future<void> handleIncomingMeshMessage(String rawMessage) async {
    try {
      // Parse JSON
      final jsonData = jsonDecode(rawMessage) as Map<String, dynamic>;
      
      // التحقق من نوع الرسالة - هل هي Handshake؟
      final messageType = jsonData['type'] as String?;
      
      if (messageType == 'HANDSHAKE') {
        await _handleIncomingHandshake(rawMessage);
        return;
      }
      
      if (messageType == 'HANDSHAKE_ACK') {
        await _handleHandshakeAck(rawMessage);
        return;
      }
      
      // Parse to MeshMessage
      final meshMessage = MeshMessage.fromJson(jsonData);
      
      final myDeviceId = await _getMyDeviceId();
      
      LogService.info('📨 استقبال MeshMessage: ${meshMessage.messageId}');
      LogService.info('   من: ${meshMessage.originalSenderId}');
      LogService.info('   إلى: ${meshMessage.finalDestinationId}');
      LogService.info('   قفزات: ${meshMessage.hopCount}/${meshMessage.maxHops}');
      
      // Step 1: Deduplication
      if (_processedMessages.contains(meshMessage.messageId)) {
        LogService.info('⏭️ تم تجاهل رسالة مكررة: ${meshMessage.messageId}');
        return;
      }
      
      // Step 2: التحقق من صحة الرسالة (TTL و Loop Detection)
      if (!meshMessage.isValid(myDeviceId)) {
        LogService.warning('❌ رسالة غير صالحة: ${meshMessage.messageId}');
        if (meshMessage.hopCount >= meshMessage.maxHops) {
          LogService.warning('   - تجاوزت الحد الأقصى للقفزات (TTL)');
        }
        if (meshMessage.trace.contains(myDeviceId)) {
          LogService.warning('   - حلقة اكتشفت (Loop Detection)');
        }
        return;
      }
      
      // Step 3: هل أنا الهدف؟
      if (meshMessage.isForMe(myDeviceId)) {
        LogService.info('✅ أنا الهدف! معالجة الرسالة...');
        await _processMessageForMe(meshMessage);
        _processedMessages.add(meshMessage.messageId);
        return;
      }
      
      // Step 4: هل أنا Relay؟ (Store-Carry-Forward)
      if (!meshMessage.isFromMe(myDeviceId)) {
        LogService.info('📦 أنا Relay - تخزين وإعادة توجيه...');
        await _storeAndForward(meshMessage);
        _processedMessages.add(meshMessage.messageId);
      } else {
        LogService.info('⏭️ تجاهل رسالة مني: ${meshMessage.messageId}');
      }
    } catch (e) {
      LogService.error('خطأ في معالجة MeshMessage', e);
    }
  }

  /// معالجة الرسالة الموجهة لي (الهدف)
  Future<void> _processMessageForMe(MeshMessage meshMessage) async {
    try {
      LogService.info('🎯 معالجة رسالة موجهة لي: ${meshMessage.messageId}');

      // إذا كانت الرسالة من نوع ACK فهي رسالة تحكم (Control Plane)
      // ولا تُعرض للمستخدم، بل تُستخدم لتحديث حالة الرسالة الأصلية.
      if (meshMessage.type == MeshMessage.typeAck) {
        await _handleAck(meshMessage);
        return;
      }

      // الرسائل العادية سيتم معالجتها تلقائياً في IncomingMessageHandler
      // لأن IncomingMessageHandler يستمع إلى onMessageReceived stream
      // و handleIncomingMeshMessage() يتم استدعاؤه قبل _handleIncomingMessage()
      // لذلك سيتم معالجة الرسالة في IncomingMessageHandler._handleIncomingMessage()
    } catch (e) {
      LogService.error('خطأ في معالجة الرسالة الموجهة لي', e);
    }
  }

  /// معالجة ACK MeshMessage عند وصوله للمرسل الأصلي.
  /// يستخدم originalMessageId المخزن في metadata لتحديث حالة الرسالة في DB.
  Future<void> _handleAck(MeshMessage meshMessage) async {
    try {
      final metadata = meshMessage.metadata ?? const <String, dynamic>{};
      final originalMessageId = metadata['originalMessageId'] as String?;

      if (originalMessageId == null) {
        LogService.warning('تم استقبال ACK بدون originalMessageId - سيتم تجاهله');
        return;
      }

      final database = await _ref.read(appDatabaseProvider.future);
      final updated = await database.updateMessageStatus(originalMessageId, 'delivered');

      if (updated) {
        LogService.info('✅ ACK received – تم تحديث حالة الرسالة إلى delivered: $originalMessageId');
      } else {
        LogService.warning('⚠️ ACK received ولكن لم يتم العثور على رسالة في DB: $originalMessageId');
      }
    } catch (e) {
      LogService.error('خطأ في معالجة ACK MeshMessage', e);
    }
  }

  /// تخزين وإعادة توجيه الرسالة (Store-Carry-Forward)
  /// 
  /// 🔒 BLIND RELAY SECURITY:
  /// - Relay nodes فقط تنظر إلى header (destination ID) للتوجيه
  /// - المحتوى المشفر (encryptedContent) لا يتم فك تشفيره في Relay
  /// - Relay لا يمكنها قراءة محتوى الرسالة - فقط تمريرها
  Future<void> _storeAndForward(MeshMessage meshMessage) async {
    try {
      final database = await _ref.read(appDatabaseProvider.future);
      final myDeviceId = await _getMyDeviceId();
      
      // 🔒 SECURITY: نحن Relay - نحفظ فقط header metadata
      // encryptedContent يبقى مشفراً - لا نحاول فك تشفيره
      // نحن فقط ننظر إلى finalDestinationId للتوجيه
      
      // إضافة رسالة إلى RelayQueue (المحتوى مشفر - لا نراه)
      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: meshMessage.messageId,
          toHash: meshMessage.finalDestinationId, // Using ID as hash for now (Blind Relaying)
          ttl: Value(meshMessage.maxHops),
          payload: meshMessage.toJsonString(), // Encapsulate entire message as payload
          createdAt: meshMessage.timestamp, // Pass DateTime directly, not Value check generated code normally
          trace: Value(jsonEncode(meshMessage.trace)),
        ),
      );

      
      LogService.info('💾 تم تخزين الرسالة في RelayQueue (Blind Relay): ${meshMessage.messageId}');
      LogService.info('   - Destination: ${meshMessage.finalDestinationId}');
      LogService.info('   - Content: 🔒 Encrypted (Blind to Relay)');
      
      // إعادة توجيه الرسالة إلى جميع الأجهزة المتصلة
      // المحتوى يبقى مشفراً - لا نراه
      final updatedMessage = meshMessage.addHop(myDeviceId);
      await _forwardMessage(updatedMessage);
      
    } catch (e) {
      LogService.error('خطأ في Store-Carry-Forward', e);
    }
  }

  /// إعادة توجيه رسالة إلى جميع الأجهزة المتصلة (Flooding)
  Future<bool> _forwardMessage(MeshMessage meshMessage) async {
    try {
      final messageJson = meshMessage.toJsonString();
      
      // إرسال الرسالة عبر Socket
      final result = await _methodChannel.invokeMethod<bool>(
        'socket_write',
        {
          'peerId': meshMessage.finalDestinationId,
          'message': messageJson,
        },
      );
      
      if (result == true) {
        LogService.info('✅ تم إعادة توجيه الرسالة: ${meshMessage.messageId}');
      } else {
        LogService.warning('⚠️ فشل إعادة توجيه الرسالة: ${meshMessage.messageId}');
      }
      
      return result ?? false;
    } catch (e) {
      LogService.error('خطأ في إعادة توجيه الرسالة', e);
      return false;
    }
  }

  /// إرسال جميع الرسائل من RelayQueue عند اتصال جهاز جديد
  /// هذا يجعل الجهاز يعمل كـ "Data Mule"
  Future<void> flushRelayQueue(String newPeerId) async {
    try {
      final database = await _ref.read(appDatabaseProvider.future);
      final queue = await database.getRelayPacketsForSync();
      
      if (queue.isEmpty) {
        LogService.info('📭 RelayQueue فارغة - لا توجد رسائل للإرسال');
        return;
      }
      
      LogService.info('📤 إرسال ${queue.length} رسالة من RelayQueue إلى $newPeerId');
      
      for (final queuedMessage in queue) {
        try {
          // إعادة بناء MeshMessage من RelayQueueTableData
          final Map<String, dynamic> payloadMap;
          try {
            payloadMap = jsonDecode(queuedMessage.payload) as Map<String, dynamic>;
          } catch (e) {
            LogService.error('فشل في فك تشفير payload للرسالة ${queuedMessage.packetId}', e);
            await database.deletePacket(queuedMessage.packetId);
            continue;
          }

          final meshMessage = MeshMessage.fromJson(payloadMap);
          
          // التحقق من صحة الرسالة قبل الإرسال
          final myDeviceId = await _getMyDeviceId();
          if (!meshMessage.isValid(myDeviceId)) {
            LogService.warning('⚠️ رسالة غير صالحة في RelayQueue: ${meshMessage.messageId}');
            await database.deletePacket(queuedMessage.packetId);
            continue;
          }
          
          // إعادة توجيه الرسالة
          final sent = await _forwardMessage(meshMessage);
          
          if (sent) {
            // حذف الرسالة من RelayQueue بعد الإرسال الناجح
            await database.deletePacket(queuedMessage.packetId);
            LogService.info('✅ تم إرسال رسالة من RelayQueue: ${meshMessage.messageId}');
          } else {
            // زيادة عدد المحاولات
            await database.incrementRetryCount(queuedMessage.packetId);
          }
        } catch (e) {
          LogService.error('خطأ في إرسال رسالة من RelayQueue', e);
          await database.incrementRetryCount(queuedMessage.packetId);
        }
      }
      
      // تنظيف الرسائل القديمة والفاشلة
      await database.cleanupOldRelayMessages();
      await database.removeFailedMessages();
      
    } catch (e) {
      LogService.error('خطأ في flushRelayQueue', e);
    }
  }

  /// معالجة Handshake الوارد (Server Side)
  Future<void> _handleIncomingHandshake(String handshakeJson) async {
    try {
      _handshakeProtocol ??= _ref.read(handshakeProtocolProvider);

      final ackMessage = await _handshakeProtocol!.processIncomingHandshake(handshakeJson);
      
      if (ackMessage != null) {
        // إرسال Handshake ACK
        final handshake = jsonDecode(handshakeJson) as Map<String, dynamic>;
        final peerId = handshake['peerId'] as String?;
        
        if (peerId != null) {
          await _methodChannel.invokeMethod<bool>(
            'socket_write',
            {
              'peerId': peerId,
              'message': ackMessage,
            },
          );
          
          // إكمال Handshake
          await _completeHandshake(peerId);
        }
      }
    } catch (e) {
      LogService.error('خطأ في معالجة Handshake الوارد', e);
    }
  }

  /// معالجة Handshake ACK (Client Side)
  Future<void> _handleHandshakeAck(String ackJson) async {
    try {
      _handshakeProtocol ??= _ref.read(handshakeProtocolProvider);

      final accepted = await _handshakeProtocol!.processHandshakeAck(ackJson);
      
      if (accepted) {
        final ack = jsonDecode(ackJson) as Map<String, dynamic>;
        final peerId = ack['peerId'] as String?;
        
        if (peerId != null) {
          // إكمال Handshake
          await _completeHandshake(peerId);
        }
      }
    } catch (e) {
      LogService.error('خطأ في معالجة Handshake ACK', e);
    }
  }

  /// تنظيف Set الرسائل المعالجة (لمنع تسرب الذاكرة)
  void cleanupProcessedMessages() {
    if (_processedMessages.length > 1000) {
      _processedMessages.clear();
      LogService.info('🧹 تم تنظيف Set الرسائل المعالجة');
    }
  }

  // ==================== Transport & Discovery Layer ====================

  /// تهيئة Transport & Discovery Layer
  Future<void> initializeTransportLayer() async {
    try {
      LogService.info('🚀 تهيئة Transport & Discovery Layer...');
      
      // تهيئة DiscoveryStrategy
      _discoveryStrategy = _ref.read(discoveryStrategyProvider);
      await _discoveryStrategy!.updateBatteryStatus();
      
      // تهيئة HandshakeProtocol
      _handshakeProtocol = _ref.read(handshakeProtocolProvider);
      
      // تهيئة UDP Broadcast Service
      _udpBroadcastService = _ref.read(udpBroadcastServiceProvider);
      final interval = _discoveryStrategy!.currentInterval;
      
      LogService.info('📊 Discovery Interval: ${interval}s');
      
      final started = await _udpBroadcastService!.start(intervalSeconds: interval);
      
      if (started) {
        LogService.info('✅ تم تهيئة Transport & Discovery Layer بنجاح');
      } else {
        LogService.warning('⚠️ فشل بدء UDP Broadcast Service - قد يكون WiFi غير متصل');
      }
    } catch (e) {
      LogService.error('خطأ في تهيئة Transport & Discovery Layer', e);
    }
  }

  /// الاتصال بجهاز معين (مع Handshake Protocol)
  /// [ip]: عنوان IP للجهاز
  /// [port]: Port للاتصال TCP
  /// [deviceId]: معرف الجهاز المتوقع
  Future<bool> connectToPeer(String ip, int port, String deviceId) async {
    try {
      LogService.info('🔗 محاولة الاتصال بالجهاز: $deviceId @ $ip:$port');
      
      // التحقق من أن الجهاز غير متصل بالفعل
      if (_connectedPeers.contains(deviceId)) {
        LogService.info('الجهاز متصل بالفعل: $deviceId');
        return true;
      }

      // الاتصال عبر Socket (سيتم تنفيذها في Native)
      final connected = await _methodChannel.invokeMethod<bool>(
        'connectToPeer',
        {
          'ip': ip,
          'port': port,
        },
      );

      if (connected != true) {
        LogService.warning('فشل الاتصال بالجهاز: $deviceId');
        return false;
      }

      // إرسال Handshake Message
      _handshakeProtocol ??= _ref.read(handshakeProtocolProvider);

      final handshakeMessage = await _handshakeProtocol!.createHandshakeMessage();
      
      // إرسال Handshake عبر Socket
      final handshakeSent = await _methodChannel.invokeMethod<bool>(
        'socket_write',
        {
          'peerId': deviceId,
          'message': handshakeMessage,
        },
      );

      if (handshakeSent != true) {
        LogService.warning('فشل إرسال Handshake إلى: $deviceId');
        return false;
      }

      LogService.info('✅ تم إرسال Handshake إلى: $deviceId');
      LogService.info('⏳ في انتظار Handshake ACK...');
      
      // ملاحظة: Handshake ACK سيتم استقباله في handleIncomingMeshMessage
      // وسيتم استدعاء _completeHandshake تلقائياً
      
      return true;
    } catch (e) {
      LogService.error('خطأ في الاتصال بالجهاز', e);
      return false;
    }
  }

  /// إكمال Handshake (يتم استدعاؤه عند استقبال Handshake ACK)
  Future<void> _completeHandshake(String peerId) async {
    try {
      if (_connectedPeers.contains(peerId)) {
        return; // Handshake مكتمل بالفعل
      }

      _connectedPeers.add(peerId);
      LogService.info('✅ Handshake مكتمل مع: $peerId');
      
      // 🔥 CRUCIAL: إرسال RelayQueue فوراً بعد Handshake
      await flushRelayQueue(peerId);
      
    } catch (e) {
      LogService.error('خطأ في إكمال Handshake', e);
    }
  }

  /// التحقق من أن الجهاز متصل (أكمل Handshake)
  bool isPeerConnected(String peerId) {
    return _connectedPeers.contains(peerId);
  }

  /// تحديث Discovery Interval (يتم استدعاؤه عند تغيير Battery Mode)
  void updateDiscoveryInterval(int intervalSeconds) {
    _udpBroadcastService?.updateInterval(intervalSeconds);
    LogService.info('تم تحديث Discovery Interval إلى: ${intervalSeconds}s');
  }
}

/// Provider لـ MeshService
final meshServiceProvider = Provider<MeshService>((ref) => MeshService(ref));

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

