import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:sodium_libs/sodium_libs.dart' hide SodiumInit;
import 'package:sodium_libs/sodium_libs.dart' as sodium_libs show SodiumInit;
import '../../utils/log_service.dart';
import '../../utils/bloom_filter.dart';
import '../../services/auth_service.dart';
import '../../security/security_providers.dart';
import '../../database/database_provider.dart';
import '../../database/app_database.dart';

class HandshakeSession {
  final String? peerId;
  final String? peerPublicKey; // Base64
  final String? sentNonce; // My nonce (expecting signature)
  final String? receivedNonce; // Peer's nonce (I signed/will sign)
  final bool isInitiator;
  final bool isComplete;

  HandshakeSession({
    this.peerId,
    this.peerPublicKey,
    this.sentNonce,
    this.receivedNonce,
    required this.isInitiator,
    this.isComplete = false,
  });

  HandshakeSession copyWith({
    String? peerId,
    String? peerPublicKey,
    String? sentNonce,
    String? receivedNonce,
    bool? isComplete,
  }) {
    return HandshakeSession(
      peerId: peerId ?? this.peerId,
      peerPublicKey: peerPublicKey ?? this.peerPublicKey,
      sentNonce: sentNonce ?? this.sentNonce,
      receivedNonce: receivedNonce ?? this.receivedNonce,
      isInitiator: this.isInitiator,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class HandshakeResult {
  final String? messageToSend; // JSON payload to send (0x02 header added by service)
  final HandshakeSession session;
  final String? peerBloomFilter; // If received

  HandshakeResult({
    this.messageToSend,
    required this.session,
    this.peerBloomFilter,
  });
}

class HandshakeProtocol {
  final Ref _ref;
  Sodium? _sodium;
  
  static const String TYPE_INIT = 'HANDSHAKE_INIT';
  static const String TYPE_AUTH = 'HANDSHAKE_AUTH';
  static const String TYPE_FIN = 'HANDSHAKE_FIN';
  
  HandshakeProtocol(this._ref);

  Future<void> _ensureSodium() async {
    if (_sodium == null) {
      _sodium = await sodium_libs.SodiumInit.init();
    }
  }

  // Step 1: Initiator creates INIT message
  Future<HandshakeResult> createInit() async {
    await _ensureSodium();
    final authService = _ref.read(authServiceProvider.notifier);
    final keyManager = _ref.read(keyManagerProvider);

    final nonceBytes = _sodium!.randombytes.buf(32);
    final nonce = base64Encode(nonceBytes);

    final publicKey = await keyManager.getPublicKey();
    final myPeerId = authService.currentUser?.userId ?? 'unknown';

    final message = {
      'type': TYPE_INIT,
      'senderId': myPeerId,
      'publicKey': base64Encode(publicKey),
      'nonce': nonce,
    };

    final session = HandshakeSession(
      isInitiator: true,
      sentNonce: nonce,
    );

    return HandshakeResult(messageToSend: jsonEncode(message), session: session);
  }

  // Step 2: Receiver processes INIT, creates AUTH
  Future<HandshakeResult> processInit(String json, HandshakeSession? existingSession) async {
    await _ensureSodium();
    final data = jsonDecode(json);
    if (data['type'] != TYPE_INIT) throw Exception('Invalid handshake type: ${data['type']}');

    final peerId = data['senderId'];
    final peerNonce = data['nonce'];
    final peerPublicKeyBase64 = data['publicKey'];

    LogService.info('📥 Handshake INIT from $peerId');

    // Verify peer identity logic (Whitelisting or TOFU)
    await _verifyPeerIdentityCandidate(peerId, peerPublicKeyBase64);

    // Sign peer's nonce
    final keyManager = _ref.read(keyManagerProvider);
    final signature = await keyManager.sign(base64Decode(peerNonce));

    // Create my nonce
    final myNonceBytes = _sodium!.randombytes.buf(32);
    final myNonce = base64Encode(myNonceBytes);

    final publicKey = await keyManager.getPublicKey();
    final myPeerId = _ref.read(authServiceProvider.notifier).currentUser?.userId ?? 'unknown';

    // Create BloomFilter
    final bloomFilter = await _createBloomFilter();

    final message = {
      'type': TYPE_AUTH,
      'senderId': myPeerId,
      'publicKey': base64Encode(publicKey),
      'nonce': myNonce,
      'signature': base64Encode(signature),
      'bloomFilter': bloomFilter,
    };

    final session = HandshakeSession(
       isInitiator: false,
       peerId: peerId,
       peerPublicKey: peerPublicKeyBase64,
       receivedNonce: peerNonce,
       sentNonce: myNonce,
    );

    return HandshakeResult(
      messageToSend: jsonEncode(message),
      session: session,
      peerBloomFilter: null, // INIT doesn't have BF usually
    );
  }

  // Step 3: Initiator processes AUTH, creates FIN
  Future<HandshakeResult> processAuth(String json, HandshakeSession session) async {
    await _ensureSodium();
    final data = jsonDecode(json);
    if (data['type'] != TYPE_AUTH) throw Exception('Invalid handshake type: ${data['type']}');

    final peerId = data['senderId'];
    final peerNonce = data['nonce'];
    final peerSignature = data['signature'];
    final peerPublicKeyBase64 = data['publicKey'];

    LogService.info('📥 Handshake AUTH from $peerId');

    // Verify peer identity
    await _verifyPeerIdentityCandidate(peerId, peerPublicKeyBase64);

    // Verify signature of my nonce
    final keyManager = _ref.read(keyManagerProvider);
    final valid = await keyManager.verify(
       base64Decode(session.sentNonce!),
       base64Decode(peerSignature),
       base64Decode(peerPublicKeyBase64),
    );

    if (!valid) throw Exception('Handshake signature verification failed for $peerId');

    // Sign peer's nonce
    final signature = await keyManager.sign(base64Decode(peerNonce));

    final myPeerId = _ref.read(authServiceProvider.notifier).currentUser?.userId ?? 'unknown';
    final bloomFilter = await _createBloomFilter();

    final message = {
      'type': TYPE_FIN,
      'senderId': myPeerId,
      'signature': base64Encode(signature),
      'bloomFilter': bloomFilter,
    };

    final newSession = session.copyWith(
       peerId: peerId,
       peerPublicKey: peerPublicKeyBase64,
       receivedNonce: peerNonce,
       isComplete: true,
    );

    // Persist verified key
    await _persistPeerKey(peerId, peerPublicKeyBase64);

    return HandshakeResult(
      messageToSend: jsonEncode(message),
      session: newSession,
      peerBloomFilter: data['bloomFilter'],
    );
  }

  // Step 4: Receiver processes FIN
  Future<HandshakeResult> processFin(String json, HandshakeSession session) async {
    await _ensureSodium();
    final data = jsonDecode(json);
    if (data['type'] != TYPE_FIN) throw Exception('Invalid handshake type: ${data['type']}');

    final peerSignature = data['signature'];

    LogService.info('📥 Handshake FIN from ${session.peerId}');

    if (session.peerPublicKey == null) throw Exception('Peer public key missing in session');

    final keyManager = _ref.read(keyManagerProvider);
    final valid = await keyManager.verify(
       base64Decode(session.sentNonce!),
       base64Decode(peerSignature),
       base64Decode(session.peerPublicKey!),
    );

    if (!valid) throw Exception('Handshake signature verification failed for ${session.peerId}');

    final newSession = session.copyWith(isComplete: true);

    // Persist verified key
    await _persistPeerKey(session.peerId!, session.peerPublicKey!);

    return HandshakeResult(
      messageToSend: null, // Complete
      session: newSession,
      peerBloomFilter: data['bloomFilter'],
    );
  }

  Future<void> _verifyPeerIdentityCandidate(String peerId, String publicKeyBase64) async {
      final database = await _ref.read(appDatabaseProvider.future);
      final contact = await database.getContactById(peerId);
      
      if (contact != null && contact.publicKey != null && contact.publicKey != publicKeyBase64) {
         LogService.warning('🚨 Peer key mismatch! Possible spoofing. Stored: ${contact.publicKey}, Received: $publicKeyBase64');
         throw Exception('Peer Identity Spoofing Detected: Key Mismatch');
      }
  }

  Future<void> _persistPeerKey(String peerId, String publicKeyBase64) async {
      final database = await _ref.read(appDatabaseProvider.future);
      final contact = await database.getContactById(peerId);
      if (contact == null) {
          // New contact? Maybe don't insert automatically unless we want to.
          // For now we assume existing contacts or update existing.
          // If the prompt implies we should just authenticate, maybe we don't insert.
          // But Handshake usually implies connection with *someone*.
          LogService.info('Authenticated new peer: $peerId');
      } else if (contact.publicKey != publicKeyBase64) {
          LogService.info('Updating authenticated peer key: $peerId');
          await database.updateContact(
            peerId,
            ContactsTableCompanion(publicKey: Value(publicKeyBase64)),
          );
      }
  }
  
  Future<String> _createBloomFilter() async {
      final database = await _ref.read(appDatabaseProvider.future);
      final messageIds = await database.getAllKnownMessageIds();
      final bloomFilter = BloomFilter();
      for (final id in messageIds) {
        bloomFilter.add(id);
      }
      return bloomFilter.toBase64();
  }
}

final handshakeProtocolProvider = Provider<HandshakeProtocol>((ref) {
  return HandshakeProtocol(ref);
});
