# Transport, Discovery, and Routing

## 1) Discovery (UDP)
- Component: `UdpBroadcastManager`.
- Beacon format: `SADA_DISCOVERY|v1|<peerId>|8888`.
- Broadcast interval: 15 seconds.
- Listeners ignore local self packets.

## 2) Connection Establishment
- TCP port: `8888`.
- Deterministic role rule in background service:
  - Smaller peer ID waits inbound (server-preferred).
  - Larger peer ID attempts outbound connection.
- Cooldown for reconnect attempts per peer/IP key.

## 3) Framed TCP Messaging
- `SocketManager` uses robust framing:
  - Header: 4-byte big-endian payload length.
  - Payload: raw message bytes.
- Maximum payload size guard: 1 MB.
- Receiver buffers partial frames and only emits complete payloads.

## 4) Handshake and Peer Readiness
- `MeshEngine` message types:
  - `HANDSHAKE`
  - `HANDSHAKE_ACK`
- On accepted handshake:
  - Peer added to connected set.
  - Bloom filters exchanged.
  - Pending relay queue sync starts.

## 5) Store-Carry-Forward (DTN)
- Outgoing mesh messages are inserted into `relay_queue`.
- Relay records include:
  - `messageId`
  - `recipientHash` (blind relay privacy)
  - `payload`
  - `expiresAt`
- Relay pump periodically flushes queue to connected peers.

## 6) ACK and Status Lifecycle
- ACK type: `MSG_ACK`.
- On ACK:
  - Message status updated to `delivered`.
  - Relay queue item removed by `messageId`.
  - `ackCleanupCount` increased for diagnostics.

## 7) Media/Voice over Mesh
- Header + chunk protocol (`MediaProtocol`).
- Message assembled from chunk table (`media_chunks`).
- Voice flow supports encrypted bytes + checksum verification.

## 8) Diagnostic Keys to watch
From diagnostics screen/map:
- `isSocketConnected`
- `connectedPeers`
- `handshakeAttempts`
- `handshakeAcks`
- `relayQueueActiveCount`
- `relayFlushedCount`
- `ackCleanupCount`
- UDP: sent/received/lastFromIp/lastError

## 9) Known operational blockers
If messages do not flow, first inspect:
- Discovery seen but socket not connected.
- Socket connected but no handshake ACK.
- Relay queue growing without flush/acks.
- Key mismatch causing decrypt failures.
