import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/log_service.dart';
import 'mesh_channel.dart';
import 'mesh_service.dart';

/// مدير الاتصالات Mesh
/// يتعامل مع اتصالات الأجهزة الجديدة ويستدعي flushRelayQueue
class MeshConnectionManager {
  final Ref _ref;
  StreamSubscription<ConnectionInfo>? _connectionSubscription;
  String? _lastConnectedPeerId;

  MeshConnectionManager(this._ref) {
    _startListening();
  }

  void _startListening() {
    final meshChannel = MeshChannel();
    
    _connectionSubscription?.cancel();
    _connectionSubscription = meshChannel.onConnectionInfo.listen(
      (connectionInfo) async {
        await _handleConnectionChange(connectionInfo);
      },
      onError: (error) {
        LogService.error('خطأ في استقبال تحديثات الاتصال', error);
      },
    );
  }

  Future<void> _handleConnectionChange(ConnectionInfo connectionInfo) async {
    try {
      if (connectionInfo.isConnected && connectionInfo.groupFormed) {
        LogService.info('🔗 اتصال جديد تم إنشاؤه');
        LogService.info('   - Group Owner: ${connectionInfo.isGroupOwner}');
        LogService.info('   - Group Owner Address: ${connectionInfo.groupOwnerAddress}');
        
        // الحصول على معرف الجهاز المتصل
        // في الوقت الحالي، نستخدم groupOwnerAddress كمعرف مؤقت
        // في المستقبل، يمكن الحصول على معرف الجهاز من خلال handshake
        final peerId = connectionInfo.groupOwnerAddress ?? 'unknown';
        
        // إذا كان هذا جهاز جديد (لم يكن متصل من قبل)
        if (peerId != _lastConnectedPeerId) {
          LogService.info('📤 جهاز جديد متصل - إرسال RelayQueue...');
          
          final meshService = _ref.read(meshServiceProvider);
          await meshService.flushRelayQueue(peerId);
          
          _lastConnectedPeerId = peerId;
        }
      } else {
        LogService.info('🔌 تم قطع الاتصال');
        _lastConnectedPeerId = null;
      }
    } catch (e) {
      LogService.error('خطأ في معالجة تغيير الاتصال', e);
    }
  }

  void dispose() {
    _connectionSubscription?.cancel();
  }
}

/// Provider لـ MeshConnectionManager
final meshConnectionManagerProvider = Provider<MeshConnectionManager>((ref) {
  final manager = MeshConnectionManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});

