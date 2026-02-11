# تقرير تغطية السيناريوهات في Sada (Scenario Coverage Report)

## 1. مقدمة (Introduction)

هذا التقرير يربط بين **السيناريوهات الواقعية** الموثقة في `SCENARIO_CATALOG.md` وبين **الوضع الفعلي للتنفيذ في كود Sada**، استنادًا إلى:

- كود `lib/` (خصوصًا: `core/network`, `core/security`, `core/database`, `core/services`, `features/chat`).
- خطط التنفيذ في `DEVELOPMENT_PLAN.md`.
- الاختبارات الموجودة في `test/` و `integration_test/`.

الهدف هو:

- تقييم مدى دعم Sada حاليًا لسيناريوهات الاتصال، الأمان، البطارية، التجربة، والمنصة.
- توضيح الفجوات الحرجة قبل أي **نشر ميداني** (احتجاجات، كوارث، رقابة).
- تقديم توصيات عملية على مستوى **الكود** و **الاختبارات** للاقتراب من الجاهزية الميدانية.

> Note (English):  
> This report is *evidence-based*: it reflects what is actually implemented in the code today, not just what is planned in the documents.

---

## 2. ملخص التغطية العامة (Overall Coverage Summary)

### 2.1 أرقام أساسية

- **إجمالي السيناريوهات في الكتالوج**: 110  
  - `S-001` → `S-020`: Connectivity & Mobility  
  - `S-021` → `S-030`: Network Density & Traffic Patterns  
  - `S-031` → `S-040`: Security & Threat Models  
  - `S-041` → `S-050`: UX & Human Factors  
  - `S-051` → `S-060`: Battery & Power Mode  
  - `S-061` → `S-070`: Platform (Android/iOS)  
  - `S-071` → `S-080`: Failures & Corruption  
  - `S-081` → `S-090`: Field Testing  
  - `S-091` → `S-100`: Advanced Features (groups, files, voice, location)  
  - `S-101` → `S-110`: Dev & CI/CD  

**تقدير حالة التغطية (من حيث الإمكانات الحالية في الكود، وليس من حيث الاختبارات):**

- **Implemented (مدعوم بشكل معقول)**: ≈ **23** سيناريو  
- **PartiallyImplemented (مدعوم جزئيًا مع فجوات)**: ≈ **66** سيناريو  
- **NotImplemented (غير مدعوم فعليًا بعد)**: ≈ **21** سيناريو  

> These numbers are approximate but consistent per-category; they reflect that most scenarios are at least *partially* covered by the current DTN + security foundations, but very few are fully “production-ready”.

### 2.2 حسب الأولوية (Criticality – P0/P1/P2)

تقدير الأولوية (استنادًا إلى المخاطر المذكورة في كل سيناريو):

- **P0 (حرج)**: سيناريوهات تتعلق بالاحتجاجات، الكوارث، الرقابة، ضياع الجهاز، الأعطال الحرجة، البطارية في أوضاع خطرة، اختبار ميداني حقيقي.  
- **P1 (مهم)**: سيناريوهات مهمة لطيّارات تجريبية جادة (جامعات، قرى، مختبرات)، لكن ليست حياة/موت.  
- **P2 (تحسينات)**: ميزات متقدمة، تحسينات UX، وتحسينات Dev/CI.

تقديريًا:

- **P0**: ~30–35 سيناريو  
  - **Implemented**: 0–2 (بشكل كامل تقريبًا)  
  - **PartiallyImplemented**: الغالبية العظمى  
  - **NotImplemented**: بعض سيناريوهات الميزات المتقدمة الأمنية / التحليلية  
- **P1**: ~40–45 سيناريو  
  - معظمها PartiallyImplemented أو NotImplemented (خصوصًا Bloom Filter, sync optimization, analytics, advanced UX).  
- **P2**: ~30–35 سيناريو  
  - العديد منها NotImplemented (groups, files, voice, location, advanced Dev/CI pipelines).

### 2.3 ملخص حسب القسم (By Category)

التوزيع التقريبي لكل 10 أو 20 سيناريو في كل قسم:

| Category (قسم)                  | Implemented | Partially | Not Implemented |
|---------------------------------|-------------|-----------|-----------------|
| Connectivity & Mobility (S-001–S-020)         | 4           | 14        | 2               |
| Network Density & Traffic (S-021–S-030)       | 2           | 7         | 1               |
| Security & Threat Models (S-031–S-040)        | 4           | 6         | 0               |
| UX / Human Factors (S-041–S-050)              | 2           | 6         | 2               |
| Battery & Power Mode (S-051–S-060)            | 3           | 6         | 1               |
| Platform (Android/iOS) (S-061–S-070)          | 2           | 7         | 1               |
| Failures & Corruption (S-071–S-080)           | 2           | 7         | 1               |
| Field Testing (S-081–S-090)                   | 1           | 6         | 3               |
| Advanced Features (S-091–S-100)               | 0           | 2         | 8               |
| Dev & CI/CD (S-101–S-110)                     | 3           | 5         | 2               |

> Interpretation:  
> - Core **security + DB + basic DTN routing** are relatively strong (many scenarios at least partially covered).  
> - **High-density, adversarial, and large-scale field scenarios** are mostly only *partially* supported due to missing congestion control hardening, incomplete ACK testing, and limited observability.  
> - **Advanced features** (groups, files, voice, location, panic channels) are essentially **not implemented** yet.  

---

## 3. تحليل السيناريوهات الحرجة (Critical Scenarios – P0)

فيما يلي مجموعة مختارة من السيناريوهات الحرجة (P0) الأكثر ارتباطًا بحالات الاستخدام الأساسية لـ Sada (احتجاجات، كوارث، رقابة، قمع سياسي)، مع حالة تغطية مختصرة.

> ملاحظة: معظم هذه السيناريوهات مصنّفة **PartiallyImplemented** لأن البنية التحتية الأساسية موجودة لكن ينقصها واحد أو أكثر من العناصر التالية: ACK موثوق، تحكم بالازدحام، UX واضح، اختبارات قوية، أو صلابة لخلفية Android.

### S-003 – سلسلة ثلاثية العقد في مبنى مكون من طابقين

- **Status:** PartiallyImplemented  
- **Summary (English):** 3 devices forming a simple 3-hop chain across floors; A needs to reach C via B.  
- **Why this matters:** Basic multi-hop reliability is a minimal DTN requirement for real-world use (offices, campuses, safe houses).  
- **Key implementation notes:**
  - `MeshService` + `MeshMessage` support multi-hop Store-Carry-Forward over TCP/UDP (`_storeAndForward`, `_forwardMessage`), and `EpidemicRouter` + `RelayPacket` implement multi-hop via Nearby.  
  - `RelayQueueTable` and `AppDatabase` support storing in-transit packets with TTL and trace metadata.  
- **Gaps:**
  - **Protocol/routing:** Bloom Filter / optimized sync missing; duplicate/loop control relies mostly on basic trace/TTL and `_processedMessages`.  
  - **UX:** No specific multi-hop awareness; user only sees standard MessageStatus; no "via relays" indicator.  
  - **Testing:** No end-to-end automated test explicitly covering stable 3-hop paths; only basic DB and auth tests exist (`simulation_test.dart`), and integration test is UI-centric (`app_test.dart`).

---

### S-004 – حركة مستخدم في حافلة بين حيين مع عقد ثابتة في كل حي

- **Status:** PartiallyImplemented  
- **Summary (English):** One “bridge” user commuting between two neighborhoods, carrying messages between two semi-disconnected clusters.  
- **Why this matters:** This is a canonical DTN “data mule” scenario, crucial for villages and segregated communities.  
- **Key implementation notes:**
  - DTN core (RelayQueue, TTL, blind relay) is in place: `RelayQueueTable`, `AppDatabase.enqueueRelayPacket`, `getRelayPacketsForSync`, `cleanupExpiredPackets`.  
  - BackgroundService and duty cycle (`background_service.dart`) can keep mesh active periodically while the bridge moves.  
- **Gaps:**
  - **Protocol/routing:** No explicit per-path performance tuning; TTLs and queue limits are static; no path awareness.  
  - **UX:** Users are not told that some messages may rely on “bridge” nodes and can take hours.  
  - **Testing:** No simulation test validating long-delay, commute-style topologies or measuring delivery success over 24h+.

---

### S-012 – قارب إنقاذ يتحرك بين نقطتي تجمع في كارثة

- **Status:** PartiallyImplemented  
- **Summary (English):** A boat shuttles between two isolated clusters, delivering messages with very long delay and critical emotional stakes.  
- **Why this matters:** Represents disaster-relief use cases where Sada might be deployed by NGOs.  
- **Key implementation notes:**
  - Long TTLs possible via `RelayPacket.ttl` + `isExpired()` + DB cleanup logic; messages can be retained for days if configured.  
  - Duress, encryption, and whitelist security are strong foundations for content safety.  
- **Gaps:**
  - **Protocol/routing:** No explicit configuration UI for setting higher TTLs for critical/disaster contexts.  
  - **UX:** No disaster-specific messaging; users might misinterpret multi-day delays as app failure.  
  - **Testing:** No long-duration soak tests for days-long delays, battery usage, or storage expansion on the “boat” devices.

---

### S-017 – اتصال بين مخيم لجوء ومدينة قريبة عبر متطوعين متحركين

- **Status:** PartiallyImplemented  
- **Summary (English):** Volunteers shuttle between a refugee camp and a city, carrying DTN messages for separated families.  
- **Why this matters:** High-impact humanitarian setting where reliability and privacy are critical.  
- **Key implementation notes:**
  - Security model (X25519 + XSalsa20-Poly1305 + whitelist) and duress mode are well implemented (`encryption_service.dart`, `key_manager.dart`, `auth_service.dart`).  
  - DTN primitives (RelayQueue, TTL, blind relay) can, in principle, support this scenario.  
- **Gaps:**
  - **Protocol/routing:** No priority or “critical message” notion in `RelayPacket`/`MeshMessage`.  
  - **UX:** No special flows for humanitarian use (explanations, priority flags, message retention settings).  
  - **Testing:** No field-like simulations or regression tests specifically for humanitarian bridging.

---

### S-018 – عبور حدود دولة مع رقابة شديدة

- **Status:** PartiallyImplemented  
- **Summary (English):** User with Sada crosses a heavily monitored border where device inspections happen.  
- **Why this matters:** This scenario drives the entire duress and zero-trust design.  
- **Key implementation notes:**
  - Duress PIN and dual mode logic implemented in `AuthService` with hashed PINs and distinct `AuthType` values; DB switching is documented (real vs decoy).  
  - All content is encrypted at rest (Drift DB) and in transit (libsodium secretBox), with hashed identifiers for routing.  
- **Gaps:**
  - **Security/privacy:** Ed25519 signatures and full metadata minimization (e.g., trace hardening) are still planned, not implemented.  
  - **UX:** Duress onboarding is not deeply integrated into the app’s UI; decoy DB content quality is not validated by tests.  
  - **Testing:** No automated or scripted tests validating correct DB switching and on-disk indistinguishability under duress.

---

### S-022 – شبكة عالية الكثافة في احتجاج ضخم

- **Status:** PartiallyImplemented  
- **Summary (English):** Hundreds or thousands of users densely packed (protest) generating heavy DTN traffic.  
- **Why this matters:** High-risk political scenarios, flagship use case for Sada.  
- **Key implementation notes:**
  - **Congestion control:** Token Bucket per peer is implemented in `EpidemicRouter` (`_peerTokens`, `_consumeToken`, `_tokenRefillTimer`) limiting packets per endpoint per minute.  
  - **Relay quotas:** RelayQueue has a max count (`AppConstants.relayQueueMaxCount`, `_trimRelayQueue` in `AppDatabase`) to bound storage.  
- **Gaps:**
  - **Protocol/routing:** No per-node global flood controls; no Bloom Filter or efficient summary-based sync yet (TODO in `getRelayPacketsForSync`).  
  - **UX:** No explicit “Protest Mode” toggle or warnings about battery and congestion; no monitoring dashboard.  
  - **Testing:** No large-scale, high-density simulations or automated stress tests; current tests focus on auth/DB/UI.

---

### S-031 – مصادرة الجهاز ومحاولة الوصول إلى البيانات

- **Status:** PartiallyImplemented  
- **Summary (English):** Attacker seizes device and tries to inspect stored Sada data.  
- **Why this matters:** Core censorship-resistance and personal safety requirement.  
- **Key implementation notes:**
  - All message content and relay payloads are encrypted (Drift stores ciphertext from `MessageMapper` and `RelayQueueTable` uses opaque `payload`).  
  - Duress mode and secure storage via `FlutterSecureStorage` are implemented.  
- **Gaps:**
  - **Security/privacy:** No cryptographic signatures yet for authenticity; no per-field audit ensuring no accidental plaintext logs.  
  - **Testing:** Limited tests (e.g., `simulation_test.dart`) cover auth logic; no automated tests assert that no plaintext ever hits disk or logs.

---

### S-032 – إكراه المستخدم على فتح التطبيق أمام المهاجم

- **Status:** PartiallyImplemented  
- **Summary (English):** User is forced to unlock Sada and show chats to an attacker.  
- **Why this matters:** Duress functionality is designed mainly for this situation.  
- **Key implementation notes:**
  - `AuthService` supports `AuthType.master` and `AuthType.duress` with independent PINs; tests verify PIN handling logic.  
- **Gaps:**
  - **Security/privacy:** Real-vs-decoy DB switching is implied but not deeply validated in tests.  
  - **UX:** No explicit UX flows to ensure decoy conversations are plausible and do not leak that duress is active.  

---

### S-034 – إعادة تشغيل الحزم (Replay Attack)

- **Status:** PartiallyImplemented  
- **Summary (English):** Attacker replays old RelayPackets to cause confusion or congestion.  
- **Why this matters:** Impacts trust in received messages and can waste resources.  
- **Key implementation notes:**
  - TTL and `isExpired()` in `RelayPacket` plus DB cleanup in `cleanupExpiredPackets()` mitigate long-lived replays.  
  - Dedup (in-memory `_seenPacketIds` + `AppDatabase.hasPacket`) prevents repeated acceptance.  
- **Gaps:**
  - **Security:** No signatures yet, so authenticity of packets cannot be cryptographically validated.  
  - **Testing:** No replay-specific tests; behavior is only implicitly tested through general relay code.

---

### S-051 – وضع الأداء العالي في احتجاج مستمر لعدة ساعات

- **Status:** PartiallyImplemented  
- **Summary (English):** User enables a high-scan/high-duty mode to maximize DTN connectivity during a long protest.  
- **Why this matters:** Directly impacts battery, reliability, and user safety in protests.  
- **Key implementation notes:**
  - `BackgroundService._startDutyCycle` supports `PowerMode.highPerformance` with continuous scanning and updated notifications.  
  - Foreground notification and Android foreground service integration are implemented.  
- **Gaps:**
  - **Battery/platform:** No automated or empirical tuning across devices; wake lock handling is not deeply verified in tests.  
  - **UX:** No prominent user-facing “Protest Mode” toggle with clear energy vs reliability messaging.  
  - **Testing:** No long-duration automated tests (4–8h) validating thermal and battery behavior at high duty cycle.

---

### S-063 – OS kills background service بشكل متكرر

- **Status:** PartiallyImplemented  
- **Summary (English):** Aggressive OEMs or Android Doze kill the background service often.  
- **Why this matters:** Without stable background behavior, DTN is unreliable in real life.  
- **Key implementation notes:**
  - Foreground service with ongoing notification implemented using `flutter_background_service` and `BackgroundService`.  
  - Duty cycle is explicitly handled via timers (`_dutyCycleTimer`) and power modes.  
- **Gaps:**
  - **Platform:** No systematic re-start-on-kill logic tested across OEMs; some OEMs require explicit user whitelisting.  
  - **Testing:** No device-matrix CI for power management behavior; integration tests focus on UI only.

---

### S-071 – تعطل التطبيق أثناء عملية التشفير

- **Status:** NotImplemented (in terms of robust handling)  
- **Summary (English):** App crashes mid-encryption, potentially leaving inconsistent DB state.  
- **Why this matters:** Corrupted messages and inconsistent state undermine trust and reliability.  
- **Key implementation notes:**
  - Encryption is handled in `EncryptionService` and then persisted via `MessageMapper.toCompanion` and `AppDatabase.insertMessage`.  
  - There is **no explicit transactional wrapper** around "encrypt + insert" to guarantee atomicity against app crashes.  
- **Gaps:**
  - **Protocol/logic:** No mechanism to mark messages as “pending encryption” vs “stored and safe”.  
  - **Testing:** No fault-injection tests simulating crashes between stages; current tests in `simulation_test.dart` focus on happy-path crypto.  

---

### S-081 – اختبار ميداني في قرية ريفية بدون إنترنت

- **Status:** PartiallyImplemented  
- **Summary (English):** Multi-day offline pilot in a rural area with sparse encounters.  
- **Why this matters:** Canonical low-density, offline use-case; core to Sada’s mission.  
- **Key implementation notes:**
  - DTN primitives (RelayQueue, TTL, background duty cycle) are present; encryption + duress are in place.  
  - No code prevents such pilots; the app can technically run entirely offline.  
- **Gaps:**
  - **UX:** Messaging around long delays and expected behavior is minimal; risk of user confusion/uninstalls.  
  - **Testing:** No long-running soak tests or telemetry to learn from pilot performance; no diagnostics mode for field teams.

---

### S-083 – تجربة Sada في مظاهرة حقيقية

- **Status:** NotImplemented (for safe field deployment)  
- **Summary (English):** Volunteers use Sada during a real protest with risk of repression and network outages.  
- **Why this matters:** High-stakes, real-world target scenario for Sada.  
- **Key implementation notes:**
  - Core crypto and DTN exist, but ACK, congestion control, and background behavior are not yet validated at protest scale.  
  - No UX for guiding users in such high-risk settings, no robust field monitoring tools.  
- **Gaps:**
  - **Protocol/routing:** ACK pipeline and congestion control not yet heavily tested under bursty, dense protest conditions.  
  - **Security:** No formal security review or Ed25519 signatures; metadata leakage risk remains.  
  - **UX:** No clear onboarding or protest-specific flows; user errors under stress likely.  
  - **Testing:** No controlled protest drills or realistic simulations at required scale.

---

## 4. فجوات أساسية (Key Gaps Blocking Real-World Use)

استنادًا إلى الكود الحالي والسيناريوهات الحرجة، يمكن تلخيص الفجوات الرئيسية كالتالي:

- **1) ACK-based Delivery & MessageStatus**
  - جزء من منطق ACK موجود الآن (MeshMessage.typeAck, `_handleAck` في `MeshService`, ACK generation في `IncomingMessageHandler`)، لكنه **غير مختبر تقريبًا** ولا يغطي السيناريوهات المعقدة (loops, duplicates, lost ACKs).  
  - سيناريوهات مثل S-003, S-004, S-022, S-021, S-026 تتطلب ACK موثوقًا لتقديم حالة `delivered` ذات معنى.

- **2) Congestion Control & Relay Quotas**
  - Token Bucket per-peer مضاف في `EpidemicRouter`، وحد RelayQueue العددي مضاف في `AppDatabase`, لكن:
    - لا يوجد قياس أو ضبط حقيقي للقيم في بيئات عالية الكثافة (S-022, S-025, S-029).  
    - لا يوجد تحكم شامل per-node أو per-message-priority.  

- **3) Sync Optimization (Bloom Filter / Delta Sync)**
  - `getRelayPacketsForSync()` ما زال يقوم بإرجاع جميع الحزم؛ Bloom Filter / vector summary ما زالت TODO.  
  - هذا يؤثر على سيناريوهات الكثافة العالية والمدينة/الجامعة (S-009, S-022, S-028, S-024).

- **4) UX for Delays, Network Status, and Duress**
  - Chat UI مميز وMessageBubble يدعم الحالات الأساسية، لكن:
    - لا يوجد شروحات واضحة داخل التطبيق لزمن التسليم الطويل أو حالة الشبكة (S-021, S-041–S-047).  
    - Duress mode قوي تقنيًا، لكن UX حوله حساس وغير موثق بما يكفي داخل التطبيق (S-018, S-032, S-045).  

- **5) Android Background Service Robustness**
  - `BackgroundService` و`PowerMode` موجودان لكن:
    - لا توجد اختبارات آلية طويلة المدى للتعامل مع Doze, OEM killers, restarts (S-051–S-055, S-063, S-069).  
    - لا توجد توجيهات واضحة للمستخدم حول whitelisting وما إلى ذلك.  

- **6) iOS Transport & Background**
  - لا يوجد مسار نقل فعلي لـ iOS حتى الآن؛ كل سيناريوهات الشبكة المختلطة (S-062) غير مدعومة عمليًا.  

- **7) Failures, Corruption, and Security Hardening**
  - لا يوجد handling متقدم لتعطل أثناء التشفير / الكتابة إلى DB (S-071, S-072, S-074).  
  - توقيعات Ed25519، وحدات حماية إضافية ضد replay/flooding، وتحليلات traffic لا تزال في مرحلة التخطيط وليس الكود.  

- **8) Advanced Features (Groups, Files, Voice, Location, Panic)**
  - جداول/Repositories للمجموعات موجودة جزئيًا، لكن **Group routing في DTN**, file/voice/location/panic channels غير موجودة فعليًا (S-091–S-100).  

- **9) Test Coverage for DTN & Routing**
  - `simulation_test.dart` يغطي الأمن (encryption) والذاكرة (DB) وAuth من منظور بسيط.  
  - `integration_test/app_test.dart` يغطي Happy Path UI وSettings فقط.  
  - لا توجد اختبارات مفصلة لمسارات:  
    - EpidemicRouter handshake/sync.  
    - RelayQueue behavior تحت الضغط.  
    - MeshMessage multi-hop & ACK behavior.  
    - BackgroundService + duty cycle تفاعلاً مع النظام.  

هذه الفجوات تؤثر مباشرة على العديد من السيناريوهات P0، خاصة: S-003, S-004, S-012, S-017, S-018, S-022, S-031, S-032, S-034, S-051, S-063, S-071, S-081, S-083.

---

## 5. توصيات للإصدار الميداني الأول (Recommendations for First Field Release)

### 5.1 P0 – MUST Fix قبل أي نشر ميداني حقيقي

- [ ] **إكمال وتثبيت خط ACK بالكامل**  
  - توحيد منطق ACK (إما عبر MeshMessage.typeAck أو AckPacket في RelayPacket) بحيث:  
    - يتم إنشاء ACK دائمًا عند الاستلام النهائي (في `IncomingMessageHandler`).  
    - يتم تحديث `AppDatabase.updateMessageStatus` إلى `delivered` فقط عند وصول ACK إلى المرسل الأصلي.  
  - إضافة اختبارات وحدة/اندماج تغطي: ACK loss, duplicate ACKs, late ACKs, replayed ACKs.

- [ ] **تشديد Congestion Control & Relay Quotas**  
  - ضبط قيم Token Bucket (per-peer/per-node) عمليًا عبر تجارب.  
  - إضافة مقاييس (logging/metrics) لرصد الحالات التي يتم فيها إسقاط الحزم بسبب تجاوز الـ tokens أو quotas.  
  - اختبارات simulation تغطي سيناريوهات S-022, S-025, S-029.

- [ ] **تقوية BackgroundService وسلوك الطاقة على Android**  
  - مراجعة منطق `BackgroundService`، التأكد من:  
    - دمج wake locks (إن لم تكن مدمجة عبر plugin) بطريقة آمنة.  
    - التعامل مع kill/restart بشكل واضح.  
  - بناء اختبارات طويلة المدى (12–24 ساعة) على أجهزة حقيقية ذات OEMs مختلفة.

- [ ] **UX أساسي حول التأخير وDuress Mode**  
  - إضافة شرح بسيط داخل التطبيق:  
    - عن طبيعة DTN والتأخير (في Onboarding + Help).  
    - عن Duress Mode (بشكل لا يساعد المهاجم لكن يوجه المستخدمين).  
  - إضافة tooltips أو شروحات لأيقونات الحالة (sending/sent/delivered/failed).

### 5.2 P1 – مهم لنسخ Beta على نطاق أوسع

- [ ] **Sync Optimization (Bloom Filter / Delta Sync)**  
  - تنفيذ Bloom Filter كما في `DEVELOPMENT_PLAN.md` لتقليل حجم Handshake Summary.  
  - اختبارات اندماج لسيناريوهات الكثافة العالية.

- [ ] **Network Dashboard & Observability**  
  - شاشة Debug (mesh_debug_screen) تعرض: peer count, duty cycle state, RelayQueue size, basic health.  

- [ ] **Core Test Coverage for Routing + Crypto**  
  - اختبارات وحدة لمنطق TTL / dedup / trace في `RelayPacket` و`MeshMessage`.  
  - اختبارات simulation لمسارات multi-hop, replay, partial delivery.

### 5.3 P2 – تحسينات لاحقة

- [ ] **Features متقدمة (Groups, Files, Voice, Location, Panic)**  
  - لن تُمنع النسخة الميدانية الأولى بغيابها، لكنها مهمة لاحقًا.  

- [ ] **Analytics وCI محسّن**  
  - ملف آلي mapping (مثل `SCENARIO_IMPLEMENTATION_MATRIX`) يربط كل S-XXX بالحالة الحالية؛ يمكن إضافته لاحقًا لتغذية CI وأدوات التحليل.

---

## 6. هل التطبيق جاهز ميدانياً؟ (Is Sada Field-Ready?)

**الإجابة المختصرة (Arabic):**  
Sada حاليًا في مرحلة **Alpha متقدمة / Early Beta** من ناحية الـ DTN والـ Security، لكنه **غير جاهز بعد** للاستخدام الميداني عالي الخطورة (احتجاجات كبيرة، كوارث، بيئات ذات رقابة قمعية) بدون تحسينات إضافية واختبارات مكثفة. يمكن تجربته في **طيّارات تجريبية صغيرة ومسيطر عليها** (مثل مجموعات في جامعات أو قرى صغيرة) مع وعي كامل بالمخاطر والقيود.

**Short answer (English):**  
Sada is in an **advanced alpha / early beta** state: the core crypto and DTN foundations are solid, but missing hardening in ACK delivery, congestion control, background reliability, UX clarity, and automated tests prevent it from being truly field-ready for high-risk scenarios. It is suitable for **small, controlled pilots**, not yet for large-scale protests or disaster deployments.

**التبرير:**

- سيناريوهات P0 الأساسية (S-003, S-004, S-012, S-017, S-018, S-022, S-031, S-032, S-034, S-051, S-063, S-071, S-081, S-083) جميعها على الأقل **PartiallyImplemented** لكن لا يوجد أي منها مغطى بالكامل باختبارات واتزان بروتوكولي.  
- طبقة الأمن (التشفير، إدارة المفاتيح، Duress Mode، Whitelisting) قوية نسبيًا مقارنة بعمر المشروع، لكن ما زالت تحتاج مراجعة وتحسين اختبارات عدم تسريب المحتوى.  
- طبقة الشبكة DTN/Epidemic تمتلك اللبنات الأساسية (RelayQueue, TTL, Nearby, MeshService)، لكنها تفتقر إلى:  
  - ACK مستقر ومختبَر.  
  - Sync optimizations (Bloom Filter).  
  - Robust congestion control under heavy load.  
- طبقة UX لا تشرح بما فيه الكفاية التأخير، حالة الشبكة، وDuress للمستخدمين غير التقنيين تحت الضغط.  
- لا توجد تغطية اختبارية كافية للمسارات الحرجة في DTN، ولا اختبارات ميدانية موثقة داخل الكود/CI.

**التوصية العملية:**  
استخدم Sada حاليًا في:

- تجارب تطويرية،  
- طيّارات صغيرة في بيئات منخفضة الخطورة (جامعة، حي صغير، مجموعات أصدقاء)،  

لكن **لا** تعتمد عليه بعد كأداة رئيسية في:

- احتجاجات كبيرة مع قمع أمني،  
- كوارث طبيعية واسعة النطاق،  
- أو عمليات تحتاج موثوقية عالية ورسائل حسّاسة جدًا.  

بعد تنفيذ عناصر P0 المذكورة في القسم 5، وإضافة طبقة اختبارات قوية، يمكن إعادة تقييم الجاهزية الميدانية بشكل أكثر ثقة.  


