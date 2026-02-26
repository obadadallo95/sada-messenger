import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:sada/core/database/app_database.dart';
import 'package:sada/core/utils/constants.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('RelayPacket Tests', () {
    test('Should enqueue and retrieve relay packets', () async {
      // Arrange
      final packet = RelayQueueTableCompanion.insert(
        packetId: 'packet1',
        toHash: 'user123',
        ttl: const Value(10),
        payload: '{"test": "data"}',
        createdAt: DateTime.now(),
        trace: const Value('[]'),
      );

      // Act
      await database.enqueueRelayPacket(packet);
      final retrieved = await database.getRelayPacketById('packet1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.packetId, equals('packet1'));
      expect(retrieved.toHash, equals('user123'));
    });

    test('Should deduplicate packets with same ID', () async {
      // Arrange
      final packet1 = RelayQueueTableCompanion.insert(
        packetId: 'duplicate',
        toHash: 'user123',
        ttl: const Value(10),
        payload: '{"version": 1}',
        createdAt: DateTime.now(),
      );

      final packet2 = RelayQueueTableCompanion.insert(
        packetId: 'duplicate',
        toHash: 'user456',
        ttl: const Value(5),
        payload: '{"version": 2}',
        createdAt: DateTime.now(),
      );

      // Act
      await database.enqueueRelayPacket(packet1);
      await database.enqueueRelayPacket(packet2); // Should be skipped

      final queue = await database.getRelayPacketsForSync();

      // Assert
      expect(queue.length, equals(1));
      expect(queue.first.payload, contains('version": 1')); // Original kept
    });

    test('Should enforce priority-based eviction when queue is full', () async {
      // Arrange - Fill queue with low priority packets
      for (int i = 0; i < AppConstants.relayQueueMaxCount; i++) {
        await database.enqueueRelayPacket(
          RelayQueueTableCompanion.insert(
            packetId: 'low_$i',
            toHash: 'user$i',
            ttl: const Value(10),
            payload: 'x' * 100, // Small payload
            createdAt: DateTime.now(),
            priority: const Value(0), // Low priority
          ),
        );
      }

      // Act - Add high priority packet
      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'high_priority',
          toHash: 'important',
          ttl: const Value(10),
          payload: 'important data',
          createdAt: DateTime.now(),
          priority: const Value(2), // High priority
        ),
      );

      // Assert
      final highPriorityPacket = await database.getRelayPacketById(
        'high_priority',
      );
      expect(
        highPriorityPacket,
        isNotNull,
        reason: 'High priority packet should be enqueued',
      );

      final queueSize = await database.getRelayStorageSize();
      expect(queueSize, lessThanOrEqualTo(AppConstants.relayQueueMaxCount));
    });

    test('Should enforce byte-based quota', () async {
      // Arrange - Create large packet that exceeds byte limit
      final largePayload = 'x' * (AppConstants.relayQueueMaxBytes + 1000);

      // Act
      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'huge',
          toHash: 'user1',
          ttl: const Value(10),
          payload: largePayload,
          createdAt: DateTime.now(),
        ),
      );

      // Assert - Should be rejected or queue should be trimmed
      final byteSize = await database.getRelayQueueByteSize();
      expect(byteSize, lessThanOrEqualTo(AppConstants.relayQueueMaxBytes));
    });

    test('Should cleanup expired packets', () async {
      // Arrange - Add old packet
      final oldPacket = RelayQueueTableCompanion.insert(
        packetId: 'old',
        toHash: 'user1',
        ttl: const Value(10),
        payload: 'old data',
        createdAt: DateTime.now().subtract(
          const Duration(days: 8),
        ), // Older than 7 days
      );

      final recentPacket = RelayQueueTableCompanion.insert(
        packetId: 'recent',
        toHash: 'user2',
        ttl: const Value(10),
        payload: 'recent data',
        createdAt: DateTime.now(),
      );

      await database.enqueueRelayPacket(oldPacket);
      await database.enqueueRelayPacket(recentPacket);

      // Act
      final deletedCount = await database.cleanupExpiredPackets();

      // Assert
      expect(deletedCount, equals(1));
      final remaining = await database.getRelayPacketsForSync();
      expect(remaining.length, equals(1));
      expect(remaining.first.packetId, equals('recent'));
    });

    test('Should retrieve packets for specific target hash', () async {
      // Arrange
      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'packet1',
          toHash: 'targetA',
          ttl: const Value(10),
          payload: 'data1',
          createdAt: DateTime.now(),
        ),
      );

      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'packet2',
          toHash: 'targetB',
          ttl: const Value(10),
          payload: 'data2',
          createdAt: DateTime.now(),
        ),
      );

      // Act
      final packetsForA = await database.getPacketsForTargetHash('targetA');

      // Assert
      expect(packetsForA.length, equals(1));
      expect(packetsForA.first.packetId, equals('packet1'));
    });

    test('Should track retry count', () async {
      // Arrange
      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'retry_test',
          toHash: 'user1',
          ttl: const Value(10),
          payload: 'data',
          createdAt: DateTime.now(),
        ),
      );

      // Act
      await database.incrementRetryCount('retry_test');
      await database.incrementRetryCount('retry_test');

      final packet = await database.getRelayPacketById('retry_test');

      // Assert
      expect(packet, isNotNull);
      expect(packet!.retryCount, equals(2));
    });

    test('Should provide relay queue metrics', () async {
      // Arrange - Add packets with different priorities
      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'high1',
          toHash: 'user1',
          ttl: const Value(10),
          payload: 'x' * 100,
          createdAt: DateTime.now(),
          priority: const Value(2),
        ),
      );

      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'standard1',
          toHash: 'user2',
          ttl: const Value(10),
          payload: 'x' * 100,
          createdAt: DateTime.now(),
          priority: const Value(1),
        ),
      );

      await database.enqueueRelayPacket(
        RelayQueueTableCompanion.insert(
          packetId: 'low1',
          toHash: 'user3',
          ttl: const Value(10),
          payload: 'x' * 100,
          createdAt: DateTime.now(),
          priority: const Value(0),
        ),
      );

      // Act
      final metrics = await database.getRelayQueueMetrics();

      // Assert
      expect(metrics['totalCount'], equals(3));
      expect(metrics['highPriority'], equals(1));
      expect(metrics['standardPriority'], equals(1));
      expect(metrics['lowPriority'], equals(1));
      expect(metrics['totalBytes'], greaterThan(0));
    });
  });
}
