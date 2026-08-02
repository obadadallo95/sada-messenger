> Audit date: 2026-08-02  
> Original audited path: `/Users/obadadallo/Desktop/sada`  
> Current project path: `/Users/obadadallo/Development/sada`  
> Git commit: `6847ca78b1948ecc096eac5dd681f049dba36235`

## Phase 0 verification note — 2026-08-02

This note records later verification only; it does not alter the original audit findings below.

- Duplicate-source issue: resolved. The three byte-identical untracked Kotlin copies were removed, and all remaining byte-identical untracked files whose names contained ` 2` were independently verified and removed. No ` 2` filenames remain.
- Clean build: `clean`, resource processing, Kotlin compilation, and `assembleDebug` pass; the debug APK is generated.
- Unit tests: 18 declared, 15 passed, 3 skipped, 0 failures, and 0 errors.
- Lint: the Kotlin 2.1 metadata crash was resolved by aligning AGP/lint and the stable Compose BOM while retaining Gradle 8.11.1. Lint now executes and reports 27 errors and 108 warnings, so the Phase 0 lint gate remains failing. The errors comprise four API-qualified style resources, one LoRa serial constant, sixteen Media3 opt-in findings, and six missing Arabic translations. They were not suppressed or changed because this checkpoint prohibits LoRa behavior changes and user-facing changes.
- Room schema: Room 2.6.1 schema export is configured at `app/schemas`; current schema version 21 was generated. No historical schema JSON files are available, so existing migrations cannot yet be validated with Room migration tests from exported history.
- Remaining warnings: kapt language-version fallback, native-library symbol stripping, Kotlin nullability/type mismatches, deprecated APIs/icons, unchecked casts, always-true conditions, and the lint warning inventory remain unresolved.

### Phase 0 completion — 2026-08-02

- The authoritative clean command completed successfully: clean, resource processing, Kotlin compilation, debug APK assembly, unit tests, and lint all passed.
- Unit tests: 15 passed, 3 skipped, 0 failures, and 0 errors.
- Lint: passed with 0 errors and 109 warnings; no detector, category, or finding was suppressed.
- Room schema version 21 is exported under `app/schemas`.
- The release build no longer falls back silently to debug signing when release credentials are unavailable.
- Phase 1 was not started; runtime/service ownership and networking architecture were not refactored.

# Sada local architecture audit

Audit basis: local folder `/Users/obadadallo/Desktop/sada`, including tracked, ignored, and generated local content. No source-controlled files or Git state were changed. Gradle generated/updated build output during verification.

## 1. Local project state

### Repository

- Root: `/Users/obadadallo/Desktop/sada`
- Android modules: root project plus one application module, `:app`, declared in [settings.gradle.kts](/Users/obadadallo/Desktop/sada/settings.gradle.kts:1).
- Branch: `main`
- HEAD: `6847ca78b1948ecc096eac5dd681f049dba36235`
- Commit: `Cleanup: Removed legacy-flutter as per project requirements.`
- Commit date: 2026-04-27 12:15:17 +0200
- Author: `obadadallo95`
- Tracked modifications: none reported by `git diff HEAD`.
- Untracked files: none reported by `git ls-files --others --exclude-standard`.
- Branch has no configured upstream.
- Configured remote: `origin`, GitHub URL present in `.git/config`.
- Cached `origin/main` and local `HEAD` report `0 ahead / 0 behind`.
- A live fetch was deliberately not performed. Therefore the folder matches its cached remote-tracking ref, but current GitHub parity cannot be asserted.

Important ignored files:

- `local.properties`: Android SDK location; appropriately ignored.
- `key.properties`: signing-related material; appropriately ignored, but present locally.
- `.gradle/`, `app/build/`, `.idea/`: ignored generated/local state.
- No ignored application source was identified.

### Build configuration

[app/build.gradle.kts](/Users/obadadallo/Desktop/sada/app/build.gradle.kts:1) configures:

- compile/target SDK 35, minimum SDK 24.
- Kotlin/JVM 21.
- Compose, Room 2.6.1, Hilt, WorkManager, Google Nearby, libsodium, Media3 and USB serial.
- Release builds fall back to the debug signing key when release properties are absent. This is unsuitable for production release governance.

### Verification result

Command attempted:

```text
./gradlew :app:assembleDebug :app:testDebugUnitTest :app:lintDebug --stacktrace
```

Result: **failed before Kotlin compilation, tests, or lint**.

Failure:

```text
:app:parseDebugLocalResources
android12splash 2.png
' ' is not a valid file-based resource name character
```

The failing path was under ignored generated output:

`app/build/intermediates/packaged_res/debug/packageDebugResources/drawable-hdpi-v4/android12splash 2.png`

No corresponding current source resource was found. This looks like stale/contaminated build output, but a clean was not run because the audit prohibited deleting files. Consequently:

- Debug APK: not verified.
- Unit tests: not executed.
- Lint: not executed.
- Instrumentation tests: none found.
- Existing reports cannot establish current correctness.
- Duplicate source files named `CleanupWorker 2.kt`, `SyncProtocol 2.kt`, and `HelpBottomSheet 2.kt` also declare duplicate symbols and are likely to cause compilation errors once resource parsing is cleared.

## 2. Executive verdict

Sada is an architectural prototype with substantial implementation work, but it is not presently a reliable offline store-carry-forward messenger.

The strongest implemented pieces are:

- Room-backed local chats/messages and relay records.
- Direct-message encryption primitives.
- TCP framing.
- BLE advertising/scanning.
- Wi-Fi Direct group handling.
- LAN UDP discovery.
- A foreground connectivity service.
- A canonical-looking `MeshEngine` packet lifecycle.

The decisive problem is ownership fragmentation. The foreground service owns background discovery and connections, while the activity owns the only `MeshEngine` that parses packets, performs handshakes, persists relays, decrypts messages, sends ACKs and pumps the queue. After a cold process restart into the service, links may be formed but there is no canonical packet processor attached to them.

In addition, wire identifiers and traces are hashed again on every serialization. A message parsed after one hop contains already-hashed identifiers; serializing it for the next hop hashes them again. This breaks destination recognition, sender resolution, trace stability and practical multi-hop delivery.

Current release verdict: **no-go**. Direct text messaging may work in a narrow two-device, foreground, same-process session, but even that needs physical validation. Multi-hop, process-death recovery, reliable ACK propagation and background relay are not logically complete.

## 3. Actual feature inventory

| Screen/feature | Entry point and runtime wiring | Status |
|---|---|---|
| Onboarding | `MainActivity` route `onboarding` → `OnboardingScreen` | Working UI |
| Registration | Route `register`; saves nickname and causes `KeyManager.getKeyPair()` to create identity; starts service | Partial; identity exists, but no recovery/export or identity-version protocol |
| Home | `HomeScreen` with `HomeViewModel` and Room flows | Working local UI; network statistics combine incompatible owners |
| Added contacts | `AddedContactsScreen` → `ContactsViewModel` | Partial |
| QR contacts | `ContactsScreen`, QR parsing/scanning and Room contact insertion | Implemented; physical camera and identity-interoperability validation required |
| Groups | `GroupsScreen`, `CreateGroupScreen`, `HomeViewModel`, group handlers in `MeshEngine` | Partial; not validated through canonical DTN lifecycle |
| Direct chat | `ChatScreen` → activity-created `ChatViewModel` → activity-created `MeshEngine` | Partial; foreground narrow path only |
| Text send | [ChatViewModel.kt](/Users/obadadallo/Desktop/sada/app/src/main/kotlin/org/sada/messenger/ui/viewmodels/ChatViewModel.kt:122) | Partial; local enqueue works, delivery does not |
| Reply | Stored locally in `MessageEntity` | Partial; reply metadata is not included in the mesh packet |
| Edit | Local database update only; code explicitly says network protocol TODO | Placeholder |
| Delete/pin | Local Room operations | Working locally only |
| Forward | Direct route encrypts and calls mesh; group route separate | Partial |
| Voice recording | `AudioRecorderManager`, microphone button in `ChatScreen` | Partial |
| Voice playback | Play button contains `/* Play logic */` | Placeholder |
| Attachments | Picker exists, but visible bottom sheet says “No attachment options” | Disconnected/contradictory |
| Generic media | `MeshEngine.sendMedia` and `MediaProtocol` exist, but `FEATURE_MEDIA_ENABLED=false` | Hidden/disabled and internally inconsistent |
| Crisis report | Source and ViewModel exist; route and callbacks commented out | Hidden |
| Diagnostics | Route `diagnostics`; merges activity engine, UDP singleton, transport and service snapshots | Partial; combines states from different manager instances |
| Settings/legal | Active routes and local preference behavior | Working local UI |
| Status publishing | Settings invokes `MeshEngine.publishStatusToVerifiedContacts` | Partial DTN path |
| Blocked contacts | Active route and Room state | Working locally |
| Growth/service profiles | Source exists; route and callback disabled | Hidden |
| `AppNavigator` | DI-friendly alternative navigator | Dead; `MainActivity` owns actual Compose `NavHost` |
| `ChatViewModelRefactored` and use cases | Hilt-oriented alternative | Dead/disconnected |
| `NearbyMeshManager` | Complete Google Nearby implementation | Dead; never instantiated |
| `MessageRouter` | Separate routing system with placeholder sends | Obsolete/dead |
| `BatteryAwareBleManager` | Alternative duty-cycled BLE design | Dead |
| LoRa | Activity creates USB serial manager and gives it to `MeshEngine` | Experimental/partial |

## 4. Runtime ownership map

```text
Android process
|
+-- MainActivity
|   |
|   +-- AppDatabase singleton
|   +-- KeyManager instance
|   +-- EncryptionManager instance
|   +-- SocketManager singleton -------------------------+
|   +-- UdpBroadcastManager singleton ----------------+  |
|   +-- raw WifiP2pManager + receiver (peer list only) |  |
|   +-- WifiDirectManager A ---------------------------|--+
|   +-- TransportManager(WifiDirect A, SocketManager)  |  |
|   +-- LoraSerialManager                              |  |
|   +-- MeshEngine A                                   |  |
|       +-- SocketManager callbacks                    |  |
|       +-- relay pump / handshake / parsing / ACK     |  |
|       +-- lazy BleMeshManager B                      |  |
|       +-- lazy WifiDirectManager B ------------------|--+
|       +-- Lora callbacks                             |  |
|   +-- manually constructed ViewModels -> MeshEngine A|  |
|                                                      |  |
+-- MeshForegroundService                              |  |
    |                                                  |  |
    +-- AppDatabase singleton                          |  |
    +-- KeyManager instance                            |  |
    +-- SocketManager singleton -----------------------+  |
    +-- UdpBroadcastManager singleton --------------------+
    +-- BleMeshManager C
    +-- WifiDirectManager C
    +-- discovery, reconnection, battery modes
    +-- NO MeshEngine
    +-- NO relay pump
    +-- NO packet receive/decrypt/ACK owner

Dead alternative graph:
Hilt modules -> MeshEngine D (not activated by MainActivity)
NearbyMeshManager singleton (unused)
BatteryAwareBleManager (unused)
MessageRouter (unused/placeholders)
```

Potential live-instance counts:

- `SocketManager`: one process singleton.
- `UdpBroadcastManager`: one process singleton, but its single receive callback is overwritten by whichever owner registers last.
- `MeshEngine`: normally one activity instance; a Hilt-created second instance is possible only if DI wiring is activated later.
- `WifiDirectManager`: at least two while activity and service coexist; up to three if `MeshEngine.wifiDirectManager` is evaluated.
- `BleMeshManager`: service instance plus a possible lazy activity-engine instance.
- Raw `WifiP2pManager` activity ownership exists in addition to all `WifiDirectManager` instances.
- `BatteryAwareBleManager`, `NearbyMeshManager`, `MessageRouter`: zero current runtime instances.

## 5. Canonical text-message lifecycle

The actual UI path is:

1. `ChatScreen` invokes `ChatViewModel.sendMessage`.
2. [ChatViewModel.sendMessage](/Users/obadadallo/Desktop/sada/app/src/main/kotlin/org/sada/messenger/ui/viewmodels/ChatViewModel.kt:122) resolves the contact/public key.
3. It inserts plaintext into Room with status `sending`.
4. It derives a Curve25519 shared secret and encrypts content using libsodium SecretBox.
5. It constructs `MeshMessage`.
6. `MeshEngine.sendMeshMessage` adds sender public-key metadata.
7. `storeAndForward` immediately calls `addHop(myId)`, even at the originating phone.
8. It deletes any existing queue record for that message ID, calculates priority, and inserts a `RelayQueueEntity`.
9. `forwardToPeers` serializes the packet and ultimately calls `TransportManager.sendFramed`.
10. `ChatViewModel` changes local status to `sent` because queueing returned without exception—not because any transport accepted the packet.

Receive path:

1. TCP `SocketManager` removes its four-byte length prefix.
2. `MeshEngine.handleIncomingData` removes the one-byte text-frame marker.
3. `handleIncomingJson` parses a `MeshMessage`.
4. `processIncomingMeshMessage` checks persistent/in-memory duplicate state and validity.
5. If destination matches, it checks verification, decrypts and stores the message.
6. It sends a raw `MSG_ACK` over the currently connected socket.
7. If not the destination, it calls `storeAndForward`.

Critical consequences:

- “Sent” means persisted in the local relay queue, not transmitted.
- The origin is counted as the first hop.
- `maxHops=10` is rejected when `hopCount >= maxHops`; only nine `storeAndForward` additions survive.
- At the first relay, hashed sender/destination fields are parsed into the identity fields and then hashed again when forwarded. A recipient after one carrier will generally no longer match.
- Trace entries are likewise repeatedly hashed.
- No cryptographic signature authenticates packet headers, hop count, TTL, trace, sender/destination hashes or ACKs.

ACK path:

- Destination emits raw `MSG_ACK`.
- A relay forwards it only if it still has the corresponding queue record.
- The ACK is not a `MeshMessage`, is not persisted, has no TTL/trace/deduplication, and cannot be store-carried across a later encounter.
- A relay deletes its data copy immediately after forwarding an ACK once, even without upstream confirmation.

## 6. Discovery and transport lifecycle

### BLE

[BleMeshManager.kt](/Users/obadadallo/Desktop/sada/app/src/main/kotlin/org/sada/messenger/network/direct/BleMeshManager.kt:1) advertises a truncated peer identifier and scans using low-power settings, but scan/advertising remain continuously requested. It periodically restarts scanning; it is not a true sleep/scan pulse cycle.

BLE is a discovery trigger only. On discovery, service and engine callbacks attempt Wi-Fi Direct formation. It does not carry canonical packets.

`BatteryAwareBleManager` contains more explicit scan windows and battery logic but is never constructed.

### Wi-Fi Direct

[WifiDirectManager.kt](/Users/obadadallo/Desktop/sada/app/src/main/kotlin/org/sada/messenger/network/direct/WifiDirectManager.kt:32) handles P2P discovery, group creation, peer selection and TCP connection to the group owner. It uses the same singleton `SocketManager`.

Problems:

- Multiple independent manager/receiver instances can race over group formation and disconnection.
- The activity passes `WifiDirectManager A` to `TransportManager`, while BLE-triggered formation may occur through service manager C or lazy engine manager B. Thus the transport label can report LAN even when a different instance formed the P2P group.
- There is no authoritative post-exchange close policy. Connections close on error, explicit disconnect, activity/service teardown or pause—not after inventory convergence.

### LAN/UDP/TCP

`MeshForegroundService` sends UDP beacons at adaptive intervals and listens on port 8888. LAN discovery requires both devices to have IP reachability on the same LAN, hotspot, or Wi-Fi Direct subnet. It does not use visible router beacon content as a data channel.

UDP carries discovery strings only. Message data uses TCP.

`SocketManager` supports only one active client socket/input/output pair. The server accept loop may accept another client, but `setupSocket` replaces the shared streams and cancels the previous read job. Therefore the canonical TCP system communicates with one peer at a time.

### Other Wi-Fi modes

No implementation was found for:

- Wi-Fi Aware.
- `LocalOnlyHotspot`.
- Wi-Fi scan results as a Sada channel.
- Android NSD/DNS-SD.
- Wi-Fi P2P service discovery.

`NearbyMeshManager` uses Google Nearby Connections but is dead code.

### High-throughput wake/close

- BLE peer discovery calls `createGroup()` or `startDiscovery()`.
- UDP discovery can trigger LAN TCP fallback after a grace interval.
- Pending relay counts can request faster UDP discovery.
- No reliable “exchange complete” event closes Wi-Fi Direct/TCP.
- `lan_fallback_enabled` is displayed by `TransportManager`, but its send path does not enforce the setting; the service also attempts LAN regardless.

## 7. Store-carry-forward analysis

### Persistence

The relay queue is Room-backed and survives process death. The entity is defined at [Entities.kt](/Users/obadadallo/Desktop/sada/app/src/main/kotlin/org/sada/messenger/data/entities/Entities.kt:111).

However, persistence alone is insufficient: after service-only process restoration, no `MeshEngine` loads or flushes it.

### Multi-hop

Logical result by carrier count:

- Direct, zero carrier: plausible in a foreground two-device session; physical validation required.
- One carrier: broken by repeated hashing when the carrier reserializes the parsed packet.
- Two, five or ten carriers: broken for the same reason.
- Ten hops are additionally inconsistent with origin-side hop increment and the `>= maxHops` rejection.

### Identifier transformation

[MeshMessage.toJson](/Users/obadadallo/Desktop/sada/app/src/main/kotlin/org/sada/messenger/data/models/MeshMessage.kt:110) hashes identity fields and every trace entry. `fromJson` stores those hashes back into fields that `toJson` assumes are plaintext. Therefore sender, destination and trace hashes transform again at every serialization.

### TTL

TTL is reset at every `storeAndForward`:

- `getMessageTTL` always returns a fresh 24/48-hour duration.
- `remainingTtlMs` received from a previous hop is ignored.
- `expiresAt` is rebuilt from current time.

Therefore TTL represents per-hop residence time, not total packet lifetime. A moving packet can persist indefinitely if it encounters a relay before each reset expires.

### Duplicates

- Persistent seen IDs prevent reprocessing for 48 hours.
- `storeAndForward` deletes then inserts by message ID, reducing duplicates within one engine.
- The database lacks a unique index on `relay_queue.messageId`; concurrent engines/coroutines can still insert duplicates.
- `remove + insert` is not wrapped in a transaction.
- Seen retention is shorter than a TTL that can be repeatedly reset.

### Bloom filters and inventory

Bloom filters are exchanged during handshakes per peer, but:

- They contain only active relay IDs.
- Persisted seen IDs are commented out.
- The filter remains a handshake-time snapshot and is not updated after packets are sent/received.
- All selected “peer-specific” writes go through one shared socket, so looping over several logical peer IDs does not address distinct connections.
- `syncPendingPackets` compares the parsed hashed destination directly with a plaintext peer ID, weakening direct-delivery prioritization.

### Queue pressure and priority

- Queue cap logic exists at 1,000 records.
- `removeOldest` orders by earliest expiry but does not protect priority 0 despite its comment.
- The periodic gossip subset is randomized instead of priority ordered.
- `RelayQueueDao.getActiveRelaysOrderedByPriority` exists but canonical flushing uses unordered `getActiveRelays`.
- Retries are periodic resends; there is no per-packet attempt state, exponential retry, per-peer transmission state or custody acknowledgment.

### ACK propagation

ACK packets cannot traverse delayed carriers. They work only across the currently open chain of live sockets and are unauthenticated. Delivered/expired copies are therefore not reliably purged across the mesh.

## 8. Background and battery analysis

### Screen locked

A running foreground service should remain eligible to execute with the screen off, subject to Android/OEM restrictions. The code does not hold a wake lock despite declaring the permission. Physical testing is required.

### Activity destroyed

The service continues BLE, Wi-Fi Direct, UDP and TCP management.

The activity’s `MeshEngine` is not explicitly shut down in `onDestroy`; its coroutine scope and singleton socket callbacks can retain the activity and may continue packet processing while the process remains alive. This is an accidental memory-retention path, not sound service ownership.

### Process killed/restarted

The service is `START_STICKY`, and `onTaskRemoved` schedules an exact alarm. But:

- No boot receiver exists.
- Exact alarms may require policy/permission considerations on modern Android.
- After cold service recreation there is no `MeshEngine`.
- Incoming TCP frames have no packet callback.
- The persisted relay queue has no active pump.
- LoRa is not started by the service.

Thus packets survive on disk but do not autonomously resume.

### Doze and battery

`MeshForegroundService.updateDiscoveryMode` defines IDLE, BURST, BACKOFF, POWER_SAVE and EMERGENCY_ONLY modes. These modes do affect UDP beacon interval. They do not meaningfully pulse or stop BLE; the status monitor restarts continuous BLE advertising/scanning if they stop.

No WorkManager job is scheduled. Both duplicate `CleanupWorker` files are disconnected. No reboot recovery is declared.

The manifest requests battery-optimization exemption permission, but the app only opens settings; it does not establish that exemption. OEM background behavior remains unvalidated.

## 9. Voice-message lifecycle

Actual canonical voice path:

1. `ChatScreen` microphone toggles `ChatViewModel`.
2. `AudioRecorderManager` records MPEG-4 AAC at 96 kbps/44.1 kHz.
3. A main-thread handler stops around 30 seconds.
4. Recordings under 500 ms are deleted.
5. `MeshEngine.sendVoiceMessage` rejects files over 360 KiB.
6. The entire file is encrypted as one byte array.
7. It is Base64-encoded into one `MeshMessage`.
8. The normal relay queue and text JSON framing carry it.
9. Destination decrypts the complete payload and writes an `.m4a` cache file.
10. The UI play button has no playback implementation.

Assessment:

- Duration and byte limit are enforced.
- Compression is simply MediaRecorder AAC; no transport-specific re-encoding or bitrate adaptation occurs.
- The active voice route is not chunked.
- No checksum is included.
- No chunk-level retry, resume or cleanup policy exists.
- Retry behavior is only whole-packet gossip.
- A 360 KiB encrypted file expands materially under Base64 but remains below the TCP 1 MiB guard; LoRa transport would create thousands of fragments.
- `VoiceMessageEnvelope` is unused.
- The separate `MediaProtocol` header/chunk/checksum flow is not used by `sendVoiceMessage`.
- Generic media reception is disabled by `FEATURE_MEDIA_ENABLED=false`.
- Playback, interruption recovery, duplicate voice-file cleanup and missing-chunk recovery are absent.

## 10. Duplicate and contradictory systems

| Canonical candidate | Duplicate/disconnected candidate | Consequence |
|---|---|---|
| Activity-created `MeshEngine` | Hilt `NetworkModule` engine | DI graph does not own actual runtime |
| `ChatViewModel` | `ChatViewModelRefactored` + `SendMessageUseCase` | Refactored use case reports success while `sendViaMesh` is empty |
| `MeshEngine.storeAndForward` | `MessageRouter` | Router’s `sendToNextHop`, direct send and relay methods return placeholder `true` |
| `BleMeshManager` | `BatteryAwareBleManager` | Documented battery-aware behavior is not runtime behavior |
| Raw BLE + Wi-Fi Direct | `NearbyMeshManager` | Dependency and code exist but never participate |
| Activity `WifiDirectManager A` | engine lazy manager B and service manager C | Conflicting receiver/state ownership |
| Service UDP callback | Activity UDP callback | Singleton has one callback; later registration overwrites earlier behavior |
| One activity `NavHost` | `AppNavigator` | Documentation describes navigation system not used |
| Single-packet voice | `VoiceMessageEnvelope` and media chunks | Docs claim chunk/checksum semantics absent from active voice |
| `CleanupWorker.kt` | `CleanupWorker 2.kt` | Duplicate class; neither scheduled |
| `SyncProtocol.kt` | `SyncProtocol 2.kt` | Duplicate class likely blocks compilation |
| `HelpBottomSheet.kt` | `HelpBottomSheet 2.kt` | Duplicate composables likely block compilation |
| Docs database v18 | Runtime Room database v21 | Documentation is stale |
| Docs claim `MessageRouter`/battery BLE canonical | Runtime `MeshEngine`/plain BLE | Misleading implementation guidance |
| Docs claim non-destructive migrations | `fallbackToDestructiveMigration()` | Possible user-data loss on an uncovered migration path |

## 11. Defects by severity

### P0

1. **Background service lacks the packet engine.**  
   Evidence: [MeshForegroundService.kt](/Users/obadadallo/Desktop/sada/app/src/main/kotlin/org/sada/messenger/core/services/MeshForegroundService.kt:124) creates discovery/connection managers only; [MainActivity.kt](/Users/obadadallo/Desktop/sada/app/src/main/kotlin/org/sada/messenger/MainActivity.kt:225) creates `MeshEngine`.  
   Consequence: cold background receive, relay, ACK and queue flush do not operate.  
   Direction: move one application-scoped engine into the service-owned runtime.

2. **Identifiers and trace are re-hashed at every hop.**  
   Evidence: `MeshMessage.fromJson` lines 78–98 and `toJson` lines 110–129.  
   Consequence: practical multi-hop delivery breaks after the first carrier.  
   Direction: define immutable wire fields and never transform already-wire-formatted identifiers.

3. **TTL resets at every relay.**  
   Evidence: `storeAndForward` lines 1132–1144 and `getMessageTTL` lines 1203–1208.  
   Consequence: expired data can circulate indefinitely.  
   Direction: carry immutable `createdAt/expiresAt` or decrement a received remaining TTL.

4. **Current local build is not reproducible.**  
   Evidence: Gradle resource parse failure plus duplicate Kotlin declarations.  
   Consequence: no APK, tests or lint can be verified.  
   Direction: first establish a clean-build baseline while preserving source history.

### P1

- ACKs are non-persistent, unauthenticated and not DTN packets.
- Multiple Wi-Fi Direct/BLE owners can create and tear down conflicting groups.
- Only one TCP peer can be active; logical multi-peer lists are sent over the same socket.
- `sendMeshMessage` reports success after queue insertion regardless of transport result.
- Relay queue has no unique message-ID constraint or transactional upsert.
- Destructive Room fallback can erase message/relay state.
- KeyManager wipes secure preferences after corruption and may fall back to plaintext preferences.
- Automatic key-rotation helpers exist without a demonstrated identity/key-transition protocol; if invoked, stored contacts and outstanding ciphertext can become incompatible.
- LoRa double-fragments data: `MeshEngine` fragments, then `LoraSerialManager.sendData` fragments each fragment again. Receive code can also feed partial fragments upward twice.
- `LoraPacketizer` uses a one-byte message hash, allowing easy collision and cross-message corruption.
- Service-only process restart neither starts LoRa nor reattaches packet callbacks.

### P2

- BLE is effectively continuous despite battery-mode claims.
- Queue pressure eviction does not preserve emergency priority.
- Gossip and flush ignore the priority-ordered DAO.
- Bloom inventories omit persisted seen IDs and go stale during a connection.
- No per-peer custody/transmission state.
- No close-after-convergence transport lifecycle.
- `lan_fallback_enabled` is not actually enforced.
- Voice has no chunking, checksum, playback, retry/resume or lifecycle cleanup.
- Generic attachment UI and backend contradict one another.
- Room migration tests are absent.
- WorkManager dependency and workers are unused.
- Exact-alarm restart and Doze/OEM behavior are not validated.
- No reboot receiver.
- Message headers and ACKs lack authentication.
- Metadata leaks sender public keys and message type/size despite blind-relay claims.

### P3

- Documentation describes obsolete classes and database versions.
- Duplicate “2” source files remain.
- Hilt is configured but the real activity graph is manual.
- Diagnostics combine unrelated instance state.
- Numerous placeholder/hidden screens increase audit noise.
- CI omits lint, instrumentation, migration and physical-network tests.
- Release signing silently falls back to debug.

## 12. Maturity scores

Scale: 0 = absent, 5 = field-ready.

| Area | Score | Reason |
|---|---:|---|
| Direct messaging | 2/5 | Plausible foreground implementation, unbuilt and unvalidated |
| Discovery | 2/5 | BLE/UDP code exists; ownership and battery behavior conflict |
| Transport establishment | 2/5 | Wi-Fi Direct/LAN code exists; multi-owner races and one socket |
| Store-carry-forward | 1/5 | Persistent queue exists, but no cold-background owner |
| Multi-hop | 0/5 | Re-hashing and TTL semantics break the model |
| Background operation | 1/5 | Connectivity service exists without packet processing |
| Battery efficiency | 1/5 | UDP modes exist; BLE remains continuous |
| Voice transport | 1/5 | Recording/encryption implemented; no chunk/retry/playback |
| Security | 2/5 | Good primitives; unauthenticated headers/ACKs and unsafe recovery |
| Maintainability | 1/5 | Duplicated architectures, manual ownership, stale docs |
| Automated testing | 1/5 | Four unit-test files; core canonical engine/lifecycle untested |
| Physical-device validation | 0/5 | No evidence in the authoritative local project |
| Release readiness | 0/5 | Build not verified and core lifecycle has P0 failures |

## 13. Recommended target architecture

Prefer consolidation around `MeshEngine`, Room and the existing transports.

```text
MeshForegroundService (sole runtime lifecycle owner)
|
+-- MeshRuntime / MeshCoordinator (one application-scoped instance)
    |
    +-- IdentityManager
    +-- PacketCodec (immutable versioned wire packet)
    +-- PacketProcessor
    +-- RelayRepository (Room, transactional)
    +-- PeerSessionRegistry
    +-- DiscoveryCoordinator
    |   +-- pulsed BLE
    |   +-- optional LAN UDP
    +-- TransportCoordinator
    |   +-- Wi-Fi Direct/TCP
    |   +-- LAN/TCP fallback
    |   +-- optional LoRa adapter
    +-- ACK/custody processor using the same DTN packet model
```

The activity and ViewModels should issue commands and observe Room/runtime state; they should not create networking managers.

Preserve:

- `MeshEngine` business logic where correct.
- `SocketManager` framing, after making connections session-scoped.
- Room message/relay entities, with schema strengthening.
- Existing BLE, Wi-Fi Direct and UDP adapters.
- EncryptionManager primitives.
- Diagnostics counters.

Retire or absorb:

- `MessageRouter`.
- `NearbyMeshManager` unless deliberately selected as a supported transport.
- `BatteryAwareBleManager` as a separate alternative; move its useful pulse policy into the canonical BLE adapter.
- Hilt/manual duplicate graphs.
- Duplicate source files and dead refactored ViewModel paths.

## 14. Stabilization phases

### Phase 1: Reproducible baseline

- Objective: clean build, unit tests and lint from a documented environment.
- Likely files: duplicate Kotlin/resources, Gradle and CI configuration.
- Risks: accidentally discarding unique code from duplicated files.
- Automated tests: assemble, unit test, lint, Room schema validation.
- Physical tests: launch smoke test.
- Completion: clean checkout produces APK with zero duplicate symbols/resources.

### Phase 2: Single runtime owner

- Objective: service owns one engine and all manager instances.
- Likely files: `MeshForegroundService`, `MainActivity`, modules/factory, `MeshEngine`.
- Risks: lifecycle regressions and callback loss.
- Tests: service create/destroy/restart, singleton ownership assertions.
- Physical tests: activity destroyed, process killed, screen locked.
- Completion: queued packet flushes after cold service restart without opening UI.

### Phase 3: Versioned immutable packet format

- Objective: fix ID, trace, hop and total-lifetime semantics.
- Likely files: `MeshMessage`, codec and engine processing.
- Risks: incompatibility with installed prototypes.
- Tests: serialize/parse/relay across 1, 2, 5 and 10 simulated hops.
- Physical tests: three-device carrier scenario.
- Completion: destination and sender identity remain stable; expiry never extends.

### Phase 4: Reliable custody and ACK

- Objective: persistent per-peer send state and multi-hop ACK packets.
- Likely files: Room entities/DAOs, `MeshEngine`.
- Risks: premature deletion or queue growth.
- Tests: missing ACK, duplicated ACK, delayed carrier, crash during transaction.
- Physical tests: recipient encountered after sender departs.
- Completion: sender becomes delivered only after a persisted destination ACK returns.

### Phase 5: Discovery and transport policy

- Objective: one pulsed low-power discovery coordinator and explicit high-throughput sessions.
- Likely files: service, BLE and Wi-Fi Direct managers, transport manager.
- Risks: OEM-specific scan throttling and P2P instability.
- Tests: policy/state-machine tests.
- Physical tests: multiple manufacturers, idle/low-battery/Doze.
- Completion: BLE has measured scan/sleep windows; Wi-Fi transport closes after convergence/timeout.

### Phase 6: Multi-peer sessions and inventory

- Objective: explicit peer sessions and correct per-peer inventories.
- Likely files: socket/session layer, Bloom/inventory protocol.
- Risks: memory, contention and broadcast duplication.
- Tests: three concurrent peers, stale Bloom filter and false-positive cases.
- Physical tests: three-to-five simultaneous devices.
- Completion: every logical peer maps to a distinct connection/session.

### Phase 7: Voice and optional LoRa

- Objective: bounded, chunked, resumable voice; LoRa uses the same packet lifecycle.
- Likely files: recorder, voice envelope/chunk DAO, LoRa adapter.
- Risks: storage pressure and fragment collision.
- Tests: chunk loss/reordering, checksum, restart, expiry.
- Physical tests: dropped links, LoRa hardware compatibility.
- Completion: a 30-second voice message resumes after interruption and reconstructs only after checksum verification.

### Phase 8: Field/release hardening

- Objective: security review, migration safety and release gates.
- Risks: legacy database/key compatibility.
- Tests: migrations from every supported schema; fuzzed packet parsing; release build.
- Physical tests: full matrix below.
- Completion: no P0/P1 defects, signed non-debug release and documented field evidence.

## 15. Physical-device test matrix

| Scenario | Required assertion |
|---|---|
| Two devices direct | Discover, connect, handshake, encrypted send, recipient persist, ACK, sender delivered |
| Three devices, no A↔C contact | B store-carries after A disconnects; later C receives; ACK eventually returns |
| Five sequential carriers | Stable IDs, trace, TTL and ciphertext across every hop |
| Ten hops | Explicit policy result: delivery through ten relays or deterministic max-hop rejection |
| Delayed encounters | Queue survives hours and resumes without UI |
| Duplicate arrivals | One inbox record, one queue record, harmless repeated ACK |
| Dropped connection | Partial frame discarded safely; packet remains queued |
| Missing ACK | Sender stays pending and retries within policy |
| Expiration | Every carrier deletes at the same absolute expiry |
| Screen off | Discovery/relay behavior and battery consumption measured |
| Doze | Document actual encounter latency and OEM restrictions |
| Process restart | Cold service recreation resumes parsing and queue flush |
| Phone reboot | Registered restart mechanism restores runtime |
| Low battery | Defined mode changes BLE and transport behavior, not just UDP interval |
| Multiple peers | Distinct concurrent sessions and per-peer inventories |
| Android versions | API 24, 29/30, 31/32, 33, 34 and 35 |
| Manufacturers | At minimum Google, Samsung, Xiaomi/Redmi, Oppo/OnePlus and Motorola |
| Wi-Fi Direct unavailable | LAN fallback policy behaves truthfully |
| No shared LAN | BLE-triggered Wi-Fi Direct still establishes data path |
| LoRa | Collision, missing fragments, reconnect and canonical TTL/ACK behavior |
| Voice | 0.5 s, 30 s, size boundary, interrupted transfer, corrupt chunk and checksum failure |

Final conclusion: the correct consolidation candidate is `MeshEngine`, but it must become service-owned and operate on a corrected immutable packet format before Sada can claim store-carry-forward or multi-hop messaging. The architecture-review discipline chiefly changes the recommended direction from adding more transports to consolidating ownership and proving one complete text lifecycle first.
