import 'package:drift/drift.dart';

/// Table for Relay Packets (Store-Carry-Forward).
/// Stores encrypted packets destined for other users.
/// Implements "Blind Relaying" via hashed IDs.
@TableIndex(name: 'relay_queue_to_hash_idx', columns: {#toHash})
@TableIndex(name: 'relay_queue_created_at_idx', columns: {#createdAt})
class RelayQueueTable extends Table {
  /// Unique packet identifier (UUID).
  TextColumn get packetId => text()();

  /// SHA-256 Hash of the Destination User ID.
  /// Relays check this against their own hash.
  TextColumn get toHash => text()();

  /// Time To Live (in hours or hops).
  IntColumn get ttl => integer().withDefault(const Constant(24))();

  /// Encrypted payload (BLOB).
  /// Content is opaque to the relay node.
  TextColumn get payload => text()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// JSON list of hashed device IDs this packet has traversed.
  TextColumn get trace => text().withDefault(const Constant('[]'))();

  /// When this packet was added to this device's queue.
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();

  /// Number of times the packet has been forwarded/retried.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Priority level: 0=Low, 1=Standard (default), 2=High (ACKs, Admin)
  IntColumn get priority => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {packetId};
}
