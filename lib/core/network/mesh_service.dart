// ignore_for_file: unused_element

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../utils/log_service.dart';
import '../utils/bloom_filter.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';
import '../services/auth_service.dart';
import '../services/metrics_service.dart';
import 'models/mesh_message.dart';
import 'discovery/udp_broadcast_service.dart';
import '../power/discovery_strategy.dart';
import 'protocols/handshake_protocol.dart';

/// خدمة Mesh لإدارة الاتصالات والرسائل
/// تدعم Store-Carry-Forward Mesh Routing Protocol
class MeshService {
  static const EventChannel _messageChannel = EventChannel(
    'org.sada.messenger/messageReceived',
  );
  static const EventChannel _socketStatusChannel = EventChannel(
    'org.sada.messenger/socketStatus',
  );
  static const MethodChannel _methodChannel = MethodChannel(
    'org.sada.messenger/mesh',
  );
  static const int _maxSocketPayloadBytes = 1024 * 1024; // 1 MB safety ceiling

  Stream<String>? _messageStream;
  Stream<Map<String, dynamic>>? _socketStatusStream;
  StreamSubscription<Map<String, dynamic>>? _socketStatusSubscription;

  /// Set لتتبع الرسائل المعالجة (Deduplication)
  /// يمنع معالجة نفس الرسالة مرتين
  final Set<String> _processedMessages = {};

  /// Set لتتبع الأجهزة المتصلة التي أكملت Handshake
  final Set<String> _connectedPeers = {};
  final _connectedPeersController = StreamController<List<String>>.broadcast();
  final Map<String, PeerSessionState> _peerStates = {};
  final Map<String, Completer<bool>> _handshakeAckWaiters = {};
  final Set<String> _handshakeInProgress = {};
  final Map<String, String> _peerIdByIp = {};
  final Map<String, DateTime> _lastFallbackAttemptAt = {};
  String? _lastTransportError;
  int _handshakeAttempts = 0;
  int _handshakeAcks = 0;
  int _handshakeTimeouts = 0;
  String? _lastSocketRemoteIp;
  String? _activeSocketPeerId;

  /// خرائط Bloom Filters للأجهزة المتصلة لتجنب إرسال رسائل مكررة
  final Map<String, BloomFilter> _peerBloomFilters = {};

  /// Stream للأجهزة المتصلة (لواجهة المستخدم)
  Stream<List<String>> get connectedPeersStream =>
      _connectedPeersController.stream;

  /// الحصول على القائمة الحالية
  List<String> get connectedPeers => _connectedPeers.toList();

  /// تقرير تشخيص طبقة النقل (Discovery/Socket/Handshake).
  Future<Map<String, dynamic>> getTransportDiagnostics() async {
    bool socketConnected = false;
    try {
      socketConnected =
          await _methodChannel.invokeMethod<bool>('isSocketConnected') ?? false;
    } catch (_) {
      socketConnected = false;
    }

    final peerStates = _peerStates.map((k, v) => MapEntry(k, v.name));
    final readyPeers = _peerStates.entries
        .where((e) => e.value == PeerSessionState.peerReady)
        .map((e) => e.key)
        .toList();

    String blockerHint = '';
    if (socketConnected && readyPeers.isEmpty) {
      blockerHint = 'socket_connected_but_no_peer_ready_handshake_incomplete';
    } else if (!socketConnected && _peerStates.isNotEmpty) {
      blockerHint = 'peer_discovered_but_socket_not_connected';
    }
    if (_peerStates.containsKey('unknown')) {
      blockerHint = 'invalid_peer_id_unknown_from_discovery_or_native_status';
    }

    return {
      'myDeviceId': _myDeviceId ?? '',
      'socketConnected': socketConnected,
      'activeSocketPeerId': _activeSocketPeerId ?? '',
      'connectedPeers': _connectedPeers.toList(),
      'readyPeers': readyPeers,
      'peerStates': peerStates,
      'knownPeerIps': _peerIdByIp,
      'blockerHint': blockerHint,
      'lastTransportError': _lastTransportError ?? '',
      'handshakeAttempts': _handshakeAttempts,
      'handshakeAcks': _handshakeAcks,
      'handshakeTimeouts': _handshakeTimeouts,
      'lastSocketRemoteIp': _lastSocketRemoteIp ?? '',
      'udp': _udpBroadcastService?.getDiagnostics() ?? const <String, dynamic>{},
      'pendingHandshakeWaiters': _handshakeAckWaiters.length,
      'processedMessagesCount': _processedMessages.length,
      'udpServiceInitialized': _udpBroadcastService != null,
      'discoveryStrategyInitialized': _discoveryStrategy != null,
    };
  }

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

  String _tag(String peerId) => '[peer=$peerId]';

  void _setPeerState(
    String peerId,
    PeerSessionState state, {
    String? reason,
  }) {
    final old = _peerStates[peerId];
    _peerStates[peerId] = state;
    LogService.info(
      '${_tag(peerId)} state: ${old?.name ?? 'none'} -> ${state.name}'
      '${reason != null ? ' ($reason)' : ''}',
    );
  }

  bool _isPeerReady(String peerId) =>
      _peerStates[peerId] == PeerSessionState.peerReady;

  void _markPeerDisconnected(String peerId, {String? reason}) {
    _setPeerState(peerId, PeerSessionState.discovered, reason: reason);
    _peerBloomFilters.remove(peerId);
    _handshakeAckWaiters.remove(peerId);
    if (_connectedPeers.remove(peerId)) {
      _connectedPeersController.add(_connectedPeers.toList());
      LogService.info('${_tag(peerId)} removed from ready peers');
    }
  }

  Map<String, dynamic> _toJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, val) => MapEntry(key.toString(), val));
      }
      throw const FormatException('Decoded JSON is not an object');
    }
    throw const FormatException('Unsupported JSON payload shape');
  }

  /// Unified socket writer for framed TCP transport.
  /// Validates payload size before it reaches the native framing layer.
  Future<bool> _socketWrite({
    required String peerId,
    required String message,
    required String context,
    bool allowBeforeReady = false,
  }) async {
    try {
      if (!allowBeforeReady && !_isPeerReady(peerId)) {
        LogService.warning(
          '${_tag(peerId)} [$context] blocked: peer is not Peer_Ready',
        );
        _lastTransportError = 'write_blocked_peer_not_ready:$peerId:$context';
        return false;
      }

      if (message.isEmpty) {
        LogService.warning('${_tag(peerId)} [$context] رفض إرسال payload فارغ');
        return false;
      }

      final payloadBytes = utf8.encode(message);
      if (payloadBytes.length > _maxSocketPayloadBytes) {
        LogService.warning(
          '${_tag(peerId)} [$context] payload أكبر من الحد المسموح '
          '(${payloadBytes.length} > $_maxSocketPayloadBytes)',
        );
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>('socket_write', {
        'peerId': peerId,
        'message': message,
      });

      if (result == true) {
        LogService.info('${_tag(peerId)} 📤 [FLUTTER] Message sent to native');
      } else {
        LogService.warning(
          '${_tag(peerId)} ⚠️ [FLUTTER] Failed to send message to native',
        );
      }

      return result ?? false;
    } catch (e) {
      LogService.error('${_tag(peerId)} خطأ في socket_write [$context]', e);
      _lastTransportError = 'socket_write_exception:$peerId:$context:${e.toString()}';
      return false;
    }
  }

  /// Stream للرسائل المستلمة
  Stream<String> get onMessageReceived {
    _messageStream ??= _messageChannel.receiveBroadcastStream().map((
      dynamic event,
    ) {
      try {
        if (event == null) return '';
        final message = event as String;
        LogService.info('📥 [FLUTTER] Received message from Native: ${message.length} chars');
        return message;
      } catch (e) {
        LogService.error('خطأ في معالجة الرسالة المستلمة', e);
        return '';
      }
    }).asBroadcastStream();

    return _messageStream!;
  }

  /// Stream لحالة Socket
  Stream<Map<String, dynamic>> get onSocketStatus {
    _socketStatusStream ??= _socketStatusChannel.receiveBroadcastStream().map((
      dynamic event,
    ) {
      try {
        if (event == null) {
          return {
            'status': 'unknown',
            'message': '',
            'isConnected': false,
            'isServer': false,
          };
        }
        final statusJson = _toJsonMap(event);
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
    }).asBroadcastStream();

    return _socketStatusStream!;
  }

  /// الحصول على معرف الجهاز الحالي
  Future<String> _getMyDeviceId() async {
    if (_myDeviceId != null && _myDeviceId!.isNotEmpty && _myDeviceId != 'unknown') {
      return _myDeviceId!;
    }

    final authService = _ref.read(authServiceProvider.notifier);
    final currentUser = authService.currentUser;
    final resolved = currentUser?.userId;
    if (resolved == null || resolved.isEmpty || resolved == 'unknown') {
      return 'unknown';
    }
    _myDeviceId = resolved;
    return resolved;
  }

  bool _isValidPeerId(String? peerId) {
    if (peerId == null) return false;
    final normalized = peerId.trim().toLowerCase();
    return normalized.isNotEmpty && normalized != 'unknown' && normalized != 'null';
  }

  String? _extractIpFromRemoteAddress(String? remoteAddress) {
    if (remoteAddress == null || remoteAddress.isEmpty) return null;
    // Example: /192.168.1.21:8888
    final cleaned = remoteAddress.startsWith('/')
        ? remoteAddress.substring(1)
        : remoteAddress;
    final idx = cleaned.lastIndexOf(':');
    if (idx <= 0) return cleaned;
    return cleaned.substring(0, idx);
  }

  String? _resolvePeerIdFromSocketEvent(Map<String, dynamic> event) {
    final peerId = event['peerId']?.toString();
    if (_isValidPeerId(peerId)) return peerId;

    final ip = _extractIpFromRemoteAddress(event['remoteAddress']?.toString());
    if (ip != null && _peerIdByIp.containsKey(ip)) {
      return _peerIdByIp[ip];
    }

    if (_isValidPeerId(_activeSocketPeerId)) return _activeSocketPeerId;
    return null;
  }

  Future<void> _sendHandshakeRecoveryProbe() async {
    final socketConnected =
        await _methodChannel.invokeMethod<bool>('isSocketConnected') ?? false;
    if (!socketConnected || _connectedPeers.isNotEmpty) return;

    String probePeerId = '';
    if (_isValidPeerId(_activeSocketPeerId)) {
      probePeerId = _activeSocketPeerId!;
    } else if (_lastSocketRemoteIp != null && _lastSocketRemoteIp!.isNotEmpty) {
      probePeerId = 'ip:${_lastSocketRemoteIp!}';
    } else if (_peerIdByIp.isNotEmpty) {
      probePeerId = _peerIdByIp.values.first;
    } else {
      return;
    }

    if (_handshakeInProgress.contains(probePeerId)) return;
    unawaited(_sendHandshakeWithRetry(probePeerId));
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
  Future<bool> sendMessage(
    String peerId,
    String encryptedContent, {
    String? senderId,
  }) async {
    try {
      // التحقق من حالة الاتصال أولاً
      var isConnected =
          await _methodChannel.invokeMethod<bool>('isSocketConnected') ?? false;

      LogService.info('🔍 حالة Socket قبل الإرسال: $isConnected');

      if (!isConnected) {
        LogService.warning('⚠️ Socket غير متصل - محاولة بدء الخادم...');
        // محاولة بدء الخادم
        try {
          await _methodChannel.invokeMethod('startServer');
          // انتظار قليل للاتصال
          await Future.delayed(const Duration(milliseconds: 2000));

          // التحقق مرة أخرى
          isConnected =
              await _methodChannel.invokeMethod<bool>('isSocketConnected') ??
              false;
          LogService.info('🔍 حالة Socket بعد بدء الخادم: $isConnected');
        } catch (e) {
          LogService.warning('فشل بدء الخادم: $e');
        }
      }

      // إذا كان Socket لا يزال غير متصل، نحاول إرسال الرسالة على أي حال
      // (قد يكون الاتصال موجوداً لكن لم يتم اكتشافه بعد)
      if (!isConnected) {
        LogService.warning(
          '⚠️ Socket لا يزال غير متصل - سيتم محاولة الإرسال على أي حال',
        );
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

      final result = await _socketWrite(
        peerId: peerId,
        message: payload,
        context: 'sendMessage',
      );

      if (result) {
        LogService.info('✅ تم إرسال الرسالة بنجاح إلى $peerId');
      } else {
        LogService.error('❌ فشل إرسال الرسالة إلى $peerId');
        LogService.error('   - Socket متصل: $isConnected');
        LogService.error(
          '   - قد تحتاج الأجهزة إلى الاتصال عبر WiFi P2P أولاً',
        );
      }

      return result;
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
      final result = await _methodChannel.invokeMethod<bool>('sendMessage', {
        'message': message,
      });
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
      final jsonData = _toJsonMap(rawMessage);

      // التحقق من نوع الرسالة - هل هي Handshake؟
      final messageType = jsonData['type']?.toString();

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
      LogService.info(
        '   قفزات: ${meshMessage.hopCount}/${meshMessage.maxHops}',
      );

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
        final sourcePeerId = meshMessage.trace.isNotEmpty
            ? meshMessage.trace.last
            : null;
        await _storeAndForward(meshMessage, receivedFromPeerId: sourcePeerId);
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

      // ملاحظة: الرسائل من نوع ACK تمت معالجتها سابقاً في IncomingMessageHandler بشكل أمن (مشفرة)
      // ولكن لغرض الـ backward compatibility أو في حال لم يتم تشفيرها،
      // يمكن معالجة الـ Metadata هنا إذا لزم الأمر.
      // حالياً، سنترك المعالجة لـ IncomingMessageHandler لتوحيد المنطق.

      if (meshMessage.type == MeshMessage.typeAck) {
        LogService.info(
          '📨 ACK message routed to IncomingMessageHandler via stream.',
        );
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
        LogService.warning(
          'تم استقبال ACK بدون originalMessageId - سيتم تجاهله',
        );
        return;
      }

      final database = await _ref.read(appDatabaseProvider.future);
      final updated = await database.updateMessageStatus(
        originalMessageId,
        'delivered',
      );

      if (updated) {
        LogService.info(
          '✅ ACK received – تم تحديث حالة الرسالة إلى delivered: $originalMessageId',
        );

        final metricsService = _ref.read(metricsServiceProvider);
        metricsService.recordMessageDelivered();
      } else {
        LogService.warning(
          '⚠️ ACK received ولكن لم يتم العثور على رسالة في DB: $originalMessageId',
        );
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
  Future<void> _storeAndForward(
    MeshMessage meshMessage, {
    String? receivedFromPeerId,
  }) async {
    try {
      final database = await _ref.read(appDatabaseProvider.future);
      final myDeviceId = await _getMyDeviceId();

      // 🔒 SECURITY: نحن Relay - نحفظ فقط header metadata
      // encryptedContent يبقى مشفراً - لا نحاول فك تشفيره
      // نحن فقط ننظر إلى finalDestinationId للتوجيه

      // يجب تقليل TTL (hopCount++) قبل التخزين/الإرسال لمنع إعادة تدوير
      // نفس metadata القديمة في الشبكة.
      final forwardedMessage = meshMessage.addHop(myDeviceId);
      final remainingTtl = forwardedMessage.maxHops - forwardedMessage.hopCount;
      if (remainingTtl <= 0) {
        LogService.warning(
          '⚠️ الرسالة انتهت صلاحيتها قبل إعادة التوجيه: ${meshMessage.messageId}',
        );
        await database.deletePacket(meshMessage.messageId);
        return;
      }

      await _persistRelayPacketAtomic(
        database: database,
        message: forwardedMessage,
        ttl: remainingTtl,
      );

      LogService.info(
        '💾 تم تخزين الرسالة في RelayQueue (Blind Relay): ${meshMessage.messageId}',
      );
      LogService.info('   - Destination: ${meshMessage.finalDestinationId}');
      LogService.info('   - Content: 🔒 Encrypted (Blind to Relay)');

      // إعادة توجيه الرسالة إلى جميع الأجهزة المتصلة (Epidemic Fanout)
      // المحتوى يبقى مشفراً - لا نراه
      await _forwardMessage(
        forwardedMessage,
        excludePeerId: receivedFromPeerId,
      );
    } catch (e) {
      LogService.error('خطأ في Store-Carry-Forward', e);
    }
  }

  Future<void> _persistRelayPacketAtomic({
    required AppDatabase database,
    required MeshMessage message,
    required int ttl,
  }) async {
    await database.enqueueRelayPacket(
      RelayQueueTableCompanion.insert(
        packetId: message.messageId,
        toHash: message.finalDestinationId, // Blind relay header only
        ttl: Value(ttl),
        payload: message.toJsonString(), // Persist newest hop metadata
        createdAt: message.timestamp,
        trace: Value(jsonEncode(message.trace)),
      ),
    );
  }

  /// إعادة توجيه رسالة إلى جميع الأجهزة المتصلة (Epidemic Fanout)
  Future<bool> _forwardMessage(
    MeshMessage meshMessage, {
    String? excludePeerId,
  }) async {
    try {
      final messageJson = meshMessage.toJsonString();
      final peersSnapshot = _connectedPeers.toList(growable: false);
      if (peersSnapshot.isEmpty) {
        LogService.info('📭 لا يوجد أقران متصلون لإعادة التوجيه');
        return false;
      }

      var sentCount = 0;
      for (final peerId in peersSnapshot) {
        if (excludePeerId != null && peerId == excludePeerId) {
          continue;
        }
        final sent = await _socketWrite(
          peerId: peerId,
          message: messageJson,
          context: 'forwardMessage',
        );
        if (sent) {
          sentCount++;
          LogService.info(
            '✅ تم إعادة توجيه ${meshMessage.messageId} إلى $peerId',
          );
        } else {
          LogService.warning(
            '⚠️ فشل إعادة توجيه ${meshMessage.messageId} إلى $peerId',
          );
        }
      }

      return sentCount > 0;
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

      LogService.info(
        '📤 إرسال ${queue.length} رسالة من RelayQueue إلى $newPeerId',
      );

      for (final queuedMessage in queue) {
        try {
          // إعادة بناء MeshMessage من RelayQueueTableData
          final Map<String, dynamic> payloadMap;
          try {
            payloadMap =
                jsonDecode(queuedMessage.payload) as Map<String, dynamic>;
          } catch (e) {
            LogService.error(
              'فشل في فك تشفير payload للرسالة ${queuedMessage.packetId}',
              e,
            );
            await database.deletePacket(queuedMessage.packetId);
            continue;
          }

          final meshMessage = MeshMessage.fromJson(payloadMap);

          // التحقق من صحة الرسالة قبل الإرسال
          final myDeviceId = await _getMyDeviceId();
          if (!meshMessage.isValid(myDeviceId)) {
            LogService.warning(
              '⚠️ رسالة غير صالحة في RelayQueue: ${meshMessage.messageId}',
            );
            await database.deletePacket(queuedMessage.packetId);
            continue;
          }

          // Bloom Filter Optimization (P1-SYNC)
          final peerBF = _peerBloomFilters[newPeerId];
          if (peerBF != null && peerBF.contains(meshMessage.messageId)) {
            // الجهاز الآخر *ربما* لديه هذه الرسالة
            // بما أننا نستخدم Store-Carry-Forward، تخطيها يوفر Bandwidth
            // False Positive risk: 1% (مقبول لشبكة Mesh)
            // يمكن تحسينها بـ Vector Summary later
            LogService.info(
              '⏭️ تخطي إرسال ${meshMessage.messageId} إلى $newPeerId (موجود حسب Bloom Filter)',
            );
            continue;
          }

          // تقليل TTL/Hop قبل أي إعادة توجيه جديدة وتخزين النسخة الجديدة
          final forwardedMessage = meshMessage.addHop(myDeviceId);
          final remainingTtl =
              forwardedMessage.maxHops - forwardedMessage.hopCount;
          if (remainingTtl <= 0) {
            LogService.warning(
              '⚠️ رسالة انتهت TTL أثناء flush: ${meshMessage.messageId}',
            );
            await database.deletePacket(queuedMessage.packetId);
            continue;
          }

          await _persistRelayPacketAtomic(
            database: database,
            message: forwardedMessage,
            ttl: remainingTtl,
          );

          // إعادة توجيه الرسالة
          final sent = await _forwardMessage(forwardedMessage);

          if (sent) {
            // حذف الرسالة من RelayQueue بعد الإرسال الناجح
            await database.deletePacket(queuedMessage.packetId);
            LogService.info(
              '✅ تم إرسال رسالة من RelayQueue: ${meshMessage.messageId}',
            );
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

      final result = await _handshakeProtocol!.processIncomingHandshake(
        handshakeJson,
      );

      if (result != null) {
        // إرسال Handshake ACK
        final handshake = jsonDecode(handshakeJson) as Map<String, dynamic>;
        final peerId = handshake['peerId'] as String?;

        if (peerId != null) {
          _activeSocketPeerId = peerId;
          _setPeerState(
            peerId,
            PeerSessionState.socketConnected,
            reason: 'incoming handshake',
          );
          await _socketWrite(
            peerId: peerId,
            message: result.ackMessage,
            context: 'handshakeAck',
            allowBeforeReady: true,
          );
          _setPeerState(
            peerId,
            PeerSessionState.handshakeAck,
            reason: 'ACK sent',
          );

          // إكمال Handshake
          await _completeHandshake(peerId, result.peerBloomFilter);
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

      final result = await _handshakeProtocol!.processHandshakeAck(ackJson);

      if (result.isAccepted) {
        final ack = jsonDecode(ackJson) as Map<String, dynamic>;
        final peerId = ack['peerId'] as String?;

        if (peerId != null) {
          _setPeerState(
            peerId,
            PeerSessionState.handshakeAck,
            reason: 'ACK received',
          );
          _handshakeAckWaiters.remove(peerId)?.complete(true);
          // إكمال Handshake
          await _completeHandshake(peerId, result.peerBloomFilter);
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

      // Unified transport: every node listens as TCP server on startup.
      await _methodChannel.invokeMethod('startServer');
      LogService.info('✅ TCP server listener started (unified transport mode)');

      _socketStatusSubscription?.cancel();
      _socketStatusSubscription = onSocketStatus.listen((event) {
        final status = event['status']?.toString() ?? 'unknown';
        _lastSocketRemoteIp = _extractIpFromRemoteAddress(
          event['remoteAddress']?.toString(),
        );
        final resolvedPeerId = _resolvePeerIdFromSocketEvent(event);
        if (resolvedPeerId == null) {
          LogService.warning(
            'socket status without resolvable peerId: status=$status raw=${event.toString()}',
          );
          _lastTransportError =
              'socket_status_unresolved_peer:$status:${event.toString()}';
          if (status == 'connected') {
            unawaited(_sendHandshakeRecoveryProbe());
          }
          return;
        }

        if (status == 'connected') {
          _activeSocketPeerId = resolvedPeerId;
          _setPeerState(
            resolvedPeerId,
            PeerSessionState.socketConnected,
            reason: 'native socket connected',
          );
          if (!_connectedPeers.contains(resolvedPeerId) &&
              !_handshakeInProgress.contains(resolvedPeerId)) {
            unawaited(_sendHandshakeWithRetry(resolvedPeerId));
          }
        } else if (status == 'disconnected' || status == 'error') {
          _markPeerDisconnected(
            resolvedPeerId,
            reason: 'native status: $status',
          );
        }
      });

      final started = await _udpBroadcastService!.start(
        intervalSeconds: interval,
      );

      if (started) {
        LogService.info('✅ تم تهيئة Transport & Discovery Layer بنجاح');
      } else {
        LogService.warning(
          '⚠️ فشل بدء UDP Broadcast Service - قد يكون WiFi غير متصل',
        );
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
      if (!_isValidPeerId(deviceId)) {
        LogService.warning('رفض connectToPeer بسبب peerId غير صالح: "$deviceId"');
        return false;
      }
      _peerIdByIp[ip] = deviceId;
      final myDeviceId = await _getMyDeviceId();
      LogService.info('${_tag(deviceId)} 🔗 محاولة الاتصال بالجهاز @ $ip:$port');
      _setPeerState(deviceId, PeerSessionState.discovered, reason: 'udp discovered');

      // التحقق من أن الجهاز غير متصل بالفعل
      if (_connectedPeers.contains(deviceId)) {
        LogService.info('${_tag(deviceId)} الجهاز Peer_Ready بالفعل');
        return true;
      }

      // Role selection rule: smaller ID acts as server-preferred.
      final iAmServerPreferred = myDeviceId.compareTo(deviceId) < 0;
      if (iAmServerPreferred) {
        await _methodChannel.invokeMethod('startServer');
        _setPeerState(
          deviceId,
          PeerSessionState.discovered,
          reason: 'server-preferred, waiting inbound connect',
        );
        LogService.info(
          '${_tag(deviceId)} role=server (smaller ID), skip outbound connect',
        );
        unawaited(_attemptClientFallbackConnect(ip, port, deviceId));
        return false;
      }

      // الاتصال عبر Socket (سيتم تنفيذها في Native)
      _setPeerState(deviceId, PeerSessionState.connecting, reason: 'client role');
      final connected = await _methodChannel.invokeMethod<bool>(
        'connectToPeer',
        {'ip': ip, 'port': port, 'peerId': deviceId},
      );

      if (connected != true) {
        _setPeerState(deviceId, PeerSessionState.failed, reason: 'connect failed');
        LogService.warning('${_tag(deviceId)} فشل الاتصال بالجهاز');
        _lastTransportError = 'connect_failed:$deviceId@$ip:$port';
        return false;
      }
      _activeSocketPeerId = deviceId;
      _setPeerState(
        deviceId,
        PeerSessionState.socketConnected,
        reason: 'connectToPeer returned connected',
      );

      return await _sendHandshakeWithRetry(deviceId);
    } catch (e) {
      _setPeerState(deviceId, PeerSessionState.failed, reason: 'exception');
      LogService.error('${_tag(deviceId)} خطأ في الاتصال بالجهاز', e);
      _lastTransportError = 'connect_exception:$deviceId@$ip:$port:${e.toString()}';
      return false;
    }
  }

  Future<void> _attemptClientFallbackConnect(
    String ip,
    int port,
    String deviceId,
  ) async {
    final last = _lastFallbackAttemptAt[deviceId];
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 10)) {
      return;
    }
    _lastFallbackAttemptAt[deviceId] = DateTime.now();

    var delayMs = 1500;
    for (var attempt = 1; attempt <= 3; attempt++) {
      await Future.delayed(Duration(milliseconds: delayMs));

      if (_connectedPeers.contains(deviceId) || _isPeerReady(deviceId)) {
        return;
      }

      final connectedNow =
          await _methodChannel.invokeMethod<bool>('isSocketConnected') ?? false;
      final stillDisconnected = !connectedNow;
      if (!stillDisconnected) {
        return;
      }

      try {
        LogService.info(
          '${_tag(deviceId)} fallback outbound connect attempt $attempt/3',
        );
        _setPeerState(
          deviceId,
          PeerSessionState.connecting,
          reason: 'fallback client connect attempt $attempt',
        );
        final connected = await _methodChannel.invokeMethod<bool>(
          'connectToPeer',
          {'ip': ip, 'port': port, 'peerId': deviceId},
        );
        if (connected == true) {
          _activeSocketPeerId = deviceId;
          _setPeerState(
            deviceId,
            PeerSessionState.socketConnected,
            reason: 'fallback connect succeeded',
          );
          await _sendHandshakeWithRetry(deviceId);
          return;
        } else {
          _lastTransportError =
              'fallback_connect_failed:$deviceId@$ip:$port:attempt_$attempt';
          LogService.warning('${_tag(deviceId)} fallback connect failed');
        }
      } catch (e) {
        _lastTransportError =
            'fallback_connect_exception:$deviceId@$ip:$port:attempt_$attempt:${e.toString()}';
        LogService.error('${_tag(deviceId)} fallback connect exception', e);
      }

      delayMs *= 2;
    }
  }

  Future<bool> _sendHandshakeWithRetry(String peerId) async {
    if (_handshakeInProgress.contains(peerId)) {
      return false;
    }
    _handshakeInProgress.add(peerId);
    _handshakeProtocol ??= _ref.read(handshakeProtocolProvider);
    try {
      for (var attempt = 1; attempt <= 3; attempt++) {
        _handshakeAttempts++;
        _setPeerState(
          peerId,
          PeerSessionState.handshakeSent,
          reason: 'attempt $attempt',
        );

        final handshakeMessage = await _handshakeProtocol!.createHandshakeMessage();
        final sent = await _socketWrite(
          peerId: peerId,
          message: handshakeMessage,
          context: 'handshake',
          allowBeforeReady: true,
        );
        if (!sent) {
          LogService.warning(
            '${_tag(peerId)} handshake write failed on attempt $attempt',
          );
        } else {
          final waiter = Completer<bool>();
          _handshakeAckWaiters[peerId] = waiter;
          try {
            final acked = await waiter.future.timeout(const Duration(seconds: 5));
            if (acked) {
              _handshakeAcks++;
              LogService.info(
                '${_tag(peerId)} handshake completed on attempt $attempt',
              );
              return true;
            }
          } catch (_) {
            _handshakeTimeouts++;
            LogService.warning(
              '${_tag(peerId)} handshake ACK timeout (attempt $attempt)',
            );
          } finally {
            _handshakeAckWaiters.remove(peerId);
          }
        }

        if (attempt < 3) {
          final delayMs = 500 * (1 << (attempt - 1));
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }

      _setPeerState(peerId, PeerSessionState.failed, reason: 'handshake retries exhausted');
      return false;
    } finally {
      _handshakeInProgress.remove(peerId);
    }
  }

  /// إكمال Handshake (يتم استدعاؤه عند استقبال Handshake ACK)
  Future<void> _completeHandshake(String peerId, [BloomFilter? peerBF]) async {
    try {
      if (_connectedPeers.contains(peerId)) {
        // تحديث Bloom Filter حتى لو كنا متصلين بالفعل (قد يكون إعادة اتصال سريع)
        if (peerBF != null) {
          _peerBloomFilters[peerId] = peerBF;
        }
        return;
      }

      _connectedPeers.add(peerId);
      if (peerBF != null) {
        _peerBloomFilters[peerId] = peerBF;
      }

      _connectedPeersController.add(_connectedPeers.toList());
      _setPeerState(peerId, PeerSessionState.peerReady, reason: 'handshake complete');
      LogService.info('${_tag(peerId)} ✅ Handshake مكتمل');

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

  void updateDiscoveryInterval(int intervalSeconds) {
    _udpBroadcastService?.updateInterval(intervalSeconds);
    LogService.info('تم تحديث Discovery Interval إلى: ${intervalSeconds}s');
  }

  void dispose() {
    _socketStatusSubscription?.cancel();
    _connectedPeersController.close();
    _peerBloomFilters.clear();
  }
}

enum PeerSessionState {
  discovered,
  connecting,
  socketConnected,
  handshakeSent,
  handshakeAck,
  peerReady,
  failed,
}

/// Provider لـ MeshService
final meshServiceProvider = Provider<MeshService>((ref) {
  final service = MeshService(ref);
  ref.onDispose(service.dispose);
  return service;
});
