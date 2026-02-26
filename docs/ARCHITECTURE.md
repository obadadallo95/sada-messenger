# Sada Architecture (Android Native)

## 1) High-Level Layers

```mermaid
flowchart TD
    UI["Jetpack Compose UI"] --> VM["ViewModels"]
    VM --> DB["Room DAOs / Entities"]
    VM --> ME["MeshEngine"]
    ME --> SM["SocketManager (TCP framed)"]
    ME --> UDP["UdpBroadcastManager (discovery)"]
    ME --> CRYPTO["EncryptionManager + KeyManager"]
    ME --> NOTIF["SadaNotificationManager"]
    SVC["MeshForegroundService"] --> UDP
    SVC --> SM
```

## 2) Core Components

### `MainActivity`
- App bootstrap and dependency wiring.
- Builds NavHost and top-level routes.
- Initializes DB, key management, mesh engine, and services.
- Applies locale, RTL/LTR direction, app lock flow, and theme mode.

### `MeshEngine`
- Canonical message transport/routing logic.
- Handshake handling (`HANDSHAKE`, `HANDSHAKE_ACK`).
- Store-Carry-Forward queue management.
- Message ACK processing and status updates.
- Media and voice chunked transfer/reassembly.
- Diagnostics counters (relay active/flushed/ack cleanup, handshake stats).

### `SocketManager`
- Reliable TCP read/write layer.
- 4-byte big-endian frame prefix + payload.
- Server and client modes.
- Read loop and status callbacks.

### `UdpBroadcastManager`
- UDP broadcast discovery on LAN.
- Sends discovery beacons and listens for peers.
- Maintains diagnostics (sent/received/last error/last sender).

### `MeshForegroundService`
- Persistent background runner for mesh discovery/connectivity.
- Foreground notification with controls (Pause/Resume/Stop).
- Keeps mesh alive after app UI is closed.

## 3) Data Layer

Room database (`AppDatabase`, version 8):
- `contacts`
- `chats`
- `messages` (indexed by `chatId`, `timestamp`)
- `relay_queue`
- `group_members`
- `group_join_requests`
- `media_chunks`

Migrations are explicitly implemented (1..7 -> 7 and 7 -> 8), avoiding destructive resets for production upgrade paths.

## 4) Runtime Route Map

Registered routes (NavHost):
- `onboarding`
- `register`
- `home`
- `chats`
- `groups`
- `settings`
- `settings/about`
- `settings/privacy`
- `settings/terms`
- `my_qr`
- `create_group`
- `contacts`
- `chat/{chatId}`
- `diagnostics`
- `crisis_report/{chatId}`

## 5) Architectural Principles
- Offline-first behavior.
- Fail-closed on cryptographic path errors where possible.
- Diagnostics-first engineering for field troubleshooting.
- UI truthfulness: real transport/db state, not static placeholders.
