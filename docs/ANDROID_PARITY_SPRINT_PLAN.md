# Sada Android Native Parity Sprint (v1)

## Goal
Establish a reliable Android-native core that matches the legacy Flutter behavior before further UI expansion.

## Source of Truth
- Legacy reference: `/Users/obadadallo/Desktop/sada/legacy-flutter/lib`
- Native target: `/Users/obadadallo/Desktop/sada/app/src/main/kotlin`

## Current Status
- UI polish in Compose is strong.
- Core parity is incomplete in transport, handshake policy, message delivery path, and security model parity.

## P0 (Must complete first)
1. Direct message path must be fully wired end-to-end.
   - Owner: `ChatViewModel`, `MeshEngine`.
   - Done criteria:
     - `sendMessage()` reaches transport path.
     - Status transitions: `sending -> sent|failed`.
2. Discovery + connection lifecycle must be deterministic.
   - Owner: `MainActivity`, `UdpBroadcastManager`, `SocketManager`, `MeshEngine`.
   - Done criteria:
     - UDP listener started from app bootstrap.
     - periodic broadcast heartbeat is running.
     - peer discovery feeds connect attempts.
3. Handshake policy must allow first-contact bootstrap.
   - Owner: `MeshEngine`.
   - Done criteria:
     - Unknown peers are not permanently deadlocked.
     - Handshake metrics expose attempts/timeouts/acks.
4. Database safety must be production-safe.
   - Owner: `AppDatabase`.
   - Done criteria:
     - remove `fallbackToDestructiveMigration()`.
     - add explicit migration path.
5. Diagnostic truthfulness.
   - Owner: `MeshDiagnosticsScreen`, `MeshEngine`.
   - Done criteria:
     - no mock counters where transport status is shown.

## P1 (Core parity)
1. Duress parity:
   - Implement dual-database decoy mode parity with legacy behavior.
2. Auth hardening parity:
   - PIN KDF + lockout/backoff parity.
3. Background survivability:
   - Foreground service + restart policy parity for DTN workloads.
4. Message lifecycle parity:
   - Pending / Relayed / Delivered / Failed rendered from real state.

## P2 (After core parity)
1. Design refinement and polish.
2. Feature expansion (voice/video optimization, LoRa improvements, advanced caching).

## Working Rules
1. No new mock data in production screens.
2. Every UI state must map to real data source.
3. Every transport/security change must include diagnostic field updates.
4. Every P0/P1 item requires at least one integration test.

