# Sada Android Native - Feature Parity Matrix

## Objective
Deliver Android Native with full functional parity to `legacy-flutter` before adding new UI-only enhancements.

Reference:
- Legacy Flutter: `/Users/obadadallo/Desktop/sada/legacy-flutter/lib`
- Native Android: `/Users/obadadallo/Desktop/sada/app/src/main/kotlin`

Status labels:
- `DONE`: Functional and verified in native.
- `PARTIAL`: Exists but missing critical behavior.
- `MISSING`: Not implemented.

---

## A) Core Transport & Mesh

1. UDP Discovery (broadcast/listen)
- Legacy: `legacy-flutter/lib/core/network/discovery/udp_broadcast_service.dart`
- Native: `app/src/main/kotlin/org/sada/messenger/managers/UdpBroadcastManager.kt`, `MainActivity.kt`
- Status: `PARTIAL`
- Gap: discovery exists but needs stable peer session establishment proof.

2. TCP framed transport (4-byte length prefix)
- Legacy: Flutter+native bridge stack
- Native: `app/src/main/kotlin/org/sada/messenger/SocketManager.kt`
- Status: `DONE` (framing present)
- Gap: verify in two-device tests with reconnect scenarios.

3. Handshake + Peer Ready state
- Legacy: `legacy-flutter/lib/core/network/protocols/handshake_protocol.dart`
- Native: `app/src/main/kotlin/org/sada/messenger/network/MeshEngine.kt`
- Status: `PARTIAL`
- Gap: first-contact policy and accepted peer lifecycle need strict verification.

4. Store-Carry-Forward (Epidemic fanout + relay queue)
- Legacy: `legacy-flutter/lib/core/network/mesh_service.dart`
- Native: `app/src/main/kotlin/org/sada/messenger/network/MeshEngine.kt`
- Status: `PARTIAL`
- Gap: fanout and retry behavior need end-to-end validation with metrics.

5. ACK path + delivery status updates
- Legacy: full message status loop
- Native: `MeshEngine.handleMessageAck`, DB status updates
- Status: `PARTIAL`
- Gap: delivery counters and message tick-state parity not fully proven.

---

## B) Security & Privacy

1. E2E encryption with libsodium ECDH
- Legacy: `legacy-flutter/lib/core/security/encryption_service.dart`
- Native: `app/src/main/kotlin/org/sada/messenger/security/EncryptionManager.kt`
- Status: `DONE` (base mechanism present)
- Gap: full chat pipeline and failure behavior parity.

2. Fail-closed messaging when recipient key missing
- Legacy: strict fail-closed behavior
- Native: `ChatViewModel.kt`
- Status: `DONE` (implemented)
- Gap: UX feedback to user for failed state.

3. Duress mode (decoy DB model)
- Legacy: dual-database behavior
- Native: `DuressManager.kt` wipe-only
- Status: `MISSING`
- Gap: native currently has wipe-only emergency mode, not decoy mode parity.

4. PIN hardening + lockout/backoff
- Legacy: strong KDF + lockout
- Native: no parity yet
- Status: `MISSING`

---

## C) Database & Data Safety

1. Message/relay indexing + retention
- Legacy: tuned Drift tables/migrations
- Native: Room entities/DAO present
- Status: `PARTIAL`
- Gap: retention, cleanup, queue pressure controls.

2. Safe migrations
- Legacy: versioned migrations
- Native: `fallbackToDestructiveMigration()`
- Status: `MISSING`
- Gap: destructive migration must be removed and replaced with explicit migrations.

---

## D) UI/UX Truthfulness

1. Settings screen actions
- Native status: `PARTIAL -> IN PROGRESS`
- Implemented: diagnostics, my QR, battery optimization action.
- Remaining: unlock features only when functional.

2. Home/Groups: no mock data
- Native files: `HomeScreen.kt`, `GroupsScreen.kt`
- Status: `MISSING`
- Gap: relay counts, nearby groups, join actions still mocked/placeholders.

3. Message state icons (pending/relayed/delivered/failed/read)
- Legacy has richer status semantics
- Native status: `PARTIAL`
- Gap: full state mapping in Compose chat UI.

---

## E) Background Reliability

1. Foreground service lifecycle
- Legacy: stronger DTN-oriented background stack
- Native: permissions present, service lifecycle parity not complete
- Status: `PARTIAL`

---

## Sprint Execution Order (Mandatory)

### Sprint P0 (stability first)
1. Transport session establishment proof (2 devices, repeatable).
2. Handshake acceptance + peer-ready stabilization.
3. ACK + delivered state proof.
4. Remove destructive DB migration.

### Sprint P1 (security parity)
1. Duress decoy DB parity.
2. PIN hardening + lockout/backoff parity.

### Sprint P2 (UX parity)
1. Remove mock values in Home/Groups.
2. Full message-state UI parity.
3. Settings feature unlock by capability flags.

---

## Acceptance Gates (DoD)
No item is marked `DONE` unless:
1. Implemented in native code.
2. Visible in UI without mock placeholders.
3. Verified on two physical devices.
4. Diagnostic screen shows coherent state transitions.
