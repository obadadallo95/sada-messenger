import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../utils/log_service.dart';
import '../../services/auth_service.dart';
import '../../security/security_providers.dart';
import '../../database/database_provider.dart';
import '../../database/app_database.dart';

/// بروتوكول Handshake لتحديد هوية الأجهزة المتصلة
/// يضمن أننا نعرف من هو الجهاز المتصل قبل قبول الرسائل
class HandshakeProtocol {
  final Ref _ref;
  
  // ignore: constant_identifier_names
  static const String HANDSHAKE_TYPE = 'HANDSHAKE';
  // ignore: constant_identifier_names
  static const String HANDSHAKE_ACK_TYPE = 'HANDSHAKE_ACK';
  // ignore: constant_identifier_names
  static const String STATUS_ACCEPTED = 'ACCEPTED';
  // ignore: constant_identifier_names
  static const String STATUS_REJECTED = 'REJECTED';
  
  HandshakeProtocol(this._ref);

  /// إنشاء Handshake Message (Client Side)
  /// يتم إرسالها فوراً عند فتح الاتصال
  Future<String> createHandshakeMessage() async {
    try {
      final authService = _ref.read(authServiceProvider.notifier);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final keyManager = _ref.read(keyManagerProvider);
      final publicKeyBytes = await keyManager.getPublicKey();
      final publicKeyBase64 = base64Encode(publicKeyBytes);

      final handshake = {
        'type': HANDSHAKE_TYPE,
        'peerId': currentUser.userId,
        'publicKey': publicKeyBase64,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return jsonEncode(handshake);
    } catch (e) {
      LogService.error('خطأ في إنشاء Handshake Message', e);
      rethrow;
    }
  }

  /// معالجة Handshake Message الواردة (Server Side)
  /// التحقق من peerId والرد بـ Handshake ACK
  Future<String?> processIncomingHandshake(String handshakeJson) async {
    try {
      final handshake = jsonDecode(handshakeJson) as Map<String, dynamic>;
      
      if (handshake['type'] != HANDSHAKE_TYPE) {
        LogService.warning('رسالة Handshake غير صحيحة: ${handshake['type']}');
        return null;
      }

      final peerId = handshake['peerId'] as String?;
      final publicKey = handshake['publicKey'] as String?;
      
      if (peerId == null) {
        LogService.warning('Handshake بدون peerId');
        return null;
      }

      LogService.info('🤝 معالجة Handshake من: $peerId');

      // التحقق من أن المرسل هو جهة اتصال معروفة (Contact Whitelisting)
      final database = await _ref.read(appDatabaseProvider.future);
      final contact = await database.getContactById(peerId);
      
      if (contact == null) {
        LogService.warning('🚫 Handshake من مرسل غير معروف: $peerId');
        // رفض Handshake من غير جهات الاتصال
        return _createHandshakeAck(peerId, STATUS_REJECTED);
      }

      // تحديث publicKey إذا كان متاحاً
      if (publicKey != null && contact.publicKey != publicKey) {
        LogService.info('تحديث publicKey للجهة: $peerId');
        await database.updateContact(
          peerId,
          ContactsTableCompanion(publicKey: Value(publicKey)),
        );
      }

      // قبول Handshake
      LogService.info('✅ Handshake مقبول من: $peerId');
      return _createHandshakeAck(peerId, STATUS_ACCEPTED);
      
    } catch (e) {
      LogService.error('خطأ في معالجة Handshake', e);
      return null;
    }
  }

  /// معالجة Handshake ACK (Client Side)
  /// التحقق من أن Handshake تم قبوله
  Future<bool> processHandshakeAck(String ackJson) async {
    try {
      final ack = jsonDecode(ackJson) as Map<String, dynamic>;
      
      if (ack['type'] != HANDSHAKE_ACK_TYPE) {
        LogService.warning('Handshake ACK غير صحيح: ${ack['type']}');
        return false;
      }

      final peerId = ack['peerId'] as String?;
      final status = ack['status'] as String?;
      
      if (status == STATUS_ACCEPTED) {
        LogService.info('✅ Handshake ACK مقبول من: $peerId');
        return true;
      } else {
        LogService.warning('❌ Handshake ACK مرفوض من: $peerId');
        return false;
      }
    } catch (e) {
      LogService.error('خطأ في معالجة Handshake ACK', e);
      return false;
    }
  }

  /// إنشاء Handshake ACK Message
  String _createHandshakeAck(String peerId, String status) {
    final authService = _ref.read(authServiceProvider.notifier);
    final currentUser = authService.currentUser;
    final myPeerId = currentUser?.userId ?? 'unknown';

    final ack = {
      'type': HANDSHAKE_ACK_TYPE,
      'peerId': myPeerId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(ack);
  }
}

/// Provider لـ HandshakeProtocol
final handshakeProtocolProvider = Provider<HandshakeProtocol>((ref) {
  return HandshakeProtocol(ref);
});

