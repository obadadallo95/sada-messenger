# 🏗️ Sada — Architecture Overview

> **بنية تحتية رقمية للتواصل المجتمعي — Community Communication Infrastructure**

## المبادئ المعمارية

| المبدأ | الوصف |
|---|---|
| **Reliability First** | الموثوقية أهم من الأمان المفرط — الرسالة يجب أن تصل |
| **Offline-Native** | لا يوجد سيرفر مركزي. كل شيء يعمل محلياً |
| **Battery-Aware** | كل قرار تصميمي يراعي عمر البطارية (الكهرباء مقطوعة) |
| **Range Over Speed** | المدى (LoRa: 5 كم) أهم من سرعة النقل |

---

## طبقات النظام

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                       │
│   Flutter + Riverpod + GoRouter + ScreenUtil     │
├─────────────────────────────────────────────────┤
│                Application Layer                 │
│   ChatController · IncomingMessageHandler        │
│   AuthService · NotificationService              │
├─────────────────────────────────────────────────┤
│                 Network Layer                    │
│   MeshService · HandshakeProtocol                │
│   UdpBroadcastService · EpidemicRouter           │
│   BlobTransferProtocol                           │
├─────────────────────────────────────────────────┤
│               Transport Layer                    │
│   WiFi Direct (TCP/UDP)  ·  LoRa (مخطط)         │
│   SocketManager.kt (Native Android)             │
├─────────────────────────────────────────────────┤
│                Storage Layer                     │
│   Drift (SQLite) · FlutterSecureStorage          │
│   MeshFileProvider (Voice/Binary files)          │
├─────────────────────────────────────────────────┤
│                Security Layer                    │
│   EncryptionService (libsodium)                  │
│   KeyManager · PIN Auth (Argon2id)               │
└─────────────────────────────────────────────────┘
```

---

## شبكة Mesh — كيف تعمل؟

### 1. الاكتشاف (Discovery)
```
Phone A ──UDP broadcast──> WiFi LAN ──> Phone B
         "SADA_DISCOVERY|v1|deviceId|8888"
```
- كل جهاز يبث هويته عبر UDP port 45454
- `DiscoveryStrategy` يُكيّف معدل البث حسب البطارية

### 2. الاتصال (Connection)
```
Phone A ──TCP connect──> Phone B:8888
         ← Handshake (JSON: peerId + publicKey + BloomFilter) →
         ← Handshake ACK →
         [Connected & Ready]
```

### 3. التوجيه (Store-Carry-Forward)
```
Phone A ──msg──> Phone B (not destination)
                Phone B stores msg in RelayQueue
                Phone B walks to new location
                Phone B ──msg──> Phone C (destination!)
```
- **TTL**: 10 hops max
- **Loop Detection**: trace list يمنع إعادة المرور
- **Deduplication**: Bloom Filters + in-memory Set

### 4. LoRa Gateway *(مخطط)*
```
[WiFi Mesh] ←→ [Phone as Gateway] ←→ [LoRa 868MHz] ←→ [Remote Phone/Node]
                                         5 km range
```

---

## قاعدة البيانات

| الجدول | الغرض |
|---|---|
| `contacts` | جهات الاتصال (id, name, publicKey) |
| `chats` | المحادثات (id, peerId, lastUpdated) |
| `messages` | الرسائل (مشفرة at-rest via E2E) |
| `relay_queue` | رسائل الـ Store-Carry-Forward المنتظرة |

---

## البث الصوتي

```
Record (Opus .ogg)
  → Save to local file (MeshFileProvider)
  → Chunk into 64KB pieces (BlobTransferProtocol)
  → Encrypt each chunk reference
  → Send via MeshService
  → Receiver reassembles chunks
  → Play via audioplayers
```

---

## التقنيات والمكتبات

| المكتبة | الاستخدام |
|---|---|
| `sodium_libs` | E2E Encryption (X25519 + XSalsa20) |
| `drift` | SQLite ORM |
| `flutter_riverpod` | State Management |
| `go_router` | Navigation |
| `mobile_scanner` | QR Code scanning |
| `record` | Audio recording (Opus) |
| `audioplayers` | Audio playback |
| `flutter_secure_storage` | Key storage |
