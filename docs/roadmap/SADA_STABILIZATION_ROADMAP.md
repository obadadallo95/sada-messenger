# Sada stabilization roadmap

Roadmap basis: the preserved local architecture audit dated 2026-08-02, code at commit `6847ca78b1948ecc096eac5dd681f049dba36235`, and a fresh clean baseline run in `/Users/obadadallo/Development/sada` on 2026-08-02.

Baseline result: clean, resource processing, Kotlin compilation, debug APK generation, and unit tests completed. Lint crashed in `androidx.compose.runtime.lint.ComposableStateFlowValueDetector` because it supports Kotlin metadata only through 2.0 while the analyzed metadata is 2.1. This roadmap does not treat the current APK or passing unit tests as evidence that multi-hop or background operation is correct.

## Phase 0 verification status — 2026-08-02

- Duplicate source/output copies: all verified byte-identical untracked ` 2` files were removed; none remain.
- Clean build: clean, resources, Kotlin compilation, and debug APK assembly pass.
- Unit tests: 18 declared; 15 pass and 3 are skipped, with no failures or errors.
- Lint: the toolchain metadata incompatibility is fixed and lint executes. The gate still fails on 27 real errors and 108 warnings. No lint detector was disabled, no baseline was introduced, and no finding was suppressed.
- Room: schema export is configured to tracked `app/schemas`, and database version 21 is generated. Historical exported schemas are unavailable, so migration testing from earlier versions remains blocked on authentic history.
- Remaining warnings: kapt fallback to language 1.9, unstripped native libraries, Kotlin nullability/type warnings, deprecated APIs/icons, unchecked casts, always-true conditions, plus the lint inventory.
- Checkpoint status: Phase 0 is not complete and no commit should be created until lint passes without violating the no-networking/no-LoRa/no-user-facing-change restrictions or those restrictions are explicitly revised.

### Phase 0 completion — 2026-08-02

- Clean build, resource processing, Kotlin compilation, and debug APK assembly pass.
- Unit tests: 15 passed, 3 skipped, 0 failures, and 0 errors.
- Lint passes with 0 errors and 109 warnings; remaining warnings are recorded debt and were not suppressed.
- Room schema version 21 is exported under `app/schemas`; historical schema limitations remain as documented above.
- Silent release fallback to debug signing has been removed while debug builds remain available.
- Phase 1 has not started. No runtime ownership, service, or networking architecture work was performed.

## Guardrails and priorities

- Preserve the existing Room data, encryption primitives, transport adapters, and useful `MeshEngine` behavior until replacements have characterization tests.
- Make one lifecycle owner authoritative before changing wire semantics.
- Introduce versioned formats and migrations; never reinterpret persisted or received legacy data silently.
- Keep voice and LoRa out of early phases. They depend on the canonical packet, persistence, ACK, and session layers.
- Every phase lands behind automated gates and a reversible Git checkpoint.

### P0/P1 blocker table

| Priority | Blocker | User-visible consequence | Owning phase | Exit evidence |
|---|---|---|---|---|
| P0 | No service-owned packet runtime | Cold/background receive, relay, ACK, and queue flush stop | 1 | Queue resumes after service-only cold restart |
| P0 | IDs and trace re-hash at each serialization | Multi-hop destination/sender recognition breaks | 2 | Golden packets remain byte/semantically stable across 1, 2, 5, and 10 relays |
| P0 | TTL is reset at every relay | Packets can circulate past intended lifetime | 2 | Absolute `expiresAt` never increases |
| P0 | Baseline lint toolchain crashes | CI cannot enforce a complete quality gate | 0 | Clean CI build, tests, and lint all complete |
| P1 | Relay `remove + insert` is non-transactional and message ID is not unique | Duplicate/lost queue rows under concurrency or crash | 3 | Unique constraint plus atomic upsert and crash tests |
| P1 | ACK is transient raw socket state | Delivery cannot complete after delayed encounters | 4 | Persisted destination ACK store-carries back to sender |
| P1 | Multiple BLE/Wi-Fi owners | Discovery and group state race or disconnect | 1/5 | Exactly one manager instance and one policy owner |
| P1 | One shared TCP stream represents multiple logical peers | Inventory and sends target the wrong peer | 6 | One distinct session per connected peer |
| P1 | Queue insertion is reported as sent | UI overstates delivery | 3/4 | Status model distinguishes queued, transmitted, acknowledged, failed |
| P1 | Destructive Room fallback | Upgrade can erase messages and relay state | 9 | Tested migrations from every supported schema |
| P1 | Key storage can degrade or reset identity | Contacts/ciphertext can become unrecoverable | 9 | Explicit failure/recovery and key lifecycle tests |
| P1 | Release may be debug-signed | Production provenance is invalid | 9 | Release build fails closed without release credentials |
| P1 | LoRa double fragmentation and one-byte collision key | Cross-message corruption and excessive fragments | 8 | One fragmentation layer with collision-safe IDs |

## Phase dependency graph

```text
Phase 0 baseline
    |
Phase 1 single runtime ownership
    |
Phase 2 immutable versioned packet format
    |
Phase 3 transactional relay persistence
    |
Phase 4 persistent DTN ACK
    |
Phase 5 discovery/battery policy
    |
Phase 6 peer sessions/inventory
    |
Phase 7 voice transport ----+
    |                        |
Phase 8 optional LoRa -------+
    |
Phase 9 security, migrations, release hardening
```

Phase 5 policy design can be prepared while Phase 4 is tested, but must integrate only after runtime ownership is singular. Phase 7 and Phase 8 may be developed independently after Phase 6 interfaces stabilize; neither may define a second packet lifecycle.

## Phase 0 — Reproducible repository baseline

**Objective.** Make a clean checkout produce deterministic build, test, lint, schema, and CI evidence before architectural changes.

**Exact current defects.** The three byte-identical untracked Kotlin copies have been removed locally but the checkpoint is not committed. Numerous other `* 2.*` untracked files remain and require individual disposition. Generated and local outputs exist under ignored paths. Room has `exportSchema = true` in `AppDatabase` but no `room.schemaLocation`/Room Gradle plugin, producing a KSP warning and no governed schema history. Lint crashes on Kotlin metadata 2.1 in the Compose StateFlow detector. Kapt falls back from language 2.0+ to 1.9. Kotlin compilation emits nullability, deprecated API/icon, unchecked-cast, and always-true-condition warnings. CI runs `assembleDebug` and `testDebugUnitTest`, but not lint. The Gradle wrapper scripts and wrapper JAR are ignored, which can prevent a genuinely clean checkout from running the documented command. Release signing fallback is deferred to Phase 9.

**Dependencies.** None.

**Likely files/classes.** `.gitignore`, `gradle/wrapper/gradle-wrapper.jar`, `gradlew`, `gradlew.bat`, `build.gradle.kts`, `app/build.gradle.kts`, `gradle/libs.versions.toml` if introduced, `.github/workflows/android-ci.yml`, `AppDatabase`, `app/schemas/`, current warning locations, and the remaining duplicate-style untracked files.

**Ordered implementation tasks.**

1. Commit the preserved audit and the three verified Kotlin duplicate removals as a documentation/baseline checkpoint.
2. Inventory every remaining duplicate-style file; compare against canonical content and obtain an explicit keep/delete/rename decision per file.
3. Verify wrapper provenance, then track the wrapper scripts/JAR or document a secure reproducible alternative.
4. Configure Room schema output in a tracked directory without setting `exportSchema = false`; export version 21 and validate it in CI.
5. Align Android Gradle Plugin, Kotlin, Compose lint, and metadata dependencies so `lintDebug` completes. Do not permanently disable `StateFlowValueCalledInComposition` merely to obtain green output.
6. Capture and classify all compiler/lint warnings; fix correctness warnings first and establish a ratchet for remaining debt.
7. Add one CI command or equivalent ordered jobs for clean, assemble, unit tests, and lint; retain reports/artifacts on failure.
8. Document JDK 21, SDK 35, and the exact baseline command.

**Automated tests.** `./gradlew clean :app:assembleDebug :app:testDebugUnitTest :app:lintDebug`; Room schema JSON presence/diff check; clean-checkout wrapper smoke test; APK artifact existence; unit-test XML summary gate.

**Physical-device tests.** Install and launch the debug APK on one API 24 and one API 35 device; complete registration, open the home screen, and confirm the foreground service notification without testing mesh correctness.

**Risks.** Toolchain upgrades can surface new lint findings or alter generated code. Tracking previously ignored wrapper assets may expose accidental local modifications. Duplicate-style files may contain unique content despite similar names.

**Rollback strategy.** Revert toolchain/config commits independently; retain the last known buildable wrapper and schema artifacts; never delete an unverified duplicate-style file.

**Explicit non-goals.** Runtime ownership, packet format, relay behavior, ACK changes, BLE policy, sessions, voice, LoRa, features, or UI redesign.

**Definition of done.** A fresh clone executes the baseline command with no task crash; APK, unit-test, lint, and Room-schema artifacts are retained; CI enforces all three gates; all remaining duplicate-style files have documented dispositions; warnings have owners and no unclassified correctness warning remains.

**Recommended Git checkpoint.** `phase-0/reproducible-baseline` with small commits for audit/duplicates, wrapper/schema, lint/toolchain, warning ratchet, and CI.

## Phase 1 — Single runtime ownership

**Objective.** Establish one service-owned `MeshRuntime` or `MeshCoordinator`, with exactly one live instance of every networking manager; activities and ViewModels become clients/observers.

**Exact current defects.** `MainActivity` creates the only active `MeshEngine`, while `MeshForegroundService` creates discovery and connection managers without a packet processor or relay pump. Activity, engine, and service can create two or three `WifiDirectManager` instances and two BLE managers. Raw `WifiP2pManager` ownership also exists in the activity. `UdpBroadcastManager` and `SocketManager` are singletons with callbacks that can be overwritten. The Hilt `NetworkModule` describes a disconnected alternative graph. Activity destruction can retain engine callbacks; a cold sticky-service restart cannot parse packets or flush Room.

**Dependencies.** Phase 0 green baseline and characterization tests around current callbacks/queue behavior.

**Likely files/classes.** `core/services/MeshForegroundService.kt`, `MainActivity.kt`, `network/MeshEngine.kt`, `SocketManager.kt`, `managers/UdpBroadcastManager.kt`, `network/TransportManager.kt`, `network/direct/BleMeshManager.kt`, `network/direct/WifiDirectManager.kt`, `di/NetworkModule.kt`, `SadaApplication.kt`, activity-created ViewModels, and a new narrowly scoped `MeshRuntime`/`MeshCoordinator` plus runtime interface.

**Ordered implementation tasks.**

1. Add a characterization test and debug-only ownership registry that records construction/start/stop/callback attachment for engine, BLE, Wi-Fi Direct, UDP, socket, and transport objects.
2. Define a minimal `MeshRuntime` interface: start/stop, enqueue command, runtime state flow, and diagnostic snapshot. Do not move algorithms yet.
3. Wrap the existing `MeshEngine` and existing manager instances in one application-scoped coordinator constructed by a single DI/factory path.
4. Make `MeshForegroundService` the sole lifecycle caller of runtime `start/stop`; make startup idempotent and restart-safe.
5. Route activity/ViewModel commands through the runtime interface and observe Room/state flows; remove their construction and callback ownership only after parity tests pass.
6. Remove or absorb duplicate raw Wi-Fi P2P and lazy engine manager creation; ensure UDP/socket callback registration supports the sole runtime.
7. Add deterministic teardown and reattachment behavior for service restart and process recreation.
8. Update diagnostics to report only the canonical runtime.

**Automated tests.** Constructor/ownership assertion for one instance per manager; service repeated `onCreate`/`onStartCommand`/`onDestroy`; activity recreation without manager recreation; callback installed once; persisted queue pump starts after service recreation; idempotent start/stop; no activity reference retained.

**Physical-device tests.** Two devices with activity foregrounded; activity destroyed while service remains; screen locked; swipe task away; kill process and allow service recreation; reopen UI and confirm the same runtime state; repeat Wi-Fi Direct formation/disconnect ten times.

**Risks.** Callback gaps during handoff, duplicate service starts, Android background-start limits, Hilt/service initialization cycles, and accidental behavior changes from moving lifecycle code.

**Rollback strategy.** Keep the runtime adapter thin and preserve the old engine internals; land command/observer seams before deleting activity ownership; revert the final ownership switch without reverting characterization tests.

**Explicit non-goals.** Packet schema or hashing fixes, TTL semantics, relay schema changes, persistent ACK, multi-socket support, BLE duty-cycle tuning, voice, or LoRa.

**Definition of done.** Runtime diagnostics and tests prove one engine, one BLE manager, one Wi-Fi Direct manager, one UDP manager, one socket/transport owner; a queued packet resumes processing after cold service recreation without opening the activity; activity recreation creates no network object and loses no callback.

**Recommended Git checkpoint.** `phase-1/single-runtime-owner` after a device-tested ownership switch.

**Exact recommended first implementation task.** Add a failing `MeshRuntimeOwnershipTest` plus a debug-only `RuntimeOwnershipRegistry` seam that counts live construction/start/callback ownership for `MeshEngine`, `BleMeshManager`, `WifiDirectManager`, `UdpBroadcastManager`, `SocketManager`, and `TransportManager`. Assert the target invariant of exactly one service-owned instance while documenting current failures. This creates evidence and a safe seam; it must not yet relocate or rewrite networking logic.

## Phase 2 — Immutable versioned packet format

**Objective.** Introduce a versioned canonical wire packet whose sender, destination, trace, hop count, creation time, and absolute expiry remain stable across relays.

**Exact current defects.** `MeshMessage.toJson` hashes identity and trace fields on every serialization, while `fromJson` stores hashes into fields later treated as plaintext. The origin is added as a hop; `hopCount >= maxHops` makes the advertised limit inconsistent. `remainingTtlMs` is ignored and `expiresAt` is rebuilt at every relay. Headers are mutable and unauthenticated. Legacy packet compatibility is undefined.

**Dependencies.** Phase 1 sole runtime and stable codec call sites.

**Likely files/classes.** `data/models/MeshMessage.kt`, new `PacketEnvelope`/`PacketCodec`, `network/MeshEngine.kt`, `network/protocols/SyncProtocol.kt`, encryption/header utilities, and golden fixtures under `app/src/test`.

**Ordered implementation tasks.** Specify protocol version and canonical encoding; distinguish local identity material from stable wire identifiers; define origin/relay hop semantics and inclusive limit; carry immutable `createdAt` and `expiresAt`; validate sizes/ranges before processing; create a legacy decoder with explicit upgrade/drop policy; make serialization pure and deterministic; route all canonical transports through one codec; add header authentication design hooks for Phase 9.

**Automated tests.** Golden vectors; encode/decode identity; repeated encode/decode at 1/2/5/10 relays; stable sender/destination/trace; expiry never extends; boundary tests at max hops and expiry; malformed/oversize/fuzz inputs; explicit legacy-version behavior.

**Physical-device tests.** A→C direct, A→B→C, five sequential carriers, max-hop boundary, expired packet encounter, and mixed old/new prototype behavior according to the documented compatibility policy.

**Risks.** Installed prototypes become incompatible, identifier choices leak metadata, clock skew affects expiry, and dual decoders enlarge attack surface.

**Rollback strategy.** Feature-gate protocol emission by version while keeping the legacy decoder; rollback emission without rewriting stored legacy rows; never downgrade a v2 row silently.

**Explicit non-goals.** Transactional queue redesign, ACK semantics, peer concurrency, voice chunks, LoRa fragments, or final cryptographic header scheme.

**Definition of done.** Canonical vectors are deterministic; all identity/trace values remain stable through ten simulated relays; absolute expiry is identical at every hop; unsupported versions fail safely; three-device delivery reaches the intended recipient.

**Recommended Git checkpoint.** `phase-2/versioned-packet-v2`, with spec/fixtures committed before implementation.

## Phase 3 — Transactional relay persistence

**Objective.** Make relay storage idempotent, atomic, crash-safe, priority-aware, and observable from enqueue through retry.

**Exact current defects.** `relay_queue.messageId` is not uniquely constrained. Canonical enqueue deletes then inserts outside a transaction. Concurrent engines/coroutines can duplicate or lose rows. Queue cap eviction contradicts its priority-protection comment. Flush uses unordered active relays despite a priority DAO. Gossip is randomized. There is no attempt/backoff/per-peer state, and queue insertion is reported as sent.

**Dependencies.** Phase 2 stable packet ID/version/expiry.

**Likely files/classes.** `data/entities/Entities.kt` (`RelayQueueEntity`), `data/db/AppDatabase.kt` (`RelayQueueDao`, migrations), new `RelayRepository`, `network/MeshEngine.kt`, message status entity/DAO, and queue workers owned by the runtime.

**Ordered implementation tasks.** Add a unique message-ID index; define queue state and attempt timestamps; implement one `@Transaction` upsert; migrate existing duplicates deterministically; enforce absolute expiry; implement priority-preserving pressure eviction; order ready work by emergency priority then retry time; use bounded exponential backoff with jitter; separate queued/transmitted/acknowledged/permanent-failure UI status; make runtime restart reload due work.

**Automated tests.** Concurrent duplicate enqueue; crash/fault injection at transaction boundaries; migration with existing duplicates; 1,001-row pressure with priority 0 protection; retry/backoff clock tests; process-restart recovery; expiry deletion; status transition tests.

**Physical-device tests.** Enqueue offline, force-stop/restart, reconnect; flood near cap; interrupt during send; verify emergency packets survive pressure and retries resume.

**Risks.** Schema migration errors, starvation of low priority traffic, retry storms, and misleading status migration.

**Rollback strategy.** Backup/export schema; retain old columns during one release; make repository switch feature-gated; provide downgrade-safe refusal rather than destructive fallback.

**Explicit non-goals.** Delivery ACK implementation, session concurrency, BLE duty cycle, voice, and LoRa.

**Definition of done.** One row per canonical packet under concurrency and restart; no priority-0 eviction while lower priorities exist; deterministic retry scheduling; enqueue never claims delivery; migration retains all nonduplicate live data.

**Recommended Git checkpoint.** `phase-3/transactional-relay-store` after migration and fault-injection tests.

## Phase 4 — Persistent store-carry-forward ACK

**Objective.** Model a destination ACK as a canonical delayed DTN packet that is persisted, deduplicated, authenticated later by Phase 9 hooks, and relayed after disconnected encounters.

**Exact current defects.** Destination sends raw `MSG_ACK` only over the active socket. ACK has no canonical ID, version, expiry, trace, dedupe, persistence, or delayed path. Relays delete data after one upstream ACK forward without confirmation. A relay can ACK only while retaining the original queue row.

**Dependencies.** Phases 2 and 3 packet and persistence semantics.

**Likely files/classes.** packet type definitions/codec, `MeshEngine` packet processor, `RelayRepository`, message status DAO, ACK/custody state entities, and sync/inventory protocol.

**Ordered implementation tasks.** Define deterministic ACK identity referencing packet ID and final recipient; create ACK only after recipient persistence succeeds; persist it in the same relay store with bounded expiry; deduplicate idempotently; relay through the normal scheduler; update sender delivery only on a valid destination ACK; specify relay custody/deletion rules; handle duplicate, expired, forged/invalid, and out-of-order ACKs; reserve authenticated origin binding for Phase 9.

**Automated tests.** Delayed recipient and delayed return carrier; duplicate ACK; ACK before local status observation; crash after inbox insert/before ACK enqueue; missing/expired ACK; wrong destination/message reference; data retention until policy permits deletion.

**Physical-device tests.** A gives B a packet and leaves; B later meets C; C later meets B or D; ACK eventually returns to A without a continuous socket chain. Repeat with process restarts at every leg.

**Risks.** ACK amplification, permanent queue growth, premature deletion, replay, and ambiguity between end-to-end delivery and relay custody.

**Rollback strategy.** Keep legacy raw ACK receive disabled only after canonical ACK device evidence; retain data rows longer during rollout; feature-gate canonical ACK emission by protocol version.

**Explicit non-goals.** Concurrent socket sessions, battery policy, final header authentication/key lifecycle, voice, or LoRa.

**Definition of done.** Sender reaches delivered only from a persisted valid destination ACK; ACK survives process death and disconnected carriers; duplicates are harmless; queue retention/deletion is deterministic and tested.

**Recommended Git checkpoint.** `phase-4/dtn-ack` after three-device delayed-return validation.

## Phase 5 — Discovery and battery policy

**Objective.** Run true BLE scan/sleep pulses and explicit Wi-Fi/LAN transport wake, exchange, convergence, idle-timeout, and close rules from one coordinator.

**Exact current defects.** Current BLE scanning/advertising remain continuously requested and are periodically restarted; service battery modes mainly alter UDP cadence. `BatteryAwareBleManager` is dead alternative code. Multiple owners currently race. Wi-Fi Direct/TCP lacks authoritative close-after-convergence. `lan_fallback_enabled` is displayed but not consistently enforced. Doze/OEM behavior is unvalidated.

**Dependencies.** Phase 1 ownership; Phase 4 supplies a meaningful exchange-complete condition.

**Likely files/classes.** `MeshForegroundService`, `BleMeshManager`, useful policy logic from `BatteryAwareBleManager`, `WifiDirectManager`, `UdpBroadcastManager`, `TransportManager`, runtime coordinator, preferences, diagnostics.

**Ordered implementation tasks.** Define discovery state machine and measurable windows per normal/idle/backoff/power-save/emergency mode; separate BLE scan and advertising schedules; centralize wake requests; enforce LAN fallback preference; define transport session deadline, inventory convergence, pending-transfer, and idle-close rules; serialize Wi-Fi Direct operations; expose counters/timestamps; handle Android permission/throttling outcomes explicitly.

**Automated tests.** Virtual-clock state-machine tests; no scan during sleep window; emergency override; backoff; preference enforcement; one wake per event; converge/timeout/error close; repeated start/stop idempotency.

**Physical-device tests.** Screen on/off, Doze, low battery, charging, emergency mode, ten wake/exchange/close cycles, OEM scan throttling, LAN enabled/disabled, and battery drain measurement over 8/24 hours.

**Risks.** Missed encounters, OEM restrictions, Wi-Fi Direct instability, excessive radio wakeups, and false convergence closing too early.

**Rollback strategy.** Remotely/configurably select conservative policy constants; preserve one coordinator and revert only schedules; collect diagnostics before changing defaults.

**Explicit non-goals.** Multi-peer sockets, voice, LoRa, packet schema changes, or new discovery technologies.

**Definition of done.** Traces show actual scan and sleep intervals; battery modes change BLE and transport behavior; Wi-Fi/TCP opens only on policy demand and closes on convergence/timeout; encounter rate and battery budget meet documented thresholds on the device matrix.

**Recommended Git checkpoint.** `phase-5/discovery-transport-policy` with measured device evidence attached.

## Phase 6 — Peer sessions and inventory

**Objective.** Give each connected peer a distinct session and maintain correct, current per-peer inventory/Bloom synchronization.

**Exact current defects.** `SocketManager` holds one client socket and replacing it cancels the prior read job. Logical peer loops write through the same stream. Bloom filters contain only active relay IDs, omit persisted seen IDs, and become stale after handshake. Hashed destinations are compared with plaintext peer IDs. No per-peer transmission/custody state exists.

**Dependencies.** Phases 2–5 define stable IDs, persistence, ACKs, and session lifecycle.

**Likely files/classes.** `SocketManager.kt` refactored into `PeerSession`/registry, `TransportManager`, `SyncProtocol`, inventory/Bloom implementation, runtime coordinator, relay repository per-peer state, Wi-Fi Direct/LAN adapters.

**Ordered implementation tasks.** Define stable peer/session identity and lifecycle; replace global streams with a registry keyed by peer/session; bind callbacks and writes to a session; implement framed backpressure and limits; define inventory contents including active and recently seen IDs; update inventory incrementally; add exact reconciliation for Bloom false positives; persist per-peer attempt/custody state where necessary; close only after convergence/policy.

**Automated tests.** Three concurrent sessions with interleaved frames; disconnect/reconnect isolation; write routing; backpressure; stale Bloom update; false positive recovery; persisted-seen suppression; per-peer retry state; no cross-peer ACK/data leakage.

**Physical-device tests.** Three to five simultaneous devices, peer churn, duplicate inventories, one slow peer, one disconnecting peer, and repeated convergence across Wi-Fi Direct/LAN constraints.

**Risks.** Android Wi-Fi Direct may constrain topology, connection count raises memory/battery use, concurrency introduces ordering bugs, and Bloom tuning can lose opportunities.

**Rollback strategy.** Keep registry abstraction compatible with a one-session limit; lower concurrency without reverting session correctness; retain exact reconciliation fallback.

**Explicit non-goals.** Voice chunks, LoRa, final security hardening, or support for Nearby/Wi-Fi Aware.

**Definition of done.** Every logical peer maps to its own streams, callbacks, inventory, and send state; three concurrent peers exchange without cross-talk; inventory converges after mid-session changes and Bloom false positives cannot permanently suppress delivery.

**Recommended Git checkpoint.** `phase-6/peer-session-registry` after five-device churn testing.

## Phase 7 — Voice transport

**Objective.** Deliver bounded voice through the canonical packet/store/ACK/session lifecycle with chunking, integrity, retry/resume, playback, and cleanup.

**Exact current defects.** Active voice encrypts and Base64-encodes one file up to 360 KiB into one `MeshMessage`. It has no chunk checksum, chunk retry/resume, lifecycle cleanup, or playback. `VoiceMessageEnvelope` and media chunk protocol are disconnected. Generic media receive is disabled. Whole-packet retry wastes bandwidth.

**Dependencies.** Phases 2–6. No implementation before their interfaces stabilize.

**Likely files/classes.** `AudioRecorderManager`, `ChatViewModel`, `ChatScreen`, `MeshEngine` voice entry points, `VoiceMessageEnvelope`, canonical codec packet types, chunk/manifest Room entities/DAOs, `EncryptionManager`, Media3 playback, cache cleanup.

**Ordered implementation tasks.** Specify encrypted voice manifest and bounded chunk format; choose end-to-end checksum and per-chunk integrity; stream encrypt/chunk without large main-thread allocations; persist send/receive manifests and bitmap; request/retry only missing chunks; resume after restart/session change; verify full checksum before atomic publication; implement playback states and interruption handling; enforce expiry/storage quota and safe cleanup; migrate or explicitly reject legacy whole-file voice.

**Automated tests.** Boundary duration/size; loss, duplication, reordering, corruption; resume after restart; wrong key/checksum; concurrent voices; quota/expiry cleanup; incomplete file never playable; Media3 state tests.

**Physical-device tests.** 1/10/30-second recordings; link drop at 10/50/90%; delayed carriers; process death; low storage; playback interruption/headset; five sequential relays.

**Risks.** Storage pressure, metadata leakage, nonce misuse, battery cost, incompatible audio codecs, and partial-file exposure.

**Rollback strategy.** Feature-flag voice v2 sending while retaining text; preserve manifests for later resume; disable playback of unverifiable content; never fall back to unchunked LoRa transfer.

**Explicit non-goals.** Images/video/general attachments, live calling, transcription, or codec-quality redesign beyond the bounded transport need.

**Definition of done.** A 30-second voice message resumes after interruption/restart, retries only missing chunks, publishes only after checksum success, plays reliably, and expires/cleans up within documented quotas.

**Recommended Git checkpoint.** `phase-7/resumable-voice-v2` after loss/restart device evidence.

## Phase 8 — Optional LoRa adapter

**Objective.** Make LoRa an optional adapter beneath the canonical lifecycle with exactly one fragmentation/reassembly layer and collision-safe identifiers.

**Exact current defects.** `MeshEngine` fragments, then `LoraSerialManager.sendData` fragments each fragment again. Receive paths may surface partial fragments twice. `LoraPacketizer` identifies a message with a one-byte hash, enabling collisions and cross-message corruption. Service restart does not own/start LoRa. A large Base64 voice packet would produce thousands of fragments.

**Dependencies.** Phases 1–6; Phase 7 only if voice over LoRa is intentionally supported.

**Likely files/classes.** `network/lora/LoraCore.kt`, `LoraSerialManager.kt`, runtime transport adapter interface, packet codec, session/repository state, USB permission lifecycle, diagnostics.

**Ordered implementation tasks.** Decide the single fragmentation boundary; derive collision-safe transfer IDs from canonical packet IDs; specify fragment index/count/length/checksum and hard bounds; implement bounded reassembly with expiry; connect completion/failure to repository retry state; make USB attach/detach and permission runtime-owned; apply transport capability/size policy; ensure only reassembled canonical bytes reach packet processing.

**Automated tests.** MTU boundaries; loss/reorder/duplicate; simultaneous colliding-prefix IDs; corrupt header/payload; count overflow; timeout/memory cap; USB detach/restart; one and only one delivery upward.

**Physical-device tests.** Supported radios/baud rates, interference/range, detach/reattach, two simultaneous senders, delayed carrier, text and deliberately bounded voice if enabled.

**Risks.** Hardware variance, regulatory airtime, extremely low throughput, fragment floods, memory exhaustion, and pressure to fork protocol semantics.

**Rollback strategy.** Keep adapter optional and disabled by default; text continues over canonical transports; discard expired partial reassemblies without touching canonical queue data.

**Explicit non-goals.** A separate LoRa message model, second encryption layer, unrestricted media, radio firmware redesign, or guaranteed voice support.

**Definition of done.** Packet bytes fragment exactly once; transfer IDs are collision-safe; incomplete/corrupt sets never reach the codec; restart/reattach resumes according to policy; disabling LoRa changes no canonical semantics.

**Recommended Git checkpoint.** `phase-8/optional-lora-adapter` with hardware/airtime evidence.

## Phase 9 — Security, migrations and release hardening

**Objective.** Authenticate packet headers/ACKs, define identity/key lifecycle, guarantee migration safety, fail release signing closed, and enforce CI plus field validation gates.

**Exact current defects.** Headers, hops, TTL, trace, identifiers, and ACKs are unauthenticated. Metadata leaks remain. `KeyManager` may wipe corrupt secure preferences and may fall back to plaintext; key rotation lacks a transition protocol. Room calls `fallbackToDestructiveMigration()`. Migration tests and schema governance are absent today. Release uses debug signing if `key.properties` is missing. CI omits lint, instrumentation, migration, security/fuzz, release, and field-evidence gates.

**Dependencies.** All canonical formats and lifecycle behavior from Phases 1–8.

**Likely files/classes.** packet codec/security envelope, `EncryptionManager`, `KeyManager`, `SecureKeyManager`, contact/identity entities, `AppDatabase` migrations and schemas, `app/build.gradle.kts`, ProGuard/R8 rules, `.github/workflows/android-ci.yml`, manifest/network security config, fuzz and migration test suites.

**Ordered implementation tasks.** Threat-model sender, relay, replay, metadata, storage, and device compromise; authenticate immutable headers and destination ACKs with domain-separated canonical bytes; define nonce/replay windows; design identity backup/recovery and signed key transition or explicitly prohibit rotation; remove plaintext/wipe fallbacks in favor of explicit recoverable failure; add non-destructive migrations from every supported version and remove destructive fallback; make release signing fail without explicit release credentials and verify certificate; add dependency/static/fuzz/release gates; minimize logs/metadata; execute and archive the field matrix.

**Automated tests.** Header/ACK tamper and replay; wrong key; key corruption/recovery/transition; migration from each supported schema with data assertions; downgrade refusal; fuzz parser/reassembly bounds; release assemble/signature/R8 smoke; CI clean build/unit/lint/instrumentation/security gates.

**Physical-device tests.** Upgrade devices holding real messages/queue/keys; reinstall/recovery policy; tampered peer; clock skew; release APK across API/OEM matrix; long-duration background/battery/mesh field run.

**Risks.** Locking users out, invalidating contacts/ciphertext, cryptographic canonicalization mistakes, migration data loss, R8 reflection/native breakage, and signing-secret exposure.

**Rollback strategy.** Never rollback schemas destructively; stage read-old/write-new transitions; retain signed protocol-version compatibility windows; halt release on failed migration/security gates; rotate release keys only under documented store policy.

**Explicit non-goals.** New chat features, anonymous routing claims beyond the threat model, custom cryptographic primitives, or unsupported transport expansion.

**Definition of done.** Tampered/replayed headers and ACKs are rejected; identity/key behavior is documented and tested without silent reset/plaintext downgrade; every supported database upgrades without loss; release cannot be debug-signed; CI and archived device evidence satisfy all P0/P1 gates.

**Recommended Git checkpoint.** `phase-9/release-candidate-hardening`, followed by a signed release-candidate tag only after field sign-off.

## Do not work on yet

- Do not start Phase 1 until Phase 0 lint/toolchain, schema export, CI, and duplicate-file decisions are complete.
- Do not optimize routing, Bloom filters, or multi-peer behavior while ownership and wire identifiers are unstable.
- Do not implement persistent ACK before packet identity/expiry and transactional storage are fixed.
- Do not tune BLE duty cycles in the disconnected `BatteryAwareBleManager`; policy belongs in the single runtime.
- Do not implement voice playback/chunking or generic attachments before the canonical store/session lifecycle is stable.
- Do not touch LoRa fragmentation until the transport adapter contract and packet bounds exist.
- Do not invoke automatic key rotation or remove legacy migrations without an identity and data-compatibility plan.
- Do not add Nearby, Wi-Fi Aware, hotspot, NSD, or other transports during stabilization.
- Do not rewrite the app, redesign UI, activate hidden screens, or conflate queued with delivered.

## Physical-device test matrix

| Dimension/scenario | Minimum coverage | Required evidence |
|---|---|---|
| Android versions | API 24, 29/30, 31/32, 33, 34, 35 | OS/build, permissions, logs, outcome |
| Manufacturers | Google, Samsung, Xiaomi/Redmi, Oppo/OnePlus, Motorola | OEM power settings and observed latency |
| Two-device direct | Encrypted send, recipient persist, ACK return | Packet/status timeline and database assertions |
| Three-device delayed carrier | No A↔C contact | B stores after A leaves; C receives later; ACK returns later |
| Five sequential carriers | Text and ACK | Stable IDs/trace/expiry at each recorded hop |
| Hop limit | Exact boundary and one beyond | Deterministic accept/drop reason |
| Delayed encounter | Hours with UI closed | Queue survives and resumes from service only |
| Duplicate/replay | Same packet/ACK via two paths | One inbox/queue effect and safe replay rejection |
| Dropped/partial connection | Drop at framing and transfer boundaries | No corrupt delivery; queued retry remains |
| Expiration/clock skew | Before/at/after absolute expiry | No carrier extends expiry |
| Activity/process lifecycle | Rotate, destroy, swipe, kill, sticky restart | One runtime and automatic queue pump |
| Reboot | Supported restart mechanism | Runtime restored per documented policy |
| Screen off/Doze | Normal and OEM-restricted modes | Encounter latency and battery consumption |
| Battery states | Charging, normal, low, emergency | Measured BLE/UDP/transport policy transitions |
| Multi-peer | Three to five peers, churn and one slow peer | Distinct sessions with no cross-talk |
| Queue pressure | At and beyond 1,000 rows | Priority preservation and bounded storage |
| Voice | 1/10/30 sec, loss/restart/low storage | Resume, checksum, playback, cleanup |
| LoRa optional | Radio matrix, range/interference, detach | Fragment/reassembly/airtime evidence |
| Upgrade/migration | Every supported DB/key version | Before/after row and decryptability proof |
| Release | Signed minified APK on representative devices | Certificate, install/upgrade, runtime smoke |

Each field run must record app commit, protocol/schema versions, device/OS, battery settings, topology, timestamps, expected result, actual result, logs, and database/diagnostic snapshots with private content redacted.

## Branch and commit strategy

- Preserve `main` as the last verified checkpoint; use branches prefixed `codex/phase-N-short-purpose` (or the team-standard equivalent).
- One phase per branch. Do not stack Phase 2 production work on an unmerged Phase 1 review branch.
- Commit specifications, golden fixtures, and failing characterization tests before behavioral implementation when practical.
- Keep schema migrations, generated schema JSON, and migration tests in the same commit.
- Keep toolchain-only changes separate from behavior changes, and manager ownership moves separate from algorithm edits.
- Use small checkpoints named by invariant, for example `test: characterize runtime ownership`, `refactor: service owns mesh runtime`, and `test: prove cold restart queue pump`.
- Require baseline CI plus phase-specific automated tests before merge; require the listed physical evidence for phases that change radios, background lifecycle, migrations, voice, LoRa, or release behavior.
- Tag the end of each completed phase (`stabilization-phase-N`) only after its definition of done is met. Revert whole invariant commits rather than editing history; never squash away migration or protocol provenance after release.

## Next action

Complete Phase 0 first. After its definition of done, begin Phase 1 with the ownership characterization task stated above; do not begin by moving constructors or rewriting `MeshEngine`.
