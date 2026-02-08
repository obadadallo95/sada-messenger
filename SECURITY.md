# Security Documentation

## Overview

**Sada** implements a **"No-Server" Architecture** where all data lives on the device only. This document explains the security architecture, encryption implementation, and Duress Mode logic.

---

## 🏗️ No-Server Architecture

### Zero Data Collection

**Sada** is a **decentralized, offline mesh messenger**. We (the developers) **cannot see, store, or process** any of your messages, contacts, or data.

### What This Means

- **No Central Servers**: All communication happens peer-to-peer via WiFi Direct and Bluetooth LE
- **No Metadata Logs**: Since there are no servers, there are no server logs, connection logs, or metadata trails
- **No Analytics**: We don't track your usage, location, or behavior
- **No Account Information**: User registration is device-bound and offline-only

### Data Storage

- **Local Only**: All data (messages, contacts, keys) is stored locally on your device using **Drift (SQLite)**
- **Encryption Keys**: Your private keys are stored securely in your device's **Android Keystore** (encrypted storage)
- **No Cloud Sync**: There is no cloud backup, sync, or remote storage

---

## 🔐 Encryption Stack

### Library: libsodium (NaCl)

Sada uses **libsodium** via the `sodium_libs` Flutter package for all cryptographic operations.

**Cryptographic Primitives:**
- **Key Exchange**: X25519 (Curve25519)
- **Encryption**: XSalsa20-Poly1305 (authenticated encryption)
- **Hashing**: BLAKE2b

### Key Exchange: X25519

- **Type**: Elliptic Curve Diffie-Hellman (ECDH)
- **Curve**: Curve25519
- **Key Size**: 256 bits (32 bytes)
- **Security Level**: ~128 bits of security

### Message Encryption: XSalsa20-Poly1305

- **Stream Cipher**: XSalsa20 (eXtended Salsa20)
- **MAC**: Poly1305 (authenticated encryption)
- **Nonce Size**: 24 bytes
- **Key Size**: 32 bytes (256 bits)
- **Security**: 128-bit security level

### Shared Secret Derivation

1. **ECDH Key Exchange**: Calculate shared secret using X25519
2. **Blake2b Hashing**: Hash the shared secret to derive session key
3. **Forward Secrecy**: Each session derives a new shared secret

---

## 🛡️ Duress Mode (Plausible Deniability)

### Concept

Duress Mode allows users to enter a **different PIN** that loads a **fake database** with innocent-looking data, protecting real conversations during forced device inspection.

### Architecture

```
┌─────────────────────────────────────┐
│         PIN Entry                   │
│  ┌───────────────────────────────┐ │
│  │  Master PIN: 123456          │ │
│  │  Duress PIN: 999999          │ │
│  └───────────────────────────────┘ │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│    SHA-256 Hash + Salt              │
│  ┌───────────────────────────────┐ │
│  │  Master Hash: abc123...       │ │
│  │  Duress Hash: xyz789...       │ │
│  └───────────────────────────────┘ │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│    AuthService.verifyPin()          │
│  ┌───────────────────────────────┐ │
│  │  Match Master → AuthType.master│ │
│  │  Match Duress → AuthType.duress│ │
│  └───────────────────────────────┘ │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│    Database Selection                │
│  ┌───────────────────────────────┐  │
│  │  Master → sada_encrypted.db  │  │
│  │  Duress → sada_dummy.db       │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Database Separation

- **Master PIN**: Opens `sada_encrypted.sqlite` (real database with actual messages)
- **Duress PIN**: Opens `sada_dummy.sqlite` (dummy database with fake contacts/messages)

### PIN Storage Security

- **Never stored in plain text**: All PINs are hashed with SHA-256
- **Salt**: Unique salt per user (stored in FlutterSecureStorage)
- **Hash Storage**: Hashes stored in FlutterSecureStorage (encrypted)

### Dummy Database Seeding

When Duress Mode is activated for the first time, the dummy database is automatically populated with:
- **Fake Contacts**: "Mom", "Football Group", etc.
- **Innocent Messages**: "Don't forget to buy bread", "Match is at 5 PM"
- **Realistic Timestamps**: Messages appear to be recent

**UI Consistency**: The UI is **identical** in both modes - no visual indicators of Duress Mode.

---

## 📡 Mesh Networking & Zero Metadata

### WiFi Direct (P2P) Communication

Messages are routed through the mesh network:
1. **Encrypted**: Using X25519 + XSalsa20-Poly1305
2. **Routed**: Through other devices in the mesh to reach destination
3. **Not Stored**: Intermediate devices only forward encrypted packets (they cannot decrypt)

### Zero Metadata

Since there are no servers:
- **No Connection Logs**: We don't know who talks to whom
- **No Message Metadata**: We don't know when messages were sent
- **No Location Data**: We don't track device locations
- **No User Profiles**: We don't store user information

### What Intermediate Devices See

- **Encrypted Packets**: Only encrypted data (cannot be read)
- **Routing Information**: Only enough to forward packets (no message content)
- **No Storage**: Messages are not stored on intermediate devices

---

## 🔒 Secure Storage

### FlutterSecureStorage

**Android Configuration:**
- Uses **Android Keystore** for encrypted storage
- Private keys stored securely

**iOS Configuration:**
- Uses **Keychain** with `first_unlock_this_device` accessibility

### What's Stored Securely?

- ✅ **Private Keys**: Curve25519 private keys
- ✅ **PIN Hashes**: Master and Duress PIN hashes
- ✅ **User Credentials**: User ID, display name
- ✅ **Profile Pictures**: Base64 encoded avatars (separate for Master/Duress)

---

## 🔐 Biometric App Lock

- **Library**: `local_auth`
- **Methods**: Fingerprint, Face ID, Iris
- **Storage**: Lock state in SharedPreferences
- **Verification**: Required before enabling/disabling lock

---

## ⚠️ Security Limitations

### What Sada Does NOT Protect You From

1. **Compromised Devices**: If your phone has spyware/malware, Sada cannot protect your inputs
2. **Physical Access & Coercion**: If forced to unlock, Duress Mode helps but is not magic
3. **Metadata & Traffic Analysis**: Active radio signals can be detected by sophisticated adversaries
4. **Social Engineering**: Phishing, trust violations, impersonation
5. **Implementation Bugs**: Sada is in Alpha - has not undergone formal security audit

**See [docs/SECURITY.md](docs/SECURITY.md) for detailed threat model.**

---

## 📋 Security Checklist

- [x] E2E Encryption (XSalsa20-Poly1305)
- [x] Secure Key Exchange (X25519)
- [x] Forward Secrecy (ECDH + Hashing)
- [x] Secure Storage (FlutterSecureStorage)
- [x] Duress Mode (Dual PIN System)
- [x] Biometric Lock
- [x] Device Binding
- [x] No Plain Text PINs
- [x] Secure Random (libsodium)
- [x] No-Server Architecture
- [x] Zero Metadata Collection
- [ ] Security Audit (Planned)
- [ ] Penetration Testing (Planned)

---

## 🔗 References

- [libsodium Documentation](https://doc.libsodium.org/)
- [Signal Protocol](https://signal.org/docs/)
- [Curve25519](https://cr.yp.to/ecdh.html)
- [XSalsa20-Poly1305](https://doc.libsodium.org/secret-key_cryptography/secretbox)
- [Drift Documentation](https://drift.simonbinder.eu/)

---

**Last Updated**: 2025-01-27

