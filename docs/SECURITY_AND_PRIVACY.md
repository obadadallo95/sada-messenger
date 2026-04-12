# 🔐 Security & Privacy Model — Sada Messenger

> *"No server. No tracking. No compromise."*
> *"لا خادم. لا تتبع. لا تنازل."*

***

## Threat Model / نموذج التهديد

Sada is designed to protect users against:

| Threat | Protection |
|---|---|
| Network surveillance (ISP, government) | All traffic is E2E encrypted — no plaintext ever leaves the device |
| Server breach | No server exists — there is nothing to breach |
| Man-in-the-middle attack | ECDH key exchange + message signing prevents MITM |
| Physical device access | Android Keystore (TEE/StrongBox) + app lock with PIN |
| Relay node eavesdropping | Blind relay — nodes carry encrypted blobs, never plaintext |
| Replay attacks | Unique nonce per message + TTL enforcement |
| Brute-force PIN | PBKDF2-HMAC-SHA256 with 120,000 iterations + lockout |

***

## Cryptographic Stack / طبقة التشفير

### Key Generation & Exchange
- **Algorithm**: ECDH (Curve25519 / X25519)
- **Key Storage**: Android Keystore — hardware-backed (StrongBox or TEE when available)
- **Identity**: Public key (base64) used as mesh identity — no phone number or email required
- **Forward Secrecy**: New session keys derived per conversation

### Message Encryption
- **Algorithm**: AES-256-GCM
- **IV**: Randomly generated per message (never reused)
- **Integrity**: GCM authentication tag — tamper detection built-in
- **Signing**: Ed25519 message signing for sender verification

### Key Derivation
- **Function**: Blake2b with context string
- **PIN Hashing**: PBKDF2-HMAC-SHA256, 120,000 iterations, random salt

### Group Security
- Shared symmetric group key per group
- Key rotation on member leave/kick
- Admin-controlled key distribution

***

## Relay Privacy / خصوصية التمرير

Sada uses **blind relay** — intermediary nodes that forward messages without being able to read them:

```
Sender                    Relay Node                  Recipient
  │                           │                           │
  │  encrypt(msg, recipient)  │                           │
  │──────────────────────────►│                           │
  │                           │  forward(encrypted_blob)  │
  │                           │──────────────────────────►│
  │                           │                           │ decrypt(msg)
```

- Relay queue stores: `recipientHash = SHA-256(destinationId)` — not the ID itself
- Relay nodes **cannot** read message content
- Relay nodes **cannot** identify the final recipient
- TTL: 24 hours — messages expire and are deleted automatically

***

## App Lock & Device Security / قفل التطبيق

| Feature | Implementation |
|---|---|
| PIN lock | 6-digit PIN, PBKDF2-SHA256, salted |
| Biometric | Android BiometricPrompt API |
| Auto-lock | Configurable timeout |
| Brute-force protection | Progressive lockout (to be enforced) |
| Screen security | FLAG_SECURE — prevents screenshots in recent apps |

***

## Android Permission Analysis / تحليل الأذونات

Every permission Sada requests has a specific, minimal justification:

| Permission | Why it's needed | Can user deny? |
|---|---|---|
| BLUETOOTH_SCAN | Discover nearby mesh peers | ❌ Core feature |
| BLUETOOTH_CONNECT | Establish peer connections | ❌ Core feature |
| BLUETOOTH_ADVERTISE | Make device discoverable to peers | ❌ Core feature |
| ACCESS_WIFI_STATE | LAN/UDP peer discovery | ❌ Core feature |
| CAMERA | QR code scanning for contact add | ✅ Optional |
| RECORD_AUDIO | Voice messages | ✅ Optional |
| POST_NOTIFICATIONS | Message alerts (Android 13+) | ✅ Optional |
| FOREGROUND_SERVICE | Keep mesh alive in background | ❌ Core feature |
| REQUEST_IGNORE_BATTERY | Prevent OS from killing mesh service | ❌ Core feature |

***

## Known Limitations & Hardening Roadmap / القيود المعروفة

### Current Limitations
- Group key rotation on member leave: **planned, not yet implemented**
- PIN brute-force lockout: **partial implementation**
- Panic wipe (emergency data deletion): **in v2.0 roadmap**

### Security Hardening Priorities (v2.0)
- [ ] Enforce brute-force lockout/backoff on PIN verification
- [ ] Implement group key rotation on kick/leave
- [ ] Add panic button for emergency data wipe
- [ ] Ensure release builds strip all sensitive debug logs
- [ ] Third-party security audit (goal for public release)

***

## Open Source Security / أمان المصدر المفتوح

Sada is **fully open source** under GPL v3. This means:
- Anyone can audit the cryptographic implementation
- No hidden backdoors are possible
- Community can verify all privacy claims
- Security researchers can report vulnerabilities

> To report a security vulnerability, please email: **security@sada-messenger.org**
> لإبلاغ عن ثغرة أمنية: **security@sada-messenger.org**
