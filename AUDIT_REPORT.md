# Security & Stability Audit Report: Sada Mesh Messenger

**Date:** October 26, 2023
**Auditor:** Jules (Principal Systems Engineer)

## 1. Executive Summary

A comprehensive technical audit of the Sada Mesh Messenger codebase was conducted, focusing on the critical areas of concurrency, binary integrity, memory management, protocol vulnerabilities, and logic flaws.

**Overall Status:** Significantly Improved. Critical vulnerabilities related to memory exhaustion (OOM) and potential buffer overflows have been addressed. Rate limiting has been introduced to mitigate flooding attacks.

## 2. Findings & remediation

### 2.1 Binary Integrity & Buffer Overflows (Critical)

**Finding:** The `SocketManager.kt` implementation for processing incoming frames used a `ByteArrayOutputStream` that could grow indefinitely if a malicious peer sent a stream of bytes without a valid header or with a large claimed size. This posed a high risk of Denial of Service (DoS) via Out-Of-Memory (OOM) crash. Additionally, the frame parsing loop performed excessive memory copying (`toByteArray()` inside the loop).

**Fix Applied:**
-   Introduced `MAX_BUFFER_SIZE_BYTES` (2 MB) constant.
-   Added a strict check in `processIncomingFrames` to disconnect if the buffer exceeds this limit.
-   Optimized the loop to remove unnecessary memory allocations and copying.

### 2.2 Memory Management: Blob Reassembly (High)

**Finding:** The `BlobReassembler` (in `blob_transfer_protocol.dart`) stored all chunks in memory without a limit on the total size or the number of concurrent sessions. A malicious or buggy peer could initiate multiple large transfers (e.g., 5 peers sending 100MB files), causing the application to crash due to OOM. There was also no cleanup mechanism for incomplete transfers.

**Fix Applied:**
-   **Concurrent Session Limit:** Capped at 5 concurrent reassembly sessions.
-   **Total Memory Limit:** Capped at 50 MB total usage across all sessions.
-   **Session Pruning:** Implemented `pruneStale()` to remove sessions inactive for more than 30 seconds.
-   **Chunk Validation:** Added a check for `totalChunks` to prevent allocation attacks (max ~128MB per file).

### 2.3 Protocol Vulnerabilities: Flooding (Medium)

**Finding:** The `MeshService` processed every incoming message and stored it in the `RelayQueue` (SQLite) without any rate limiting. An unauthenticated peer could flood the network with thousands of messages, bloating the database and consuming CPU/Battery.

**Fix Applied:**
-   **Traffic Policing:** Implemented a Token Bucket algorithm (`_TrafficPolice`) in `MeshService.dart`.
-   **Rate Limit:** Configured to allow ~300 messages/minute with a burst capacity of 50. Excess messages are dropped with a warning log.

### 2.4 Concurrency & Race Conditions (Medium)

**Finding:** The interaction between the Background Isolate (Mesh Engine) and the Main UI Thread appears generally safe due to the use of Flutter's `MethodChannel` and `EventChannel`, which serialize communication. However, the `SocketManager` runs network I/O on `Dispatchers.IO`.

**Analysis:**
-   `EventChannel` sinks are thread-safe in the sense that Flutter handles the message posting to the main thread loop.
-   The "smaller ID acts as server" rule in `MeshService` is deterministic but relies on both peers seeing each other's ID correctly. The fallback logic (`_attemptClientFallbackConnect`) handles cases where the rule might be ambiguous temporarily.
-   **Recommendation:** No critical race conditions were found in the reviewed paths, but continued monitoring of the `_connectedPeers` set access (which is guarded by the main isolate's single-threaded nature in Dart) is recommended.

### 2.5 Logic Flaws: Role Selection (Low)

**Finding:** The role selection logic (`myDeviceId.compareTo(deviceId) < 0`) is sound for unique IDs. The potential edge case is if `myDeviceId` is reset or spoofed.

**Analysis:**
-   The fallback mechanism (`_attemptClientFallbackConnect`) provides resilience if the primary role selection fails (e.g., firewall issues or timing).
-   **Recommendation:** Ensure `myDeviceId` persistence is robust (which `AuthService` seems to handle).

## 3. Code-Level Hardening Summary

| File | Change | Impact |
| :--- | :--- | :--- |
| `SocketManager.kt` | Added `MAX_BUFFER_SIZE_BYTES` check | Prevents Native OOM crashes |
| `blob_transfer_protocol.dart` | Added `BlobReassemblyManager` limits (5 sessions, 50MB) | Prevents Dart Heap OOM |
| `blob_transfer_protocol.dart` | Added `pruneStale()` | Prevents memory leaks from dropped transfers |
| `mesh_service.dart` | Added `_TrafficPolice` (Token Bucket) | Prevents DB bloating & CPU exhaustion |

## 4. Future Recommendations

1.  **File-Based Reassembly:** For very large files (>100MB), move `BlobReassembler` to use `RandomAccessFile` (disk) instead of RAM.
2.  **Authenticated Handshake:** Currently, the handshake exchanges IDs. Implementing a challenge-response mechanism using the `libsodium` keys would prevent ID spoofing.
3.  **Relay Queue Quotas:** Implement a per-peer quota for `RelayQueue` storage (e.g., max 10MB per peer) to ensure fair usage of the store-carry-forward buffer.

---
**Audit Status:** COMPLETE
**Verdict:** The system is now significantly more resilient to stress and abuse.
