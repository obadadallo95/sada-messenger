# 🚀 Transport & Discovery Layer

## Overview

The Transport & Discovery Layer is the "Nervous System" of Sada Mesh Network. It handles:
- **UDP Broadcasting** for local WiFi LAN discovery
- **Battery-Aware Discovery** with dynamic intervals
- **Secure Handshake Protocol** for peer identification
- **Connection Management** with automatic RelayQueue flushing

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Transport & Discovery Layer                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐    ┌──────────────────┐             │
│  │ UDP Broadcast    │───▶│ Discovery        │             │
│  │ Service          │    │ Strategy         │             │
│  └──────────────────┘    └──────────────────┘             │
│         │                          │                        │
│         │                          │                        │
│         ▼                          ▼                        │
│  ┌──────────────────────────────────────────┐              │
│  │         MeshService                        │              │
│  │  - connectToPeer()                        │              │
│  │  - initializeTransportLayer()            │              │
│  └──────────────────────────────────────────┘              │
│         │                                                   │
│         ▼                                                   │
│  ┌──────────────────┐                                       │
│  │ Handshake        │                                       │
│  │ Protocol         │                                       │
│  └──────────────────┘                                       │
│         │                                                   │
│         ▼                                                   │
│  ┌──────────────────┐                                       │
│  │ flushRelayQueue │                                       │
│  └──────────────────┘                                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. UDP Broadcast Service (`lib/core/network/discovery/udp_broadcast_service.dart`)

**Purpose**: Discover devices on the same WiFi LAN (even without internet).

**Features**:
- Broadcasts UDP packets every N seconds to `255.255.255.255:45454`
- Listens on Port `45454` for incoming broadcasts
- Payload format: `SADA_DISCOVERY|v1|DeviceId|Port`
- Only runs when WiFi is connected

**Methods**:
- `start({int intervalSeconds})`: Start UDP service
- `stop()`: Stop UDP service
- `updateInterval(int intervalSeconds)`: Update broadcast interval
- `_sendBroadcast()`: Send UDP broadcast packet
- `_handleIncomingBroadcast()`: Process incoming UDP packets

**Platform Channel**: `org.sada.messenger/udp`
- `startUdpService`: Start UDP listener
- `stopUdpService`: Stop UDP service
- `sendBroadcast`: Send UDP broadcast
- `isWifiConnected`: Check WiFi status

---

### 2. Discovery Strategy (`lib/core/power/discovery_strategy.dart`)

**Purpose**: Battery-Aware discovery intervals based on power mode and app state.

**Intervals**:
- **Performance Mode**: 5 seconds (foreground + charging)
- **Balanced Mode**: 60 seconds (default background)
- **Low Power Mode**: 5-10 minutes (battery < 15%)

**Factors**:
- PowerMode (Performance/Balanced/Low Power)
- App Lifecycle (Foreground/Background)
- Battery Level (< 15% = Low Power)
- Charging Status (Charging = Performance)

**Methods**:
- `updateStrategy()`: Update discovery interval
- `updateBatteryStatus()`: Get battery level from native
- `updateAppLifecycle()`: Update foreground/background state
- `updatePowerMode()`: Update power mode

---

### 3. Handshake Protocol (`lib/core/network/protocols/handshake_protocol.dart`)

**Purpose**: Secure peer identification before accepting messages.

**Flow**:
1. **Client Side**: Send `HANDSHAKE` message immediately on connection
2. **Server Side**: Validate `peerId`, check Contacts database
3. **Server Side**: Reply with `HANDSHAKE_ACK` (ACCEPTED/REJECTED)
4. **Client Side**: Process ACK, complete handshake
5. **Post-Handshake**: Trigger `flushRelayQueue(peerId)`

**Message Format**:
```json
{
  "type": "HANDSHAKE",
  "peerId": "device-id",
  "publicKey": "base64-encoded-public-key",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

**Security**:
- Only contacts in `ContactsDatabase` are accepted
- Unknown peers are rejected (Anti-Spam)
- Public keys are updated if changed

**Methods**:
- `createHandshakeMessage()`: Create handshake JSON
- `processIncomingHandshake()`: Validate and respond
- `processHandshakeAck()`: Verify acceptance

---

### 4. MeshService Integration (`lib/core/network/mesh_service.dart`)

**New Methods**:
- `initializeTransportLayer()`: Initialize all discovery components
- `connectToPeer(ip, port, deviceId)`: Connect with handshake
- `_handleIncomingHandshake()`: Process handshake (server)
- `_handleHandshakeAck()`: Process ACK (client)
- `_completeHandshake()`: Complete handshake + flush queue
- `updateDiscoveryInterval()`: Update UDP broadcast interval

**Connection Flow**:
```
1. UDP Broadcast received
   ↓
2. connectToPeer(ip, port, deviceId)
   ↓
3. TCP Socket connection
   ↓
4. Send HANDSHAKE message
   ↓
5. Receive HANDSHAKE_ACK
   ↓
6. _completeHandshake()
   ↓
7. flushRelayQueue(peerId) 🔥
```

---

## Integration Points

### App Initialization (`lib/app.dart`)
```dart
// تهيئة Transport & Discovery Layer
final meshService = ref.read(meshServiceProvider);
await meshService.initializeTransportLayer();
```

### Battery Mode Changes
```dart
// تحديث Discovery Interval عند تغيير PowerMode
final strategy = ref.read(discoveryStrategyProvider);
strategy.updatePowerMode(newMode);
meshService.updateDiscoveryInterval(strategy.currentInterval);
```

### App Lifecycle
```dart
// تحديث Discovery Interval عند تغيير App State
strategy.updateAppLifecycle(isForeground);
meshService.updateDiscoveryInterval(strategy.currentInterval);
```

---

## Native Implementation (Android)

### Required Methods in MainActivity.kt

**UDP Service**:
- `startUdpService`: Start UDP listener on port 45454
- `stopUdpService`: Stop UDP service
- `sendBroadcast`: Send UDP broadcast packet
- `isWifiConnected`: Check WiFi connection status

**Event Channel**: `org.sada.messenger/udpEvents`
- Emit events: `{"payload": "...", "ip": "..."}`

**TODO**: Implement native UDP socket handling in Kotlin.

---

## Testing Checklist

- [ ] UDP Broadcast sends packets every N seconds
- [ ] UDP Listener receives broadcasts from other devices
- [ ] Discovery Strategy updates interval based on battery
- [ ] Handshake Protocol validates contacts
- [ ] Handshake ACK triggers flushRelayQueue
- [ ] Unknown peers are rejected
- [ ] Connection only established after handshake
- [ ] RelayQueue flushed after successful handshake

---

## Future Enhancements

1. **Native UDP Implementation**: Full UDP socket handling in Kotlin
2. **Network State Monitoring**: Listen to WiFi state changes
3. **Service Discovery (NSD/Bonjour)**: Use native discovery protocols
4. **BLE Discovery**: Add Bluetooth Low Energy for proximity discovery
5. **Connection Pooling**: Manage multiple simultaneous connections
6. **Connection Retry Logic**: Automatic retry for failed connections

---

**Last Updated**: 2024
**Status**: ✅ Flutter Layer Complete | ⏳ Native Implementation Pending

