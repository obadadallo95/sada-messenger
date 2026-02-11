import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:sada/core/database/app_database.dart';
import 'package:sada/core/utils/constants.dart';
import 'package:sada/core/utils/log_service.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // 1. Setup in-memory database
    database = AppDatabase.forTesting(NativeDatabase.memory());
    
    // 2. Reduce limits for testing
    // Limit to ~2KB or small count to easily trigger eviction
    AppConstants.relayQueueMaxBytes = 1024 * 2; // 2KB
    AppConstants.relayQueueMaxCount = 10; // 10 packets
  });

  tearDown(() async {
    await database.close();
    // Reset constants
    AppConstants.relayQueueMaxBytes = 100 * 1024 * 1024;
    AppConstants.relayQueueMaxCount = 5000;
  });

  test('Relay Queue: Should accept High Priority packets even when full of Low Priority', () async {
    // 1. Fill queue with Low Priority packets (Priority 0)
    // Payload size 100 bytes
    final payload = '*' * 100; 
    
    for (int i = 0; i < AppConstants.relayQueueMaxCount; i++) {
        await database.enqueueRelayPacket(
          RelayQueueTableCompanion.insert(
            packetId: 'low-$i',
            toHash: 'dest',
            payload: payload,
            priority: const Value(0), // Low
            ttl: const Value(10),
            queuedAt: Value(DateTime.now().add(Duration(seconds: i))), // Ensure strict order
            createdAt: DateTime.now(),
          ),
        );
    }
    
    // Verify full
    expect(await database.getRelayStorageSize(), AppConstants.relayQueueMaxCount);
    
    // 2. Try to add High Priority packet (Priority 2)
    // This should trigger eviction of a Low Priority packet
    await database.enqueueRelayPacket(
      RelayQueueTableCompanion.insert(
        packetId: 'high-1',
        toHash: 'dest',
        payload: payload,
        priority: const Value(2), // High
        ttl: const Value(10),
        createdAt: DateTime.now(),
      ),
    );
    
    // 3. Verify High Priority is present
    final highPacket = await database.getRelayPacketById('high-1');
    expect(highPacket, isNotNull, reason: 'High priority packet should be accepted');
    
    // 4. Verify size is still at limit (1 deleted, 1 added)
    // Actually, max count is 10. If we add 1, we delete 1.
    expect(await database.getRelayStorageSize(), AppConstants.relayQueueMaxCount);
    
    // 5. Verify a Low priority packet was removed (Should be the oldest or lowest priority?)
    // Our logic sorts by Priority ASC, then Time ASC.
    // So 'low-0' (oldest low priority) should be gone.
    final low0 = await database.getRelayPacketById('low-0');
    expect(low0, isNull, reason: 'Oldest low priority packet should be evicted');
    
    final low1 = await database.getRelayPacketById('low-1');
    expect(low1, isNotNull, reason: 'Newer low priority packet should remain');
  });

  test('Relay Queue: Should REJECT Low Priority packet when full of High Priority', () async {
     // 1. Fill queue with High Priority packets
    final payload = '*' * 100;
    
    for (int i = 0; i < AppConstants.relayQueueMaxCount; i++) {
        await database.enqueueRelayPacket(
          RelayQueueTableCompanion.insert(
            packetId: 'high-$i',
            toHash: 'dest',
            payload: payload,
            priority: const Value(2), // High
            ttl: const Value(10),
            createdAt: DateTime.now(),
          ),
        );
    }
    
    expect(await database.getRelayStorageSize(), AppConstants.relayQueueMaxCount);

    // 2. Try to add Low Priority packet
    await database.enqueueRelayPacket(
      RelayQueueTableCompanion.insert(
        packetId: 'low-fail',
        toHash: 'dest',
        payload: payload,
        priority: const Value(0), // Low
        ttl: const Value(10),
        createdAt: DateTime.now(),
      ),
    );
    
    // 3. Verify Low Priority packet failed to insert (eviction failed because all existing are higher priority)
    final lowFail = await database.getRelayPacketById('low-fail');
    expect(lowFail, isNull, reason: 'Low priority packet should be rejected when queue is full of high priority');
    
    // Verify count didn't change
    expect(await database.getRelayStorageSize(), AppConstants.relayQueueMaxCount);
  });
  
  test('Relay Queue: Should verify byte limit logic', () async {
     // Set limit to 500 bytes
     AppConstants.relayQueueMaxBytes = 500;
     AppConstants.relayQueueMaxCount = 100; // Not binding
     
     final payload = '*' * 200; // 200 bytes per packet
     
     // Add 2 packets (400 bytes) -> OK
     await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'p1', 
          toHash: 'dest', 
          payload: payload, 
          priority: const Value(1), 
          ttl: const Value(10),
          createdAt: DateTime.now(),
        )
     );
     await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'p2', 
          toHash: 'dest', 
          payload: payload, 
          priority: const Value(1), 
          ttl: const Value(10),
          createdAt: DateTime.now(),
        )
     );
     
     expect(await database.getRelayQueueByteSize(), 400);

     // Add 3rd packet (Total would be 600 > 500)
     // Should evict p1 (oldest same priority)
     await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'p3', 
          toHash: 'dest', 
          payload: payload, 
          priority: const Value(1), 
          ttl: const Value(10),
          createdAt: DateTime.now(),
        )
     );
     
     final size = await database.getRelayQueueByteSize();
     expect(size, lessThanOrEqualTo(AppConstants.relayQueueMaxBytes));
     expect(size, 400); // p1 evicted, p2 + p3 remain
     
     expect(await database.getRelayPacketById('p1'), isNull);
     expect(await database.getRelayPacketById('p3'), isNotNull);
  });
}
