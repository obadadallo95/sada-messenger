# Security and Privacy Model

## 1) Identity and Key Management
- `KeyManager` generates Curve25519 keypairs using libsodium (`cryptoBoxKeypair`).
- Keypairs are stored in `EncryptedSharedPreferences`.
- Public key base64 is used as mesh identity.

## 2) End-to-End Encryption
- `EncryptionManager` derives shared session key via:
  1. ECDH (`cryptoScalarMult`) between local private key and remote public key.
  2. Blake2b key derivation with context string.
- Payload encryption:
  - `cryptoSecretBoxEasy` (XSalsa20-Poly1305).
  - Nonce + ciphertext payload.
- Decryption enforces MAC verification.

## 3) Group Security
- Group messages use shared symmetric group key (`groupKey`) stored per chat.
- Encryption/decryption performed with shared key path in `EncryptionManager`.

## 4) Blind Relay Privacy
- Relay queue stores `recipientHash = SHA-256(finalDestinationId)`.
- Intermediary nodes carry encrypted payloads without plaintext visibility.

## 5) App Lock and PIN
- `AppSecuritySettings` stores app-lock settings in encrypted preferences.
- PIN constraints: exactly 6 digits.
- Hashing: PBKDF2-HMAC-SHA256, 120k iterations, salted.

## 6) Notification Privacy
- Incoming message and SOS notifications are handled by `SadaNotificationManager`.
- Notification permission is checked explicitly on Android 13+.

## 7) Android Permission Surface
Key declared permissions include:
- Camera, record audio, notifications.
- Bluetooth scan/connect/advertise.
- Nearby Wi-Fi, location.
- Wake lock and battery optimization exemption.
- Foreground service types for long-running mesh behavior.

## 8) Threats and Hardening Priorities
- Enforce strict fail-closed behavior when recipient key is missing.
- Add brute-force lockout/backoff to PIN verification flow.
- Keep all debug logging free of plaintext sensitive content in release builds.
