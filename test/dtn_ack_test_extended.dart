
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sada/core/network/incoming_message_handler.dart';
import 'package:sada/core/network/mesh_service.dart';
import 'package:sada/core/network/models/mesh_message.dart';
import 'package:sada/core/database/app_database.dart';
import 'package:sada/core/database/database_provider.dart';
import 'package:sada/core/security/security_providers.dart';
import 'package:sada/core/security/encryption_service.dart';
import 'package:sada/core/services/auth_service.dart';
import 'package:sada/core/services/notification_service.dart';
import 'package:sada/core/services/notification_provider.dart';


// Define Mocks
// Define Mocks
class MockMeshService extends Mock implements MeshService {}
class MockAppDatabase extends Mock implements AppDatabase {}
class MockEncryptionService extends Mock implements EncryptionService {}
class MockAuthService extends Mock implements AuthService {}
class MockNotificationService extends Mock implements NotificationService {}
class FakeMessagesTableCompanion extends Fake implements MessagesTableCompanion {}
class FakeRelayQueueTableCompanion extends Fake implements RelayQueueTableCompanion {}
class FakeChatsTableCompanion extends Fake implements ChatsTableCompanion {}

void main() {
  late MockMeshService mockMeshService;
  late MockAppDatabase mockDatabase;
  late MockEncryptionService mockEncryptionService;
  late MockAuthService mockAuthService;
  late MockNotificationService mockNotificationService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeMessagesTableCompanion());
    registerFallbackValue(FakeRelayQueueTableCompanion());
    registerFallbackValue(FakeChatsTableCompanion());
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
    mockNotificationService = MockNotificationService();

    // Setup Auth Mock
    when(() => mockAuthService.currentUser).thenReturn(
      UserData(userId: 'me', displayName: 'Me', deviceHash: 'hash'),
    );

    // Setup Database Mock
    when(() => mockDatabase.getContactById(any())).thenAnswer((_) async => 
        ContactsTableData(id: 'sender', name: 'Sender', publicKey: 'dGVzdA==', isBlocked: false, createdAt: DateTime.now(), updatedAt: DateTime.now())
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
    when(() => mockDatabase.insertMessage(any())).thenAnswer((_) async {});
    when(() => mockDatabase.updateLastMessage(any(), any())).thenAnswer((_) async => true);
    when(() => mockDatabase.enqueueRelayPacket(any())).thenAnswer((_) async {});
    when(() => mockDatabase.incrementRetryCount(any())).thenAnswer((_) async {});
    when(() => mockDatabase.getAllChats()).thenAnswer((_) async => []); // Stub getAllChats
    when(() => mockDatabase.getMessageById(any())).thenAnswer((_) async => null); // Stub duplicate check

    // Setup Encryption Mock
    when(() => mockEncryptionService.calculateSharedSecret(any())).thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4]));
    when(() => mockEncryptionService.decryptMessage(any(), any())).thenReturn('Hello World');
    
    // Setup Notification Mock
    when(() => mockNotificationService.showChatNotification(
      id: any(named: 'id'), 
      title: any(named: 'title'), 
      body: any(named: 'body'), 
      payload: any(named: 'payload')
    )).thenAnswer((_) async => true);

    container = ProviderContainer(
      overrides: [
        meshServiceProvider.overrideWithValue(mockMeshService),
        appDatabaseProvider.overrideWith((ref) => Future.value(mockDatabase)),
        encryptionServiceProvider.overrideWithValue(mockEncryptionService),
        authServiceProvider.overrideWith((ref) => mockAuthService),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
      ],
    );
  });

  test('Should generate and send ACK when receiving a valid MeshMessage', () async {
    // Arrange
    final streamController = StreamController<String>.broadcast();
    when(() => mockMeshService.onMessageReceived).thenAnswer((_) => streamController.stream);
    
    // Stub encryption
    when(() => mockEncryptionService.encryptMessage(any(), any())).thenReturn('encrypted-ack');
    
    // Stub sendMeshMessage to return true
    when(() => mockMeshService.handleIncomingMeshMessage(any())).thenAnswer((_) async => true);
    when(() => mockMeshService.sendMeshMessage(
      any(), 
      any(), 
      senderId: any(named: 'senderId'),
      maxHops: any(named: 'maxHops'),
      type: any(named: 'type'),
      metadata: any(named: 'metadata'),
    )).thenAnswer((_) async => true);

    // This init starts listening
    final handler = container.read(incomingMessageHandlerProvider);
    addTearDown(() => handler.dispose()); 
    
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
      'encrypted-ack', // content (encrypted)
      senderId: myId, // senderId (me)
      maxHops: 10,
      type: MeshMessage.typeAck,
      metadata: any(named: 'metadata', that: containsPair('originalMessageId', originalMessageId)),
    )).called(1);
    
    streamController.close();
  });

  test('Should handle incoming ACK and update message status', () async {
    // Arrange
    final streamController = StreamController<String>.broadcast();
    when(() => mockMeshService.onMessageReceived).thenAnswer((_) => streamController.stream);
    when(() => mockMeshService.handleIncomingMeshMessage(any())).thenAnswer((_) async => true);
    
    // Stub updateMessageStatus
    when(() => mockDatabase.updateMessageStatus(any(), any())).thenAnswer((_) async => true);
    
    // Stub decryption for ACK payload
    final ackPayload = jsonEncode({
      'originalMessageId': 'original-msg-123',
      'ackSenderId': 'sender',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    when(() => mockEncryptionService.decryptMessage(any(), any())).thenReturn(ackPayload);
    
    final handler = container.read(incomingMessageHandlerProvider);
    addTearDown(() => handler.dispose()); 
    
    final senderId = 'sender';
    final myId = 'me';
    
    final ackMessageJson = jsonEncode({
      'messageId': 'ack-msg-1',
      'originalSenderId': senderId,
      'finalDestinationId': myId,
      'encryptedContent': 'encrypted-ack',
      'type': MeshMessage.typeAck,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Act
    streamController.add(ackMessageJson);
    await mtWaitFor(Duration(milliseconds: 200));

    // Assert
    // Verify steps
    verify(() => mockDatabase.getContactById(senderId)).called(1);
    verify(() => mockEncryptionService.calculateSharedSecret(any())).called(1);
    verify(() => mockEncryptionService.decryptMessage(any(), any())).called(1);

    // 1. Verify message status updated
    verify(() => mockDatabase.updateMessageStatus('original-msg-123', 'delivered')).called(1);
    
    // 2. Verify NO ack sent back (ACK for ACK)
    verifyNever(() => mockMeshService.sendMeshMessage(
      any(), any(), senderId: any(named: 'senderId'), maxHops: any(named: 'maxHops'), type: any(named: 'type')
    ));
    
    streamController.close();
  });
  
  test('Should ignore malformed ACK', () async {
     // Arrange
    final streamController = StreamController<String>.broadcast();
    when(() => mockMeshService.onMessageReceived).thenAnswer((_) => streamController.stream);
    when(() => mockMeshService.handleIncomingMeshMessage(any())).thenAnswer((_) async => true);
    
    // Stub decryption for INVALID payload
    final invalidPayload = jsonEncode({
      'somethingElse': 'no-original-id',
    });
    when(() => mockEncryptionService.decryptMessage(any(), any())).thenReturn(invalidPayload);
    
    final handler = container.read(incomingMessageHandlerProvider);
    addTearDown(() => handler.dispose()); 
    
    final senderId = 'sender';
    final myId = 'me';
    
    final ackMessageJson = jsonEncode({
      'messageId': 'ack-msg-2',
      'originalSenderId': senderId,
      'finalDestinationId': myId,
      'encryptedContent': 'encrypted-ack',
      'type': MeshMessage.typeAck,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Act
    streamController.add(ackMessageJson);
    await mtWaitFor(Duration(milliseconds: 200));

    // Assert
    // Verify status NOT updated
    verifyNever(() => mockDatabase.updateMessageStatus(any(), any()));
    
    streamController.close(); 
  });
}

// Helper to wait
Future<void> mtWaitFor(Duration duration) => Future.delayed(duration);

Matcher containsPair(Object? key, Object? value) => 
    predicate((Map<dynamic, dynamic> map) => map.containsKey(key) && map[key] == value);
