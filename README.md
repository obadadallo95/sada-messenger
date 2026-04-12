<div align="center">

<!-- Large ASCII or Unicode logo using the word SADA / صدى -->
<h1>
  📡 SADA · صدى
</h1>
<h3>Offline-First Encrypted Mesh Messenger for Android</h3>
<h3>تطبيق مراسلة شبكي مشفر يعمل بدون إنترنت — أندرويد</h3>

<!-- Badges row 1: Build status, License, Platform -->
<p align="center">
  <a href="https://github.com/obadadallo95/sada-messenger/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/obadadallo95/sada-messenger/android-ci.yml?style=for-the-badge&label=Build"/>
  </a>
  <a href="https://www.gnu.org/licenses/gpl-3.0">
    <img src="https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge"/>
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Android-35-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
  </a>
</p>

</div>

---

## The Core Idea / الفكرة الجوهرية

In a world where internet infrastructure can fail, be censored, or surveilled — Sada creates its own network. Every device becomes a node, relaying encrypted messages through a decentralized mesh that requires no central servers and no internet connection. Built for journalists, activists, and field teams who need secure communication in the most challenging environments.

في عالم يمكن أن تفشل فيه البنية التحتية للإنترنت، أو تُحجب، أو تُراقب — يصنع صدى شبكته الخاصة. كل جهاز يصبح عقدة، يرحل الرسائل المشفرة عبر شبكة لامركزية لا تحتاج إلى خوادم مركزية ولا إلى اتصال بالإنترنت. مبني للصحفيين والنشطاء والفرق الميدانية الذين يحتاجون إلى تواصل آمن في أصعب الظروف.

---

## How It Works / كيف يعمل

```
Device A  ──[BLE/LAN]──►  Device B  ──[Store & Forward]──►  Device C
   🔐 Encrypt               📦 Relay                          🔓 Decrypt
   ECDH + AES-256-GCM       TTL: 24h                         ECDH + AES-256-GCM
```

**Store-Carry-Forward**: When Device B receives a message not destined for it, it stores the encrypted packet and carries it until it encounters Device C (the intended recipient), then forwards it. Messages have a 24-hour TTL (Time To Live) to prevent infinite relay loops.

**التخزين-والحمل-والإعادة**: عندما يستلم الجهاز ب رسالة لا تخصه، يخزن الحزمة المشفرة ويحملها حتى يلتقي بالجهاز ج (المستلم المقصود)، ثم يعيد إرسالها. للرسائل مدة صلاحية 24 ساعة لمنع دورات الترحيل اللانهائية.

---

## Features / المميزات

### 🔐 Security & Privacy / الأمن والخصوصية

| Feature | Details | التفاصيل |
|---|---|---|
| End-to-End Encryption | ECDH key exchange + AES-256-GCM | تبادل مفاتيح ECDH + تشفير AES-256-GCM |
| Forward Secrecy | New keys per session | مفاتيح جديدة لكل جلسة |
| Message Signing | Ed25519 verification | التحقق من التوقيع Ed25519 |
| Key Storage | Android Keystore (StrongBox/TEE) | مخزن مفاتيح Android (StrongBox/TEE) |

### 📡 Mesh Networking / الشبكة المشبكة

| Feature | Details | التفاصيل |
|---|---|---|
| Transport | BLE + LAN/UDP broadcast | Bluetooth + بث LAN/UDP |
| Routing | DHT-based MessageRouter | راوتر رسائل يعتمد على DHT |
| Relay | Store-and-Forward (TTL 24h) | التخزين والإعادة (24 ساعة) |
| Battery | Adaptive BLE scan intervals (5s–60s) | فواصل مسح BLE تكيفية |

### 💬 Chat & Groups / الدردشة والمجموعات

| Feature | Status | الميزة |
|---|---|---|
| Reply / Forward / Edit / Pin | ✅ | رد / إعادة / تعديل / تثبيت |
| Group Admin Roles (Owner/Admin/Member) | ✅ | أدوار المشرفين |
| Kick / Ban / Slow Mode | ✅ | طرد / حظر / تقييد |
| Polls | ✅ | استطلاعات |
| RTL Arabic support | ✅ | دعم العربية RTL |

---

## Tech Stack / التقنيات

<p align="center">
  <img src="https://img.shields.io/badge/Kotlin-JVM21-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white"/>
  <img src="https://img.shields.io/badge/Jetpack_Compose-Material3-4285F4?style=for-the-badge&logo=jetpackcompose&logoColor=white"/>
  <img src="https://img.shields.io/badge/Room_DB-v18-003B57?style=for-the-badge&logo=sqlite&logoColor=white"/>
  <img src="https://img.shields.io/badge/Hilt-DI-F6C915?style=for-the-badge&logo=google&logoColor=black"/>
  <img src="https://img.shields.io/badge/Clean_Architecture-3_Layers-00C853?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/ZXing-QR_Code-000000?style=for-the-badge"/>
</p>

---

## Quick Start / البدء السريع

```bash
# Clone the repository
# استنساخ المستودع
git clone https://github.com/obadadallo95/sada-messenger.git
cd sada-messenger

# Build debug APK
# بناء APK للتصحيح
./gradlew :app:assembleDebug

# Install on connected device
# التثبيت على الجهاز المتصل
./gradlew :app:installDebug

# Run unit tests
# تشغيل اختبارات الوحدات
./gradlew :app:testDebugUnitTest
```

> **Note / ملاحظة:** Requires JDK 21 and Android SDK 35 — يتطلب JDK 21 و Android SDK 35

---

## Documentation / التوثيق

| Document | Language | Description | الوصف |
|---|---|---|---|
| [Quick Start](docs/QUICK_START.md) | EN/AR | Get running in 5 minutes | ابدأ خلال 5 دقائق |
| [Architecture](docs/ARCHITECTURE.md) | EN | System layers and components | طبقات النظام والمكونات |
| [Security & Privacy](docs/SECURITY_AND_PRIVACY.md) | EN | Threat model and crypto | نموذج التهديد والتشفير |
| [Transport & Routing](docs/TRANSPORT_AND_ROUTING.md) | EN | Mesh protocol details | تفاصيل بروتوكول الشبكة المشبكة |
| [UI Screens & Flows](docs/UI_SCREENS_AND_FLOWS.md) | EN | Screen map | خريطة الشاشات |
| [Roadmap v2.0](docs/ROADMAP_v2.0.md) | EN/AR | Future features | الميزات المستقبلية |
| [IP Rights](docs/INTELLECTUAL_PROPERTY.md) | EN/AR | Licensing and ownership | الترخيص والملكية |

---

## Latest Updates / آخر التحديثات (Apr 2026)

### ✅ Completed 5-Stage Development Plan / اكتمال خطة التطوير الخمس مراحل

**Stage 1: Architecture** ✅
- Clean Architecture with Data/Domain/Presentation layers — بنية نظيفة
- Hilt Dependency Injection — حقن التبعيات
- Use Case pattern for business logic — نمط Use Case

**Stage 2: Security** ✅
- Android Keystore integration (StrongBox/TEE) — مخزن مفاتيح Android
- ECDH key exchange with Forward Secrecy — تبادل مفاتيح ECDH
- AES-256-GCM encryption with random IV — تشفير AES-256-GCM

**Stage 3: Mesh Networking** ✅
- Battery-aware BLE scanning (adaptive intervals) — مسح BLE مع مراعاة البطارية
- Message Router with DHT-based routing — راوتر رسائل DHT
- Store-and-forward with TTL management — تخزين وإعادة مع TTL

**Stage 4: UI/UX** ✅
- Glass-morphism Design System — تصميم Glass-morphism
- Full RTL (Arabic) support — دعم كامل للعربية
- Dark/Light theme with system detection — نمط داكن/فاتح

**Stage 5: Testing & Performance** ✅
- Unit tests with MockK — اختبارات وحدات
- Performance monitoring — مراقبة الأداء
- Memory leak detection — كشف تسرب الذاكرة

---

## Developer / المطور

<div align="center">
<br/>
<img src="app/src/main/res/drawable/developer_obada.jpg" width="100" style="border-radius:50%"/>
<br/>
<strong>Obada Dallo · عبادة دللو</strong>
<br/>
<em>Founder & Lead Developer — "Building digital shields for a safer internet."</em><br/>
<em>المؤسس والمطور الرائد — "نبني دروعاً رقمية لإنترنت أكثر أماناً"</em>
<br/><br/>
<a href="https://github.com/obadadallo95"><img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://www.linkedin.com/in/obada-dallo-777a47a9/"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white"/></a>
<a href="https://www.facebook.com/obada.dallo33"><img src="https://img.shields.io/badge/Facebook-1877F2?style=for-the-badge&logo=facebook&logoColor=white"/></a>
<a href="https://t.me/obada_dallo95"><img src="https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white"/></a>
<a href="mailto:obada.dallo95@gmail.com"><img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white"/></a>
</div>

---

## License / الرخصة

This project is licensed under the **GNU General Public License v3.0**.
See the [LICENSE](LICENSE) file for details.

هذا المشروع مرخص تحت **رخصة GPL v3** — راجع ملف [LICENSE](LICENSE) للتفاصيل.
