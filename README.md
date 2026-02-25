<p align="center">
  <img src="assets/images/logo.png" alt="Sada Logo" width="180"/>
</p>

<h1 align="center">صدى — Sada</h1>

<p align="center">
  <strong>🌐 بنية تحتية رقمية للتواصل المجتمعي — تعمل بدون إنترنت</strong><br/>
  <strong>🌐 Offline-First Community Communication Infrastructure</strong>
</p>

<p align="center">
  <em>عندما ينقطع النت، يبقى الصدى</em><br/>
  <em>When the internet goes silent, Sada echoes on</em>
</p>

<br/>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Kotlin-1.9+-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white" alt="Kotlin"/>
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/libsodium-E2E_Encryption-6236FF?style=for-the-badge&logo=letsencrypt&logoColor=white" alt="Encryption"/>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/LoRa-868MHz_(Planned)-FF6600?style=for-the-badge&logo=hackster&logoColor=white" alt="LoRa"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/Status-Alpha-orange?style=for-the-badge" alt="Status"/>
</p>

---

> [!WARNING]
> **⚠️ Alpha Software — قيد التطوير النشط**
>
> صدى في مرحلة التطوير النشط. لم يُجرَ أول اختبار ميداني بعد.
> لا تعتمد على التطبيق كوسيلة اتصال وحيدة.
>
> **Alpha Software — Active Development.** First field test not yet completed.
> Do not rely on this app as your sole communication channel.

---

<br/>

<h2 align="center">📖 ما هي صدى؟ — What is Sada?</h2>

<table>
<tr>
<td width="50%" valign="top">

### 🇸🇾 بالعربية

**صدى** منصة تواصل مجتمعية لا مركزية تعمل **بدون إنترنت ولا خوادم**.

عندما تنقطع الخدمات — كهرباء، إنترنت، أبراج اتصال — تبقى صدى تعمل عبر **شبكة Mesh محلية** تربط الأجهزة ببعضها مباشرة.

**المشكلة:**
- ⚡ كهرباء تنقطع لساعات يومياً
- 📡 إنترنت غير مستقر أو غير متوفر
- 📱 أبراج اتصال متضررة أو محدودة التغطية
- 🏥 تنسيق الكوارث (زلازل، فيضانات) يحتاج بديل فوري

**الحل:**
شبكة تواصل محلية تعمل بين الجيران والأحياء بدون أي بنية تحتية خارجية — هاتفك هو البنية التحتية.

</td>
<td width="50%" valign="top">

### 🇬🇧 In English

**Sada** (صدى — "Echo") is a decentralized, offline-first mesh communication platform. **No servers. No internet required.**

When infrastructure fails — power outages, internet disruptions, damaged cell towers — Sada keeps communities connected through **local mesh networking** between nearby devices.

**The Problem:**
- ⚡ Power outages lasting hours daily
- 📡 Unstable or unavailable internet
- 📱 Damaged or limited cell tower coverage
- 🏥 Disaster coordination needs an immediate alternative

**The Solution:**
A local communication network between neighbors and neighborhoods — your phone **is** the infrastructure.

</td>
</tr>
</table>

---

<br/>

<h2 align="center">✨ الميزات — Features</h2>

### 📡 شبكة Mesh متعددة الطبقات — Multi-Layer Mesh Network

<table>
<tr>
<td width="50%" valign="top">

**WiFi Direct (P2P)** — المدى القريب
- اتصال مباشر بين الأجهزة (حتى 200م)
- اكتشاف تلقائي عبر UDP Broadcast
- اتصال TCP مع length-prefixed framing
- لا يحتاج router أو access point

</td>
<td width="50%" valign="top">

**LoRa 868MHz** *(قيد التطوير)* — المدى البعيد
- مدى حتى **5 كم** في البيئة الحضرية
- Heltec WiFi LoRa 32 (ESP32 + SX1276)
- استهلاك طاقة منخفض جداً
- يعمل بالطاقة الشمسية

</td>
</tr>
</table>

**Store-Carry-Forward (تخزين-حمل-إعادة توجيه):**
```
📱 Phone A ──msg──▶ 📱 Phone B (ليس الوجهة)
                    📱 Phone B يخزن الرسالة ويتحرك...
                    📱 Phone B ──msg──▶ 📱 Phone C ✅ (الوجهة!)
```
> الرسالة تنتقل من جهاز لجهاز حتى تصل — حتى لو لم يكن الجهاز المُرسل والمُستقبل متصلين مباشرة.

---

### 🔒 خصوصية احترافية — Professional-Grade Privacy

<table>
<tr>
<td>🔐</td>
<td><strong>تشفير End-to-End</strong></td>
<td>X25519 Key Exchange + XSalsa20-Poly1305 عبر <strong>libsodium</strong></td>
</tr>
<tr>
<td>🚫</td>
<td><strong>بدون خوادم</strong></td>
<td>لا يوجد سيرفر مركزي — كل البيانات محلية على جهازك فقط</td>
</tr>
<tr>
<td>🔑</td>
<td><strong>تبادل مفاتيح آمن</strong></td>
<td>مسح QR Code وجهاً لوجه — لا إرسال مفاتيح عبر الإنترنت</td>
</tr>
<tr>
<td>🔓</td>
<td><strong>مفتوح المصدر</strong></td>
<td>كود مفتوح بالكامل — يمكن لأي شخص مراجعة الأمان</td>
</tr>
<tr>
<td>🛡️</td>
<td><strong>تخزين آمن</strong></td>
<td>المفاتيح الخاصة في Android Keystore (Hardware-backed)</td>
</tr>
<tr>
<td>🔢</td>
<td><strong>App Lock</strong></td>
<td>PIN مكون من 6 أرقام مع Argon2id hashing + قفل تصاعدي</td>
</tr>
</table>

---

### 🎤 رسائل نصية وصوتية — Text & Voice Messages

<table>
<tr>
<td width="50%" valign="top">

**💬 رسائل نصية**
- مشفرة End-to-End
- تُخزَّن محلياً فقط
- تعمل offline بالكامل
- إشعارات فورية عند الاستلام

</td>
<td width="50%" valign="top">

**🎙️ رسائل صوتية**
- تسجيل بالضغط المطوّل (Hold-to-Record)
- ترميز Opus عالي الجودة
- نقل عبر Mesh بأجزاء 64KB (Blob Chunking)
- تشغيل مباشر مع شريط تقدم

</td>
</tr>
</table>

---

### 🔋 مُحسَّن للبطارية — Battery Optimized

> في بيئة الكهرباء المقطوعة، عمر البطارية = عمر الاتصال

| الوضع | معدل الاكتشاف | الاستخدام |
|---|---|---|
| ⚡ **أداء عالي** | كل 5 ثوان | أثناء الشحن أو الطوارئ |
| ⚖️ **متوازن** | كل 30-60 ثانية | الاستخدام اليومي العادي |
| 🔋 **توفير طاقة** | كل 5-10 دقائق | بطارية أقل من 15% |

- **Duty Cycling ذكي**: يُكيّف تلقائياً حسب مستوى البطارية
- **خدمة خلفية خفيفة**: تبقي الشبكة حية بأقل استهلاك

---

### 🎨 واجهة حديثة — Modern UI/UX

<table>
<tr>
<td width="50%" valign="top">

**التصميم**
- 🌙 وضع داكن (Neo-Glass / Glassmorphism)
- 🎨 خلفية Mesh Gradient متحركة
- ✨ Micro-animations سلسة
- 📐 تصميم متجاوب لكل الشاشات

</td>
<td width="50%" valign="top">

**اللغات**
- 🇸🇾 عربي كامل (RTL)
- 🇬🇧 إنجليزي كامل (LTR)
- 🔤 خطوط Google Fonts حديثة
- ↔️ تبديل لغة فوري

</td>
</tr>
</table>

---

### 👥 المزيد — Additional Features

| الميزة | الوصف |
|---|---|
| 📇 **إضافة أصدقاء** | مسح QR Code أو مشاركة رابط |
| 🔄 **إضافة ثنائية تلقائية** | عندما تضيف صديقاً، يُضاف عندك تلقائياً عنده |
| 📊 **لوحة تشخيص Mesh** | عرض حالة الشبكة، الأجهزة المتصلة، وإحصائيات النقل |
| 🔔 **إشعارات** | إشعار فوري عند وصول رسالة أو إضافة صديق |
| 🌟 **جولة تعريفية** | Feature Discovery Tour للمستخدمين الجدد |

---

<br/>

<h2 align="center">🏗️ البنية التقنية — Architecture</h2>

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│       Flutter · Riverpod · GoRouter · ScreenUtil             │
│       Material 3 · flutter_animate · Glassmorphism           │
├─────────────────────────────────────────────────────────────┤
│                    Application Layer                         │
│   ChatController · IncomingMessageHandler · AuthService      │
│   NotificationService · ProfileService · MetricsService      │
├─────────────────────────────────────────────────────────────┤
│                     Network Layer                            │
│   MeshService · HandshakeProtocol · EpidemicRouter           │
│   UdpBroadcastService · BlobTransferProtocol                 │
├─────────────────────────────────────────────────────────────┤
│                    Transport Layer                            │
│   WiFi Direct TCP/UDP  ·  LoRa 868MHz (Planned)             │
│   SocketManager.kt (Native Android / Kotlin)                │
├─────────────────────────────────────────────────────────────┤
│                     Storage Layer                             │
│   Drift (SQLite) · FlutterSecureStorage · MeshFileProvider   │
├─────────────────────────────────────────────────────────────┤
│                     Security Layer                            │
│   libsodium: X25519 + XSalsa20-Poly1305 + Blake2b           │
│   KeyManager · Argon2id PIN Hashing                          │
└─────────────────────────────────────────────────────────────┘
```

### مسار الرسالة — Message Flow

```
كتابة الرسالة
  │
  ▼
تشفير E2E (XSalsa20-Poly1305 + Nonce عشوائي)
  │
  ▼
تغليف في MeshMessage (messageId, TTL, trace, type)
  │
  ▼
إرسال عبر TCP Socket (SocketManager.kt)
  │
  ├──▶ الجهاز المُستقبل متصل مباشرة → تسليم فوري ✅
  │
  └──▶ غير متصل → Store-Carry-Forward
         │
         ▼
       تخزين في RelayQueue (SQLite)
         │
         ▼
       عند اتصال جهاز جديد → Handshake + Bloom Filter Exchange
         │
         ▼
       إرسال الرسائل المخزنة → وصول للوجهة ✅
```

---

<br/>

<h2 align="center">🛠️ التقنيات — Tech Stack</h2>

<table>
<tr><th>الطبقة</th><th>التقنية</th><th>الوصف</th></tr>
<tr><td><strong>Framework</strong></td><td>Flutter 3.10+ / Dart 3.10+</td><td>Cross-platform UI framework</td></tr>
<tr><td><strong>State</strong></td><td>Riverpod</td><td>Reactive state management with providers</td></tr>
<tr><td><strong>Navigation</strong></td><td>GoRouter</td><td>Declarative routing with ShellRoute</td></tr>
<tr><td><strong>Database</strong></td><td>Drift (SQLite)</td><td>Type-safe ORM with background isolates</td></tr>
<tr><td><strong>Encryption</strong></td><td>libsodium (sodium_libs)</td><td>X25519 ECDH + XSalsa20-Poly1305 + Blake2b</td></tr>
<tr><td><strong>PIN Hashing</strong></td><td>Argon2id</td><td>Memory-hard password hashing (via libsodium)</td></tr>
<tr><td><strong>Key Storage</strong></td><td>FlutterSecureStorage</td><td>Android Keystore / iOS Keychain</td></tr>
<tr><td><strong>Native</strong></td><td>Kotlin (Android)</td><td>SocketManager (TCP), UDP, WiFi Direct</td></tr>
<tr><td><strong>Audio</strong></td><td>record + audioplayers</td><td>Opus recording + playback</td></tr>
<tr><td><strong>QR</strong></td><td>qr_flutter + mobile_scanner</td><td>Key exchange via QR code</td></tr>
<tr><td><strong>UI</strong></td><td>Material 3 + flutter_animate</td><td>Neo-Glass design + micro-animations</td></tr>
<tr><td><strong>LoRa</strong> <em>(مخطط)</em></td><td>Heltec WiFi LoRa 32</td><td>ESP32 + SX1276, 868MHz, up to 5km range</td></tr>
</table>

---

<br/>

<h2 align="center">🚀 البدء السريع — Quick Start</h2>

### المتطلبات — Prerequisites

| الأداة | الإصدار |
|---|---|
| Flutter SDK | 3.10.4+ |
| Dart SDK | 3.10.4+ |
| Android Studio | Latest (SDK 23+) |
| Kotlin | 1.9+ |
| الأجهزة | جهازي Android على نفس شبكة WiFi للاختبار |

### التثبيت — Installation

```bash
# 1. نسخ المشروع
git clone https://github.com/obadadallo95/sada-messenger.git
cd sada-messenger

# 2. تثبيت المكتبات
flutter pub get

# 3. توليد ملفات الترجمة
flutter gen-l10n

# 4. توليد الكود (Drift, Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# 5. تشغيل التطبيق
flutter run
```

### بناء نسخة الإنتاج — Release Build

```bash
# APK مباشر
flutter build apk --release

# App Bundle (لـ Google Play)
flutter build appbundle --release
```

### الاختبار بين جهازين — Two-Device Testing

```bash
# الجهاز 1: تشغيل عادي
flutter run -d <device1_id>

# الجهاز 2: تشغيل على جهاز ثانٍ
flutter run -d <device2_id>

# تأكد أن الجهازين على نفس شبكة WiFi
# أضف صديقاً عبر مسح QR Code
# ابدأ المحادثة! 🎉
```

---

<br/>

<h2 align="center">📸 لقطات الشاشة — Screenshots</h2>

<p align="center"><em>قريباً — Coming Soon</em></p>

| الشاشة الرئيسية | المحادثة | إضافة صديق | الإعدادات |
|:---:|:---:|:---:|:---:|
| *Coming Soon* | *Coming Soon* | *Coming Soon* | *Coming Soon* |

---

<br/>

<h2 align="center">🗺️ خارطة الطريق — Roadmap</h2>

### ✅ مكتمل — Completed

- [x] بنية UI/UX (Material 3, تصميم Neo-Glass)
- [x] نظام التنقل (GoRouter + ShellRoute)
- [x] الترجمة (عربي + إنجليزي، RTL كامل)
- [x] المصادقة Offline (Device-bound User ID)
- [x] قفل التطبيق (PIN 6 أرقام + Biometric)
- [x] تشفير E2E (libsodium: X25519 + XSalsa20-Poly1305)
- [x] إدارة المفاتيح (FlutterSecureStorage)
- [x] تبادل المفاتيح عبر QR Code
- [x] قاعدة بيانات محلية (Drift/SQLite)
- [x] WiFi Direct Discovery + TCP Transport
- [x] بروتوكول Handshake (JSON + Bloom Filter)
- [x] Epidemic Routing (Store-Carry-Forward)
- [x] رسائل صوتية (Record + Playback + Mesh Transfer)
- [x] إضافة أصدقاء ثنائية الاتجاه (CONTACT_EXCHANGE)
- [x] خدمة خلفية (Foreground Service)
- [x] إدارة طاقة ذكية (Duty Cycling)

### 🚧 قيد التطوير — In Progress

- [ ] استقرارية النظام (Memory leak fixes, Battery listener)
- [ ] تشفير قاعدة البيانات (SQLCipher)
- [ ] تحسين إدارة الأخطاء

### 📋 مخطط — Planned

- [ ] **LoRa Integration** (Heltec WiFi LoRa 32 — الأولوية القصوى)
- [ ] Gateway Mode (WiFi ↔ LoRa bridge)
- [ ] مشاركة الملفات (صور، مستندات)
- [ ] مشاركة الموقع
- [ ] خريطة الشبكة المرئية (Mesh Map)
- [ ] Unit Tests + Integration Tests
- [ ] النشر على F-Droid

> 📄 للخطة التفصيلية: [ROADMAP.md](ROADMAP.md)

---

<br/>

<h2 align="center">📚 التوثيق — Documentation</h2>

| المستند | الوصف — Description |
|---|---|
| 📐 [ARCHITECTURE.md](ARCHITECTURE.md) | بنية النظام — System Architecture |
| 🔒 [SECURITY.md](SECURITY.md) | نموذج التهديد والتشفير — Threat Model & Encryption |
| 🗺️ [ROADMAP.md](ROADMAP.md) | خارطة الطريق — Development Roadmap |
| 📊 [AUDIT_REPORT.md](AUDIT_REPORT.md) | تقرير المراجعة الأمنية — Security Audit Report |

---

<br/>

<h2 align="center">🤝 المساهمة — Contributing</h2>

<table>
<tr>
<td width="50%" valign="top">

### 🇸🇾 بالعربية
نرحب بأي مساهمة! سواء كانت:
- 🐛 الإبلاغ عن أخطاء
- 💡 اقتراح ميزات جديدة
- 🔧 إصلاح مشاكل
- 📝 تحسين التوثيق
- 🌍 ترجمة لغات إضافية

</td>
<td width="50%" valign="top">

### 🇬🇧 In English
We welcome all contributions:
- 🐛 Bug reports
- 💡 Feature suggestions
- 🔧 Bug fixes & improvements
- 📝 Documentation improvements
- 🌍 Additional translations

</td>
</tr>
</table>

```bash
# 1. Fork المشروع
# 2. إنشاء فرع
git checkout -b feature/your-feature

# 3. Commit التعديلات
git commit -m "Add your feature"

# 4. Push ورفع Pull Request
git push origin feature/your-feature
```

---

<br/>

<h2 align="center">👨‍💻 المطوّر — Developer</h2>

<div align="center">

<img src="assets/images/Obada.jpg" alt="Obada Dallo" width="120" style="border-radius:50%; border: 3px solid #0D9488;"/>

### Obada Dallo (عبادة دللو)

**Lead Developer & Founder**

*مهندس برمجيات سوري مقيم في ألمانيا — بناء بنية تحتية رقمية للمجتمعات*

<br/>

[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/obadadallo95)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/obada-dallo-777a47a9/)
[![Facebook](https://img.shields.io/badge/Facebook-1877F2?style=for-the-badge&logo=facebook&logoColor=white)](https://www.facebook.com/obada.dallo33)
[![Telegram](https://img.shields.io/badge/Telegram-0088CC?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/obada_dallo95)

</div>

---

<br/>

<h2 align="center">📄 الترخيص — License</h2>

<p align="center">
  هذا المشروع مرخص تحت <strong>رخصة MIT</strong> — مفتوح المصدر بالكامل.<br/>
  Licensed under the <strong>MIT License</strong> — fully open source.
</p>

<p align="center">
  <a href="LICENSE">📄 View License</a>
</p>

---

<br/>

<h2 align="center">📞 الدعم والتواصل — Support & Contact</h2>

<p align="center">
  <a href="https://github.com/obadadallo95/sada-messenger/issues">🐛 GitHub Issues</a> &nbsp;·&nbsp;
  <a href="https://github.com/obadadallo95/sada-messenger/discussions">💬 GitHub Discussions</a>
</p>

---

<br/>

<p align="center">
  <strong>صدى — عندما ينقطع النت، يبقى الصدى 🌐</strong><br/>
  <strong>Sada — When the internet goes silent, Sada echoes on</strong>
</p>

<p align="center">
  صُنع بـ ❤️ لسوريا والمجتمعات ذات البنية التحتية الضعيفة<br/>
  Made with ❤️ for Syria and infrastructure-poor communities
</p>

<p align="center">
  <em>© 2026 Obada Dallo — MIT License</em>
</p>
