import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sada/core/network/protocols/handshake_protocol.dart';
import 'package:sada/core/services/auth_service.dart';
import 'package:sada/core/security/key_manager.dart';
import 'package:sada/core/security/security_providers.dart';
import 'package:sada/core/database/app_database.dart';
import 'package:sada/core/database/database_provider.dart';
import 'package:sada/core/utils/bloom_filter.dart';
import 'dart:convert';
import 'dart:typed_data';

// Mocks
class MockAuthService extends Mock implements AuthService {}

class MockKeyManager extends Mock implements KeyManager {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockContactsTableData extends Mock implements ContactsTableData {}

void main() {
  late ProviderContainer container;
  late MockAuthService mockAuthService;
  late MockKeyManager mockKeyManager;
  late MockAppDatabase mockDatabase;

  setUp(() {
    mockAuthService = MockAuthService();
    mockKeyManager = MockKeyManager();
    mockDatabase = MockAppDatabase();

    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWith((ref) => mockAuthService),
        keyManagerProvider.overrideWith((ref) => mockKeyManager),
        appDatabaseProvider.overrideWith((ref) => Future.value(mockDatabase)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('HandshakeProtocol Tests', () {
    test(
      'createHandshakeMessage should generate valid JSON with Bloom Filter',
      () async {
        // Arrange
        when(() => mockAuthService.currentUser).thenReturn(
          UserData(
            userId: 'user123',
            displayName: 'user',
            deviceHash: 'hash123',
          ),
        );
        when(
          () => mockKeyManager.getPublicKey(),
        ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4]));
        when(
          () => mockDatabase.getAllKnownMessageIds(),
        ).thenAnswer((_) async => ['msg1', 'msg2']);

        final protocol = container.read(handshakeProtocolProvider);

        // Act
        final handshakeJson = await protocol.createHandshakeMessage();
        final handshake = jsonDecode(handshakeJson) as Map<String, dynamic>;

        // Assert
        expect(handshake['type'], equals('HANDSHAKE'));
        expect(handshake['peerId'], equals('user123'));
        expect(handshake['publicKey'], isNotNull);
        expect(handshake['bloomFilter'], isNotNull);
        expect(handshake['timestamp'], isNotNull);

        // Verify Bloom Filter can be decoded
        final bf = BloomFilter.fromBase64(handshake['bloomFilter'] as String);
        expect(bf.contains('msg1'), isTrue);
        expect(bf.contains('msg2'), isTrue);
      },
    );

    test('processIncomingHandshake should accept known contact', () async {
      // Arrange
      final contact = MockContactsTableData();
      when(() => contact.publicKey).thenReturn('oldKey');
      when(
        () => mockDatabase.getContactById('peer123'),
      ).thenAnswer((_) async => contact);
      when(
        () => mockDatabase.updateContact(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockAuthService.currentUser).thenReturn(
        UserData(userId: 'user123', displayName: 'user', deviceHash: 'hash123'),
      );
      when(
        () => mockDatabase.getAllKnownMessageIds(),
      ).thenAnswer((_) async => ['msg1']);

      final protocol = container.read(handshakeProtocolProvider);

      final bf = BloomFilter();
      bf.add('peerMsg1');
      final handshakeJson = jsonEncode({
        'type': 'HANDSHAKE',
        'peerId': 'peer123',
        'publicKey': 'newKey',
        'bloomFilter': bf.toBase64(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Act
      final result = await protocol.processIncomingHandshake(handshakeJson);

      // Assert
      expect(result, isNotNull);
      expect(result!.ackMessage, isNotNull);
      expect(result.peerBloomFilter, isNotNull);
      expect(result.peerBloomFilter!.contains('peerMsg1'), isTrue);

      final ack = jsonDecode(result.ackMessage) as Map<String, dynamic>;
      expect(ack['status'], equals('ACCEPTED'));
    });

    test('processIncomingHandshake should reject unknown contact', () async {
      // Arrange
      when(
        () => mockDatabase.getContactById('unknown123'),
      ).thenAnswer((_) async => null);
      when(() => mockAuthService.currentUser).thenReturn(
        UserData(userId: 'user123', displayName: 'user', deviceHash: 'hash123'),
      );

      final protocol = container.read(handshakeProtocolProvider);

      final handshakeJson = jsonEncode({
        'type': 'HANDSHAKE',
        'peerId': 'unknown123',
        'publicKey': 'someKey',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Act
      final result = await protocol.processIncomingHandshake(handshakeJson);

      // Assert
      expect(result, isNotNull);
      expect(result!.peerBloomFilter, isNull);

      final ack = jsonDecode(result.ackMessage) as Map<String, dynamic>;
      expect(ack['status'], equals('REJECTED'));
    });

    test(
      'processHandshakeAck should parse accepted ACK with Bloom Filter',
      () async {
        // Arrange
        final protocol = container.read(handshakeProtocolProvider);

        final bf = BloomFilter();
        bf.add('ackMsg1');
        final ackJson = jsonEncode({
          'type': 'HANDSHAKE_ACK',
          'peerId': 'peer123',
          'status': 'ACCEPTED',
          'bloomFilter': bf.toBase64(),
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Act
        final result = await protocol.processHandshakeAck(ackJson);

        // Assert
        expect(result.isAccepted, isTrue);
        expect(result.peerBloomFilter, isNotNull);
        expect(result.peerBloomFilter!.contains('ackMsg1'), isTrue);
      },
    );

    test('processHandshakeAck should parse rejected ACK', () async {
      // Arrange
      final protocol = container.read(handshakeProtocolProvider);

      final ackJson = jsonEncode({
        'type': 'HANDSHAKE_ACK',
        'peerId': 'peer123',
        'status': 'REJECTED',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Act
      final result = await protocol.processHandshakeAck(ackJson);

      // Assert
      expect(result.isAccepted, isFalse);
      expect(result.peerBloomFilter, isNull);
    });

    test(
      'processIncomingHandshake should handle missing Bloom Filter gracefully',
      () async {
        // Arrange
        final contact = MockContactsTableData();
        when(() => contact.publicKey).thenReturn('key');
        when(
          () => mockDatabase.getContactById('peer123'),
        ).thenAnswer((_) async => contact);
        when(() => mockAuthService.currentUser).thenReturn(
          UserData(
            userId: 'user123',
            displayName: 'user',
            deviceHash: 'hash123',
          ),
        );
        when(
          () => mockDatabase.getAllKnownMessageIds(),
        ).thenAnswer((_) async => []);

        final protocol = container.read(handshakeProtocolProvider);

        final handshakeJson = jsonEncode({
          'type': 'HANDSHAKE',
          'peerId': 'peer123',
          'publicKey': 'key',
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Act
        final result = await protocol.processIncomingHandshake(handshakeJson);

        // Assert
        expect(result, isNotNull);
        expect(result!.peerBloomFilter, isNull); // No BF provided
        final ack = jsonDecode(result.ackMessage) as Map<String, dynamic>;
        expect(ack['status'], equals('ACCEPTED'));
      },
    );
  });
}
