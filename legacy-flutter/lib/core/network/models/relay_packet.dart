import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// Represents a packet in the Delay-Tolerant Network (DTN).
/// Used for Store-Carry-Forward routing where the relay node
/// does not know the final destination's identity (Blind Relaying).
class RelayPacket {
  /// Unique identifier for this packet.
  final String packetId;

  /// SHA-256 hash of the target User ID.
  /// Relay nodes check this against their own ID hash to see if they are the recipient.
  final String toHash;

  /// Time To Live (TTL) in hops or time duration.
  /// Used to purge old packets from the network.
  final int ttl;

  /// Encrypted content (The actual message).
  /// Relay nodes cannot decrypt this.
  final String payload;

  /// Timestamp when this packet was created.
  final DateTime createdAt;

  /// List of hashed IDs of devices this packet has passed through.
  /// Used for loop detection and network analysis (anonymized).
  final List<String> trace;

  const RelayPacket({
    required this.packetId,
    required this.toHash,
    required this.ttl,
    required this.payload,
    required this.createdAt,
    this.trace = const [],
  });

  /// Creates a new [RelayPacket].
  /// [targetUserId] is hashed automatically.
  factory RelayPacket.create({
    required String targetUserId,
    required String encryptedPayload,
    int ttl = 24, // Default 24 hours (or hops, depending on logic)
  }) {
    final toHash = sha256.convert(utf8.encode(targetUserId)).toString();
    return RelayPacket(
      packetId: const Uuid().v4(),
      toHash: toHash,
      ttl: ttl,
      payload: encryptedPayload,
      createdAt: DateTime.now(),
      trace: [],
    );
  }

  factory RelayPacket.fromJson(Map<String, dynamic> json) {
    final packetId = json['packetId']?.toString();
    final toHash = json['toHash']?.toString();
    final payload = json['payload']?.toString();

    if (packetId == null || packetId.isEmpty) {
      throw const FormatException('RelayPacket.packetId is missing');
    }
    if (toHash == null || toHash.isEmpty) {
      throw const FormatException('RelayPacket.toHash is missing');
    }
    if (payload == null) {
      throw const FormatException('RelayPacket.payload is missing');
    }

    final ttlValue = json['ttl'];
    final ttl = ttlValue is int
        ? ttlValue
        : int.tryParse(ttlValue?.toString() ?? '') ?? 0;

    final createdAtRaw = json['createdAt']?.toString();
    final createdAt = createdAtRaw == null
        ? DateTime.now()
        : DateTime.tryParse(createdAtRaw) ?? DateTime.now();

    final traceRaw = json['trace'];
    final trace = traceRaw is List
        ? traceRaw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    return RelayPacket(
      packetId: packetId,
      toHash: toHash,
      ttl: ttl,
      payload: payload,
      createdAt: createdAt,
      trace: trace,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packetId': packetId,
      'toHash': toHash,
      'ttl': ttl,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'trace': trace,
    };
  }

  /// Checks if this packet is valid for the given [myUserId].
  /// Returns true if [myUserId] hashes to [toHash].
  bool isForMe(String myUserId) {
    final myHash = sha256.convert(utf8.encode(myUserId)).toString();
    return toHash == myHash;
  }

  /// Checks if the packet has expired based on [createdAt] and [ttl] (in hours).
  bool isExpired() {
    final now = DateTime.now();
    final expirationTime = createdAt.add(Duration(hours: ttl));
    return now.isAfter(expirationTime);
  }

  /// Adds a hop to the trace.
  /// [deviceId] should be hashed before adding to preserve privacy if strictly required,
  /// or added as is if [trace] is just for debug/routing optimization within trusted circle.
  /// Here we assume anonymized trace is preferred.
  RelayPacket addHop(String deviceId) {
    // We can hash the device ID to keep the trace anonymous but verifiable for loops
    final hopHash = sha256.convert(utf8.encode(deviceId)).toString();

    // Check for loops
    if (trace.contains(hopHash)) {
      // Loop detected, maybe decrease TTL faster or handle elsewhere
    }

    return RelayPacket(
      packetId: packetId,
      toHash: toHash,
      ttl: ttl - 1, // Decrease TTL on hop
      payload: payload,
      createdAt: createdAt,
      trace: [...trace, hopHash],
    );
  }
}
