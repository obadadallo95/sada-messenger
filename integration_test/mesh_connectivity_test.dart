// integration_test/mesh_connectivity_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sada/core/database/app_database.dart';
import 'package:sada/core/database/database_provider.dart';
import 'package:sada/core/network/mesh_service.dart';
import 'package:sada/core/security/key_manager.dart';
import 'package:sada/core/security/security_providers.dart';
import 'package:sada/core/services/auth_service.dart';
import 'package:sada/core/utils/log_service.dart';

// Mock Classes
class MockAuthService extends AuthService {
  @override
  UserData? get currentUser => UserData(
        userId: 'test_device_a',
        displayName: 'Device A',
        deviceHash: 'hash_a',
        publicKey: 'pub_key_a',
      );

  @override
  bool get isLoggedIn => true;
}

class MockKeyManager extends KeyManager {
  @override
  Future<Uint8List> getPublicKey() async {
    return utf8.encode('pub_key_a');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Mesh Connectivity & Handshake Integration Test', (tester) async {
    LogService.info('🚀 Starting Mesh Connectivity Test...');

    // 1. Setup Test Server (Device B)
    // Listen on loopback (127.0.0.1) which is accessible from within the emulator/device if we connect to it.
    final serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = serverSocket.port;
    LogService.info('📡 Test Server (Device B) listening on port $port');

    // 2. Setup Provider Container with Overrides
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWith((ref) => MockAuthService()),
        keyManagerProvider.overrideWith((ref) => MockKeyManager()),
        appDatabaseProvider.overrideWith((ref) => AppDatabase.forTesting(NativeDatabase.memory())),
      ],
    );

    // Initialize Database with a contact for Device B (so handshake is accepted)
    // We assume Device A knows Device B (Contact Whitelisting)
    final db = await container.read(appDatabaseProvider.future);
    await db.insertContact(ContactsTableCompanion(
      id: drift.Value('device_b'),
      name: drift.Value('Device B'),
      publicKey: drift.Value('pub_key_b'),
      isBlocked: drift.Value(false),
    ));

    final meshService = container.read(meshServiceProvider);

    // Initialize Transport Layer (Starts Native Server, etc.)
    await meshService.initializeTransportLayer();

    // 3. Connect Device A to Device B
    LogService.info('🔗 Connecting Device A to Device B (127.0.0.1:$port)...');

    // We need to listen for connection on ServerSocket
    final connectionCompleter = Completer<Socket>();
    serverSocket.listen((socket) {
      LogService.info('✅ Device B received connection from ${socket.remoteAddress.address}:${socket.remotePort}');
      connectionCompleter.complete(socket);
    });

    // NOTE: On Android Emulator, 127.0.0.1 is the emulator itself.
    // Since the test code runs inside the app process on the emulator, and ServerSocket is bound there,
    // the Native code connecting to 127.0.0.1 should hit it.
    final connectResult = await meshService.connectToPeer('127.0.0.1', port, 'device_b');
    expect(connectResult, true, reason: 'connectToPeer should return true (connection initiated)');

    final deviceBSocket = await connectionCompleter.future;

    // 4. Handshake Verification
    LogService.info('🤝 Verifying Handshake...');

    // Device A should send Handshake Message immediately after connection

    // Helper to read framed messages (4-byte Big Endian length prefix)
    Stream<List<int>> framedStream(Socket socket) async* {
      final buffer = <int>[];
      await for (final chunk in socket) {
        buffer.addAll(chunk);
        while (buffer.length >= 4) {
          final length = ByteData.sublistView(Uint8List.fromList(buffer.take(4).toList())).getUint32(0, Endian.big);
          if (buffer.length >= 4 + length) {
             final frame = buffer.sublist(4, 4 + length);
             buffer.removeRange(0, 4 + length);
             yield frame;
          } else {
            break;
          }
        }
      }
    }

    final socketStream = framedStream(deviceBSocket);
    final iterator = StreamQueue(socketStream);

    // Read First Message (Handshake)
    LogService.info('⏳ Waiting for Handshake message...');
    final frame1 = await iterator.next.timeout(const Duration(seconds: 5), onTimeout: () {
      throw TimeoutException('Timed out waiting for Handshake message');
    });

    expect(frame1[0], 0x00, reason: 'First byte should be 0x00 (Text/JSON)');
    final jsonStr = utf8.decode(frame1.sublist(1));
    LogService.info('📩 Received: $jsonStr');
    final handshakeMsg = jsonDecode(jsonStr);

    expect(handshakeMsg['type'], 'HANDSHAKE');
    expect(handshakeMsg['peerId'], 'test_device_a');
    LogService.info('✅ Received Handshake from Device A');

    // NEGATIVE TEST: Try sending message BEFORE Handshake ACK (should fail/block)
    LogService.info('⛔ Testing Message Block Before Handshake...');
    final prematureMsg = base64Encode(utf8.encode('Premature Message'));
    final sentPremature = await meshService.sendMessage('device_b', prematureMsg);
    expect(sentPremature, false, reason: 'Message should be blocked before Handshake completion');
    LogService.info('✅ Premature message blocked successfully');

    // Send Handshake ACK from Device B
    final ackMsg = {
      'type': 'HANDSHAKE_ACK',
      'peerId': 'device_b',
      'status': 'ACCEPTED',
      'timestamp': DateTime.now().toIso8601String(),
    };
    final ackJson = jsonEncode(ackMsg);
    final ackBytes = utf8.encode(ackJson);
    final ackFrame = Uint8List(4 + 1 + ackBytes.length);
    ByteData.view(ackFrame.buffer).setUint32(0, 1 + ackBytes.length, Endian.big);
    ackFrame[4] = 0x00;
    ackFrame.setRange(5, ackFrame.length, ackBytes);

    deviceBSocket.add(ackFrame);
    await deviceBSocket.flush();
    LogService.info('📤 Sent Handshake ACK from Device B');

    // Wait for MeshService to process ACK and set state to peerReady
    // We can poll connectedPeers
    bool isConnected = false;
    for (int i=0; i<20; i++) {
      if (meshService.isPeerConnected('device_b')) {
        isConnected = true;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    expect(isConnected, true, reason: 'Device A should consider Device B connected after ACK');
    LogService.info('✅ Handshake Complete! Device A is ready.');

    // 5. Message Flow Verification
    LogService.info('📨 Testing Message Flow...');

    // Send Text Message from Device A
    final msgContent = base64Encode(utf8.encode('Hello World'));
    await meshService.sendMessage('device_b', msgContent);

    // Verify receipt at Device B
    LogService.info('⏳ Waiting for Text message...');
    final frame2 = await iterator.next;
    expect(frame2[0], 0x00, reason: 'Should be Text frame');
    final msgJsonStr = utf8.decode(frame2.sublist(1));
    LogService.info('📩 Received: $msgJsonStr');
    final msgJson = jsonDecode(msgJsonStr);
    // Usually sendMessage sends a JSON with senderId, peerId, content
    expect(msgJson['peerId'], 'device_b');
    expect(msgJson['content'], msgContent);
    LogService.info('✅ Device B received Text Message');

    // Send Binary Message (Voice chunk)
    final voiceData = Uint8List.fromList([1, 2, 3, 4, 5]);
    await meshService.socketWriteBytes(
      peerId: 'device_b',
      bytes: voiceData,
      context: 'test_voice',
    );

    // Verify receipt at Device B
    LogService.info('⏳ Waiting for Binary message...');
    final frame3 = await iterator.next;
    expect(frame3[0], 0x01, reason: 'Should be Binary frame (0x01)');
    expect(frame3.sublist(1), voiceData);
    LogService.info('✅ Device B received Binary/Voice Message');

    // 6. Negative Testing: Handshake Failure (Unknown Peer)
    LogService.info('⛔ Testing Handshake Failure (Unknown Peer)...');
    try {
      // Connect to the App's server (port 8888) as an unknown peer
      final unknownPeerSocket = await Socket.connect('127.0.0.1', 8888);

      // Send Handshake from 'unknown_peer'
      final unknownHandshake = {
        'type': 'HANDSHAKE',
        'peerId': 'unknown_peer',
        'publicKey': base64Encode(utf8.encode('pub_key_unknown')),
        'timestamp': DateTime.now().toIso8601String(),
      };
      final unknownJson = jsonEncode(unknownHandshake);
      final unknownBytes = utf8.encode(unknownJson);
      final unknownFrame = Uint8List(4 + 1 + unknownBytes.length);
      ByteData.view(unknownFrame.buffer).setUint32(0, 1 + unknownBytes.length, Endian.big);
      unknownFrame[4] = 0x00; // Text header
      unknownFrame.setRange(5, unknownFrame.length, unknownBytes);

      unknownPeerSocket.add(unknownFrame);
      await unknownPeerSocket.flush();

      // Verify REJECTED ACK
      // We reuse framedStream helper logic but need to pass the socket
      final unknownStream = framedStream(unknownPeerSocket);
      final unknownIter = StreamQueue(unknownStream);

      LogService.info('⏳ Waiting for REJECTED ACK...');
      final unknownAckFrame = await unknownIter.next.timeout(const Duration(seconds: 5));
      final unknownAckJson = jsonDecode(utf8.decode(unknownAckFrame.sublist(1)));

      expect(unknownAckJson['type'], 'HANDSHAKE_ACK');
      expect(unknownAckJson['status'], 'REJECTED');
      LogService.info('✅ Handshake Rejected as expected');

      await unknownPeerSocket.close();
    } catch (e) {
      LogService.error('❌ Failed Negative Test: $e');
      rethrow;
    }

    // 7. Cleanup
    LogService.info('🧹 Cleaning up...');

    // Close sockets
    await deviceBSocket.close();
    await serverSocket.close();
    await meshService.closeSocket();

    // Diagnostic Log
    final diagnostics = await meshService.getTransportDiagnostics();
    LogService.info('📊 Diagnostics: $diagnostics');

    LogService.info('🎉 Integration Test Passed!');
  });
}
