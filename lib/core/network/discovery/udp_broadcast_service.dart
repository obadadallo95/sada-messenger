import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/log_service.dart';
import '../../services/auth_service.dart';
import '../mesh_service.dart';

/// خدمة UDP Broadcast لاكتشاف الأجهزة على نفس WiFi LAN
/// تعمل كـ "Router Bridge" - تكتشف الأجهزة حتى بدون إنترنت
/// 
/// ملاحظة: UDP Sockets في Flutter تحتاج Platform Channels
/// سيتم تنفيذها في Native (Android/iOS) لاحقاً
class UdpBroadcastService {
  // ignore: constant_identifier_names
  static const int DISCOVERY_PORT = 45454;
  // ignore: constant_identifier_names
  static const String DISCOVERY_PREFIX = 'SADA_DISCOVERY';
  // ignore: constant_identifier_names
  static const String DISCOVERY_VERSION = 'v1';
  
  static const MethodChannel _udpChannel = MethodChannel('org.sada.messenger/udp');
  static const EventChannel _udpEventChannel = EventChannel('org.sada.messenger/udpEvents');
  
  final Ref _ref;
  StreamSubscription<dynamic>? _udpSubscription;
  Timer? _broadcastTimer;
  bool _isRunning = false;
  String? _myDeviceId;
  final int _tcpPort = 8888; // Port للاتصال TCP (SocketManager)
  
  UdpBroadcastService(this._ref);

  /// بدء خدمة UDP Broadcast
  /// [intervalSeconds]: الفترة بين كل broadcast (سيتم التحكم بها من DiscoveryStrategy)
  Future<bool> start({int intervalSeconds = 60}) async {
    if (_isRunning) {
      LogService.warning('UDP Broadcast Service يعمل بالفعل');
      return true;
    }

    try {
      // التحقق من حالة WiFi
      if (!await _isWifiConnected()) {
        LogService.warning('WiFi غير متصل - لا يمكن بدء UDP Broadcast');
        return false;
      }

      // الحصول على معرف الجهاز
      _myDeviceId = await _getMyDeviceId();
      
      // بدء UDP Service عبر Platform Channel
      final started = await _udpChannel.invokeMethod<bool>(
        'startUdpService',
        {'port': DISCOVERY_PORT},
      );
      
      if (started != true) {
        LogService.warning('فشل بدء UDP Service');
        return false;
      }
      
      LogService.info('✅ تم بدء UDP Broadcast Service على Port $DISCOVERY_PORT');
      
      // بدء الاستماع للبث الوارد
      _startListening();
      
      // بدء البث الدوري
      _startBroadcasting(intervalSeconds);
      
      _isRunning = true;
      return true;
    } catch (e) {
      LogService.error('خطأ في بدء UDP Broadcast Service', e);
      await stop();
      return false;
    }
  }

  /// إيقاف خدمة UDP Broadcast
  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;
    _broadcastTimer?.cancel();
    _udpSubscription?.cancel();
    
    await _udpChannel.invokeMethod('stopUdpService');
    
    LogService.info('تم إيقاف UDP Broadcast Service');
  }

  /// تحديث فترة البث (للاستجابة لتغييرات Battery Mode)
  void updateInterval(int intervalSeconds) {
    if (!_isRunning) return;
    
    _broadcastTimer?.cancel();
    _startBroadcasting(intervalSeconds);
    
    LogService.info('تم تحديث فترة UDP Broadcast إلى $intervalSeconds ثانية');
  }

  /// بدء البث الدوري
  void _startBroadcasting(int intervalSeconds) {
    _broadcastTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      try {
        await _sendBroadcast();
      } catch (e) {
        LogService.error('خطأ في إرسال UDP Broadcast', e);
      }
    });
    
    // إرسال broadcast فوري عند البدء
    _sendBroadcast();
  }

  /// إرسال UDP Broadcast
  Future<void> _sendBroadcast() async {
    try {
      _myDeviceId ??= await _getMyDeviceId();

      // إنشاء payload: SADA_DISCOVERY|v1|DeviceId|Port
      final payload = '$DISCOVERY_PREFIX|$DISCOVERY_VERSION|$_myDeviceId|$_tcpPort';
      
      // إرسال عبر Platform Channel
      await _udpChannel.invokeMethod('sendBroadcast', {
        'payload': payload,
        'port': DISCOVERY_PORT,
      });
      
      LogService.info('📡 تم إرسال UDP Broadcast: ${payload.substring(0, 50)}...');
    } catch (e) {
      LogService.error('خطأ في إرسال UDP Broadcast', e);
    }
  }

  /// بدء الاستماع للبث الوارد
  void _startListening() {
    _udpSubscription = _udpEventChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        try {
          if (event is Map) {
            final payload = event['payload'] as String?;
            final peerIp = event['ip'] as String?;
            
            if (payload != null && peerIp != null) {
              await _handleIncomingBroadcast(payload, peerIp);
            }
          }
        } catch (e) {
          LogService.error('خطأ في معالجة UDP Broadcast الوارد', e);
        }
      },
      onError: (error) {
        LogService.error('خطأ في استقبال UDP Broadcast', error);
      },
    );
    
    LogService.info('👂 بدء الاستماع لـ UDP Broadcast على Port $DISCOVERY_PORT');
  }

  /// معالجة UDP Broadcast الوارد
  Future<void> _handleIncomingBroadcast(String payload, String peerIp) async {
    try {
      // التحقق من أن payload ليس فارغاً
      if (payload.isEmpty) {
        LogService.warning('UDP Broadcast فارغ');
        return;
      }
      
      final parts = payload.split('|');
      
      if (parts.length < 4) {
        LogService.warning('UDP Broadcast غير صحيح (أجزاء غير كافية): $payload');
        return;
      }
      
      final prefix = parts[0];
      final version = parts[1];
      final peerDeviceId = parts[2];
      final peerPort = int.tryParse(parts[3]) ?? 8888;
      
      if (prefix != DISCOVERY_PREFIX) {
        LogService.warning('UDP Broadcast غير معروف: $prefix');
        return;
      }

      // تجاهل البث من نفس الجهاز
      if (peerDeviceId == _myDeviceId) {
        LogService.info('تجاهل UDP Broadcast من نفس الجهاز: $peerDeviceId');
        return;
      }
      
      // التحقق من أن peerDeviceId ليس فارغاً
      if (peerDeviceId.isEmpty) {
        LogService.warning('UDP Broadcast بدون DeviceId');
        return;
      }
      
      LogService.info('📨 استقبال UDP Broadcast من: $peerDeviceId @ $peerIp:$peerPort (v$version)');
      
      // الاتصال بالجهاز المكتشف
      await _connectToDiscoveredPeer(peerIp, peerPort, peerDeviceId);
      
    } catch (e) {
      LogService.error('خطأ في معالجة UDP Broadcast', e);
    }
  }

  /// الاتصال بالجهاز المكتشف
  Future<void> _connectToDiscoveredPeer(String ip, int port, String deviceId) async {
    try {
      final meshService = _ref.read(meshServiceProvider);
      
      LogService.info('🔗 محاولة الاتصال بالجهاز المكتشف: $deviceId @ $ip:$port');
      
      // استدعاء MeshService للاتصال
      // سيتم تنفيذ Handshake Protocol في MeshService
      await meshService.connectToPeer(ip, port, deviceId);
      
    } catch (e) {
      LogService.error('خطأ في الاتصال بالجهاز المكتشف', e);
    }
  }

  /// الحصول على معرف الجهاز الحالي
  Future<String> _getMyDeviceId() async {
    final authService = _ref.read(authServiceProvider.notifier);
    final currentUser = authService.currentUser;
    return currentUser?.userId ?? 'unknown';
  }

  /// التحقق من اتصال WiFi
  Future<bool> _isWifiConnected() async {
    try {
      // التحقق عبر Platform Channel
      final isConnected = await _udpChannel.invokeMethod<bool>('isWifiConnected');
      return isConnected ?? true; // افتراض أن WiFi متصل
    } catch (e) {
      // حتى لو لم يكن هناك إنترنت، قد يكون WiFi متصل
      return true; // افتراض أن WiFi متصل
    }
  }

  /// تنظيف الموارد
  void dispose() {
    stop();
  }
}

/// Provider لـ UdpBroadcastService
final udpBroadcastServiceProvider = Provider<UdpBroadcastService>((ref) {
  final service = UdpBroadcastService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

