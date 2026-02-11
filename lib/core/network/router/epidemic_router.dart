import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:crypto/crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' show Value;
import '../models/relay_packet.dart';
import '../../database/app_database.dart';
import '../../database/database_provider.dart';
import '../../utils/log_service.dart';
import '../mesh_service.dart';

part 'epidemic_router.g.dart';

/// Manages the "Epidemic Routing" strategy for the Delay-Tolerant Network.
/// Handles:
/// 1. Discovery of nearby peers (via Nearby Connections API).
/// 2. Handshake and Exchange of held packets (Bloom Filter / Vector Summary).
/// 3. Store-Carry-Forward logic (Blind Relaying).
@Riverpod(keepAlive: true)
class EpidemicRouter extends _$EpidemicRouter {
  /// Strategy for Nearby Connections (P2P_CLUSTER fits best for mesh/group comms).
  static const Strategy strategy = Strategy.P2P_CLUSTER;

  /// Current user ID (should be fetched from Auth/Settings).
  String? _myUserId;
  
  /// Hash of the current user ID (for receiving checks).
  String? _myUserHash;

  /// Active connections map: EndpointId -> ConnectionInfo
  final Map<String, ConnectionInfo> _connectedEndpoints = {};

  /// Cached set of packet IDs we've already seen during this session.
  /// This is an in-memory fast path on top of the database-level deduplication.
  final Set<String> _seenPacketIds = {};

  /// Token bucket per connected peer to prevent flooding.
  /// Each endpoint starts with [_maxTokensPerPeer] tokens, which are replenished
  /// periodically. Every outbound payload consumes one token.
  final Map<String, int> _peerTokens = {};

  static const int _maxTokensPerPeer = 20;
  static const Duration _tokenRefillInterval = Duration(minutes: 1);

  Timer? _tokenRefillTimer;
  void Function(int)? _onPeerCountChanged;
  void Function(int, int, int)? _onMetricsUpdated;

  @override
  Future<void> build() async {
    return;
  }

  /// Initialize the router with the user's identity.
  Future<void> initialize(String userId, {
    void Function(int)? onPeerCountChanged,
    void Function(int sent, int received, int dropped)? onMetricsUpdated,
  }) async {
    _myUserId = userId;
    _onPeerCountChanged = onPeerCountChanged;
    _onMetricsUpdated = onMetricsUpdated;
    _myUserHash = sha256.convert(utf8.encode(userId)).toString();
    LogService.info('EpidemicRouter initialized for User: $userId (Hash: $_myUserHash)');
  }

  /// Start advertising and discovery to find peers.
  Future<bool> startService() async {
    if (_myUserId == null) {
      LogService.error('Cannot start EpidemicRouter: User ID not set.');
      return false;
    }

    try {
      final nearby = Nearby();

      _ensureTokenBucketStarted();
      
      // Stop any previous sessions
      await nearby.stopAdvertising();
      await nearby.stopDiscovery();

      // Start Advertising
      // We use the UserHash as the "NickName" to quickly identify targets? 
      // Or just a random/device name and exchange hashes in handshake.
      // Privacy-wise, broadcasting Hash might leak presence if attacker knows the UserID.
      // Better to broadcast a random Ephemeral ID and exchange identity after secure connection.
      // For simplicity in this implementation step, we'll use a semi-anonymous name.
      final deviceName = "MeshNode-${_myUserId!.substring(0, 4)}"; 

      await nearby.startAdvertising(
        deviceName,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: 'com.sada.messenger', // Must match manifest
      );

      // Start Discovery
      await nearby.startDiscovery(
        _myUserId!,
        strategy,
        onEndpointFound: _onEndpointFound,
        // Cast to dynamic to satisfy the Nearby API's OnEndpointLost typedef without
        // tightly coupling our signature to the external package.
        onEndpointLost: _onEndpointLost as dynamic,
        serviceId: 'com.sada.messenger',
      );

      LogService.info('EpidemicRouter service started (Advertising & Discovery).');
      return true;
    } catch (e) {
      LogService.error('Failed to start EpidemicRouter service', e);
      return false;
    }
  }

  /// Stop all nearby connection activities.
  Future<void> stopService() async {
    final nearby = Nearby();
    await nearby.stopAdvertising();
    await nearby.stopDiscovery();
    await nearby.stopAllEndpoints();
    _connectedEndpoints.clear();
    _peerTokens.clear();
    LogService.info('EpidemicRouter service stopped.');
  }

  // --- Callbacks ---

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) async {
    LogService.info('Connection Initiated: $endpointId (${info.endpointName})');
    // Auto-accept connection for mesh networking
    try {
      await Nearby().acceptConnection(
        endpointId,
        onPayLoadRecieved: (eid, payload) => _onPayloadReceived(eid, payload),
        onPayloadTransferUpdate: (eid, update) {
          // Handle progress if needed
        },
      );
    } catch (e) {
      LogService.error('Failed to accept connection', e);
    }
  }

  void _onConnectionResult(String endpointId, Status status) {
    LogService.info('Connection Result for $endpointId: $status');
    if (status == Status.CONNECTED) {
      // Trigger Handshake immediately!
      _initiateHandshake(endpointId);
      // We don't add to _connectedEndpoints until handshake complete? 
      // Actually we should track connection state here.
      // But for peer count, getting Handshake is better.
      // However, for raw connection count:
      _connectedEndpoints[endpointId] = ConnectionInfo(endpointId, endpointId, true); // Dummy info if not available
      _onPeerCountChanged?.call(_connectedEndpoints.length);
    } else {
      _connectedEndpoints.remove(endpointId);
      _onPeerCountChanged?.call(_connectedEndpoints.length);
    }
  }

  void _onDisconnected(String endpointId) {
    LogService.info('Disconnected: $endpointId');
    _connectedEndpoints.remove(endpointId);
    _onPeerCountChanged?.call(_connectedEndpoints.length);
  }

  void _onEndpointFound(String endpointId, String userName, String serviceId) async {
    LogService.info('Endpoint Found: $endpointId ($userName)');
    // Auto-request connection
    try {
      final deviceName = "MeshNode-${_myUserId!.substring(0, 4)}";
      await Nearby().requestConnection(
        deviceName,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      LogService.error('Failed to request connection', e);
    }
  }

  void _onEndpointLost(String endpointId) {
    LogService.info('Endpoint Lost: $endpointId');
  }

  // --- Duty Cycle & Battery Optimization ---
  
  Timer? _dutyCycleTimer;
  static const Duration _scanDuration = Duration(minutes: 2);
  static const Duration _sleepDuration = Duration(minutes: 5);

  /// Start the Duty Cycle (Scan -> Sleep -> Scan ...).
  void startDutyCycle() {
    LogService.info('⏳ Starting Duty Cycle...');
    _runScanCycle();
    _dutyCycleTimer = Timer.periodic(_scanDuration + _sleepDuration, (timer) {
      _runScanCycle();
    });
  }

  /// Stop the Duty Cycle.
  void stopDutyCycle() {
    _dutyCycleTimer?.cancel();
    stopService(); // Stops discovery
  }

  Future<void> _runScanCycle() async {
    LogService.info('🔄 Duty Cycle: Waking up to SCAN...');
    await startService(); // Start Discovery/Advertising
    
    // Scan for _scanDuration
    Future.delayed(_scanDuration, () async {
      LogService.info('zzz Duty Cycle: Sleeping...');
      await stopService(); // Stop Discovery to save battery
      // Advertising might need to stay on if we want to be discoverable?
      // For true duty cycle, both usually sleep, or we use low-power BLE advertising if supported.
      // Nearby Connections P2P_CLUSTER uses WiFiDirect/Bluetooth.
    });
  }

  // --- Handshake & Protocol ---

  Future<void> _initiateHandshake(String endpointId) async {
    LogService.info('Initiating Handshake with $endpointId...');
    
    final db = await ref.read(appDatabaseProvider.future);
    // Get candidate packets for sync
    final queueEntries = await db.getRelayPacketsForSync();

    // Filter out obviously expired / invalid packets before advertising them.
    // This keeps summaries small and avoids wasting bandwidth on dead packets.
    final summary = <Map<String, dynamic>>[];
    for (final entry in queueEntries) {
      try {
        final relayPacket = RelayPacket(
          packetId: entry.packetId,
          toHash: entry.toHash,
          ttl: entry.ttl,
          payload: entry.payload,
          createdAt: entry.createdAt,
          trace: List<String>.from(
            (jsonDecode(entry.trace) as List?) ?? const <String>[],
          ),
        );

        // TTL-based and time-based expiry check.
        if (relayPacket.ttl <= 0 || relayPacket.isExpired()) {
          continue;
        }

        summary.add({
          'id': relayPacket.packetId,
          'to': relayPacket.toHash,
          'ttl': relayPacket.ttl,
          'created': relayPacket.createdAt.millisecondsSinceEpoch,
        });
      } catch (e) {
        LogService.error('Failed to prepare relay packet summary entry', e);
      }
    }

    final handshakePayload = {
      'type': 'HANDSHAKE_SUMMARY',
      'senderHash': _myUserHash,
      'summary': summary,
    };
    
    _sendJson(endpointId, handshakePayload);
  }

  void _onPayloadReceived(String endpointId, Payload payload) async {
    if (payload.type != PayloadType.BYTES) return;
    
    try {
      final bytes = payload.bytes!;
      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final type = data['type'];
      
      if (type == 'HANDSHAKE_SUMMARY') {
        await _handleHandshakeSummary(endpointId, data);
      } else if (type == 'REQUEST_PACKETS') {
        await _handlePacketRequest(endpointId, data);
      } else if (type == 'RELAY_PACKET') {
        await _handleRelayPacket(data);
      }
    } catch (e) {
      LogService.error('Error handling payload from $endpointId', e);
    }
  }

  /// Handle request for specific packets from peer
  Future<void> _handlePacketRequest(String endpointId, Map<String, dynamic> data) async {
    final ids = List<String>.from(data['ids'] ?? []);
    LogService.info('Peer $endpointId requested ${ids.length} packets.');
    
    final db = await ref.read(appDatabaseProvider.future);
    
    for (final id in ids) {
      try {
        final packetData = await db.getRelayPacketById(id);
        if (packetData == null) {
          LogService.warning('Requested relay packet not found locally: $id');
          continue;
        }

        // Convert RelayQueueTableData to RelayPacket for TTL / trace handling.
        final currentPacket = RelayPacket(
          packetId: packetData.packetId,
          toHash: packetData.toHash,
          ttl: packetData.ttl,
          payload: packetData.payload,
          createdAt: packetData.createdAt,
          trace: List<String>.from(
            (jsonDecode(packetData.trace) as List?) ?? const <String>[],
          ),
        );

        // Apply this hop (decrement TTL and extend trace).
        final myId = _myUserId ?? 'unknown-node';
        final forwardedPacket = currentPacket.addHop(myId);

        // If packet expired after this hop, drop it locally and do not forward.
        if (forwardedPacket.ttl <= 0 || forwardedPacket.isExpired()) {
          await db.deletePacket(forwardedPacket.packetId);
          LogService.info('Dropped expired relay packet during send: ${forwardedPacket.packetId}');
          continue;
        }

        // Persist updated TTL / trace so future syncs see the new state.
        await db.enqueueRelayPacket(RelayQueueTableCompanion.insert(
          packetId: forwardedPacket.packetId,
          toHash: forwardedPacket.toHash,
          ttl: Value(forwardedPacket.ttl),
          payload: forwardedPacket.payload,
          createdAt: forwardedPacket.createdAt,
          trace: Value(jsonEncode(forwardedPacket.trace)),
        ));

        // Wrap packet for transport.
        final packetJson = <String, dynamic>{
          'type': 'RELAY_PACKET',
          ...forwardedPacket.toJson(),
        };
        
        _sendJson(endpointId, packetJson);
        LogService.info('Sent RelayPacket ${forwardedPacket.packetId} to $endpointId');
        _onMetricsUpdated?.call(1, 0, 0); // Sent
      } catch (e) {
        LogService.error('Failed to send requested relay packet: $id', e);
      }
    }
  }

  Future<void> _handleHandshakeSummary(String endpointId, Map<String, dynamic> data) async {
    final summary = List<Map<String, dynamic>>.from(data['summary'] ?? []);
    LogService.info('Handshake: Peer has ${summary.length} packets.');

    final packetsToRequest = <String>[];
    final db = await ref.read(appDatabaseProvider.future);

    for (final item in summary) {
      final String toHash = item['to'];
      final String packetId = item['id'];
      
      // 1. Is it for ME?
      if (toHash == _myUserHash) {
        LogService.info('Found packet for ME! Requesting $packetId');
        packetsToRequest.add(packetId);
      } 
      // 2. Do I already have it?
      else {
        final exists = await db.hasPacket(packetId);
        if (!exists) {
           packetsToRequest.add(packetId);
        }
      }
    }
    
    if (packetsToRequest.isNotEmpty) {
      LogService.info('Requesting ${packetsToRequest.length} packets from $endpointId');
      _sendJson(endpointId, {
        'type': 'REQUEST_PACKETS',
        'ids': packetsToRequest,
      });
    }
  }
  
  Future<void> _handleRelayPacket(Map<String, dynamic> packetData) async {
    try {
      // Parse using RelayPacket model
      final packet = RelayPacket.fromJson(packetData);
      final db = await ref.read(appDatabaseProvider.future);

      // Quick in-memory deduplication.
      if (_seenPacketIds.contains(packet.packetId)) {
        LogService.info('♻️ In-memory duplicate packet ignored: ${packet.packetId}');
        return;
      }

      // Database-level deduplication.
      if (await db.hasPacket(packet.packetId)) {
        LogService.info('♻️ Duplicate packet ignored: ${packet.packetId}');
        _seenPacketIds.add(packet.packetId);
        return;
      }

      // TTL / expiry safeguards – do not accept dead packets into our queue.
      if (packet.ttl <= 0 || packet.isExpired()) {
        LogService.info('🕒 Dropped expired relay packet: ${packet.packetId}');
        _seenPacketIds.add(packet.packetId);
        _onMetricsUpdated?.call(0, 0, 1); // Dropped (Expired)
        return;
      }

      if (packet.isForMe(_myUserId!)) {
         LogService.info('✅ RECEIVED FINAL MESSAGE: ${packet.packetId}');
         try {
           final meshService = ref.read(meshServiceProvider);
           // The payload is the serialized MeshMessage
           await meshService.handleIncomingMeshMessage(packet.payload);
         } catch (e) {
           LogService.error('Failed to process delivered packet payload', e);
         }
      } else {
         LogService.info('📥 Storing Relay Packet: ${packet.packetId}');
         await db.enqueueRelayPacket(RelayQueueTableCompanion.insert(
           packetId: packet.packetId,
           toHash: packet.toHash,
           ttl: Value(packet.ttl),
           payload: packet.payload,
           createdAt: packet.createdAt,
            trace: Value(jsonEncode(packet.trace)),
          ));
          
          _onMetricsUpdated?.call(0, 1, 0); // Received (Relayed)
       }
    } catch (e) {
      LogService.error('Failed to handle incoming relay packet', e);
      _onMetricsUpdated?.call(0, 0, 1); // Dropped (Error)
    }
  }

  void _sendJson(String endpointId, Map<String, dynamic> data) {
    // تطبيق Token Bucket بسيط لكل Endpoint لتفادي flooding.
    if (!_consumeToken(endpointId)) {
      LogService.warning('🚫 Token bucket exceeded for $endpointId – تم تجاهل payload من النوع: ${data['type']}');
      _onMetricsUpdated?.call(0, 0, 1); // Dropped
      return;
    }

    final bytes = utf8.encode(jsonEncode(data));
    Nearby().sendBytesPayload(endpointId, Uint8List.fromList(bytes));
  }

  /// يبدأ مؤقت إعادة تعبئة الـ tokens إذا لم يكن قد بدأ سابقاً.
  void _ensureTokenBucketStarted() {
    if (_tokenRefillTimer != null) return;

    _tokenRefillTimer = Timer.periodic(_tokenRefillInterval, (_) {
      if (_peerTokens.isEmpty) return;
      _peerTokens.updateAll((key, value) => _maxTokensPerPeer);
      LogService.info('🔁 تم إعادة تعبئة Token Bucket لجميع الأقران');
    });
  }

  /// يحاول استهلاك Token واحد للـ [endpointId].
  /// يعيد false إذا لم يتبق أي Tokens.
  bool _consumeToken(String endpointId) {
    final currentTokens = _peerTokens[endpointId] ?? _maxTokensPerPeer;
    if (currentTokens <= 0) {
      return false;
    }
    _peerTokens[endpointId] = currentTokens - 1;
    return true;
  }
}
