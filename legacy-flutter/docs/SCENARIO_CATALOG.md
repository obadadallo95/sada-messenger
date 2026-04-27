## كتالوج سيناريوهات Sada – SCENARIO CATALOG

يهدف هذا الكتالوج إلى توثيق مجموعة كبيرة من السيناريوهات الواقعية لاستخدام Sada في بيئات مختلفة (قرى، مدن، احتجاجات، كوارث، جامعات، إلخ)، بحيث تساعد في:

- تصميم البروتوكولات والمعمارية (DTN, Epidemic Routing, Store-Carry-Forward, TTL, RelayQueue, ACK).
- ترتيب أولويات التنفيذ (Networking, Security, UX, Battery, Background Services).
- بناء خطة اختبارات شاملة (Unit, Integration, Simulation, Field Testing).
- تحسين تجربة المستخدم وشرح سلوك التطبيق تحت الضغط أو التأخير الطويل.

**Legend (English):**

- **Context**: Real-world description: number of devices, mobility pattern, environment, connectivity.
- **Risks**: Key risks (delivery failure, privacy leak, UX confusion, battery drain, flooding, etc.).
- **Technical Considerations**: How DTN, routing, TTL, RelayQueue, ACK, congestion control, background services, security, and MessageStatus are impacted.
- **UX Considerations**: How to communicate state and delays to the user (status icons, hints, onboarding).
- **Suggested Tests**: Concrete ideas for simulations, lab tests, and field tests.

كل سيناريو يحمل معرفًا فريدًا على شكل `S-XYZ` وعنوانًا عربيًا قصيرًا، مع وصف تفصيلي باللغة الإنجليزية حسب القالب المطلوب.

---

## 1. سيناريوهات الاتصال والحركة (Connectivity & Mobility)

### S-001 – اتصال مباشر بين شخصين في غرفة واحدة

**Context (English):**
- 2 devices (A and B) in the same room (indoor, ~5–10m distance).
- Both users have Sada open in the foreground with Bluetooth and WiFi enabled.
- No internet or cell coverage; only local radio.

**Risks:**
- Misconfiguration of permissions may prevent discovery.
- Nearby Connections negotiation might fail intermittently.

**Technical Considerations:**
- DTN routing path is single-hop (A→B), so TTL and RelayQueue are trivial.
- Epidemic Routing should still work, but main focus is on quick discovery and connection.
- MessageStatus should quickly move from `sending` → `sent` → `delivered`.

**UX Considerations:**
- Show a clear "Connected locally" indicator (mesh status bar).
- Messages should feel almost real-time; delays >2–3s may confuse users.

**Suggested Tests:**
- Manual test: Send 100 short messages between two devices in airplane mode in a room, measure latency and failure rate.
- Simulation: Emulate radio drop/reconnect mid-conversation and check MessageStatus transitions.

***

### S-002 – اتصال مباشر في شارع مفتوح مع حركة بسيطة

**Context (English):**
- 2 devices walking on the same street, distance fluctuates between 5–30m.
- Short intermittent LOS (line-of-sight) as people move.
- No internet; only Bluetooth LE and WiFi Direct.

**Risks:**
- Intermittent disconnects as devices move behind obstacles.
- Messages stuck in `sending` if connectivity blips are not handled gracefully.

**Technical Considerations:**
- Nearby Connections must handle quick connect/disconnect cycles.
- Pending messages should be stored and retried via DTN when contact is restored.

**UX Considerations:**
- Show subtle indication when peer is "out of range" vs "in range".
- Avoid spamming the user with connection toast notifications.

**Suggested Tests:**
- Manual walking test: two users walk up/down a street sending messages every 10–20 seconds.
- Log analysis: verify that RelayQueue does not fill with duplicates during brief disconnections.

***

### S-003 – سلسلة ثلاثية العقد في مبنى مكون من طابقين

**Context (English):**
- 3 devices: A on floor 1, B on staircase, C on floor 2.
- Direct A↔C contact is weak, but A↔B and B↔C are strong.

**Risks:**
- Messages A→C depend on B’s presence; if B moves away, path breaks.
- Long-lived partial deliveries without ACKs can confuse A.

**Technical Considerations:**
- Epidemic Routing should ensure that as long as B periodically meets A and C, messages are relayed.
- TTL must be sufficient to survive hours of intermittent encounters.

**UX Considerations:**
- For A, show that messages are "relayed" rather than directly delivered.
- Consider a subtle "via relays" icon for educational purposes.

**Suggested Tests:**
- Office test: Place devices on different floors and move the middle node periodically, sending queued messages.
- Simulation: Configure a 3-node chain with varying contact intervals (5–30 minutes) and measure delivery success rate.

***

### S-004 – حركة مستخدم في حافلة بين حيين مع عقد ثابتة في كل حي

**Context (English):**
- Devices in neighborhood X and neighborhood Y, each with 5–10 users.
- One user (the "bridge") rides a bus daily between X and Y carrying Sada.

**Risks:**
- If the bridge user is offline or battery-dead, the two communities become isolated.
- RelayQueue on the bridge may grow too large if message volume is high.

**Technical Considerations:**
- TTL must cover at least one daily commute (~24h).
- RelayQueue limits and cleanup policies must prevent disk exhaustion on the bridge device.

**UX Considerations:**
- Users should understand that delivery might take "hours" in such topology.
- Provide an informational tooltip explaining "indirect delivery via other users".

**Suggested Tests:**
- Simulation: 20-node scenario with one high-mobility node bridging two clusters, low encounter frequency.
- Field test: One user commuting between two office buildings, sending messages from one side to the other over a day.

***

### S-005 – مستخدم راكب قطار يمر بالقرب من عقد عابرة

**Context (English):**
- 1 device on a train (high speed), several devices near stations or along the tracks.
- Contacts are very short (a few seconds) as train passes by.

**Risks:**
- Not enough time to perform Nearby handshake, auth, and data transfer.
- Partial payload transfers leading to corrupted packets if not handled correctly.

**Technical Considerations:**
- Discovery and connection setup time must be optimized (fast handshake).
- Consider limiting packet sizes or using chunking in future for large messages.

**UX Considerations:**
- Do not mislead user into thinking such short contacts guarantee delivery.
- Possibly show "opportunistic contact" but with lower reliability expectation.

**Suggested Tests:**
- Lab: Use two devices on moving carts simulating fast pass-bys and measure how many packets complete.
- Simulation: Contact durations of 2–10 seconds with various packet sizes and reties.

***

### S-006 – مدينة متوسطة مع عقد ثابتة في مقاهي وأماكن عمل

**Context (English):**
- ~50 Sada users in a mid-size city.
- Some nodes are semi-stationary (cafes, offices, community centers).

**Risks:**
- Unequal load: stationary nodes might carry a disproportionate amount of traffic.
- Potential privacy risk if stationary devices become "traffic hubs".

**Technical Considerations:**
- Congestion control (Token Bucket) should prevent flooding through these hubs.
- RelayQueue limits on stationary devices must be carefully tuned.

**UX Considerations:**
- No special UX for hubs, but app should remain responsive on such nodes.
- Avoid visible slowdowns in chat UI due to background DTN load.

**Suggested Tests:**
- Simulation: Half of devices "stationary" and half mobile; measure queue sizes at stationary nodes.
- Field test: Phones placed in cafes/offices while others roam around city center.

***

### S-007 – حي سكني مع مستخدمين قلائل وحركة ليلية فقط

**Context (English):**
- 5–8 users in a residential area, mostly at home during the day and moving only at night.

**Risks:**
- Message delays can easily reach 12–24 hours.
- Users may assume Sada "stopped working" overnight.

**Technical Considerations:**
- TTL should be at least 2–3 days.
- Background service must survive OS optimizations during long idle periods.

**UX Considerations:**
- Status indicators should hint that "delivery may take hours or days".
- Consider a tooltip in the chat header for low-density networks.

**Suggested Tests:**
- Simulation: Nodes only meet during specific "night windows".
- Long-running test: Keep devices idle during the day and move them together at night, observing delivery.

***

### S-008 – مستخدمون في مركز تسوق مزدحم

**Context (English):**
- 30–100 Sada users in a mall with heavy but short-lived contacts.

**Risks:**
- High connection churn (connect/disconnect) can cause CPU and battery spikes.
- Message flooding if many people broadcast messages at once.

**Technical Considerations:**
- Token Bucket per-peer and per-node are critical to avoid flooding.
- Duty cycle may temporarily switch to a "high-performance" mode if user explicitly enables it.

**UX Considerations:**
- Provide a "High Performance / Protest Mode" toggle that warns about increased battery usage.
- Show short hints about increased reliability vs battery cost.

**Suggested Tests:**
- Simulation: 50 nodes with random short contacts and high message volumes.
- Stress test: Continuous message sending from 10 devices in close proximity.

***

### S-009 – حي جامعي مع حركة مشاة كثيفة بين مبانٍ

**Context (English):**
- University campus with 100–200 users moving between classes.
- High density in lecture halls and cafeterias; sparse in some dorm areas.

**Risks:**
- Bursts of traffic at certain times (start/end of lectures).
- Potential for RelayQueue growth during high-load windows.

**Technical Considerations:**
- Epidemic Routing should work efficiently if congestion control is tuned.
- Bloom Filter–based summaries can reduce handshake overhead in dense clusters (future work).

**UX Considerations:**
- Students expect near-realtime delivery within the same building; manage expectations across campus.
- Sada might be used as a local social/chat tool; ensure UI remains smooth.

**Suggested Tests:**
- Campus simulation: 200-node contact traces with high-density clusters.
- Field test: small pilot with students moving across 3–4 main buildings.

***

### S-010 – مبنى حكومي مع مناطق ذات حواجز معدنية (Faraday-like zones)

**Context (English):**
- Building with some areas that significantly attenuate radio signals (elevators, basements).
- Users move in and out of such zones.

**Risks:**
- Unexpected "black holes" where messages cannot progress.
- User confusion when messages "resume" after leaving those zones.

**Technical Considerations:**
- Background service must buffer and continue scanning periodically even when radio is weak.
- TTL must be high enough to tolerate long stays in low-connectivity zones.

**UX Considerations:**
- Indicate when the device is "offline from mesh" due to radio conditions.
- Avoid scaring users; frame it as "waiting for nearby peers".

**Suggested Tests:**
- Manual tests in basements/elevators with logs capturing radio status and DTN behavior.
- Simulation: periodic "radio off" intervals for some nodes.

***

### S-011 – قافلة سيارات تتحرك على طريق سريع

**Context (English):**
- 5–10 cars with Sada users driving in the same direction on a highway.
- Relative distances change but stay under 200–300m.

**Risks:**
- Handshakes might be short-lived at high speeds.
- Node ordering constantly changes, affecting relay paths.

**Technical Considerations:**
- High-mobility scenario demands fast connection and small packet sizes.
- Store-Carry-Forward is essential when vehicles occasionally leave/enter the convoy.

**UX Considerations:**
- Drivers should not be distracted; app should operate mostly in background.
- Notifications must be minimal yet informative.

**Suggested Tests:**
- Controlled drive test with multiple cars and pre-planned message exchanges.
- Simulation: high-speed node motion with synthetic GPS traces.

***

### S-012 – قارب إنقاذ يتحرك بين نقطتي تجمع في كارثة

**Context (English):**
- Boat shuttling between two refugee clusters on opposite shores.
- Acts as a mobile relay for messages between families separated by water.

**Risks:**
- Very long contact intervals (e.g., hours between trips).
- High emotional stakes; UX must avoid over-promising delivery times.

**Technical Considerations:**
- TTL must be several days; RelayQueue on the boat device may grow significantly.
- Device must be rugged and able to run background service for long hours.

**UX Considerations:**
- Status language should emphasize "will attempt delivery when possible".
- Consider an optional "message expiration" hint to avoid infinite waiting.

**Suggested Tests:**
- Simulation: two fully disconnected clusters linked by a single shuttling node.
- Long-duration field test on a boat or ferry with sparse contact times.

***

### S-013 – حديقة عامة مع مستخدمين يجلسون لفترات طويلة

**Context (English):**
- 10–20 users in a park; many are mostly stationary for 1–3 hours.

**Risks:**
- Good opportunity for fast message spreading; but also risk of flooding if one node spams.

**Technical Considerations:**
- Epidemic Routing should quickly saturate the component with messages.
- Token Bucket and per-node throttling are important to prevent abuse.

**UX Considerations:**
- Chat should feel responsive; visual latency should be minimal.
- Avoid UI lag when many new messages arrive via background sync.

**Suggested Tests:**
- Simulation: 20-node fully connected component with random message generation.
- Field test: friends sitting in a park using Sada as group chat.

***

### S-014 – اتصال بين قطارين يتقاطعان في محطة

**Context (English):**
- Two trains stopping at the same station for a few minutes.
- Some Sada users on each train.

**Risks:**
- Very short window of connectivity for cross-train messages.
- Partial relays may not have enough time to propagate further.

**Technical Considerations:**
- Maximize throughput in short contact windows; prioritize smaller packets and critical messages.
- Consider future priority flags in RelayPacket metadata.

**UX Considerations:**
- Do not promise guaranteed cross-train delivery; show "attempting opportunistic delivery".

**Suggested Tests:**
- Lab simulation of 2 clusters connecting briefly for 2–5 minutes.
- Measure how many messages can cross cluster boundary per window.

***

### S-015 – مستخدم في طائرة بدون اتصال إلا لحظات عند البوابة

**Context (English):**
- Device A on a plane, only has mesh contact when boarding and deplaning at gates with Sada users.

**Risks:**
- Long offline intervals; messages may be significantly delayed.
- Risk of users expecting instant delivery incorrectly.

**Technical Considerations:**
- DTN model must store messages on A and neighbors until next meaningful contact.
- TTLs likely in the range of days; RelayQueue cleanup policies must avoid premature deletion.

**UX Considerations:**
- For such use cases, an explanation in onboarding about "offline store-carry-forward" is critical.

**Suggested Tests:**
- Simulation: Node with contact windows only twice per day.
- Field test: User toggling airplane mode except during boarding gates.

***

### S-016 – شبكة بينية بين طابقات عدة في ناطحة سحاب

**Context (English):**
- Many floors with different Sada user densities.
- Elevators and stairwells act as occasional vertical bridges.

**Risks:**
- Vertical connectivity may be fragile; certain floors may become disconnected.

**Technical Considerations:**
- Epidemic Routing plus recurrent vertical bridges should gradually spread messages.
- Performance depends on how often users traverse stairs/elevators.

**UX Considerations:**
- Nothing special in UI, but logs/metrics should show component structures for debugging.

**Suggested Tests:**
- Simulation: Multi-layer graph with limited vertical edges.
- Office field: staff moving between floors carrying devices.

***

### S-017 – اتصال بين مخيم لجوء ومدينة قريبة عبر متطوعين متحركين

**Context (English):**
- Refugee camp with many Sada users; volunteers commute to the city and back.

**Risks:**
- Loss/theft of relay devices could drop many in-transit messages.

**Technical Considerations:**
- Having multiple volunteer devices reduces single-point-of-failure risk.
- RelayQueue limits and TTL must be tuned for humanitarian contexts (long retention).

**UX Considerations:**
- Provide optional "critical message" label to encourage longer TTLs (future feature).

**Suggested Tests:**
- Humanitarian simulation: multiple bridge nodes between two dense clusters.
- Stress: removal (failure) of some bridge devices mid-simulation.

***

### S-018 – عبور حدود دولة مع رقابة شديدة

**Context (English):**
- User carrying Sada-enabled phone crosses a heavily monitored border.

**Risks:**
- Device inspection, forced unlock, or confiscation.
- Exposure of RelayQueue contents and topology hints.

**Technical Considerations:**
- Duress mode with decoy DB must be strongly tested.
- RelayQueue data should be indistinguishable from random encrypted blobs.

**UX Considerations:**
- Clear duress onboarding: when and how to use duress PIN, what it hides.

**Suggested Tests:**
- Security review: inspect on-disk DB files and confirm no plaintext.
- Usability test: can users correctly trigger duress mode under stress?

***

### S-019 – مستخدمون يتنقلون بين مباني جامعة ومستشفى مجاور

**Context (English):**
- Some nodes are students/staff moving between a campus and a hospital.

**Risks:**
- Healthcare-related messages might be sensitive; privacy must be maintained at all hops.

**Technical Considerations:**
- Zero-trust model (no decryption at relays) must hold; ACLs via contact whitelist.

**UX Considerations:**
- For sensitive communication, UI might emphasize end-to-end encryption and "blind relays".

**Suggested Tests:**
- Simulation mixing student and hospital nodes, verifying no relays can decrypt payloads.
- Threat modeling: test compromised relay cannot infer sender/receiver identities.

***

### S-020 – مجموعة من الأصدقاء في نزهة جبلية بلا تغطية

**Context (English):**
- 4–6 hikers with Sada devices; no cell coverage, only mesh.

**Risks:**
- Battery is critical; devices must last entire hike.
- Messages may be delayed when people spread apart on the trail.

**Technical Considerations:**
- Balanced or Power-Saving modes should reduce scan frequency when not in use.
- On-demand "boost" mode can temporarily increase scanning when sending critical messages.

**UX Considerations:**
- Simple "Hiking mode" preset might choose appropriate power settings by default.

**Suggested Tests:**
- Full-day hike test with logs for battery usage and delivery times.
- Simulation with distance-based encounter patterns matching trail behavior.

***

## 2. سيناريوهات كثافة الشبكة (Network Density & Traffic Patterns)

### S-021 – شبكة منخفضة الكثافة في قرية صغيرة

**Context (English):**
- 8–15 Sada users in a small rural village.
- Encounters are rare; people see each other mainly at a single market.

**Risks:**
- Delivery delays of 24–72h are common.
- Users might uninstall the app thinking it is broken.

**Technical Considerations:**
- High TTL (48–72h) and periodic RelayQueue cleanup for very old packets.
- ACK-based delivery may be delayed; statuses should not misrepresent failure.

**UX Considerations:**
- Clear messaging: "This app works over days in low-density networks".
- Possibly a "Network density is low" banner when few peers are seen.

**Suggested Tests:**
- Simulation: 10-node network with only 1–2 daily encounter windows.
- UX tests: user interviews in low-connectivity communities to fine-tune wording.

***

### S-022 – شبكة عالية الكثافة في احتجاج ضخم

**Context (English):**
- Hundreds or thousands of users within a small geographic area.
- Very frequent encounters, extremely dynamic topology.

**Risks:**
- Massive message flooding if users broadcast widely.
- Battery drain from high-duty scanning and constant connections.

**Technical Considerations:**
- Token Bucket and per-node rate limits are essential to avoid mesh meltdown.
- RelayQueue max count must be conservative to avoid device storage overload.

**UX Considerations:**
- Provide an explicit "Protest Mode" with warnings about battery usage and flood control.

**Suggested Tests:**
- Large-scale simulation (e.g., 500 nodes) with randomized messaging bursts.
- Lab stress tests on several devices sending at maximum app rate under protest-like density.

***

### S-023 – Many-to-One traffic toward a coordinator

**Context (English):**
- Hundreds of protest participants send updates to one "coordinator" device.

**Risks:**
- Coordinator RelayQueue and MessagesTable may grow faster than others.
- Potential hotspot for analysis if seized.

**Technical Considerations:**
- Congestion control plus optional forwarding priority for coordinator-bound traffic.
- Good DB performance required on coordinator device.

**UX Considerations:**
- Coordinator UI must handle heavy message inflow smoothly.
- Consider summary views or filters to manage incoming reports.

**Suggested Tests:**
- Simulation: 200 sending nodes, 1 receiving coordinator, measuring DB growth and latency.
- Manual: send frequent short messages from many devices to one in a small room.

***

### S-024 – One-to-Many broadcast via DTN

**Context (English):**
- A journalist or organizer wants to broadcast a message to many followers via DTN.

**Risks:**
- Broadcast semantics over epidemic routing can cause huge replication overhead.

**Technical Considerations:**
- Possibly use group IDs or channel IDs, future group-routing primitives.
- TTL and max hops must be chosen to avoid uncontrolled flooding.

**UX Considerations:**
- Differentiate 1:1 messages from "broadcast-style" messages in UI.

**Suggested Tests:**
- Simulation with one source and 100+ sinks, measuring replication factor.
- Design experiment around various TTL and max-hops settings.

***

### S-025 – Burst traffic during sudden event (tear gas, police movement)

**Context (English):**
- At a protest, a sudden police advance leads to many messages in a short time.

**Risks:**
- Message backlog in RelayQueue.
- Battery and CPU spikes on all devices.

**Technical Considerations:**
- Token Bucket and queue trimming policies must prevent meltdown.
- ACKs might be delayed; some messages will expire before delivery.

**UX Considerations:**
- Indicate that "network is busy" without causing panic.
- Possibly cluster similar messages (e.g., repeated alerts).

**Suggested Tests:**
- Simulation: artificially inject bursts of messages triggered by an "event" flag.
- Manual: group of users sending panic messages simultaneously during an exercise.

***

### S-026 – Long-term low traffic but heavy backlog after connectivity resumes

**Context (English):**
- Offline community with very few messages daily.
- Suddenly reconnects with another cluster, causing a backlog flush.

**Risks:**
- UI might be flooded with queued messages all at once.

**Technical Considerations:**
- DB and RelayQueue flush performance must be acceptable.
- ACK storms must be controlled (backpressure).

**UX Considerations:**
- Order messages by timestamp, not arrival time alone.
- Provide a "new since X" grouping.

**Suggested Tests:**
- Simulation: 2 clusters isolated for days, then connected for a short window.
- Performance tests on mass message insertion into MessagesTable.

***

### S-027 – Low-traffic private chat with rare in-person meetings

**Context (English):**
- Two friends only meet once a week but want to stay in touch via Sada.

**Risks:**
- Expectation mismatch: they may expect near-real-time like WhatsApp.

**Technical Considerations:**
- TTLs should cover at least their typical inter-meeting interval.
- Friendly "last peer seen" stats (non-sensitive) might help them understand.

**UX Considerations:**
- For low-density networks, show explicit hints about offline nature.

**Suggested Tests:**
- UX interviews and A/B texts for "delay explanation" copy.
- Simulation: 2 nodes meeting once per 7 days with periodic messages.

***

### S-028 – High-traffic group of power users in one neighborhood

**Context (English):**
- A group of activists using Sada heavily and daily in a small area.

**Risks:**
- Very high per-node message volume.
- Larger RelayQueues and more CPU usage in background service.

**Technical Considerations:**
- Consider more aggressive RelayQueue cleanup/limits for "power users".
- Potential for incremental sync/bloom filters (Week 4 optimization).

**UX Considerations:**
- Ensure chat scrolling, search, and status updates remain fast.

**Suggested Tests:**
- Controlled pilot with real heavy users; gather logs and performance metrics.

***

### S-029 – Malicious node flooding random content

**Context (English):**
- One compromised node injects many messages per minute to random peers.

**Risks:**
- Network-wide buffer bloat and battery drain.
- Potential denial-of-service on honest users.

**Technical Considerations:**
- Token Bucket per-peer (in EpidemicRouter) is critical.
- Possibly graylisting or banning offending peers (future feature).

**UX Considerations:**
- Users should not see obvious signs of flooding apart from minor slowdowns.
- Admin or power-user tools might be needed for debugging.

**Suggested Tests:**
- Simulation with one or more "spam" nodes targeting random IDs.
- Evaluate effectiveness of Token Bucket settings at various thresholds.

***

### S-030 – Malfunctioning client repeatedly resending same packets

**Context (English):**
- A buggy client keeps resending identical packets due to a local error.

**Risks:**
- Waste of bandwidth and RelayQueue space.

**Technical Considerations:**
- Deduplication in DB (`hasPacket`) and in-memory `_seenPacketIds` must work correctly.

**UX Considerations:**
- End users should not see duplicates; status should stay stable.

**Suggested Tests:**
- Unit tests: artificially call the relay handling methods with identical packets.
- Simulation: node repeatedly issues same RelayPacket; ensure network stays stable.

***

## 3. سيناريوهات الأمان والتهديد (Security & Threat Models)

### S-031 – مصادرة الجهاز ومحاولة الوصول إلى البيانات

**Context (English):**
- Attacker confiscates a device from a user and tries to browse Sada data.

**Risks:**
- Exposure of real conversations, contacts, and relay metadata.

**Technical Considerations:**
- Dual DB with duress mode must fully hide the real DB when duress PIN is used.
- All messages and relay packets must remain encrypted with libsodium.

**UX Considerations:**
- Duress PIN flow must look natural; UI should not reveal that a decoy view is shown.

**Suggested Tests:**
- Manual: Configure duress mode, then hand device to a tester acting as attacker.
- Technical: Inspect on-disk DB under both master and duress modes.

***

### S-032 – إكراه المستخدم على فتح التطبيق أمام المهاجم

**Context (English):**
- Attacker forces user to unlock Sada and show chat history.

**Risks:**
- Real conversation exposure and contact graph visibility.

**Technical Considerations:**
- Duress PIN logic must route to decoy DB seamlessly.
- Real DB keys must not be loaded under duress mode.

**UX Considerations:**
- Decoy content should look plausible and not empty.
- Avoid UI glitches that suggest mode switching.

**Suggested Tests:**
- Role-play scenarios where participants test duress flow under time pressure.
- Measure whether external observer can tell master vs duress apart.

***

### S-033 – جهاز متسرب (Compromised Relay Node)

**Context (English):**
- An attacker controls a relay node but not endpoint devices.

**Risks:**
- Attempts to infer social graph from toHash, trace, and traffic patterns.

**Technical Considerations:**
- Use SHA-256 hashes for `toHash` and anonymized trace entries.
- Avoid logging or exposing real user IDs in relay-only nodes.

**UX Considerations:**
- None directly; this is mostly internal security.

**Suggested Tests:**
- Penetration test: attempt to correlate hashed IDs to real users via side channels.
- Review logs to ensure no plaintext IDs or contacts are leaked.

***

### S-034 – إعادة تشغيل الحزم (Replay Attack)

**Context (English):**
- Compromised node resends old RelayPackets repeatedly.

**Risks:**
- User confusion on receiving "stale" messages.
- Increased traffic and potential queue pollution.

**Technical Considerations:**
- TTL and createdAt-based expiration in RelayPacket must prevent infinite replay.
- ACK-based semantics help detect duplicates at endpoints.

**UX Considerations:**
- Messages older than a certain threshold might be tagged as "delayed" or "stale".

**Suggested Tests:**
- Simulation: re-inject old packets into the network and observe dedup behavior.
- Unit tests: verify isExpired() and TTL decrement logic.

***

### S-035 – Flooding Attack with Valid but Useless Encrypted Payloads

**Context (English):**
- Malicious node sends encrypted garbage that looks valid but is meaningless.

**Risks:**
- Wastes bandwidth and storage while remaining hard to distinguish cryptographically.

**Technical Considerations:**
- Rate limiting and per-node Token Buckets are primary defense.
- RelayQueue limits ensure damage is bounded.

**UX Considerations:**
- End users should not see spam messages because unknown senders are dropped by whitelist.

**Suggested Tests:**
- Simulation with adversary nodes generating random encrypted payloads at high rate.
- Check impact on honest nodes' queue sizes and CPU usage.

***

### S-036 – استنتاج الرسم البياني الاجتماعي من الأنماط الزمنية

**Context (English):**
- Observer tries to infer who talks to whom based on packet timing, not content.

**Risks:**
- Social graph leakage even with encryption.

**Technical Considerations:**
- Padding and batching might be considered in future; for now, emphasis is on hashed IDs and blind relays.

**UX Considerations:**
- Probably no user-facing change; risk is architectural and needs doc.

**Suggested Tests:**
- Traffic analysis experiments on simulated or real logs.
- Validate that no direct IDs leak inside relay logs.

***

### S-037 – ضياع الجهاز وإعادة تثبيت التطبيق

**Context (English):**
- User loses phone and later installs Sada on a new device.

**Risks:**
- Old messages and relayed packets still exist in the DTN but are no longer decryptable.

**Technical Considerations:**
- Key regeneration changes identity; old toHash values no longer match.
- Some "orphaned" packets will eventually expire via TTL.

**UX Considerations:**
- On new install, make clear that old offline messages cannot be recovered unless backup/restore is supported.

**Suggested Tests:**
- Scenario: drop one device from the network and reintroduce user with new keys.
- Confirm old packets are eventually cleaned from RelayQueues.

***

### S-038 – إلغاء صداقة / إلغاء ثقة في جهة اتصال

**Context (English):**
- User removes a contact or revokes trust after a conflict.

**Risks:**
- Future messages from that contact must not be decrypted or shown.

**Technical Considerations:**
- Whitelist-only processing in IncomingMessageHandler should enforce this strictly.
- Existing encrypted payloads might still transit as blind relays but never be opened.

**UX Considerations:**
- Clear UI for blocking and removing contacts.
- Possibly wipe chat history or move to archive.

**Suggested Tests:**
- Manual: send messages before and after blocking, verify handling.
- Ensure ACKs are not generated for blocked senders.

***

### S-039 – شخص يحاول استخدام QR مزوّر لإضافة جهة اتصال وهمية

**Context (English):**
- Attacker shows a fake QR code with malicious `id` or public key.

**Risks:**
- Insertion of rogue contact into address book.

**Technical Considerations:**
- QR parsing must validate required fields and types.
- User may require manual confirmation for adding unknown IDs.

**UX Considerations:**
- Display clear identity info (nickname, key fingerprint) before acceptance.

**Suggested Tests:**
- Fuzz QR content with malformed JSON or missing fields.
- Test confusing but valid variations of name/publicKey to ensure UI clarity.

***

### S-040 – حمل الجهاز عبر نقاط تفتيش عديدة في مدينة خاضعة للرقابة

**Context (English):**
- User passes multiple checkpoints where devices may be briefly checked.

**Risks:**
- Repeated need to present decoy conversations under duress.

**Technical Considerations:**
- Duress mode must be fast to enter and stable over multiple unlocks.

**UX Considerations:**
- Provide a quick way to enter duress PIN without obvious difference in flow.

**Suggested Tests:**
- Usability: repeated master/duress toggling across days.
- Data integrity: ensure real DB isn't accidentally exposed or corrupted.

***

## 4. سيناريوهات تجربة المستخدم (UX) (Delays, Status, Onboarding)

### S-041 – رسائل تبقى في حالة "sending" لفترة طويلة

**Context (English):**
- Low-density network; messages may have no immediate relay available.

**Risks:**
- Users interpret "sending" as "stuck" or "failed".

**Technical Considerations:**
- Distinction between `sending` (attempting immediate P2P) and `sent` (stored in DTN).
- ACK arrival might be days away, if it arrives at all.

**UX Considerations:**
- Explain in tooltip or help: "sending means waiting for nearby peers".
- Consider auto-transition from `sending` → `sent` once stored locally.

**Suggested Tests:**
- UX test: show prototypes of different status wordings/icons and gather feedback.
- End-to-end scenario in sparse network with artificial delays.

***

### S-042 – تفسير أيقونات الحالة (sent, delivered, read)

**Context (English):**
- Users are familiar with centralized messengers (WhatsApp, Signal).

**Risks:**
- Misunderstanding of `sent` (to DTN) vs `delivered` (final endpoint).

**Technical Considerations:**
- ACK semantics must drive `delivered`; absence of ACK shouldn't prematurely mark delivered.

**UX Considerations:**
- Provide subtle legend (tooltip or FAQ page) explaining each icon.
- Avoid overloading icons with conflicting meanings.

**Suggested Tests:**
- Survey users on their understanding of icons after short usage.
- A/B test alternate icon sets or labels.

***

### S-043 – مستخدم لم يقرأ الشرح الأولي (Onboarding Skipped)

**Context (English):**
- Many users skip onboarding and jump straight into chat.

**Risks:**
- They misinterpret delays and network behavior.

**Technical Considerations:**
- Onboarding must be optional but re-teachable via in-app tips.

**UX Considerations:**
- Use contextual tooltips triggered when anomalies happen (e.g., long delay).

**Suggested Tests:**
- Controlled user study: group with onboarding vs group without, compare comprehension.
- In-app analytics (if privacy-acceptable) on onboarding completion rates.

***

### S-044 – مستخدم يعتمد بالكامل على Sada في كارثة طبيعية

**Context (English):**
- After an earthquake or flood, user uses Sada as main communication tool.

**Risks:**
- High emotional state; miscommunication about delays is critical.

**Technical Considerations:**
- DTN functionality may be the only option; reliability is paramount.

**UX Considerations:**
- Provide clear explanatory copy about offline DTN and its limitations.
- Avoid technical jargon in user-facing messages.

**Suggested Tests:**
- Participatory design with disaster-response volunteers.
- Simulation of long-term outage with test participants.

***

### S-045 – ارتباك المستخدم بين قاعدة البيانات الحقيقية والوهمية (Duress)

**Context (English):**
- User accidentally logs in with duress PIN thinking it's the real account.

**Risks:**
- Confusion when "important chats" appear missing.

**Technical Considerations:**
- App must not leak which mode is active, but can provide subtle hints if user is alone.

**UX Considerations:**
- Consider optional, non-obvious cues for advanced users to know they are in duress mode (e.g., small color variation).

**Suggested Tests:**
- UX workshops exploring safe ways to communicate mode without aiding attackers.
- Long-term usage tests to see if users mis-enter duress PIN often.

***

### S-046 – إشعارات متأخرة تصل فجأة بعد ساعات

**Context (English):**
- Device reconnects to mesh after long time; many messages arrive quickly.

**Risks:**
- Notification flood overwhelming the user.

**Technical Considerations:**
- Batch notifications or summarize when many messages land at once.

**UX Considerations:**
- Use a grouped notification: "You have 25 new messages in 4 chats".

**Suggested Tests:**
- Simulation of delayed batch delivery followed by local notification generation.
- Stringent UI tests for notification grouping on different Android versions.

***

### S-047 – رسائل فاشلة (failed) مع محاولة إعادة إرسال

**Context (English):**
- Messages whose TTL has expired or all routes exhausted.

**Risks:**
- Users may repeatedly hit "resend" and spam the network.

**Technical Considerations:**
- Resend should create a new message ID and respect congestion control.

**UX Considerations:**
- Allow manual resend but show clear risk/limit indicators.

**Suggested Tests:**
- Unit: ensure resend logic creates new RelayPackets cleanly.
- UX: evaluate how users behave with failed messages and retry buttons.

***

### S-048 – استخدام Sada كبديل عن واتساب في حياة يومية عادية

**Context (English):**
- Users in a normal city with full internet still prefer Sada for privacy.

**Risks:**
- They expect WhatsApp-like reliability and speed.

**Technical Considerations:**
- Optional "online bridge" is out of scope for now; Sada remains offline-first.

**UX Considerations:**
- Marketing and copy must set expectations properly (Sada is not a direct WhatsApp replacement).

**Suggested Tests:**
- User interviews comparing expectations across different user segments.

***

### S-049 – استخدام التطبيق من قبل شخص غير تقني

**Context (English):**
- Non-technical user hears about Sada from a friend.

**Risks:**
- Overwhelmed by technical terms or unusual status behaviors.

**Technical Considerations:**
- Keep error messages and logs technical, but user-visible messages human-readable.

**UX Considerations:**
- Minimalistic UI with simple concepts: "delivered when phones meet".

**Suggested Tests:**
- Usability test with non-technical participants using a prototype.

***

### S-050 – واجهة Cyberpunk قد تُفسر كـ "لعبة" وليس أداة جادة

**Context (English):**
- Visual design is futuristic-cyberpunk; some users may take it less seriously.

**Risks:**
- Underestimation of security and seriousness of communication.

**Technical Considerations:**
- None directly, but security features must be discoverable despite the aesthetic.

**UX Considerations:**
- Add clear "Security & Privacy" section in settings explaining guarantees.

**Suggested Tests:**
- A/B of alternative themes or accent changes; survey on perceived seriousness.

***

## 5. سيناريوهات البطارية والطاقة (Battery & Power Mode)

### S-051 – وضع الأداء العالي في احتجاج مستمر لعدة ساعات

**Context (English):**
- User explicitly enables "High Performance" / "Protest Mode" for long protests.

**Risks:**
- Rapid battery drain; device may die before end of event.

**Technical Considerations:**
- BackgroundService uses high scan frequency and continuous Nearby sessions.

**UX Considerations:**
- Clear warning when enabling this mode about expected battery impact.

**Suggested Tests:**
- 4–6 hour continuous test with High Performance mode on multiple devices.
- Measure temperature, CPU load, and battery drain profiles.

***

### S-052 – وضع توفير الطاقة عندما تكون البطارية أقل من 20%

**Context (English):**
- Device battery drops below 20%; system or user switches to power-saving mode.

**Risks:**
- Reduced discovery may cause longer message delivery times.

**Technical Considerations:**
- DiscoveryStrategy should lengthen sleep periods and shorten scan windows.

**UX Considerations:**
- Show small banner "Power Saving Mode may delay message delivery".

**Suggested Tests:**
- Simulation with varying battery levels and adaptive duty cycle adjustments.
- Manual: reduce battery manually and observe mode toggling behavior.

***

### S-053 – الجهاز في وضع الشحن طوال اليوم

**Context (English):**
- Device is plugged in at home or office for many hours.

**Risks:**
- Opportunity for high-duty scanning, but potential wear on radio hardware.

**Technical Considerations:**
- PowerModeProvider may detect "charging" and allow more aggressive discovery.

**UX Considerations:**
- Possibly offer user the option to act as a "mesh hub" when charging.

**Suggested Tests:**
- Long-duration lab test of device plugged in with maximum scanning duty cycle.

***

### S-054 – تفاعل مع Android Doze وقيود الخلفية

**Context (English):**
- OS aggressively applies Doze and background limitations.

**Risks:**
- BackgroundService may be killed or throttled; missed opportunities for encounters.

**Technical Considerations:**
- Foreground service with ongoing notification is mandatory for reliability.

**UX Considerations:**
- Educate user to whitelist Sada from battery optimization, where possible.

**Suggested Tests:**
- Device-specific testing across OEMs with notorious task killers.

***

### S-055 – استخدام التطبيق خلال يوم عمل عادي مع اتصال متقطع

**Context (English):**
- User carries Sada 8–10 hours at work with moderate connectivity.

**Risks:**
- Background battery drain may be unacceptable if poorly tuned.

**Technical Considerations:**
- Balanced PowerMode should keep average consumption low (<1–2%/h ideally).

**UX Considerations:**
- Provide simple summary like "Battery impact: Low/Medium/High" in settings.

**Suggested Tests:**
- Real-world battery profiling across a typical workday for multiple power modes.

***

### S-056 – حالة سكون طويلة مع نوافذ اتصال قصيرة

**Context (English):**
- Phone is idle on a table; only small contact windows with other devices.

**Risks:**
- Wasted scans with no peers; wasted energy.

**Technical Considerations:**
- Use adaptive scanning intervals based on historical peer density.

**UX Considerations:**
- No extra UI; but telemetry may inform tuning.

**Suggested Tests:**
- Simulation of sparse contact plus dynamic scan/sleep tuning.

***

### S-057 – شحن متنقل عبر Power Bank أثناء الحركة

**Context (English):**
- User uses power bank while walking in protest or disaster area.

**Risks:**
- Higher available power may encourage more aggressive scanning; but still limited.

**Technical Considerations:**
- Detect charging state and adapt PowerMode accordingly.

**UX Considerations:**
- Offer to temporarily switch to High Performance while plugged in.

**Suggested Tests:**
- Manual experiments switching between battery and USB power mid-session.

***

### S-058 – جهاز قديم منخفض الأداء

**Context (English):**
- Old Android phone with limited CPU and weaker battery.

**Risks:**
- High CPU usage for DTN logic may cause lag and overheating.

**Technical Considerations:**
- Computation-heavy operations (encryption, hashing) must be efficient and batched.

**UX Considerations:**
- Provide an optional "light mode" (less frequent scans) for old devices.

**Suggested Tests:**
- Benchmark cryptographic operations and DTN processing on low-end devices.

***

### S-059 – شبكة منزلية مع أجهزة متعددة لكل أسرة

**Context (English):**
- Several family members use Sada at home; some devices are always charging.

**Risks:**
- Network may rely heavily on these "always-on" devices; battery less of a concern but fairness is.

**Technical Considerations:**
- Differentiated PowerModes per device; some act as mini-relay hubs.

**UX Considerations:**
- Optional "Help the mesh" opt-in: "Use my device as relay while charging".

**Suggested Tests:**
- Household scenario simulation with mix of always-on and on-the-go devices.

***

### S-060 – مستوى بطارية منخفض مع رسائل حرجة قيد الإرسال

**Context (English):**
- Battery <10%, but user needs to send critical message.

**Risks:**
- Device may die before any peer encounter occurs.

**Technical Considerations:**
- Possibly increase scan rate for short burst after sending, even in low-power mode.

**UX Considerations:**
- Show clear warning that message may not be delivered if battery dies soon.

**Suggested Tests:**
- Controlled tests sending messages at various low battery thresholds.

***

## 6. سيناريوهات المنصة (Android/iOS)

### S-061 – شبكة Android فقط مع دعم Nearby كامل

**Context (English):**
- All devices are Android with Nearby Connections enabled.

**Risks:**
- Platform assumptions may fail later when iOS devices are introduced.

**Technical Considerations:**
- EpidemicRouter can rely fully on Nearby; no need for alternative transports.

**UX Considerations:**
- Nothing special here; baseline.

**Suggested Tests:**
- Multi-device Android-only trials across varied environments (indoor/outdoor).

***

### S-062 – شبكة مختلطة Android + iOS مع محدودية iOS في الخلفية

**Context (English):**
- Some nodes are iOS devices with restricted background capabilities.

**Risks:**
- iOS devices may only participate when app is foregrounded.

**Technical Considerations:**
- Transport abstraction should allow per-platform differences.

**UX Considerations:**
- Set expectations for iOS users: "Messages may only move when app is open".

**Suggested Tests:**
- Mixed platform test: send messages through chains including iOS hops.

***

### S-063 – OS kills background service بشكل متكرر

**Context (English):**
- OEM aggressively shuts down background services.

**Risks:**
- Missed DTN opportunities and limited reliability.

**Technical Considerations:**
- Foreground service plus sticky restart logic must be used.

**UX Considerations:**
- Provide simple instructions for disabling aggressive battery killers.

**Suggested Tests:**
- Device-specific experiments on problematic OEMs (e.g., Xiaomi, Huawei).

***

### S-064 – صلاحيات Bluetooth مرفوضة

**Context (English):**
- User denies Bluetooth permissions.

**Risks:**
- Sada DTN essentially non-functional; no discovery.

**Technical Considerations:**
- App must detect and gracefully handle missing Bluetooth capability.

**UX Considerations:**
- Clear explanation: "Without Bluetooth, offline mesh cannot work".

**Suggested Tests:**
- Permission toggling tests: start app with/without Bluetooth permission.

***

### S-065 – صلاحيات Location مرفوضة على Android

**Context (English):**
- User denies Location; Nearby/BT scanning may be restricted.

**Risks:**
- Discovery fails even if Bluetooth is enabled.

**Technical Considerations:**
- Follow Android’s requirement to request coarse location for BT scanning.

**UX Considerations:**
- Provide privacy-respecting explanation why Location is needed for mesh.

**Suggested Tests:**
- Evaluate scanning success under different location permission states.

***

### S-066 – صلاحيات Notifications مرفوضة

**Context (English):**
- User denies notification permission on Android 13+.

**Risks:**
- User may never notice delivered messages while app is backgrounded.

**Technical Considerations:**
- Message delivery logic still works; only alerting is degraded.

**UX Considerations:**
- Optional non-intrusive reminder banner encouraging enabling notifications.

**Suggested Tests:**
- Functional test where notifications are disabled but messages still sync to DB.

***

### S-067 – اختلافات بين إصدارات Android (API 24–34)

**Context (English):**
- Sada runs on a wide range of Android versions.

**Risks:**
- Behavior of background services, sockets, and permissions may differ.

**Technical Considerations:**
- Use conditionals and tested APIs for each min/target SDK.

**UX Considerations:**
- Ensure consistent user experience across OS versions where possible.

**Suggested Tests:**
- Cross-version matrix tests in emulator and on physical devices.

***

### S-068 – استخدام Sada على جهاز لوحي (Tablet)

**Context (English):**
- Tablet with different form factor, possibly stationary.

**Risks:**
- Layout may break; device might become unintentional mesh hub.

**Technical Considerations:**
- UI must be responsive, and background behaviors similar.

**UX Considerations:**
- Take advantage of larger screen for debug/mesh dashboards (advanced users).

**Suggested Tests:**
- UI layout tests and background behavior observation on tablets.

***

### S-069 – إعادة تشغيل الهاتف أثناء عمل Background Service

**Context (English):**
- Device reboots while Sada background service was active.

**Risks:**
- Lost DTN window while phone is booting; background service may not auto-restart.

**Technical Considerations:**
- Boot receiver or user reminder to reopen Sada for DTN reliability.

**UX Considerations:**
- Subtle prompt on next open: "Enable background mesh again?".

**Suggested Tests:**
- End-to-end: reboot device during active mesh usage and see how quickly service recovers.

***

### S-070 – تغيّر في سياسات المتجر (Play Store / App Store) حول الخلفية

**Context (English):**
- Platform policy change affecting background execution.

**Risks:**
- Forced architectural adjustments; possible features removal.

**Technical Considerations:**
- Abstract transport and background logic, making it adaptable to policy constraints.

**UX Considerations:**
- Transparent communication when capabilities are reduced by platform limitations.

**Suggested Tests:**
- Policy review and consultation; regression tests after any major SDK update.

***

## 7. سيناريوهات الأعطال والتلف (Failures & Corruption)

### S-071 – تعطل التطبيق أثناء عملية التشفير

**Context (English):**
- App crashes mid-encryption of a message.

**Risks:**
- Incomplete or inconsistent DB records; message stuck in limbo.

**Technical Considerations:**
- Use transactional inserts: only commit message row after encryption completes.

**UX Considerations:**
- Show a simple error and allow user to resend.

**Suggested Tests:**
- Fault injection: crash app immediately after encryption call but before DB insert.

***

### S-072 – تعطل التطبيق أثناء استقبال RelayPacket

**Context (English):**
- Crash occurs during processing of incoming relay payload.

**Risks:**
- Corrupted or partially written relay queue entries.

**Technical Considerations:**
- Validate JSON payloads and handle DB errors gracefully on restart.

**UX Considerations:**
- End user should not see duplicated or malformed messages.

**Suggested Tests:**
- Inject crash at different stages in `_handleRelayPacket` and observe recovery.

***

### S-073 – اختلاف كبير في الساعة بين الأجهزة (Clock Skew)

**Context (English):**
- Devices have skewed system clocks (hours apart).

**Risks:**
- Incorrect TTL expiration and misleading timestamps.

**Technical Considerations:**
- TTL based primarily on relative durations, not absolute wallclock when possible.

**UX Considerations:**
- Indicate potential clock issues if timestamps appear in the "future" or very old.

**Suggested Tests:**
- Simulate differing device clocks and inspect TTL and message sorting behavior.

***

### S-074 – تلف جزئي في قاعدة البيانات

**Context (English):**
- App DB becomes partially corrupted (disk issues, abrupt power loss).

**Risks:**
- Loss of some messages or relay entries, potential crashes.

**Technical Considerations:**
- Drift’s migration and recovery features; fallback to new DB with minimal user disruption.

**UX Considerations:**
- Honest but minimal error messaging: "Some offline data may be lost".

**Suggested Tests:**
- Corrupt DB files intentionally and test startup recovery logic.

***

### S-075 – Packet Signature Verification Failure (future Ed25519)

**Context (English):**
- Once signatures are implemented, some packets fail signature checks.

**Risks:**
- Potentially malicious tampering; must discard such packets.

**Technical Considerations:**
- Strict drop of invalid-sig packets; no partial trust.

**UX Considerations:**
- No direct indication to user; only logs for developers.

**Suggested Tests:**
- Unit tests with corrupted signature bytes; ensure detection and logging.

***

### S-076 – فشل في قراءة مفاتيح التشفير من التخزين الآمن

**Context (English):**
- FlutterSecureStorage fails or returns invalid key material.

**Risks:**
- Encryption/decryption impossible; app may misbehave.

**Technical Considerations:**
- Regenerate keys or show blocking error; never use partially read keys.

**UX Considerations:**
- Ask user to re-register if keys cannot be restored; explain consequences.

**Suggested Tests:**
- Mock storage failures and see application behavior at startup and during encryption.

***

### S-077 – Failure in Foreground Service Notification Creation

**Context (English):**
- BackgroundService fails to create its persistent notification.

**Risks:**
- OS may kill the service; DTN capabilities drop.

**Technical Considerations:**
- Catch and log notification errors; fallback behavior (e.g., restart in normal mode).

**UX Considerations:**
- Possibly warn the user that "background mesh is not fully active".

**Suggested Tests:**
- Simulate notification channel issues and observe service lifecycle.

***

### S-078 – Corrupted RelayQueue entries due to JSON parsing errors

**Context (English):**
- RelayPacket.payload contains an invalid MeshMessage JSON string.

**Risks:**
- Dropped messages or failure in final delivery.

**Technical Considerations:**
- Strict try/catch around JSON decoding; drop or quarantine malformed entries.

**UX Considerations:**
- Invisible to user; error is internal.

**Suggested Tests:**
- Insert malformed payloads into RelayQueue via test harness.

***

### S-079 – OS-level storage full

**Context (English):**
- Device runs out of storage space.

**Risks:**
- DB writes fail, messages and relay entries lost.

**Technical Considerations:**
- App should handle `write` failures gracefully and clean up temporary files.

**UX Considerations:**
- Notify user that storage is full and DTN operation may be impaired.

**Suggested Tests:**
- Fill device storage artificially, then attempt to send/receive messages.

***

### S-080 – Network Stack Inconsistencies due to Vendor Bugs

**Context (English):**
- Vendor-specific Bluetooth/WiFi bugs cause random disconnects.

**Risks:**
- Reduced reliability; false perception that Sada is broken.

**Technical Considerations:**
- Extra robustness in discovery and retry logic; health metrics.

**UX Considerations:**
- Suggest trying different radio settings or toggling airplane mode as a troubleshooting tip.

**Suggested Tests:**
- Cross-vendor tests with focus on historically problematic devices.

***

## 8. سيناريوهات الاختبارات الميدانية (Field Testing)

### S-081 – اختبار ميداني في قرية ريفية بدون إنترنت

**Context (English):**
- Small team visits a rural area to test Sada offline over several days.

**Risks:**
- On-site issues may be hard to debug without connectivity.

**Technical Considerations:**
- Logging must be compact and exportable later.

**UX Considerations:**
- Test participants should receive simple instructions and expectations.

**Suggested Tests:**
- Deploy 10+ devices with scripted movement and messaging routines.

***

### S-082 – اختبار في حرم جامعي لمدة فصل دراسي كامل

**Context (English):**
- Long-term pilot at a university campus.

**Risks:**
- Software updates mid-pilot may introduce regressions.

**Technical Considerations:**
- CI/CD and migration strategy must be robust before pilot.

**UX Considerations:**
- Gather structured feedback per week from pilot participants.

**Suggested Tests:**
- Weekly metrics collection on delivery rates, battery cost, and user satisfaction.

***

### S-083 – تجربة Sada في مظاهرة حقيقية

**Context (English):**
- Volunteers use Sada in a real protest scenario.

**Risks:**
- Personal safety; app reliability is crucial; data must remain private.

**Technical Considerations:**
- Use only stable, audited builds and features; no experimental code.

**UX Considerations:**
- Minimal complexity; only essential features enabled.

**Suggested Tests:**
- Pre-event drills; post-event data analysis (with anonymization).

***

### S-084 – اختبار في مهرجان موسيقي كبير

**Context (English):**
- Many participants in a festival area with patchy cell coverage.

**Risks:**
- Overload and user confusion; large number of potential nodes.

**Technical Considerations:**
- Validate mesh performance at high density with multiple constraints.

**UX Considerations:**
- Simple cues about offline vs online; encourage local chat usage.

**Suggested Tests:**
- Pilot with staff/friends at festival, capturing logs and feedback.

***

### S-085 – اختبار في مدينة حدودية ذات رقابة متقطعة

**Context (English):**
- City at a border with intermittent network shutdowns.

**Risks:**
- Rapid transition between normal internet and no connectivity.

**Technical Considerations:**
- Ensure consistent behavior when internet goes from available to off; DTN remains active.

**UX Considerations:**
- Clear indication that Sada continues working offline when other apps fail.

**Suggested Tests:**
- Simulated net blocks using firewall or airplane mode schedules.

***

### S-086 – اختبار في قطار ضواحي خلال ساعات الذروة

**Context (English):**
- Commuters on suburban trains; medium density, fast movement.

**Risks:**
- Short-lived connections; limited transfer time.

**Technical Considerations:**
- Evaluate handshake speed and throughput under mobility.

**UX Considerations:**
- Focus on "send now, it will deliver later" messaging.

**Suggested Tests:**
- Have volunteers ride trains with pre-scripted messaging tasks.

***

### S-087 – اختبار في مركز إيواء خلال كارثة طبيعية

**Context (English):**
- Sada is used in an emergency shelter with many displaced people.

**Risks:**
- Emotionally charged environment; failure can cause serious distress.

**Technical Considerations:**
- Test reliability and usability with emergency workers before deploying widely.

**UX Considerations:**
- Extremely clear and empathetic messaging about what Sada can and cannot do.

**Suggested Tests:**
- Collaboration with NGOs to run controlled drills.

***

### S-088 – اختبار على مستوى مدينة كاملة (Pilot City)

**Context (English):**
- Official pilot across several neighborhoods in a city.

**Risks:**
- Scale-related bugs; high variability across user behaviors and devices.

**Technical Considerations:**
- Observability: ability to collect anonymized, aggregated stats.

**UX Considerations:**
- Provide easy channels for user feedback and bug reports.

**Suggested Tests:**
- Multi-week pilot with staged rollout and staged analysis.

***

### S-089 – اختبار في بيئة جامعية عالية الرقابة

**Context (English):**
- University with heavy surveillance and device checks.

**Risks:**
- Confiscation risk; need duress and strong security posture.

**Technical Considerations:**
- Duress mode and full encryption must be verified before any field trial.

**UX Considerations:**
- Thorough training session for student users.

**Suggested Tests:**
- Simulations of checkpoint interactions; user training evaluation.

***

### S-090 – اختبار في منطقة صناعية مع تداخل راديو شديد

**Context (English):**
- Factories and industrial equipment causing radio interference.

**Risks:**
- Unstable short-range connectivity.

**Technical Considerations:**
- Need to evaluate Sada performance under noisy RF conditions.

**UX Considerations:**
- Avoid promising strong reliability; frame as best-effort offline tool.

**Suggested Tests:**
- Field trials in factories or near heavy machinery.

***

## 9. سيناريوهات الميزات المتقدمة (Groups, Files, Voice, Location)

### S-091 – دردشة جماعية صغيرة (5–10 أعضاء)

**Context (English):**
- Small group chat functionality built over DTN.

**Risks:**
- Group routing complexity and duplication across many recipients.

**Technical Considerations:**
- Future: group ID or shared key; messages may require multiple endpoints as recipients.

**UX Considerations:**
- Expose group vs 1:1 chat clearly; clarify that group messages may take longer.

**Suggested Tests:**
- Simulation of small group chat behavior over multiple hops.

***

### S-092 – دردشة جماعية كبيرة (50+ أعضاء)

**Context (English):**
- Large groups for announcements or coordination.

**Risks:**
- Massive replication overhead and group key management issues.

**Technical Considerations:**
- May need specialized group routing or local broadcast semantics.

**UX Considerations:**
- Provide message throttling and anti-spam UI cues.

**Suggested Tests:**
- Large-group simulation with heavy message volumes.

***

### S-093 – إرسال ملف صغير (صورة) عبر DTN

**Context (English):**
- Users send small media files (e.g., compressed images).

**Risks:**
- Payload sizes may challenge short contact windows; incomplete transfers.

**Technical Considerations:**
- File chunking and reassembly; maximum payload per packet.

**UX Considerations:**
- Show progress bars and partial-transfer statuses clearly.

**Suggested Tests:**
- Transfer multiple images under varying contact durations.

***

### S-094 – إرسال ملف كبير نسبيًا (فيديو قصير)

**Context (English):**
- Sending short videos (tens of MB).

**Risks:**
- Large contributions to RelayQueue and storage; slow forwarding.

**Technical Considerations:**
- Strong need for chunked DTN delivery and per-file TTL/priority.

**UX Considerations:**
- Label such sends as "slow, offline" and avoid blocking UI.

**Suggested Tests:**
- Simulate and test chunked transfers under mobility conditions.

***

### S-095 – رسائل صوتية قصيرة

**Context (English):**
- Voice notes used as an alternative to text.

**Risks:**
- Higher payload size than plain text, but often tolerable.

**Technical Considerations:**
- Compression and chunking; potential prioritization.

**UX Considerations:**
- Show waveform and simple statuses similar to text messages.

**Suggested Tests:**
- Measure battery and network impact of frequent voice notes.

***

### S-096 – مشاركة موقع تقريبي مع حماية خصوصية عالية

**Context (English):**
- Users sharing approximate location (e.g., region) rather than exact GPS.

**Risks:**
- Over-sharing location may expose users; under-sharing may reduce usefulness.

**Technical Considerations:**
- Location fuzzing or cell-level granularity; encryption and whitelist.

**UX Considerations:**
- Clear settings for precision level; default to safe approximate values.

**Suggested Tests:**
- Privacy review and user feedback on location-sharing granularity.

***

### S-097 – قنوات تنبيه خاصة (SOS / Panic)

**Context (English):**
- Specialized "panic" messages broadcast to trusted group.

**Risks:**
- Potential overuse and false alarms; network flood.

**Technical Considerations:**
- Prioritization but strong rate limiting per user.

**UX Considerations:**
- High-friction UI (long-press, confirmation) to avoid accidental triggers.

**Suggested Tests:**
- Simulation of panic events; monitor network load and response.

***

### S-098 – تشفير متعدد المستلمين (Multiple Recipient Encryption)

**Context (English):**
- Message intended for multiple contacts, each with own keypair.

**Risks:**
- Payload bloat from multiple encrypted copies; complexity.

**Technical Considerations:**
- Possibly using per-group keys in future; not initial MVP.

**UX Considerations:**
- No complexity exposed to end-users; they just see "send to group".

**Suggested Tests:**
- Cryptographic design review; no direct field tests yet.

***

### S-099 – رسائل موقوتة الانتهاء (Self-Expiring Messages)

**Context (English):**
- Messages that should disappear after certain time.

**Risks:**
- Confusing interplay between TTL for routing vs TTL for content visibility.

**Technical Considerations:**
- Distinct "delivery TTL" vs "display TTL".

**UX Considerations:**
- Clear labeling of expiry; do not surprise users by silent deletion.

**Suggested Tests:**
- Simulation with content expiry across devices and DB cleanup.

***

### S-100 – وضع "فقط من جهات الاتصال الموثوقة"

**Context (English):**
- Strict mode allowing messages from whitelist contacts only.

**Risks:**
- Important messages via new contacts may be silently dropped.

**Technical Considerations:**
- Already approximated via contact whitelist in IncomingMessageHandler.

**UX Considerations:**
- Provide clear toggle and warnings about potential missed messages.

**Suggested Tests:**
- Tests sending from known vs unknown senders and verifying behavior.

***

## 10. سيناريوهات التطوير والـ CI (Dev, CI/CD & Regression)

### S-101 – تغيير في منطق ACK يؤدي إلى كسر MessageStatus

**Context (English):**
- Developer modifies ACK handling logic.

**Risks:**
- Messages may never progress to `delivered` or may prematurely mark as delivered.

**Technical Considerations:**
- Regression tests must cover multiple ACK arrival patterns and missing ACKs.

**UX Considerations:**
- Incorrect statuses can deeply confuse users about reliability.

**Suggested Tests:**
- CI test suites with synthetic ACK scenarios; snapshot-testing of MessageStatus in DB.

***

### S-102 – إعادة كتابة منطق RelayQueue دون اختبارات كافية

**Context (English):**
- Developer refactors RelayQueue DAOs or schema.

**Risks:**
- Data loss, broken cleanup logic, incorrect max-count handling.

**Technical Considerations:**
- Migration tests and property-based tests for queue invariants (no duplicates, TTL behavior).

**UX Considerations:**
- Sudden loss of in-flight messages may reduce trust.

**Suggested Tests:**
- CI: migration tests from older schema versions and randomized enqueue/dequeue simulations.

***

### S-103 – تعديل Duty Cycle قد يكسر استهلاك البطارية

**Context (English):**
- Changes to BackgroundService duty cycle parameters.

**Risks:**
- Unexpected battery drain or missed contacts.

**Technical Considerations:**
- Power-mode regression tests need to run on real devices.

**UX Considerations:**
- Keep the semantics of "balanced/high/low" consistent across versions.

**Suggested Tests:**
- Automated long-run tests with instrumentation on reference devices.

***

### S-104 – إعادة تصميم واجهة الحالة (Status Icons) في UI

**Context (English):**
- UX refactor for message bubbles and status icons.

**Risks:**
- Users might misinterpret new icons; regression in semantics.

**Technical Considerations:**
- No direct protocol change, but tests must confirm mapping from DB status to icons.

**UX Considerations:**
- Testing and documentation for what each icon means after redesign.

**Suggested Tests:**
- Snapshot UI tests and user comprehension surveys pre/post redesign.

***

### S-105 – refactor في MeshService يؤثر على handleIncomingMeshMessage

**Context (English):**
- Internal refactoring of MeshService.

**Risks:**
- Broken routing decisions; faulty dedup; missed ACK processing.

**Technical Considerations:**
- Extensive unit tests around MeshMessage parsing, validation, and routing.

**UX Considerations:**
- Users might see missing or duplicated messages if regressions slip through.

**Suggested Tests:**
- CI tests for valid/invalid MeshMessages, dedup behavior, and ACK handling.

***

### S-106 – إدخال Bloom Filter في Handshake Summary

**Context (English):**
- Optimization implementing Bloom Filter–based sync.

**Risks:**
- False positives/negatives causing missing packets or wasted requests.

**Technical Considerations:**
- Careful parameter tuning and correctness tests.

**UX Considerations:**
- Invisible to end user; only affects reliability/performance.

**Suggested Tests:**
- Property-based tests on BloomFilter implementation; integration tests for sync correctness.

***

### S-107 – تحسينات على Duress Mode قد تغير سلوك القاعدة المزدوجة

**Context (English):**
- Improvements to dual DB switching and duress UI.

**Risks:**
- Real DB accidentally exposed or decoy DB incomplete.

**Technical Considerations:**
- Automated tests verifying which DB is open under each PIN.

**UX Considerations:**
- Users must still find duress mode practical and believable.

**Suggested Tests:**
- End-to-end tests logging which DB file is actually used in each mode.

***

### S-108 – تكامل مع أدوات مراقبة الأداء (Performance Profilers)

**Context (English):**
- Adding optional instrumentation for performance profiling.

**Risks:**
- Accidentally logging sensitive data or hurting performance.

**Technical Considerations:**
- Ensure instrumentation is stripped or disabled in production builds.

**UX Considerations:**
- No visible effect; purely internal.

**Suggested Tests:**
- Verify no PII is logged; measure overhead of instrumentation.

***

### S-109 – تحسينات على Logging قد تكشف معلومات حساسة

**Context (English):**
- Developer adds verbose logs, possibly including decrypted message content.

**Risks:**
- Serious privacy leak if logs are exfiltrated.

**Technical Considerations:**
- Static analysis or lint rules to ban logging of decrypted content.

**UX Considerations:**
- Not visible to users directly but existential risk for trust.

**Suggested Tests:**
- Code review + automated scanning for risky logging patterns.

***

### S-110 – سيناريو Regression بعد تغييرات على BackgroundService

**Context (English):**
- Major change in BackgroundService or power management.

**Risks:**
- Previously working DTN scenarios failing silently in new release.

**Technical Considerations:**
- Regression suite focusing on long-term background connectivity and peer counts.

**UX Considerations:**
- Pre-release pilots and staged rollouts to detect regressions early.

**Suggested Tests:**
- Continuous integration scenarios mimicking long-term background tests (12–24h).

***

---

> ملاحظة: هذا الكتالوج يغطي أكثر من 110 سيناريو رئيسي مع تنويعات عديدة ضمنيًا (من حيث الكثافة، الحركة، البطارية، المنصة، والأمان). يمكن توسيعه مستقبلاً بإضافة سيناريوهات أكثر تخصصًا لكل سوق أو بلد أو حالة استخدام بدون تغيير الهيكل العام.  


