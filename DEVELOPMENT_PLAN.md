## 📡 خطة تطوير مشروع Sada (صدى) – Delay-Tolerant Mesh Messenger

### 1️⃣ الملخص التنفيذي (Executive Summary)

- **نسبة اكتمال المشروع (تقديريًا)**: **≈ 70%**  
  - طبقة الأمن والتشفير: ✅ ~100%  
  - طبقة الشبكة والـ DTN (Mesh + Epidemic Routing): 🔄 ~70–80%  
  - طبقة قاعدة البيانات (Duress + Relay Queue): ✅ ~90%  
  - طبقة الـ UI / UX: 🔄 ~65–75%  
- **تركيز السبرنت الحالي (Week 2–3)**:  
  - إكمال منطق **Epidemic Routing + ACK-based delivery**  
  - تحسين **Relay Queue + Sync Protocol** لتقليل التكرار والاستهلاك  
  - تحسين **Tracking لحالة الرسائل** داخل الـ UI والـ DB  
- **أهم العوائق الحالية (Blockers)**:
  - 🔄 عدم وجود بروتوكول ACK واضح للـ **end-to-end delivery confirmation** في طبقة Mesh/Router.
  - ⚠️ غياب آليات **congestion control** (Token Bucket / storage cap) على Relay Queue.
  - ⚠️ اعتماد المنصة على Android بشكل كبير، مع عدم وجود خطة تنفيذية واضحة لـ iOS (خاصة background execution وNearby/بدائلها).
- **Quick Wins (عائد كبير بتغييرات محدودة)**:
  - [ ] إضافة **ACK Message Type** بسيط في `MeshService` + حالة `delivered` حقيقية للرسالة.  
  - [ ] تطبيق حد أعلى لحجم Relay Queue عبر `AppDatabase.getRelayStorageSize()` مع سياسات حذف واضحة.  
  - [ ] ربط إشعارات الرسائل الواردة بشكل أوثق مع **Chat navigation** وتحسين تجربة النقر على الإشعار.  

---

### 2️⃣ نظرة معمارية عامة (Architecture Overview)

#### 2.1 مخطط المعمارية العامة (Stack Diagram)

```mermaid
flowchart TD
    UI[Features (auth/chat/contacts/settings...)\nWidgets + Screens] 
      --> State[Riverpod Controllers & Providers\nchat_controller, meshServiceProvider, authServiceProvider]

    State --> Core[Core Services & Modules\nsecurity, network, database, services, power]

    Core --> Crypto[Security Layer\nEncryptionService + KeyManager + HandshakeProtocol]
    Core --> Network[Network Layer\nMeshService + EpidemicRouter + DiscoveryService\nUDP + Nearby Connections + Socket]
    Core --> DB[Database Layer\nAppDatabase (Drift) + Duress Mode + RelayQueueTable]
    Core --> Platform[Platform Services\nBackgroundService + NotificationService + BiometricService]

    Network <--> Transport[Native Transport\nWiFi Direct / Bluetooth LE / UDP]
```

#### 2.2 تحليل هيكل الملفات (File Structure Analysis)

- **`lib/core/` (أولوية عالية – تم تنفيذه بشكل جيد)**:
  - `core/security/`  
    - `encryption_service.dart`: يغلف `sodium_libs` لاستخدام **XSalsa20-Poly1305** مع `secretBox`, ويدير Nonce وMAC والتحقق من سلامة الرسائل.  
    - `key_manager.dart`: توليد وحفظ مفاتيح Curve25519 باستخدام `FlutterSecureStorage`، مع caching للمفاتيح في الذاكرة.  
    - `security_providers.dart`: يربط `EncryptionService` و `KeyManager` مع Riverpod.  
  - `core/network/`  
    - `mesh_service.dart`: طبقة Mesh فوق `MethodChannel`/`EventChannel` (TCP sockets + UDP) مع **Store-Carry-Forward Routing** (MeshMessage + Relay Queue قديمة).  
    - `router/epidemic_router.dart`: طبقة Epidemic Routing باستخدام **Nearby Connections (P2P_CLUSTER)** + Handshake Summary/Request/RelayPacket.  
    - `protocols/handshake_protocol.dart`: بروتوكول Handshake مبني على `UserId + publicKey` مع Contact Whitelisting.  
    - `discovery_service.dart` + `discovery/udp_broadcast_service.dart`: طبقة discovery مجهولة الهوية (ServiceId عشوائي) فوق UDP.  
    - `incoming_message_handler.dart`: يربط Mesh messages مع قاعدة البيانات وجهات الاتصال والـ UI.  
  - `core/database/`  
    - `app_database.dart`: Drift Database مع جداول **Contacts / Chats / Messages / RelayQueue**، وواجهات DAO قوية (insert/get/watch/cleanup).  
    - `tables/*.dart`: تعريف الجداول (MessagesTable, RelayQueueTable, ...).  
  - `core/services/`  
    - `auth_service.dart`: إدارة `UserData`, `AuthStatus`, `AuthType` مع دعم **Duress PIN / Master PIN**.  
    - `background_service.dart`: تكامل مع `flutter_background_service` لتشغيل **EpidemicRouter** في Foreground Service مع Duty Cycle متقدم.  
    - `notification_service.dart`: إدارة إشعارات Flutter المحلية وصلاحيات `POST_NOTIFICATIONS`.  
  - `core/power/discovery_strategy.dart`: سلوك discovery بناءً على حالة الطاقة.  

- **`lib/features/` (تغطية متوسطة – UI + UX)**:
  - `features/chat/`:  
    - `application/chat_controller.dart`: مسؤول عن إرسال الرسائل، التشفير، التحديث في DB، واستدعاء `MeshService.sendMeshMessage`.  
    - `data/repositories/*.dart`: Repos مستقرة فوق `AppDatabase`.  
    - `presentation/widgets/message_bubble.dart`: عرض حالة الرسالة (sending/sent/delivered/read/failed) بصورة Cyberpunk.  
  - `features/auth/`, `features/onboarding/`, `features/settings/`, إلخ: تم تطبيقها بشكل جيد، مع UI مناسب + ربط مع Auth/PIN/Duress.

- **`lib/utils/` و `lib/models/` (تغطية خفيفة – Utilities)**:
  - `core/utils/log_service.dart`: Logging موحد مع مستويات مختلفة.  
  - `core/models/power_mode.dart`: تعريف PowerMode وخصائص Duty Cycle.  

#### 2.3 أنماط التصميم المستخدمة (Design Patterns)

- **State Management**:  
  - استخدام Riverpod / `@riverpod` و `StateNotifierProvider` مع Providers **keepAlive** في الطبقات الحساسة (`EpidemicRouter`, `meshServiceProvider`, `authServiceProvider`).  
- **Repository + DAO Pattern**:  
  - `ChatRepository`, `OnboardingRepository`, إلخ فوق `AppDatabase` مع فصل واضح بين **domain models** و **Drift tables** عبر Mappers.  
- **Service Layer**:  
  - `EncryptionService`, `NotificationService`, `BackgroundService`, `MeshService` تعمل كـ **Single Responsibility Services** مع Error Logging واضح.  
- **Zero-Trust + Whitelisting Pattern**:  
  - `HandshakeProtocol` و `IncomingMessageHandler` يطبقان **Contact Whitelisting** ورفض الرسائل من مصادر غير معروفة.  

#### 2.4 تدقيق التبعيات (Dependencies Audit)

- أمن وتشفير:
  - `sodium_libs` (libsodium)  
  - `flutter_secure_storage`  
- شبكة واتصال:
  - `nearby_connections` (Android Nearby)  
  - `permission_handler`  
  - Native TCP/UDP عبر `MethodChannel` و `EventChannel`  
- قاعدة بيانات:
  - `drift`, `drift/native`, `path_provider`  
- حالة وإدارة:
  - `flutter_riverpod`, `riverpod_annotation`  
- واجهة وتجربة:
  - `go_router`, `flutter_local_notifications`, `flutter_background_service`, `device_info_plus`, إلخ.  

> ✅ ملاحظة: لا توجد مكتبات مشبوهة أو غير ضرورية ظاهرة؛ التركيز واضح على الخصوصية والأمن.

---

### 3️⃣ مصفوفة الميزات (Feature Matrix)

#### 3.1 جدول حالة الميزات

| Feature                         | Status | Completion % | Priority | Blockers                                      |
|---------------------------------|--------|--------------|----------|-----------------------------------------------|
| End-to-End Encryption           | ✅ Complete | 100%        | P0       | None                                          |
| Key Management (X25519)         | ✅ Complete | 100%        | P0       | None                                          |
| Duress Mode (Dual DB + PINs)    | ✅ Complete | 100%        | P0       | None                                          |
| Contact Whitelisting + QR       | ✅ Complete | 95%         | P0       | تحسين UX التبادل الثنائي فقط                 |
| Mesh Transport (TCP/UDP)        | ✅ Complete | 90%         | P0       | تحسين استقرار الـ sockets                    |
| Epidemic Routing (Nearby)       | 🔄 In Progress | 85%    | P0       | ACK packets + congestion control             |
| Relay Queue (Store-Carry-Forward) | 🔄 In Progress | 80%   | P0       | Storage limit + retry policies               |
| Message Status Tracking (UI+DB) | 🔄 In Progress | 75%    | P0       | ACK من الطرف المستقبل                        |
| Background Service (Android)    | 🔄 In Progress | 80%    | P0       | ضبط Duty Cycle ديناميكي + battery heuristics |
| iOS Support (Background + Transport) | ⚠️ Blocked | 20% | P1       | قيود iOS background + بديل Nearby            |
| Permissions Handling (BT/WiFi/Notif) | 🔄 In Progress | 70% | P1 | توحيد تجربة طلب الصلاحيات                   |
| Material 3 Cyberpunk UI         | 🔄 In Progress | 70%    | P2       | تحسين micro-interactions + empty states      |
| Group Chats                     | 🔄 In Progress | 40%    | P2       | Mesh routing للجروبات + UI                   |
| Notifications UX                | 🔄 In Progress | 60%    | P2       | Deep-links أفضل + دمج مع Duress Mode         |

---

### 4️⃣ جودة الكود (Code Quality Metrics)

> تنبيه: الأرقام تقريبية مبنية على عدد الملفات وحجمها النسبي، وليست قياسًا آليًا دقيقًا.

- **Lines of Code by Module (تقريبي)**:
  - `core/network/`: ~1700–2000 سطر (MeshService, EpidemicRouter, Discovery, Handshake, Incoming Handler)  
  - `core/database/`: ~900–1100 سطر (AppDatabase, Tables, DAOs)  
  - `core/security/`: ~350–450 سطر (EncryptionService, KeyManager, providers)  
  - `core/services/`: ~800–1000 سطر (auth, background, notification, biometric, power_mode)  
  - `features/chat/`: ~900–1100 سطر (controller, repos, models, widgets)  
  - باقي `features/` (auth, onboarding, settings, etc.): ~1500–2000 سطر.  

- **Test Coverage (حالياً)**:
  - مجلد `test/` يحتوي:  
    - `simulation_test.dart`  
    - `widget_test.dart`  
    - `test_helpers.dart` + `.g.dart`  
  - مجلد `integration_test/` يحتوي:  
    - `integration_test/app_test.dart`  
  - **التقدير**: تغطية منطق الأعمال (core/network/core/security/core/database) ما زالت **منخفضة**، مع بعض الاختبارات العامة لـ UI أو simulation.  
  - ✅ فرصة واضحة لإضافة **unit tests** لـ:
    - `EncryptionService` و `KeyManager`  
    - `HandshakeProtocol`  
    - `EpidemicRouter._handleHandshakeSummary / _handleRelayPacket`  
    - `AppDatabase` DAOs (خصوصًا Relay Queue).  

- **تحليل التكرار (Duplication)**:
  - بعض الأنماط المتكررة في:
    - التعامل مع `FlutterSecureStorage` في `KeyManager`, `AuthService`, `DiscoveryService`.  
    - منطق فك التشفير ومعالجة الرسائل في `MeshService.MessageHandler` و `IncomingMessageHandler`.  
  - يمكن لاحقًا استخراج **Utility layer** صغيرة للصلاحيات وSecure Storage لتقليل التكرار.

- **نقاط الدين التقني (Technical Debt Hotspots)**:
  - `mesh_service.dart`: يحتوي على منطق Mesh Routing القديم (RelayQueue للرسائل) بالتوازي مع EpidemicRouter الجديد لـ RelayPacket – يحتاج إلى **توحيد المفهوم** حتى لا تتشعب البروتوكولات.  
  - `AppDatabase.getRelayPacketsForSync()`: يوجد TODO لبناء **Bloom Filter / Vector Summary** وتحديد الحزم بدل إرسال قائمة كاملة.  
  - TODO واضح في `EpidemicRouter` حول:  
    - فك تشفير الرسالة النهائية + ربطها بطبقة الـ chat/notification.  

---

### 5️⃣ خارطة طريق الأسبوعين القادمين (Next 2 Weeks Roadmap)

#### Week 3 (Feb 13–19, 2026)

##### ✅ Priority 1 – ACK-based Delivery & Message Status

- [ ] **تصميم وإضافة ACK Message Type في Mesh/Epidemic Layers**
  - **جهد تقديري**: 1–1.5 يوم  
  - **Dependencies**: `MeshService`, `EpidemicRouter`, `IncomingMessageHandler`, `MessagesTable`  
  - **وصف**:
    - إضافة نوع رسالة `ACK` في بروتوكول Mesh/Epidemic (مثلاً في `MeshMessage.type` أو حقل منفصل في RelayPacket).  
    - عند استلام الرسالة النهائية على جهاز المستقبل، يتم:
      - حفظها في DB.  
      - إرسال ACK نحو المرسل الأصلي (نفس المسار أو Epidemic Back-Propagation).  
    - عند وصول ACK للمرسل الأصلي، يقوم النظام بتحديث حالة الرسالة إلى `delivered`.  

- [ ] **تحديث UI لعرض حالة `delivered` الحقيقية بناءً على ACK**
  - **جهد تقديري**: 0.5 يوم  
  - **Dependencies**: `MessageModel`, `MessageMapper`, `MessageBubble` widget.  

##### ✅ Priority 2 – Relay Queue Limits & Congestion Control (v1)

- [ ] **تطبيق حد أعلى لحجم Relay Queue (مثلاً 50MB أو عدد رسائل معين)**  
  - **جهد تقديري**: 1 يوم  
  - **Dependencies**: `AppDatabase`, `RelayQueueTable`, `EpidemicRouter`, Background cleanup.  
  - **وصف**:
    - استخدام `getRelayStorageSize()` كخط أساس (count-based)، مع TODO لاحقًا لحساب الحجم الفعلي.  
    - عند تجاوز الحد، تطبيق سياسة حذف (LRU أو الأقدم زمنًا).  

- [ ] **Token Bucket بسيط لكل Node للحد من flooding**  
  - **جهد تقديري**: 1 يوم  
  - **Dependencies**: `EpidemicRouter` و/أو `MeshService`.  

##### ✅ Priority 3 – تحسينات Background Duty Cycle & Power Mode

- [ ] **ربط `PowerMode` بشكل أوضح مع Duty Cycle**  
  - **جهد تقديري**: 0.5–1 يوم  
  - **Dependencies**: `background_service.dart`, `power_mode_provider.dart`, `discovery_strategy.dart`.  

- [ ] **لوحة Debug داخل app لعرض حالة Background / Duty Cycle / Peer Count**  
  - **جهد تقديري**: 0.5 يوم  
  - **Dependencies**: `features/mesh/presentation/mesh_debug_screen.dart`.  

---

#### Week 4 (Feb 20–26, 2026)

##### ✅ Priority 1 – Sync Protocol Optimization (Bloom Filter / Delta Sync)

- [ ] **إضافة Bloom Filter أو Vector Clock مبسط في Handshake Summary**  
  - **جهد تقديري**: 1.5–2 يوم  
  - **Dependencies**: `EpidemicRouter._initiateHandshake`, `AppDatabase.getRelayPacketsForSync`.  

- [ ] **تجنب طلب حزم مكررة بين نفس العقد المتكررة الاتصال**  
  - **جهد تقديري**: 1 يوم  
  - **Dependencies**: Cache-level في `EpidemicRouter` + DB.  

##### ✅ Priority 2 – iOS Support Exploration

- [ ] **تحليل بدائل Nearby على iOS (MultipeerConnectivity / Bonjour / BLE)**  
  - **جهد تقديري**: 1–2 يوم (بحث + Prototype بسيط).  

- [ ] **تصميم واجهة مجردة للـ Transport** (Interface فوق `Nearby` / iOS backend)  
  - **جهد تقديري**: 1 يوم.  

##### ✅ Priority 3 – UX Polish & Permissions Flows

- [ ] **تجربة Permissions موحدة (Bluetooth, Location, Notifications)**  
  - **جهد تقديري**: 1 يوم  
  - **Dependencies**: `NOTIFICATIONS_SETUP.md`, `POWER_MANAGEMENT_SETUP.md`, `CAMERA_PERMISSIONS_SETUP.md`.  

- [ ] **تحسين Onboarding لشرح Duress Mode + Offline Mesh بشكل مبسط**  
  - **جهد تقديري**: 0.5–1 يوم  

---

### 6️⃣ أدلة التنفيذ (Implementation Guides) – أعلى 3 أولويات

#### 6.1 أولوية 1 – ACK-based Delivery & Message Status

##### 6.1.1 الفكرة العامة

- عند استلام رسالة نهائية (على جهاز المستقبل) في `IncomingMessageHandler` أو في طبقة `MeshService.handleIncomingMeshMessage`, يتم:
  - التأكد من أن الرسالة موجهة لهذا الجهاز.  
  - حفظ الرسالة في DB.  
  - إرسال **ACK MeshMessage** جديد يحتوي: `originalMessageId`, `senderId`, `finalDestinationId` هو **المرسل الأصلي**.  
- عند استلام ACK في جهاز المرسل الأصلي، يتم:
  - تحديث حالة الرسالة في DB إلى `delivered`.  

##### 6.1.2 خطوات تنفيذية

- **الخطوة 1 – توسيع نموذج `MeshMessage` لدعم ACK**

```dart
// lib/core/network/models/mesh_message.dart
class MeshMessage {
  static const String typeContactExchange = 'CONTACT_EXCHANGE';
  static const String typeAck = 'ACK'; // جديد

  final String messageId;
  final String originalSenderId;
  final String finalDestinationId;
  final String encryptedContent;
  final int hopCount;
  final int maxHops;
  final List<String> trace;
  final DateTime timestamp;
  final String? type;
  final Map<String, dynamic>? metadata;
}
```

- **الخطوة 2 – إرسال ACK من جهاز المستقبل**

  - في `IncomingMessageHandler._handleIncomingMessage`، بعد حفظ الرسالة بنجاح والتأكد أنها ليست `CONTACT_EXCHANGE` أو system-only:

```dart
// داخل _handleIncomingMessage بعد حفظ الرسالة الواردة
final meshService = _ref.read(meshServiceProvider);
final authService = _ref.read(authServiceProvider.notifier);
final currentUser = authService.currentUser;
final myId = currentUser?.userId;

if (myId != null && isMeshMessage) {
  final originalMessageId = messageData['messageId'] as String?;
  final originalSenderId = messageData['originalSenderId'] as String?;

  if (originalMessageId != null && originalSenderId != null) {
    final ackPayload = jsonEncode({
      'originalMessageId': originalMessageId,
    });

    await meshService.sendMeshMessage(
      originalSenderId,
      encryptedContent, // يمكن تشفير ackPayload بنفس sharedKey أو استخدام قناة meta
      senderId: myId,
      maxHops: 10,
      type: MeshMessage.typeAck,
    );
  }
}
```

- **الخطوة 3 – معالجة ACK في `MeshService.handleIncomingMeshMessage`**

```dart
Future<void> handleIncomingMeshMessage(String rawMessage) async {
  final jsonData = jsonDecode(rawMessage) as Map<String, dynamic>;
  final messageType = jsonData['type'] as String?;

  if (messageType == MeshMessage.typeAck) {
    await _handleAck(jsonData);
    return;
  }

  // بقية المنطق كما هو للرسائل العادية...
}

Future<void> _handleAck(Map<String, dynamic> data) async {
  try {
    final originalMessageId = data['originalMessageId'] as String?;
    if (originalMessageId == null) return;

    final db = await _ref.read(appDatabaseProvider.future);
    await db.updateMessageStatus(originalMessageId, 'delivered');

    LogService.info('✅ ACK received for message: $originalMessageId');
  } catch (e) {
    LogService.error('خطأ في معالجة ACK', e);
  }
}
```

- **الخطوة 4 – التأكد من أن `MessageBubble` تعرض الحالات بشكل صحيح**  
  - الكود الحالي في `message_bubble.dart` يدعم `sending/sent/delivered/read/failed` بالفعل، لذا لا حاجة لتعديلات كبيرة؛ فقط التأكد أن DB يتم تحديثها بـ `'delivered'` بناءً على ACK.

##### 6.1.3 إستراتيجية الاختبار

- **وحدة**:
  - اختبارات لـ `_handleAck` تتأكد من:
    - استدعاء `updateMessageStatus` بالقيمة الصحيحة.  
    - تجاهل ACK غير صالح (بدون `originalMessageId`).  
- **اندماج (Integration)**:
  - سيناريو Twin Devices (محاكاة): إرسال رسالة من Device A إلى B، التحقق من:  
    - حالة الرسالة في A: `sending -> sent -> delivered`.  
    - حالة الرسالة في B: `delivered` فور حفظها (بدون ACK إضافي).  

##### 6.1.4 معايير النجاح (Success Criteria)

- الرسائل التي تصل إلى المستقبل وتعود منها ACK تتحول إلى `delivered` عند المرسل الأصلي خلال TTL منطقي.  
- لا يوجد Logging لمحتوى الرسالة المفكوك، فقط IDs وحالات.  
- عدم حصول loops أو Spam في رسائل ACK.  

---

#### 6.2 أولوية 2 – Relay Queue Limits & Congestion Control

##### 6.2.1 الفكرة العامة

- منع امتلاء التخزين عبر Relay Queue، ومنع flooding من Node واحد بإرسال كمية كبيرة من الحزم.  

##### 6.2.2 خطوات تنفيذية (Storage Limit)

- **الخطوة 1 – إضافة إعداد حد أعلى (Config)**

```dart
// lib/core/utils/constants.dart
const int RELAY_QUEUE_MAX_COUNT = 5000; // مثال عددي مبدئي
```

- **الخطوة 2 – تعديل `enqueueRelayPacket` في `AppDatabase`**

```dart
Future<void> enqueueRelayPacket(RelayQueueTableCompanion packet) async {
  final currentSize = await getRelayStorageSize();
  if (currentSize >= RELAY_QUEUE_MAX_COUNT) {
    // حذف أقدم الحزم قبل الإدراج
    await _trimRelayQueue(currentSize - RELAY_QUEUE_MAX_COUNT + 1);
  }

  await into(relayQueueTable).insert(packet, mode: InsertMode.replace);
  LogService.info('📦 تم تخزين Relay Packet: ${packet.packetId.value}');
}

Future<void> _trimRelayQueue(int deleteCount) async {
  final oldest = await (select(relayQueueTable)
        ..orderBy([(t) => OrderingTerm(expression: t.queuedAt)]))
      .get();

  for (var i = 0; i < deleteCount && i < oldest.length; i++) {
    await delete(relayQueueTable)
        .delete(oldest[i]);
  }

  LogService.info('🧹 تم حذف $deleteCount من أقدم Relay Packets للحفاظ على السعة');
}
```

##### 6.2.3 خطوات تنفيذية (Token Bucket بسيط)

- **فكرة**: داخل `EpidemicRouter`، لكل Peer نحتفظ بعدد Tokens (مثلاً 20 حزمة لكل دقيقة)، ننقصه عند الإرسال ونعيد تعبئته دورياً.

```dart
// داخل EpidemicRouter
final Map<String, int> _peerTokens = {};
static const int _maxTokensPerPeer = 20;
static const Duration _tokenRefillInterval = Duration(minutes: 1);

void _startTokenRefillTimer() {
  Timer.periodic(_tokenRefillInterval, (_) {
    _peerTokens.updateAll((_, __) => _maxTokensPerPeer);
  });
}

bool _canSendToPeer(String endpointId) {
  final tokens = _peerTokens[endpointId] ?? _maxTokensPerPeer;
  if (tokens <= 0) return false;
  _peerTokens[endpointId] = tokens - 1;
  return true;
}
```

- قبل استدعاء `_sendJson(endpointId, packetJson)` في `EpidemicRouter`, يتم:

```dart
if (!_canSendToPeer(endpointId)) {
  LogService.warning('Token bucket exceeded for $endpointId, skipping packet');
  return;
}
_sendJson(endpointId, packetJson);
```

##### 6.2.4 معايير النجاح

- عدم نمو Relay Queue إلى ما لا نهاية، وبقاؤها ضمن حدود معقولة.  
- عدم إرسال أكثر من N حزمة لكل Peer في الدقيقة (قابل للضبط).  
- بقاء أداء Discovery/Duty Cycle مستقر وعدم استنزاف البطارية.  

---

#### 6.3 أولوية 3 – Sync Protocol Optimization (Bloom Filter / Delta Sync)

> هذه أولوية Week 4، ولكن وضع خطة مبكرة مفيد لتجنب إعادة تصميم لاحقة.

##### 6.3.1 الفكرة العامة

- بدلاً من إرسال قائمة كاملة بجميع `packetId` في كل Handshake، يمكن إرسال:  
  - **Bloom Filter** يمثل مجموعة الحزم التي يمتلكها الجهاز.  
  - أو **Vector Summary** (مثلاً: range-based summary أو hash-based partitioning).  
- الطرف الآخر يستخدم هذه الـ Summary لتحديد أي الحزم يفتقدها.  

##### 6.3.2 خطة مختصرة لـ Bloom Filter (v1)

- إضافة كلاس بسيط BloomFilter في `core/network/models/`:

```dart
class SimpleBloomFilter {
  final List<bool> bits;
  final int size;
  final int hashFunctions;

  SimpleBloomFilter(this.size, {this.hashFunctions = 3})
      : bits = List<bool>.filled(size, false);

  void add(String value) {
    for (var i = 0; i < hashFunctions; i++) {
      final index = _hash(value, i) % size;
      bits[index] = true;
    }
  }

  bool mightContain(String value) {
    for (var i = 0; i < hashFunctions; i++) {
      final index = _hash(value, i) % size;
      if (!bits[index]) return false;
    }
    return true;
  }

  int _hash(String value, int seed) {
    // استخدام hash بسيط (يمكن تحسينه لاحقاً)
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = (hash * 31 + code + seed) & 0x7fffffff;
    }
    return hash;
  }

  Map<String, dynamic> toJson() => {
        'size': size,
        'hashFunctions': hashFunctions,
        'bits': bits.map((b) => b ? 1 : 0).toList(),
      };

  static SimpleBloomFilter fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final filter = SimpleBloomFilter(size, hashFunctions: json['hashFunctions'] as int);
    final bitList = (json['bits'] as List).cast<int>();
    for (var i = 0; i < bitList.length && i < size; i++) {
      filter.bits[i] = bitList[i] == 1;
    }
    return filter;
  }
}
```

- في `EpidemicRouter._initiateHandshake`:
  - بدلاً من إرسال قائمة كل IDs، يتم إرسال Bloom Filter + subset صغيرة من الـ IDs الحرجة (مثلاً للحزم الحديثة).  

##### 6.3.3 معايير النجاح

- تقليل حجم Handshake Summary في الشبكات ذات الكثافة العالية إلى أقل من 5–10KB.  
- بقاء منطق الحزم كما هو (لا فقدان لحزم مهمة)، مع احتمال خطأ (false positives) مقبول.  

---

### 7️⃣ تقييم المخاطر (Risk Assessment)

- **استهلاك البطارية (Battery Drain)** – 🔴 Critical  
  - `NearbyConnections` و `WiFi Direct` مع Duty Cycle عالي قد يستنزف البطارية.  
  - **التخفيف**:
    - استخدام `PowerMode` + `discovery_strategy` لضبط intervals بناءً على البطارية والحركة.  
    - إعادة تقييم `_scanDuration` و`_sleepDuration` في `EpidemicRouter` و `BackgroundService`.  

- **قيود iOS على background execution** – ⚠️ High  
  - iOS لا يسمح بخدمات Foreground طويلة الأمد مثل Android.  
  - **التخفيف**:
    - دراسة `MultipeerConnectivity` + background modes المتاحة (VoIP, external accessory, etc).  
    - تصميم UX يقبل reconnect عند فتح التطبيق بدلاً من الاعتماد الكامل على background.  

- **هجمات Flooding / Spam من عقدة خبيثة** – ⚠️ High  
  - بدون Token Bucket وحدود Relay Queue، يمكن لجهاز خبيث إغراق الشبكة.  
  - **التخفيف**:
    - تفعيل Token Bucket per-peer.  
    - حدود Relay Queue + سياسات حذف.  
    - Whitelisting صارم + إمكانية Block/Report للعقد.  

- **تسرب محتوى الرسائل (Logging / Debug)** – Medium  
  - الكود الحالي يلتزم بعدم طباعة المحتوى المفكوك، لكن يجب الاستمرار في مراجعة أي Logs جديدة.  
  - **التخفيف**:
    - سياسة واضحة: عدم استخدام `decryptedMessage` في أي Log جديد.  
    - إمكانية تعطيل Logs الحساسة في production (`analysis_options` + flags).  

---

### 8️⃣ مؤشرات الأداء (Performance Benchmarks)

#### 8.1 الوضع الحالي (مستنتج من الكود)

- **Encryption/Decryption**:
  - استخدام `sodium.crypto.secretBox.easy` مع Nonce عشوائي؛ العمليات قصيرة نسبيًا (متوقع < 5–10ms لكل رسالة على أجهزة متوسطة).  
- **Routing Decision Time**:
  - `EpidemicRouter._handleRelayPacket` و `_handleHandshakeSummary` تعتمد على عمليات DB بسيطة + Hashing؛ متوقع < 10ms للحزمة في الظروف العادية.  
- **Database Access**:
  - Drift يستخدم Native backend مع indices معقولة؛ زمن query للرسائل والRelayQueue متوقع < 50ms في الغالبية.  

#### 8.2 الأهداف (Targets)

- **Message encryption**: < 5ms لكل رسالة.  
- **Packet relay decision**: < 10ms.  
- **Relay queue operations (insert/check/cleanup)**: < 30ms متوسّط.  
- **Discovery cycle**:
  - Balanced Mode: scan window ~20–30s لكل 5–10 دقائق.  

#### 8.3 فرص التحسين

- تخفيض استدعاءات DB المتكررة في `EpidemicRouter._handlePacketRequest` عبر caching مؤقت لجلسة المزامنة.  
- استخدام Bloom Filter أو vector summary لتقليل حجم Handshake وتحسين سرعة تحديد الحزم المفقودة.  
- تحسين `MeshService.flushRelayQueue` ليستخدم batching بدلاً من loop synchronous لكل رسالة.  

---

### 9️⃣ خلاصة عملية (Actionable Summary)

- **ما يجب بناؤه فورًا (Next)**:
  - [ ] إضافة **ACK-based delivery** وربطها مع `MessageStatus.delivered`.  
  - [ ] وضع حدود واضحة لـ **Relay Queue** وتطبيق Token Bucket مبسط لمنع flooding.  
  - [ ] تحسين Duty Cycle وسلوك Background بناءً على `PowerMode`.  

- **ما يجب التخطيط له للأسبوع القادم**:
  - [ ] إدخال **Bloom Filter / Delta Sync** في بروتوكول الـ Epidemic Routing.  
  - [ ] بدء تصميم طبقة Transport مجرّدة لدعم iOS (Multipeer / BLE).  

- **الفجوة بين الوضع الحالي والجاهزية للإنتاج**:
  - المنظومة حالياً قوية من ناحية **Security + Local Privacy + Duress Mode**.  
  - النقاط التي تفصل Sada عن نسخة جاهزة للإنتاج هي أساساً:
    - **Reliability** (ACKs + congestion control).  
    - **Cross-platform support (iOS)**.  
    - **Test coverage أعمق لطبقة core**.  

> هذه الخطة قابلة للتنفيذ بخطوات صغيرة ومقسّمة بوضوح، مع شيفرات جاهزة للنسخ ودمج مباشر في الكود الحالي، مع مراعاة الأداء والسرية والجاهزية الميدانية في سيناريوهات الأزمات والرقابة.  


