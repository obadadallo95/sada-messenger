# Sada Field Go/No-Go Checklist

Status date: 2026-02-26
Owner: Core Engineering
Decision state: **NO-GO** (Pilot only)

## Gate Policy
- PASS: requirement verified عملياً على جهازين أو أكثر.
- FAIL: requirement غير محقق أو ثبت فشله.
- BLOCKED: يحتاج بيانات ميدانية/اختبار لم يكتمل بعد.

---

## A) Transport & Mesh Reliability (Critical)

1. UDP discovery on both devices (send/receive counters increase)
- Status: **PASS**
- Evidence: Diagnostics previously showed `udp_sentCount`/`udp_receivedCount` moving.

2. TCP socket connection established after discovery
- Status: **BLOCKED**
- Reason: observed intermittent states (`discovered` without stable session).

3. Handshake completion to PeerReady state
- Status: **FAIL**
- Reason: repeated field reports with `socketConnected` but `readyPeers: []`.

4. Connected peers UI reflects only verified ready peers
- Status: **BLOCKED**
- Reason: needs final live validation after transport stabilization.

5. Automatic relay queue flush after handshake completion
- Status: **BLOCKED**
- Reason: depends on Gate #3 completion.

6. ACK round-trip updates message status to delivered
- Status: **BLOCKED**
- Reason: needs deterministic two-device run (send -> ack -> delivered).

7. Duplicate suppression and queue cleanup work under retries
- Status: **BLOCKED**
- Reason: no final stress test evidence.

---

## B) Security & Privacy (Critical)

8. E2E key agreement uses libsodium ECDH path (no plaintext fallback)
- Status: **PASS**
- Evidence: `EncryptionManager.calculateSharedSecret`, encrypted send paths exist.

9. Missing recipient key fails closed (no plaintext send)
- Status: **PASS**
- Evidence: chat/voice send paths enforce key presence.

10. Relay privacy (recipient hash, opaque payload)
- Status: **PASS**
- Evidence: `relay_queue.recipientHash` + encrypted payload.

11. PIN security (KDF + exact 6 digits)
- Status: **PASS**
- Evidence: PBKDF2-HMAC-SHA256, 120k iterations, strict 6-digit validation.

12. Brute-force lockout/backoff implemented
- Status: **FAIL**
- Reason: no active retry throttling/lockout counters in current auth flow.

---

## C) Background Survivability (Critical)

13. Foreground service persistent with notification controls
- Status: **PASS**
- Evidence: `MeshForegroundService` with Pause/Resume/Stop actions.

14. App keeps mesh running after UI close
- Status: **BLOCKED**
- Reason: needs long-run OEM/Doze validation (2-4 hours real device test).

15. Service restart behavior after task removal
- Status: **PASS**
- Evidence: `onTaskRemoved` schedules service restart.

---

## D) Data Integrity & Migrations (High)

16. Room migrations safe for updates (no destructive fallback)
- Status: **PASS**
- Evidence: explicit migrations to schema v8 in `AppDatabase`.

17. Message history never deleted by transport cleanup path
- Status: **BLOCKED**
- Reason: requires regression test across failure/retry scenarios.

---

## E) UI/UX Readiness (High)

18. Dark/light contrast passes all main screens
- Status: **BLOCKED**
- Reason: improved, but full visual QA pass not completed yet.

19. Arabic/English switch is complete and consistent
- Status: **FAIL**
- Reason: mixed i18n strategy (`tr()` + resources) still leaves partial mismatches.

20. No dead controls (button exists but no backend action)
- Status: **BLOCKED**
- Reason: needs final beta audit screen-by-screen.

---

## Release Decision
- Current production decision: **NO-GO**.
- Allowed deployment: **Controlled Pilot** (small user group, monitored diagnostics).

## Minimum Exit Criteria to flip to GO
1. Handshake gate fixed: `PeerReady` stable on both devices in repeated runs.
2. ACK gate fixed: delivered status proven end-to-end with retries.
3. Security gate fixed: lockout/backoff implemented and tested.
4. Localization/UI gate fixed: full Arabic/English + dark/light QA pass.
5. Field reliability report: at least 30 successful send/receive cycles across 2-3 devices.

---

## Immediate Execution Plan (Start Now)

### Step 1 (Today)
- Stabilize handshake state machine and PeerReady transition logging.
- Add per-peer handshake failure reason in diagnostics.

### Step 2
- Implement auth retry throttling (5 failures => 1 min lock, exponential backoff).

### Step 3
- Run formal field script: 30 message cycles, capture diagnostics before/after.
