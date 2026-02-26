# 🔒 Security & Privacy Features

## Mesh Network Privacy Protection

This document describes the security and privacy features implemented to protect user privacy in the Mesh Network.

---

## 1. Anonymous Discovery 🔍

### Problem
When devices advertise their presence via WiFi P2P, they broadcast their real device names (e.g., "Obada's Phone"), which exposes user identity.

### Solution
- **DiscoveryService** (`lib/core/network/discovery_service.dart`):
  - Generates a randomized `ServiceId` (format: `SADA-XXXX-XXXX-XXXX`)
  - Stores ServiceId securely using `FlutterSecureStorage`
  - ServiceId is generated once and reused (can be reset periodically)

### Implementation
- **MeshPeer** (`lib/core/network/mesh_channel.dart`):
  - `_anonymizeDeviceName()` method hides real device names
  - Shows only "Unknown Peer" or ServiceId (if starts with "SADA-")
  - Real names are never exposed to other devices

### UI Impact
- Radar/Peer Count shows only the **number** of nodes
- Generic labels like "Unknown Peer" instead of real names
- No user identity exposure

---

## 2. Contact Whitelisting ✅

### Problem
Without filtering, users could receive messages from random strangers, leading to spam and privacy violations.

### Solution
**Strict Anti-Spam Policy (Option A)**:
- Messages are **only accepted** from contacts in the local `ContactsDatabase`
- Messages from unknown senders are **silently dropped**
- No "Message Requests" folder (maximum privacy)

### Implementation
**IncomingMessageHandler** (`lib/core/network/incoming_message_handler.dart`):
```dart
// Step 1: Check if sender is in Contacts
final contact = await database.getContactById(senderId);
if (contact == null) {
  // Silently drop - Anti-Spam
  return;
}

// Step 2: Check if sender is blocked
if (contact.isBlocked) {
  // Silently drop
  return;
}

// Step 3: Only then process the message
```

### Security Flow
1. **Message Received** → Parse `senderId` from header
2. **Contact Check** → Query `ContactsDatabase`
3. **If Contact** → Decrypt & Show Notification
4. **If NOT Contact** → Silently Drop (Anti-Spam)

---

## 3. Blind Relay 🔐

### Problem
Relay nodes (intermediate devices) could potentially read message content, violating end-to-end encryption principles.

### Solution
**Blind Relay Implementation**:
- Relay nodes only look at **header metadata** (destination ID, hop count, trace)
- **Payload (encryptedContent) remains encrypted** and is never decrypted by relays
- Relays act as "dumb pipes" - they forward packets without seeing content

### Implementation
**MeshService._storeAndForward()** (`lib/core/network/mesh_service.dart`):
```dart
// 🔒 BLIND RELAY SECURITY:
// - Relay nodes only look at header (destination ID) for routing
// - encryptedContent is NOT decrypted in Relay
// - Relay cannot read message content - only forward it

await database.enqueueRelayMessage(
  RelayQueueTableCompanion.insert(
    messageId: meshMessage.messageId,           // Header
    originalSenderId: meshMessage.originalSenderId,  // Header
    finalDestinationId: meshMessage.finalDestinationId, // Header
    encryptedContent: meshMessage.encryptedContent,  // 🔒 Encrypted - Blind to us
    // ... other header fields
  ),
);
```

### Security Guarantees
- ✅ Relay nodes cannot read message content
- ✅ Only destination can decrypt (has recipient's private key)
- ✅ End-to-end encryption preserved
- ✅ Privacy maintained even through multiple hops

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Mesh Network Security                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [Device A] ──[Encrypted]──> [Relay 1] ──[Encrypted]──>   │
│     │                            │                           │
│     │ (Can Decrypt)              │ (Blind - Only Routes)     │
│     │                            │                           │
│     └────────────────────────────┴──> [Relay 2] ──>         │
│                                          │                    │
│                                          │ (Blind)            │
│                                          │                    │
│                                          └──> [Device B]     │
│                                               │               │
│                                               │ (Can Decrypt) │
│                                               │               │
└─────────────────────────────────────────────────────────────┘

Security Layers:
1. Anonymous Discovery (ServiceId)
2. Contact Whitelisting (Anti-Spam)
3. Blind Relay (End-to-End Encryption)
```

---

## Privacy Rules Summary

| Rule | Implementation | Status |
|------|---------------|--------|
| **No Real Names Broadcast** | DiscoveryService + MeshPeer anonymization | ✅ |
| **Contact Whitelisting** | IncomingMessageHandler contact check | ✅ |
| **Blind Relay** | MeshService only reads header, not payload | ✅ |
| **Silent Drop (Anti-Spam)** | Unknown senders rejected silently | ✅ |
| **End-to-End Encryption** | Only destination can decrypt | ✅ |

---

## Future Enhancements

1. **Periodic ServiceId Rotation**: Change ServiceId every 24 hours
2. **Message Requests Folder**: Optional folder for unknown senders (if user wants)
3. **Reputation System**: Track relay behavior without exposing content
4. **UDP Broadcasting**: Add local network broadcasting with privacy protection

---

## Testing Checklist

- [ ] Verify ServiceId is generated and stored securely
- [ ] Verify real device names are hidden in MeshPeer
- [ ] Verify messages from unknown senders are dropped
- [ ] Verify blocked contacts cannot send messages
- [ ] Verify relay nodes cannot decrypt message content
- [ ] Verify only destination can decrypt messages
- [ ] Verify UI shows only peer count, not names

---

**Last Updated**: 2024
**Security Level**: High 🔒

