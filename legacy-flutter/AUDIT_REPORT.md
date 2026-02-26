# 🔒 Sada (صدى) — تقرير مراجعة أمنية وهندسية شامل

> **التاريخ:** 2025-02-25  
> **المرحلة:** Alpha — قبل أول اختبار ميداني  
> **المراجع:** Antigravity / Deep Code Audit  
> **منهجية المراجعة:** تحليل ثابت (Static Analysis) لكامل الكود المصدري مع مراجعة يدوية معمّقة لكل ملف أمني وشبكي

---

## الملخص التنفيذي

| المجال | الحالة | مستوى الجاهزية |
|---|---|---|
| التشفير E2E | ⚠️ يعمل جزئياً | **غير جاهز للميدان** |
| إدارة المفاتيح | 🔴 ثغرات حرجة | **غير جاهز** |
| Duress Mode | 🔴 غير مكتمل | **هيكل فقط** |
| Mesh Networking | ⚠️ يعمل مع مشاكل | **يحتاج إصلاحات** |
| قاعدة البيانات | 🔴 غير مشفرة | **غير جاهز** |
| الأمان التشغيلي | 🔴 تسريبات واسعة | **غير جاهز** |
| LoRa | 🔴 غير موجود | **لم يُنفَّذ بعد** |

> [!CAUTION]
> **لا يُنصح بالنشر الميداني في الحالة الحالية.** يوجد عدد من الثغرات الحرجة التي يمكن أن تعرّض المستخدمين للخطر في بيئة عالية المخاطر (مناطق نزاع).

---

## 1. تقييم الأمان والتشفير

### 1.1 التشفير End-to-End

**الحالة الحالية:**
- الخوارزمية: X25519 ECDH → Blake2b KDF → XSalsa20-Poly1305 (عبر libsodium) ✅
- كل رسالة تُشفَّر بـ Nonce عشوائي 24 بايت ✅
- MAC verification يمنع التلاعب بالرسائل ✅

**المخاطر المكتشفة:**

| الخطورة | الوصف | الملف |
|---|---|---|
| 🔴 **حرج** | **لا يوجد Forward Secrecy** — نفس الـ Shared Secret يُستخدم لكل الرسائل بين أي زوج. إذا سُرق المفتاح الخاص، يمكن فك تشفير **كل** الرسائل السابقة والمستقبلية | [encryption_service.dart](file:///Users/obadadallo/Desktop/sada/lib/core/security/encryption_service.dart#L43-L106) |
| 🔴 **حرج** | **المفتاح الخاص مخبأ كـ `Uint8List` عادي** في ذاكرة Dart الـ heap — يمكن استخراجه من memory dump. libsodium's `SecureKey` يُستخدم فقط مؤقتاً ثم يُنسخ إلى `Uint8List` عادي | [key_manager.dart:77](file:///Users/obadadallo/Desktop/sada/lib/core/security/key_manager.dart#L77) |
| ⚠️ **عالي** | **لا يوجد آلية Key Rotation** — المفتاح يبقى ثابتاً طوال حياة التطبيق | [key_manager.dart](file:///Users/obadadallo/Desktop/sada/lib/core/security/key_manager.dart) |
| ⚠️ **عالي** | **عند فشل تحميل المفاتيح يتم توليد مفاتيح جديدة بصمت** — هذا يعني ضياع القدرة على فك تشفير كل الرسائل السابقة بدون إعلام المستخدم | [key_manager.dart:131-135](file:///Users/obadadallo/Desktop/sada/lib/core/security/key_manager.dart#L131-L135) |
| ⚠️ **عالي** | **فشل فك التشفير يُعاد كنص واضح** — `decryptedMessage = encryptedContent` إذا لم يكن هناك publicKey، مما يعني أن الرسائل تُعرض بشكل مشوّه بدل رفضها | [incoming_message_handler.dart:183-189](file:///Users/obadadallo/Desktop/sada/lib/core/network/incoming_message_handler.dart#L183-L189) |

**التوصيات:**

```
الأولوية 1 (قبل الميدان):
├── تنفيذ Double Ratchet Protocol (أو على الأقل per-session ephemeral keys)
├── استخدام SecureKey من libsodium بدلاً من Uint8List للمفاتيح الخاصة
├── عند فشل تحميل المفاتيح: إعلام المستخدم ورفض التشغيل (لا توليد صامت)
└── رفض الرسائل غير القابلة لفك التشفير بدلاً من عرض النص المشفر
```

### 1.2 إدارة المفاتيح

**الحالة الحالية:**
- المفاتيح تُخزن في `FlutterSecureStorage` (Android Keystore / iOS Keychain) ✅
- يُولَّد زوج مفاتيح Curve25519 عند أول استخدام ✅

**المخاطر:**

| الخطورة | الوصف |
|---|---|
| 🔴 **حرج** | `_cachedKeyPair` يحتوي `Uint8List privateKey` كعضو في كائن Dart عادي. هذا يعني أن المفتاح الخاص يبقى في الـ heap حتى يُجمع من GC — لا يمكن مسحه بشكل حاسم (`clearCache()` يضع `null` لكن البايتات لا تزال في الذاكرة) |
| ⚠️ **عالي** | `AndroidOptions()` فارغ — لا يُفعّل `encryptedSharedPreferences`. التعليق يقول "deprecated" لكن هذا غير صحيح في الإصدارات الحالية |
| ⚠️ **عالي** | لا يوجد فحص Integrity — إذا تم التلاعب بالمفتاح المخزن، لا يتم اكتشاف ذلك |

### 1.3 Duress Mode

**الحالة الحالية:**
- الهيكل موجود: `AuthType.duress` في `background_service.dart` يمنع تشغيل الشبكة
- النصوص (localization) موجودة: `setDuressPin`, `duressPinWarning`, `enterDuressPin`
- الـ routing موجود: `safe_notes_screen.dart`

**المخاطر:**

| الخطورة | الوصف |
|---|---|
| 🔴 **حرج** | **Duress Mode غير مكتمل فعلياً** — لا يوجد PIN ثانٍ (duress PIN) في `AuthService`. `verifyPin()` يتحقق فقط من `masterPinHash`. لا يوجد كود يميز بين Master PIN و Duress PIN |
| 🔴 **حرج** | **لا يوجد قاعدة بيانات وهمية فعلية** — `AppDatabase.create()` تأخذ filename واحد. لا يوجد كود يُنشئ أو يعرض قاعدة بيانات مختلفة. التعليق `/// تدعم Duress Mode` لم يُنفَّذ بعد |
| ⚠️ **عالي** | مجرد فحص اسم ملف قاعدة بيانات (بدون تشفير) ليس كافياً — محقق جنائي يمكنه رؤية ملفين `.db` وفهم الآلية |

**التوصية:** إما تنفيذ الآلية بالكامل أو **إزالة كل إشارات Duress Mode** من واجهة المستخدم حتى لا تعطي إحساساً زائفاً بالأمان.

### 1.4 QR Code Key Exchange — مخاطر MITM

**الحالة الحالية:**
- QR Code يحتوي: `{id, name, publicKey}` بصيغة JSON
- المسح يتم وجهاً لوجه (Physical Verification) ✅

**المخاطر:**

| الخطورة | الوصف |
|---|---|
| ⚠️ **متوسط** | لا يوجد Trust-On-First-Use (TOFU) verification — إذا تم استبدال QR Code (مثل طباعة ملصق مزور) فلا يمكن للمستخدم التحقق لاحقاً |
| ⚠️ **متوسط** | لا يوجد Safety Number / Fingerprint — لا يمكن للمستخدمين التحقق من أن المفاتيح لم تتغير |

**التوصية:** إضافة شاشة "التحقق من الأمان" تعرض fingerprint مشتق من المفتاحين العامين (مثل Signal Safety Numbers).

### 1.5 Forward Secrecy

| الخطورة | الوصف |
|---|---|
| 🔴 **حرج** | **لا يوجد Forward Secrecy إطلاقاً.** `calculateSharedSecret()` يُنتج مفتاح جلسة ثابت من مفتاحين ثابتين. سرقة المفتاح الخاص = فك تشفير كل المحادثات (ماضي + حاضر + مستقبل) |

---

## 2. مراجعة بنية Mesh Networking

### 2.1 طبقات النقل

**الحالة الحالية:**
- **WiFi LAN**: UDP Broadcast (port 45454) → TCP Socket (port 8888) ✅
- **Nearby Connections**: عبر `EpidemicRouter` (BLE + WiFi Direct) ✅
- **LoRa**: ❌ لم يُنفَّذ بعد

**المخاطر:**

| الخطورة | الوصف | الملف |
|---|---|---|
| 🔴 **حرج** | **UDP Broadcast يرسل DeviceId (SHA-256 hash) بشكل واضح** — أي جهاز على نفس الشبكة يمكنه جمع هوية جميع مستخدمي صدى. هذا يُمكّن Traffic Analysis | [udp_broadcast_service.dart:161](file:///Users/obadadallo/Desktop/sada/lib/core/network/discovery/udp_broadcast_service.dart#L161) |
| 🔴 **حرج** | **TCP Sockets بدون TLS** — كل البيانات (بما فيها Handshake JSON) تُنقل بصيغة نص واضح عبر الشبكة المحلية. مهاجم على نفس WiFi يمكنه قراءة كل metadata | [SocketManager.kt](file:///Users/obadadallo/Desktop/sada/android/app/src/main/kotlin/org/sada/messenger/SocketManager.kt) |
| ⚠️ **عالي** | **Handshake يرسل peerId و publicKey بشكل واضح** عبر TCP — حتى لو كان محتوى الرسائل مشفراً، الـ metadata (من يتحدث مع من) مكشوف | [handshake_protocol.dart](file:///Users/obadadallo/Desktop/sada/lib/core/network/protocols/handshake_protocol.dart) |
| ⚠️ **عالي** | **TCP port 8888 ثابت** — يسهّل الكشف عن مستخدمي صدى عبر port scanning | [udp_broadcast_service.dart:34](file:///Users/obadadallo/Desktop/sada/lib/core/network/discovery/udp_broadcast_service.dart#L34) |

### 2.2 Discovery و Battery Optimization

**الحالة الحالية:**
- `DiscoveryStrategy` تُكيّف فترات الاكتشاف حسب البطارية/الشحن ✅
- المدى: 5 ثوان (أداء) → 600 ثانية (بطارية منخفضة) ✅
- `EpidemicRouter` يستخدم Token Bucket لمنع burst flooding ✅

**المخاطر:**

| الخطورة | الوصف |
|---|---|
| ⚠️ **متوسط** | `updateBatteryStatus()` يُستدعى مرة واحدة عند التهيئة فقط — لا يوجد listener مستمر لتغييرات البطارية |
| ⚠️ **متوسط** | `Nearby Connections` يستخدم `Strategy.P2P_CLUSTER` مما يعني استهلاك بطارية مرتفع بسبب BLE scanning المستمر |

### 2.3 Message Routing — Loops و Broadcast Storms

**الحالة الحالية:**
- **Loop Detection**: `trace` list تمنع إعادة المرور على نفس الجهاز ✅
- **TTL**: `hopCount / maxHops` (default: 10 hops) ✅
- **Deduplication**: `_processedMessages` Set + Bloom Filters ✅
- **Token Bucket**: يحدّ من عدد الرسائل لكل peer ✅

**المخاطر:**

| الخطورة | الوصف |
|---|---|
| ⚠️ **متوسط** | `_processedMessages` هو `Set` في الذاكرة — يُفقد عند إعادة تشغيل التطبيق، مما يسمح بمعالجة رسائل مكررة |
| ⚠️ **متوسط** | `_processedMessages` ينمو بلا حد — لا يوجد حد أقصى أو تنظيف دوري (memory leak محتمل) |
| ⚠️ **عالي** | `EpidemicRouter` و `MeshService` نظامان متوازيان يقومان بنفس الوظيفة (اكتشاف + توجيه) — تعقيد غير ضروري ومصدر محتمل لتناقضات |

---

## 3. تحليل الكود والهندسة البرمجية

### 3.1 Flutter + Riverpod + GoRouter

**المخاطر:**

| الخطورة | الوصف |
|---|---|
| ⚠️ **عالي** | `keyManagerProvider` و `encryptionServiceProvider` يُنشآن instances جديدة بدون `initialize()` — الاستدعاء الأول لـ `calculateSharedSecret()` سيرمي `StateError` إذا لم يُستدعَ `initialize()` مسبقاً. لا يوجد lifecycle management |
| ⚠️ **متوسط** | `AuthService` يستخدم `StateNotifier` مع constructor يستدعي async `_checkLoginStatus()` — هذا anti-pattern لأن الـ state يمكن أن يتغير قبل أن يُقرأ |
| ⚠️ **متوسط** | `MeshService` ملف ضخم (1350+ سطر) يمزج بين Transport, Discovery, Handshake, Routing, و Diagnostics — يحتاج تقسيم |

### 3.2 Drift Database

**الحالة الحالية:**
- SQLite عبر Drift مع background isolate (`NativeDatabase.createInBackground`) ✅
- Schema version 7 مع migration strategy ✅

**المخاطر:**

| الخطورة | الوصف |
|---|---|
| 🔴 **حرج** | **قاعدة البيانات غير مشفرة** — ملف `.db` في `getApplicationDocumentsDirectory()` يمكن قراءته بأي أداة SQLite. كل الرسائل والجهات مكشوفة | 
| ⚠️ **عالي** | `getApplicationDocumentsDirectory()` لا يُشفَّر تلقائياً على Android. يجب الانتقال إلى `getApplicationSupportDirectory()` أو استخدام SQLCipher |
| ⚠️ **متوسط** | Relay Queue لا تُنظَّف بشكل كافٍ — `cleanupOldRelayMessages()` تعتمد على طابع زمني لكن لا يوجد حد على العدد الكلي |

### 3.3 Native Bridge (Kotlin)

**الحالة الحالية:**
- `MethodChannel` لاستدعاء TCP operations ✅
- `EventChannel` لـ message stream و socket status ✅
- Length-prefixed framing (4 bytes header) ✅

**المخاطر:**

| الخطورة | الوصف |
|---|---|
| ⚠️ **عالي** | `MAX_MESSAGE_SIZE_BYTES` ثابت (غير مرئي في الكود المعروض) — إذا كان كبيراً جداً قد يسمح بهجوم DoS عبر إرسال frame ضخم |
| ⚠️ **متوسط** | `ServerSocket` يقبل اتصال واحد فقط في كل مرة — اتصال ثانٍ يُلغي الأول |
| ⚠️ **متوسط** | لا يوجد authentication على TCP connection — أي جهاز على الشبكة يمكنه الاتصال بـ port 8888 |

### 3.4 Error Handling في بيئة Offline

| الخطورة | الوصف |
|---|---|
| ⚠️ **عالي** | `_addFriendToDatabase` لا يتعامل مع فشل إنشاء chat — إذا فشل `insertChat()` بعد نجاح `insertContact()` تبقى جهة الاتصال بدون محادثة |
| ⚠️ **عالي** | `CONTACT_EXCHANGE` يتجاوز Whitelist بالكامل — هذا يفتح احتمال spam عبر إرسال CONTACT_EXCHANGE من أي جهاز لإضافة نفسه قسراً |
| ⚠️ **متوسط** | `sendMeshMessage` يفشل بصمت إذا لم يكن هناك peer متصل — الرسالة تُخزن في relay queue لكن لا يوجد إخطار واضح للمستخدم |

---

## 4. نقاط الضعف التشغيلية (Operational Security)

### 4.1 Metadata Leakage

| الخطورة | الوصف |
|---|---|
| 🔴 **حرج** | **LogService يسجل كل شيء** — معرفات الأجهزة، عناوين IP، حالات الاتصال، أسماء المستخدمين. الـ Logs تبقى في `logcat` ويمكن استخراجها بأداة `adb logcat` |
| 🔴 **حرج** | **الرسائل المستلمة تُعرض في الإشعارات** — محتوى الرسالة يظهر في notification bar (مرئي للمراقب) |
| ⚠️ **عالي** | `SharedPreferences` يحتوي backup لبيانات المستخدم (`user_data_backup`) — هذا **نص واضح** يشمل userId و displayName |
| ⚠️ **عالي** | `test_output.txt` في مجلد المشروع قد يحتوي مخرجات تشخيصية حساسة |

### 4.2 Forensic Analysis

| الخطورة | الوصف |
|---|---|
| 🔴 **حرج** | قاعدة بيانات SQLite غير مشفرة = كل الرسائل قابلة للقراءة بأداة مثل `sqlite3` |
| 🔴 **حرج** | ملفات الصوت تُخزن في `getApplicationDocumentsDirectory()` بدون تشفير — ملفات `.ogg` يمكن تشغيلها مباشرة |
| ⚠️ **عالي** | عند استخدام Duress PIN (عندما يُنفَّذ)، وجود ملفي `.db` على نفس الجهاز يكشف أن هناك نظام ثنائي |

### 4.3 Physical Security

| الخطورة | الوصف |
|---|---|
| ⚠️ **عالي** | لا يوجد screen protection (FLAG_SECURE) — يمكن تصوير الشاشة أو أخذ screenshots |
| ⚠️ **عالي** | لا يوجد clipboard protection — نسخ الرسائل يبقيها في clipboard |
| ⚠️ **متوسط** | المفاتيح المخبأة في `_cachedKeyPair` عرضة لـ Cold Boot Attack (استخراج الذاكرة) |

---

## 5. LoRa Integration

### الحالة الحالية

🔴 **لم يُنفَّذ بعد.** لا يوجد أي كود LoRa في المشروع. فقط ذكر في التوثيق.

### التوصيات للتنفيذ المستقبلي

| الموضوع | التوصية |
|---|---|
| **التردد** | 868 MHz لسوريا/أوروبا (ISM band). **لا تستخدم 915 MHz** (أمريكا فقط) |
| **Spread Factor** | SF10-SF12 للمدى الأقصى في بيئة حضرية (حتى 5 كم). SF7 فقط إذا المسافة < 500م |
| **Payload** | حد أقصى ~51-222 بايت حسب SF. يجب تنفيذ message fragmentation لأي رسالة > 50 بايت |
| **Power** | Heltec WiFi LoRa 32 يستهلك ~120mA TX. يجب تنفيذ deep sleep + duty cycle (< 1% TX time) |
| **البروتوكول** | JSON ضخم جداً لـ LoRa. استخدم binary protobuf أو custom packed format |

---

## 6. Checklist قبل أول اختبار ميداني

### 🔴 حرج — يجب إكماله قبل أي اختبار

- [ ] **تشفير قاعدة البيانات** — الانتقال إلى SQLCipher عبر `drift` + `sqlcipher_flutter_libs`
- [ ] **تشفير ملفات الصوت** — استخدام XSalsa20 لتشفير `.ogg` قبل الحفظ
- [ ] **إيقاف Logging الحساس** — إزالة/تعطيل طباعة device IDs, IPs, و أسماء المستخدمين في production
- [ ] **إصلاح privacy إشعارات** — إخفاء محتوى الرسالة من notification bar
- [ ] **إزالة backup من SharedPreferences** — حذف `_storageBackupKey`
- [ ] **إصلاح CONTACT_EXCHANGE** — إضافة rate limiting + token verification بدل الفتح الكامل

### ⚠️ عالي — يُفضَّل قبل الميدان

- [ ] **إضافة FLAG_SECURE** لمنع screenshots
- [ ] **Per-session ephemeral keys** — على الأقل ratchet بسيط بدل shared secret ثابت
- [ ] **رفض الرسائل غير القابلة لفك التشفير** بدل عرض النص المشفر
- [ ] **تحديد حجم `_processedMessages`** — LRU cache بحد أقصى 10,000 عنصر
- [ ] **تعشية Port** — استخدام port عشوائي بدل 8888 الثابت
- [ ] **إكمال Duress Mode** أو إزالة إشاراته من UI

### 📋 متوسط — حسب الأولوية

- [ ] تقسيم `mesh_service.dart` إلى ملفات أصغر
- [ ] إضافة Safety Numbers لفحص هوية المفاتيح
- [ ] إضافة battery listener مستمر بدل فحص مرة واحدة
- [ ] حد على حجم relay queue
- [ ] Auto-expire لـ `_processedMessages`

---

## 7. ملاحظات معمارية إيجابية

وسط كل الملاحظات النقدية، هناك نقاط قوة مهمة:

- ✅ **اختيار libsodium** — مكتبة مُثبتة وآمنة. الخوارزميات صحيحة
- ✅ **PIN hashing بـ Argon2id** — أفضل خوارزمية متاحة لـ password hashing
- ✅ **Lockout بعد محاولات فاشلة** — مع exponential backoff
- ✅ **Loop Detection + TTL** — حماية فعالة ضد broadcast storms
- ✅ **Store-Carry-Forward** — منطق DTN سليم مع relay queue مستمر
- ✅ **Token Bucket** — يمنع flooding في epidemic routing
- ✅ **بنية Riverpod نظيفة** — dependency injection محترمة اصطلاحات Flutter

---

> **الخلاصة:** المشروع يحتوي أساس هندسي سليم لكنه يحتاج أعمال أمنية جوهرية قبل الاعتماد عليه في بيئة عالية المخاطر. أولوية العمل: **تشفير قاعدة البيانات → إيقاف التسريبات → إصلاح إدارة المفاتيح**.
