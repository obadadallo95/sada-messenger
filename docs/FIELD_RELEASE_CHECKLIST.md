# قائمة جاهزية الإصدار الميداني الأول لـ Sada (Field Release Checklist)

## 1. مقدمة (Introduction)

هذا المستند هو **قائمة جاهزية للإصدار الميداني الأول** لـ Sada، يترجم:

- تقرير تغطية السيناريوهات `SCENARIO_COVERAGE_REPORT.md`
- كتالوج السيناريوهات `SCENARIO_CATALOG.md`
- خطة التطوير `DEVELOPMENT_PLAN.md`
- حالة الكود الحالية في `lib/`, `test/`, `integration_test/`

إلى **قائمة مهام عملية ومحددة** تساعد على نقل Sada من حالة "Alpha متقدمة" إلى حالة "جاهز لتجارب ميدانية صغيرة ومضبوطة".

التعريف المستهدف لـ **"small controlled pilot"**:

- نطاق جغرافي محدود (مدينة/منطقة واحدة).
- عدد مستخدمين محدود (يفضل < 200 جهاز).
- تُستخدم Sada في:
  - احتجاجات صغيرة أو متوسطة.
  - تجارب تنسيق مجتمعية أو تدريبات طوارئ.
- مع **تنبيه واضح** للمشاركين بأنها نسخة **Alpha متقدمة / Early Beta** مع حدود معروفة.

> Out of scope (ليس ضمن هذا الإصدار):  
> - انتشار على مستوى دولة كاملة أو عشرات الآلاف من المستخدمين.  
> - اعتماد كامل في سياقات حياة/موت بدون خط اتصال بديل.  

***

## 2. أهداف الإصدار الميداني (Field Release Objectives)

- **موثوقية التوصيل متعدد القفزات (Multi-hop Reliability)**  
  رسائل النص القصير يجب أن تنتقل عبر عدّة عقد (2–4 قفزات) في شبكات صغيرة/متوسطة بكفاءة معقولة، مع حالة MessageStatus ذات معنى.

- **تجربة مستخدم صادقة وواضحة حول التأخير وحالة الشبكة**  
  المستخدمون يفهمون أن التأخير طبيعي في DTN، وأن حالة `sending/sent/delivered/failed` تعكس الواقع بصدق، مع شروحات بسيطة داخل التطبيق.

- **أساس أمني قوي**  
  - تشفير من الطرف إلى الطرف (X25519 + XSalsa20-Poly1305) مفعّل بشكل افتراضي.  
  - Duress Mode + Duress PIN تعمل كما هو موصوف، مع Whitelisting للمراسلة.  

- **استقرار على Android مع استهلاك بطارية معقول**  
  - BackgroundService وEpidemicRouter يعملان بثبات في الخلفية ضمن قيود Doze وقيود الشركات المصنّعة.  
  - PowerMode (high/balanced/low) يقدّم توازنًا عمليًا بين الاستهلاك والموثوقية.  

- **حد أدنى من المراقبة والـ Debugging للطيّارات الميدانية**  
  - شاشة Debug أساسية (Mesh / Power / Peer Count / RelayQueue Size).  
  - Logging كافٍ لاستنتاج مشاكل التوجيه/الازدحام دون تسريب محتوى حساس.  

***

## 3. مهام حرجة P0 (P0 – Critical Tasks Before Any Field Use)

> جميع المهام في هذا القسم يجب اعتبارها **Blockers** قبل أي تجربة ميدانية حقيقية، خاصةً للسيناريوهات الحرجة P0 المذكورة في `SCENARIO_COVERAGE_REPORT.md` (مثل S-003, S-004, S-012, S-017, S-018, S-022, S-031, S-032, S-034, S-051, S-063, S-071, S-081, S-083).

### 3.1 موثوقية تسليم الرسائل (ACK & MessageStatus Reliability)

| Task ID | Description (English) | Linked Scenarios (S-XXX) | Code Areas (files/modules) | Priority | Status |
|--------|------------------------|---------------------------|----------------------------|----------|--------|
| P0-ACK-1 | Finalize end-to-end ACK pipeline so that every final recipient emits a MeshMessage/RelayPacket ACK back to the original sender, updating MessageStatus to `delivered` only when ACK arrives. | S-003, S-004, S-012, S-017, S-021, S-022, S-026, S-081 | `mesh_service.dart`, `incoming_message_handler.dart`, `mesh_message.dart`, `app_database.dart`, `chat_controller.dart` | P0 | TODO |
| P0-ACK-2 | Ensure ACK packets themselves follow DTN semantics (RelayPacket-based store-carry-forward, TTL, dedup) so that ACKs can traverse multiple hops reliably. | S-003, S-004, S-012, S-017, S-022 | `epidemic_router.dart`, `relay_packet.dart`, `AppDatabase` RelayQueue methods | P0 | TODO |
| P0-ACK-3 | Align `MessageStatus` transitions with ACK logic (`draft → sending → sent → delivered → read/failed`) and remove any fake or time-based auto-`delivered` heuristics. | S-041, S-042, S-048 | `message_model.dart`, `message_mapper.dart`, `message_bubble.dart`, `app_database.dart` | P0 | TODO |
| P0-ACK-4 | Add unit/integration tests for ACK flows, including: lost ACKs, duplicate ACKs, delayed ACKs (hours later), and replayed ACKs that must not regress MessageStatus. | S-034, S-021, S-026 | `test/` (new ACK-focused tests), `integration_test/` (multi-device or simulated multi-hop), possibly a new `dtn_ack_test.dart` | P0 | TODO |
| P0-ACK-5 | Add logging/metrics hooks (without content) for ACK success/failure counts per message and per pilot run, to be inspected after field tests. | S-081, S-083 | `log_service.dart`, `mesh_service.dart`, `epidemic_router.dart`, optional `core/metrics/*` module | P0 | TODO |

---

### 3.2 التحكم بالازدحام وحدود Relay Queue (Congestion Control & Quotas)

| Task ID | Description (English) | Linked Scenarios (S-XXX) | Code Areas (files/modules) | Priority | Status |
|--------|------------------------|---------------------------|----------------------------|----------|--------|
| P0-CON-1 | Validate and tune per-peer Token Bucket settings (tokens per minute, refill interval) in `EpidemicRouter` under simulated high-density conditions; derive recommended defaults for pilots. | S-022, S-025, S-028, S-029, S-030 | `epidemic_router.dart` (Token Bucket fields), new tests in `test/` simulating flooding | P0 | TODO |
| P0-CON-2 | Extend RelayQueue quota from simple count-based limit to approximate byte-based quota (e.g., 50–100 MB), with clear eviction policy (oldest, failed, or low-priority packets first). | S-004, S-012, S-021, S-022, S-025, S-026 | `app_database.dart` (RelayQueue methods), `constants.dart` (size thresholds) | P0 | TODO |
| P0-CON-3 | Implement optional per-message or per-category priority flag (e.g., panic vs normal) in `RelayPacket`/`MeshMessage`, to bias eviction and congestion decisions for future panic/SOS use. | S-025, S-097 | `relay_packet.dart`, `mesh_message.dart`, `AppDatabase` schema & migrations | P0 | TODO |
| P0-CON-4 | Add tests for flooding and spam scenarios: malicious node flooding random packets, malfunctioning client resending same packet, many-to-one traffic to coordinator. Ensure queues remain bounded and app stays responsive. | S-022, S-025, S-029, S-030, S-023 | `test/` (new `congestion_simulation_test.dart`), possibly a lightweight simulation harness around `EpidemicRouter` + `AppDatabase` | P0 | TODO |
| P0-CON-5 | Add runtime metrics (visible in debug screen) for RelayQueue size, dropped packets due to quota, and token-bucket drops per peer. | S-022, S-028, S-081 | `mesh_debug_screen.dart` (or new), `epidemic_router.dart`, `app_database.dart` | P0 | TODO |

---

### 3.3 خدمة الخلفية وسلوك البطارية (Background Service & Battery Behavior)

| Task ID | Description (English) | Linked Scenarios (S-XXX) | Code Areas (files/modules) | Priority | Status |
|--------|------------------------|---------------------------|----------------------------|----------|--------|
| P0-BG-1 | Review and harden `BackgroundService` lifecycle: ensure foreground notification is always present when DTN is active, handle `onStart`/`stop` flows robustly, and avoid silent service death. | S-051, S-054, S-055, S-063, S-069 | `background_service.dart`, Android manifest & notification channel config | P0 | TODO |
| P0-BG-2 | Integrate explicit wake lock handling (via plugin or platform integration) so that critical DTN operations (handshakes, packet flush) are not interrupted by aggressive Doze, while keeping usage bounded. | S-051, S-063 | `background_service.dart` (Android-specific sections), platform channels if needed | P0 | TODO |
| P0-BG-3 | Implement practical PowerMode/duty cycle policies (balanced/high/low) backed by real scan/sleep intervals, and ensure EpidemicRouter's `startDutyCycle`/`stopDutyCycle` are consistent with BackgroundService. | S-051, S-052, S-055, S-056, S-058 | `background_service.dart`, `power_mode.dart`, `discovery_strategy.dart`, `epidemic_router.dart` | P0 | TODO |
| P0-BG-4 | Run multi-hour battery and connectivity soak tests on representative Android devices (stock + OEM) to calibrate defaults; codify results into comments/README for operators. | S-051, S-052, S-055, S-063, S-081 | Manual test plans + `docs/POWER_MANAGEMENT_SETUP.md`, logging hooks in `background_service.dart` / `epidemic_router.dart` | P0 | TODO |
| P0-BG-5 | Improve user guidance about battery optimizations / app whitelisting (simple in-app texts + links for OEM-specific guidance). | S-054, S-063 | `features/settings/presentation/*`, `UI_UX_AUDIT_REPORT.md` driven copy | P0 | TODO |

---

### 3.4 تجربة التأخير، حالة الشبكة، ووضع Duress (UX for Delays, Network Status, Duress)

| Task ID | Description (English) | Linked Scenarios (S-XXX) | Code Areas (files/modules) | Priority | Status |
|--------|------------------------|---------------------------|----------------------------|----------|--------|
| P0-UX-1 | Add concise in-app explanations (onboarding + help screens) for DTN behavior: delays, multi-hop, offline-first; ensure users do not expect internet-like real-time delivery. | S-021, S-041, S-042, S-044, S-048, S-049 | `onboarding/*`, `help_about_screen.dart` (or new), localized strings | P0 | TODO |
| P0-UX-2 | Refine message status UI to clearly distinguish: sending (no peer yet), sent (in DTN/RelayQueue), delivered (ACKed by final device), failed (TTL expired/broken route). Add a simple legend/tooltip. | S-041, S-042, S-047 | `message_model.dart`, `message_mapper.dart`, `message_bubble.dart`, `chat_screen.dart` | P0 | TODO |
| P0-UX-3 | Implement a lightweight network status indicator (chip or status bar) showing: mesh active/inactive, approximate peer count, and current PowerMode. | S-001, S-002, S-009, S-051, S-055 | `home_screen.dart`, `mesh_debug_screen.dart` (or header widget), `background_service.dart` hooks | P0 | TODO |
| P0-UX-4 | Improve duress UX: ensure flows for setting/using duress PIN are clear to the owner but do not reveal duress mode to an observer; document behavior in a privacy-respecting way. | S-018, S-031, S-032, S-040, S-045 | `auth_service.dart`, `auth/presentation/*`, `duress_settings_screen.dart` (if present/added) | P0 | TODO |
| P0-UX-5 | Add safe-copy texts and microcopy for confiscation & border scenarios (what duress does/does not protect), available in help/privacy section. | S-018, S-031, S-032, S-040 | `UI_UX_AUDIT_REPORT.md` derived copy, help/privacy screen implementation | P0 | TODO |

---

### 3.5 الأعطال والتلف والصلابة الأمنية (Failures & Corruption & Security Hardening)

| Task ID | Description (English) | Linked Scenarios (S-XXX) | Code Areas (files/modules) | Priority | Status |
|--------|------------------------|---------------------------|----------------------------|----------|--------|
| P0-FAIL-1 | Make message encryption + DB insert atomic: either encrypt then insert transactionally, or use a pending state to avoid partially-written records if the app crashes mid-encryption. | S-071, S-072, S-074 | `encryption_service.dart`, `chat_controller.dart`, `app_database.dart` (transactions) | P0 | TODO |
| P0-FAIL-2 | Add robust JSON parsing and quarantine for malformed RelayQueue payloads (invalid MeshMessage JSON); ensure they do not crash the router or message handler. | S-072, S-078 | `incoming_message_handler.dart`, `mesh_service.dart`, `epidemic_router.dart`, tests in `test/` | P0 | TODO |
| P0-FAIL-3 | Introduce basic signature or integrity checks roadmap (even if Ed25519 is not fully rolled out yet), and ensure that invalid or tampered packets are always dropped with logs only. | S-034, S-035, S-075 | `relay_packet.dart` (future fields), `encryption_service.dart`, security roadmap docs | P0 | TODO |
| P0-FAIL-4 | Add tests that simulate DB corruption / storage-full conditions, verifying app behavior (graceful degradation, clear logging, no crashes on startup). | S-074, S-079 | `test/db_resilience_test.dart`, manual device tests with low-storage conditions | P0 | TODO |
| P0-FAIL-5 | Add static or scripted checks to ensure no decrypted content or sensitive identifiers are ever logged (lint rule or grep-based CI check). | S-031, S-032, S-036, S-109 | `log_service.dart`, CI config, code review guidelines | P0 | TODO |

***

## 4. مهام مهمة P1 (Important for Strong Pilots)

> هذه المهام ليست Blockers مطلقة، لكنها تُحسّن جودة الطيّارات الميدانية بشكل كبير وتقلّل المخاطر التقنية.

### 4.1 تحسين بروتوكول المزامنة (Sync Optimization – Bloom Filter / Delta Sync)

| Task ID | Description (English) | Linked Scenarios (S-XXX) | Code Areas | Priority | Status |
|--------|------------------------|---------------------------|-----------|----------|--------|
| P1-SYNC-1 | Implement Bloom Filter or compact vector summary in Handshake Summary to avoid listing all packet IDs in dense meshes. | S-009, S-022, S-024, S-028, S-026 | `epidemic_router.dart` (`_initiateHandshake`), `app_database.dart` (`getRelayPacketsForSync`), BloomFilter helper | P1 | TODO |
| P1-SYNC-2 | Add per-peer sync history cache to avoid repeatedly re-requesting the same packets between frequently-meeting peers. | S-009, S-022, S-028 | `epidemic_router.dart` (peer sync cache), `RelayPacket` metadata | P1 | TODO |
| P1-SYNC-3 | Add tests / simulations measuring handshake size and sync efficiency before/after Bloom Filter, for realistic pilot topologies. | S-009, S-022, S-028 | `test/sync_efficiency_test.dart`, scripts for simulation | P1 | TODO |

---

### 4.2 أدوات مراقبة الشبكة والـ Debug (Network Debug & Observability)

| Task ID | Description (English) | Linked Scenarios (S-XXX) | Code Areas | Priority | Status |
|--------|------------------------|---------------------------|-----------|----------|--------|
| P1-OBS-1 | Implement a `Mesh Debug Screen` accessible from settings (developer/advanced section) showing: peer count, RelayQueue size, PowerMode, ACK stats, and recent errors. | S-051, S-055, S-081, S-082 | `mesh_debug_screen.dart` (new), hooks from `background_service.dart`, `epidemic_router.dart`, `app_database.dart` | P1 | TODO |
| P1-OBS-2 | Add simple log export mechanism (redacted) so pilot operators can export logs after a run for offline analysis. | S-081, S-082, S-083, S-084, S-085, S-086, S-087, S-088 | `log_service.dart`, `log_export_screen.dart` | P1 | TODO |
| P1-OBS-3 | Document a minimal “pilot operator playbook” in docs (how to read debug screen, how to export logs, how to report issues). | S-081–S-090 | `docs/FIELD_PILOT_GUIDE.md` (new) | P1 | TODO |

---

### 4.3 تغطية اختبارات أقوى لـ Routing + Crypto + DB

| Task ID | Description (English) | Linked Scenarios (S-XXX) | Code Areas | Priority | Status |
|--------|------------------------|---------------------------|-----------|----------|--------|
| P1-TEST-1 | Add unit tests for `RelayPacket` TTL/trace/`isExpired`, and MeshMessage routing decisions (multi-hop, maxHops). | S-003, S-004, S-034 | `test/relay_packet_test.dart`, `test/mesh_message_routing_test.dart` | P1 | TODO |
| P1-TEST-2 | Add tests around `HandshakeProtocol` and contact whitelisting to ensure unknown/blocked senders are never decrypted or shown. | S-031, S-032, S-038, S-039, S-100 | `test/handshake_whitelist_test.dart` (new), `incoming_message_handler.dart`, `handshake_protocol.dart` | P1 | TODO |
| P1-TEST-3 | Extend `simulation_test.dart` to cover DTN routing behaviors (simple 2–3 hop chains in-memory) in addition to crypto/DB/auth. | S-003, S-004, S-021 | `test/simulation_test.dart` | P1 | TODO |

***

## 5. مهام تحسين P2 (Nice-to-Have for Later)

> هذه المهام ليست مطلوبة للطيّارات الأولى، لكنها ستصبح مهمة للإصدارات اللاحقة أو النطاقات الأوسع.

### 5.1 ميزات متقدمة (Advanced Features)

- **P2-ADV-1 – Group Chat Routing & UX**  
  - استكمال منطق الجروبات (routing, encryption, membership) وربطه مع DTN.  
  - Scenarios: S-091, S-092.  

- **P2-ADV-2 – File / Image / Voice Transfer over DTN**  
  - تصميم وإضافة بروتوكول Chunking للملفات/الصوتيات؛ ربطه بـ RelayQueue والقيود.  
  - Scenarios: S-093, S-094, S-095.  

- **P2-ADV-3 – Approximate Location Sharing**  
  - مشاركة موقع تقريبي مع مستويات خصوصية مختلفة.  
  - Scenarios: S-096.  

- **P2-ADV-4 – Panic / SOS Channels**  
  - قنوات تنبيه خاصة مع معدل إرسال محدود وأولوية عالية في الطابور.  
  - Scenarios: S-097.  

### 5.2 CI / Analytics / Tooling

- **P2-CI-1 – Scenario Implementation Matrix**  
  - إنشاء `docs/SCENARIO_IMPLEMENTATION_MATRIX.csv` تربط كل S-XXX بالحالة (Implemented/Partially/Not) لتستخدم لاحقًا في CI.  

- **P2-CI-2 – Automated Log Scanners**  
  - أدوات لتحليل logs بعد الطيّارات (latency distributions, failure types، إلخ).  

***

## 6. سيناريوهات ميدانية مقترحة للإطلاق الأول (Recommended Pilot Scenarios)

> هذه السيناريوهات مختارة من `SCENARIO_CATALOG.md` و`SCENARIO_COVERAGE_REPORT.md` باعتبارها أهداف مناسبة بعد إكمال مهام P0 (وأجزاء من P1)، مع مخاطرة مقبولة لطيّارات صغيرة.

### S-003 – سلسلة ثلاثية العقد في مبنى مكون من طابقين

- **Type:** Small office / campus multi-floor DTN.  
- **Why suitable:** بسيط نسبيًا (3 أجهزة، بيئة داخلية)، يسمح بقياس موثوقية multi-hop بدون ازدحام كبير.  
- **Preconditions:** ACK pipeline (P0-ACK-*) مكتمل؛ Token Bucket مضبوط؛ basic debug screen متاح.  
- **Monitor:** معدل التسليم عبر 3 قفزات، زمن التسليم، سلوك MessageStatus، استقرار BackgroundService.  

### S-004 – حركة مستخدم في حافلة بين حيين مع عقد ثابتة في كل حي

- **Type:** Data-mule commuter between two neighborhoods/offices.  
- **Why suitable:** نموذج واضح لـ Store-Carry-Forward، مهم للقرى/الأحياء.  
- **Preconditions:** ACK + quotas + duty cycle مضبوطة؛ توثيق للانتظار الطويل.  
- **Monitor:** نسبة الرسائل التي تعبر من Cluster A إلى B، نمو RelayQueue على جهاز "الجسر"، استهلاك البطارية.  

### S-021 – شبكة منخفضة الكثافة في قرية صغيرة

- **Type:** Rural low-density community.  
- **Why suitable:** يطابق رؤية Sada الأصلية، بكثافة منخفضة وضغوط أقل من الاحتجاجات الضخمة.  
- **Preconditions:** UX حول التأخير جاهزة؛ مزامنة RelayQueue مستقرة؛ إرشادات للمشاركين.  
- **Monitor:** زمن التسليم (ساعات/أيام)، تفاعل المستخدمين مع حالات الرسائل، معدلات التعطّل.  

### S-051 – وضع الأداء العالي في احتجاج مستمر لعدة ساعات (على نطاق صغير)

- **Type:** Small protest / march (dozens of users, not thousands).  
- **Why suitable:** يختبر High-Performance PowerMode، الاستهلاك الحراري والبطارية في بيئة حقيقية لكن محدودة الحجم.  
- **Preconditions:** P0-BG-* مكتملة؛ UX تحذر بوضوح من استهلاك البطارية؛ debug screen تعرض PowerMode وpeer count.  
- **Monitor:** استهلاك البطارية/ساعة، حرارة الأجهزة، ثبات BackgroundService وEpidemicRouter، نجاح التسليم.  

### S-081 – اختبار ميداني في قرية ريفية بدون إنترنت

- **Type:** Multi-day offline rural pilot.  
- **Why suitable:** يعكس سيناريو الاستخدام الأهم لـ Sada؛ مخاطر أمنية أقل من الاحتجاجات عالية القمع.  
- **Preconditions:** ACK + quotas + background + UX للتأخير؛ دليل تشغيل للطيّار.  
- **Monitor:** استقرار التطبيق على مدى أيام، حجم RelayQueue، feedback المستخدمين حول الفهم والثقة.  

### S-082 – اختبار في حرم جامعي لمدة فصل دراسي كامل (نسخة مصغرة أولاً)

- **Type:** University campus micro-pilot (e.g., 20–50 users).  
- **Why suitable:** كثافة متوسطة، بيئة قابلة للمراقبة، مستخدمون تقنيون نسبيًا.  
- **Preconditions:** P0 + بعض P1 (Sync Optimization, Observability).  
- **Monitor:** معدلات التسليم، battery impact، قابلية الاستخدام اليومية.  

### S-012 / S-017 – قارب إنقاذ / متطوعون بين مخيم ومدينة (اختبار مصغّر)

- **Type:** Humanitarian-style shuttle test (in a safe training context).  
- **Why suitable:** يحاكي حالات ذات دلالات إنسانية لكن يمكن تنفيذها كتمرين منظم مع متطوعين.  
- **Preconditions:** Duress UX محسّنة؛ ACK + quotas مكتملة؛ توجيه أخلاقي واضح للمشاركين.  
- **Monitor:** زمن التسليم عبر رحلات متباعدة، نمو RelayQueue على أجهزة "الجسر"، فهم المستخدمين للتأخير.  

***

## 7. قرار الجاهزية (Readiness Decision)

- [ ] All P0 tasks in Section 3 are implemented and tested.  
- [ ] No known critical crashers or data-loss bugs in routing/crypto/DB.  
- [ ] UX for delays and duress is reviewed and approved (Arabic + English copy).  
- [ ] At least X (e.g., 5–10) internal test runs / simulations for DTN routing, ACK, congestion, and background behavior have passed.  
- [ ] At least Y (e.g., 3–5) smoke tests on real devices (different Android vendors/versions) have passed, including overnight runs.  

**When all boxes above are checked, Sada can be deployed in small controlled field pilots under the defined constraints (limited geography, <200 users, explicit disclaimers).**  


