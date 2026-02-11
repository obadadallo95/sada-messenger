
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:sada/core/network/incoming_message_handler.dart';
import 'package:sada/core/network/mesh_service.dart';
import 'package:sada/core/network/models/mesh_message.dart';
import 'package:sada/core/database/app_database.dart';
import 'package:sada/core/database/database_provider.dart';
import 'package:sada/core/security/security_providers.dart';
import 'package:sada/core/security/encryption_service.dart';
import 'package:sada/core/services/auth_service.dart';


// Define Mocks
class MockMeshService extends Mock implements MeshService {}
class MockAppDatabase extends Mock implements AppDatabase {}
class MockEncryptionService extends Mock implements EncryptionService {}
class MockAuthService extends Mock implements AuthService {}
class FakeMessagesTableCompanion extends Fake implements MessagesTableCompanion {}
class FakeRelayQueueTableCompanion extends Fake implements RelayQueueTableCompanion {}

void main() {
  late MockMeshService mockMeshService;
  late MockAppDatabase mockDatabase;
  late MockEncryptionService mockEncryptionService;
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeMessagesTableCompanion());
    registerFallbackValue(FakeRelayQueueTableCompanion());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(MeshMessage(
      messageId: 'fallback',
      originalSenderId: 'fallback',
      finalDestinationId: 'fallback',
      encryptedContent: 'fallback',
      hopCount: 0,
      timestamp: DateTime.now(),
    ));
  });

  setUp(() {
    mockMeshService = MockMeshService();
    mockDatabase = MockAppDatabase();
    mockEncryptionService = MockEncryptionService();
    mockAuthService = MockAuthService();

    // Setup Auth Mock
    when(() => mockAuthService.currentUser).thenReturn(
      UserData(userId: 'me', displayName: 'Me', deviceHash: 'hash'),
    );

    // Setup Database Mock
    when(() => mockDatabase.getContactById(any())).thenAnswer((_) async => 
        ContactsTableData(id: 'sender', name: 'Sender', publicKey: 'remoteKey', isBlocked: false, createdAt: DateTime.now(), updatedAt: DateTime.now())
    );
    when(() => mockDatabase.getChatByPeerId(any())).thenAnswer((_) async => 
        ChatsTableData(
          id: 'chat1', 
          peerId: 'sender', 
          lastUpdated: DateTime.now(), 
          avatarColor: 0, 
          isGroup: false, 
          createdAt: DateTime.now(),
        )
    );
    when(() => mockDatabase.updateMessageStatus(any(), any())).thenAnswer((_) async => true);
    when(() => mockDatabase.insertMessage(any())).thenAnswer((_) async => 1);
    when(() => mockDatabase.updateLastMessage(any(), any())).thenAnswer((_) async => true);
    when(() => mockDatabase.enqueueRelayPacket(any())).thenAnswer((_) async {});
    when(() => mockDatabase.incrementRetryCount(any())).thenAnswer((_) async {});


    // Setup Encryption Mock
    when(() => mockEncryptionService.calculateSharedSecret(any())).thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4]));
    when(() => mockEncryptionService.decryptMessage(any(), any())).thenReturn('Hello World');

    container = ProviderContainer(
      overrides: [
        meshServiceProvider.overrideWithValue(mockMeshService),
        appDatabaseProvider.overrideWith((ref) => Future.value(mockDatabase)),
        encryptionServiceProvider.overrideWithValue(mockEncryptionService),
        authServiceProvider.overrideWith((ref) => mockAuthService),
      ],
    );
  });

  test('Should generate and send ACK when receiving a valid MeshMessage', () async {
    // Arrange
    final streamController = StreamController<String>.broadcast();
    when(() => mockMeshService.onMessageReceived).thenAnswer((_) => streamController.stream);
    
    // Stub sendMeshMessage to return true
    when(() => mockMeshService.handleIncomingMeshMessage(any())).thenAnswer((_) async {});
    when(() => mockMeshService.sendMeshMessage(
      any(), 
      any(), 
      senderId: any(named: 'senderId'),
      maxHops: any(named: 'maxHops'),
      type: any(named: 'type'),
      metadata: any(named: 'metadata'),
    )).thenAnswer((_) async => true);

    // This init starts listening
    container.read(incomingMessageHandlerProvider); 
    
    final originalMessageId = 'msg-123';
    final senderId = 'sender';
    final myId = 'me';
    
    final meshMessageJson = jsonEncode({
      'messageId': originalMessageId,
      'originalSenderId': senderId,
      'finalDestinationId': myId,
      'encryptedContent': 'encrypted-content',
      'hopCount': 2,
      'maxHops': 10,
      'timestamp': DateTime.now().toIso8601String(),
    }); // This doesn't have 'type', implying normal message

    // Act
    streamController.add(meshMessageJson);
    
    // Wait for async processing
    await mtWaitFor(Duration(milliseconds: 200));

    // Assert
    // Verify an ACK was sent back to 'sender' with 'originalMessageId' in metadata
    verify(() => mockMeshService.sendMeshMessage(
      senderId, // peerId (destination of ACK)
      '', // content (empty)
      senderId: myId, // senderId (me)
      maxHops: 10,
      type: MeshMessage.typeAck,
      metadata: any(named: 'metadata', that: containsPair('originalMessageId', originalMessageId)),
    )).called(1);
    
    streamController.close();
  });
}

// Helper to wait
Future<void> mtWaitFor(Duration duration) => Future.delayed(duration);

Matcher containsPair(Object? key, Object? value) => 
    predicate((Map<dynamic, dynamic> map) => map.containsKey(key) && map[key] == value);
