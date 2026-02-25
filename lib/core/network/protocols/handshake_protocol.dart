import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../utils/log_service.dart';
import '../../utils/bloom_filter.dart';
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

      // إنشاء Bloom Filter للمزامنة (P1-SYNC)
      final database = await _ref.read(appDatabaseProvider.future);
      final messageIds = await database.getAllKnownMessageIds();
      final bloomFilter = BloomFilter();
      for (final id in messageIds) {
        bloomFilter.add(id);
      }

      final handshake = {
        'type': HANDSHAKE_TYPE,
        'peerId': currentUser.userId,
        'publicKey': publicKeyBase64,
        'bloomFilter': bloomFilter.toBase64(),
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
  Future<HandshakeResult?> processIncomingHandshake(String handshakeJson) async {
    try {
      final handshake = jsonDecode(handshakeJson) as Map<String, dynamic>;
      
      if (handshake['type'] != HANDSHAKE_TYPE) {
        LogService.warning('رسالة Handshake غير صحيحة: ${handshake['type']}');
        return null; // Ignore invalid type
      }

      final peerId = handshake['peerId'] as String?;
      final publicKey = handshake['publicKey'] as String?;
      final bloomFilterBase64 = handshake['bloomFilter'] as String?;
      
      if (peerId == null) {
        LogService.warning('Handshake بدون peerId');
        return null;
      }

      LogService.info('🤝 معالجة Handshake من: $peerId');

      // التحقق من أن المرسل هو جهة اتصال معروفة (Contact Whitelisting)
      final database = await _ref.read(appDatabaseProvider.future);
      final contact = await database.getContactById(peerId);
      
      if (contact == null) {
        // [Relay Requirement]: Allow unknown peers to connect for relay purposes.
        LogService.info('⚠️ قبول Handshake من جهة غير معروفة (لغرض Relay): $peerId');
      } else {
        // تحديث publicKey إذا كان متاحاً لجهة اتصال معروفة
        if (publicKey != null && contact.publicKey != publicKey) {
          LogService.info('تحديث publicKey للجهة: $peerId');
          await database.updateContact(
            peerId,
            ContactsTableCompanion(publicKey: Value(publicKey)),
          );
        }
      }

      // Parse Bloom Filter
      BloomFilter? peerBF;
      if (bloomFilterBase64 != null) {
        try {
          peerBF = BloomFilter.fromBase64(bloomFilterBase64);
          LogService.info('✅ تم استلام Bloom Filter من $peerId');
        } catch (e) {
          LogService.warning('فشل تحليل Bloom Filter من $peerId: $e');
        }
      }

      // قبول Handshake
      LogService.info('✅ Handshake مقبول من: $peerId');
      final ack = await _createHandshakeAck(peerId, STATUS_ACCEPTED);
      return HandshakeResult(ackMessage: ack, peerBloomFilter: peerBF);
      
    } catch (e) {
      LogService.error('خطأ في معالجة Handshake', e);
      return null;
    }
  }

  /// معالجة Handshake ACK (Client Side)
  /// التحقق من أن Handshake تم قبوله
  Future<HandshakeAckResult> processHandshakeAck(String ackJson) async {
    try {
      final ack = jsonDecode(ackJson) as Map<String, dynamic>;
      
      if (ack['type'] != HANDSHAKE_ACK_TYPE) {
        LogService.warning('Handshake ACK غير صحيح: ${ack['type']}');
        return HandshakeAckResult(isAccepted: false);
      }

      final peerId = ack['peerId'] as String?;
      final status = ack['status'] as String?;
      final bloomFilterBase64 = ack['bloomFilter'] as String?;
      
      if (status == STATUS_ACCEPTED) {
        LogService.info('✅ Handshake ACK مقبول من: $peerId');
        
        BloomFilter? peerBF;
        if (bloomFilterBase64 != null) {
           try {
             peerBF = BloomFilter.fromBase64(bloomFilterBase64);
             LogService.info('✅ تم استلام Bloom Filter (في ACK) من $peerId');
           } catch (e) {
             LogService.warning('فشل تحليل Bloom Filter (في ACK) من $peerId: $e');
           }
        }
        
        return HandshakeAckResult(isAccepted: true, peerBloomFilter: peerBF);
      } else {
        LogService.warning('❌ Handshake ACK مرفوض من: $peerId');
        return HandshakeAckResult(isAccepted: false);
      }
    } catch (e) {
      LogService.error('خطأ في معالجة Handshake ACK', e);
      return HandshakeAckResult(isAccepted: false);
    }
  }

  /// إنشاء Handshake ACK Message
  Future<String> _createHandshakeAck(String peerId, String status) async {
    final authService = _ref.read(authServiceProvider.notifier);
    final currentUser = authService.currentUser;
    final myPeerId = currentUser?.userId ?? 'unknown';

    // إضافة Bloom Filter الخاص بي في الرد أيضاً (لتحقيق التزامن ثنائي الاتجاه)
    String? myBfBase64;
    if (status == STATUS_ACCEPTED) {
       final database = await _ref.read(appDatabaseProvider.future);
       final messageIds = await database.getAllKnownMessageIds();
       final bloomFilter = BloomFilter();
       for (final id in messageIds) {
         bloomFilter.add(id);
       }
       myBfBase64 = bloomFilter.toBase64();
    }

    final ack = {
      'type': HANDSHAKE_ACK_TYPE,
      'peerId': myPeerId,
      'status': status,
      'bloomFilter': myBfBase64,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(ack);
  }
}

class HandshakeResult {
  final String ackMessage;
  final BloomFilter? peerBloomFilter;
  
  HandshakeResult({required this.ackMessage, this.peerBloomFilter});
}

class HandshakeAckResult {
  final bool isAccepted;
  final BloomFilter? peerBloomFilter;

  HandshakeAckResult({required this.isAccepted, this.peerBloomFilter});
}

/// Provider لـ HandshakeProtocol
final handshakeProtocolProvider = Provider<HandshakeProtocol>((ref) {
  return HandshakeProtocol(ref);
});

