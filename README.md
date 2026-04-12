# Sada Android Native / صدى (نسخة أندرويد الأصلية)

<p align="center">
  <img src="app/src/main/res/drawable/developer_obada.jpg" width="180" style="border-radius: 50%;" alt="Obada Dallo"/>
</p>

<h3 align="center">Obada Dallo | عبادة دللو</h3>
<p align="center"><strong>Founder & Lead Developer</strong></p>
<p align="center"><em>"Building digital shields for a safer internet."</em></p>

<p align="center">
  <a href="https://github.com/obadadallo95"><img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white"/></a>
  <a href="https://www.linkedin.com/in/obada-dallo-777a47a9/"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white"/></a>
  <a href="https://www.facebook.com/obada.dallo33"><img src="https://img.shields.io/badge/Facebook-1877F2?style=for-the-badge&logo=facebook&logoColor=white"/></a>
  <a href="https://t.me/obada_dallo95"><img src="https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white"/></a>
  <a href="mailto:obada.dallo95@gmail.com"><img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white"/></a>
</p>

---

Sada is an offline-first DTN mesh messenger for Android (Kotlin + Jetpack Compose).  
صدى هو تطبيق مراسلة شبكي لا مركزي يعمل بدون إنترنت على أندرويد.

This repository is the **native Android rewrite** of Sada, designed for stronger platform control over networking, battery, permissions, and background execution.  
هذا المستودع هو إعادة بناء أصلية بـ Kotlin بهدف تحكم أفضل بالشبكة والبطارية والصلاحيات والخلفية.

## What Sada does / ماذا يفعل صدى
- Works without internet using LAN/mesh discovery and peer-to-peer transport.
- Uses Store-Carry-Forward relay behavior for delayed delivery.
- Applies **end-to-end encryption** with ECDH + AES-256-GCM.
- Keeps mesh core alive via foreground service.
- Supports **Arabic/English** with RTL/LTR handling.
- **Chat Features**: Reply, Forward, Edit, Pin messages
- **Group Management**: Admin roles, Kick/Ban, Restrictions, Polls
- **Battery Optimized**: Adaptive BLE scanning based on battery level
- **Security**: Android Keystore, Forward Secrecy, Message Signing

## Documentation Index / فهرس التوثيق

### للمطورين الجدد:
- **Quick Start** (5 دقائق): [docs/QUICK_START.md](docs/QUICK_START.md)
- **Project Summary v1.0**: [docs/PROJECT_SUMMARY_v1.0.md](docs/PROJECT_SUMMARY_v1.0.md)

### للفهم العميق:
- System architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Transport, routing, and handshake: [docs/TRANSPORT_AND_ROUTING.md](docs/TRANSPORT_AND_ROUTING.md)
- Security & privacy model: [docs/SECURITY_AND_PRIVACY.md](docs/SECURITY_AND_PRIVACY.md)
- UI screens and feature map: [docs/UI_SCREENS_AND_FLOWS.md](docs/UI_SCREENS_AND_FLOWS.md)

### للتطوير المستقبلي:
- **خارطة طريق الإصدار 2.0 الكاملة**: [docs/ROADMAP_v2.0.md](docs/ROADMAP_v2.0.md) 🚀
- **خطة تطوير الدردشة والمجموعات**: [docs/CHAT_AND_GROUPS_ROADMAP.md](docs/CHAT_AND_GROUPS_ROADMAP.md) 🔥 أولوية فورية
- Service Profile v2.0 Roadmap: [docs/ROADMAP_ServiceProfile_v2.0.md](docs/ROADMAP_ServiceProfile_v2.0.md) ⚠️ مخفي في v1.0
- Code style + i18n rules: [docs/CODE_STYLE_AND_I18N.md](docs/CODE_STYLE_AND_I18N.md)
- **حقوق الملكية الفكرية / IP Rights**: [docs/INTELLECTUAL_PROPERTY.md](docs/INTELLECTUAL_PROPERTY.md) ⚖️
- Delivery checklist: [docs/DELIVERY_CHECKLIST.md](docs/DELIVERY_CHECKLIST.md)
- Field launch decision: [docs/GO_NO_GO_FIELD_RELEASE.md](docs/GO_NO_GO_FIELD_RELEASE.md)

## Tech Stack / التقنيات
- **Kotlin** (JVM 21), Android SDK 35
- **Jetpack Compose** (Material 3) with Glass-morphism UI
- **Room Database** with 18 Migrations
- **Coroutines + Flow** for async operations
- **Hilt** for Dependency Injection
- **Clean Architecture** (Data/Domain/Presentation)
- **Android Keystore** for secure key storage
- **ZXing** (QR Code)

## Build / البناء
```bash
./gradlew :app:assembleDebug
./gradlew :app:installDebug
```

## Latest Updates / آخر التحديثات (Apr 2025)

### ✅ Completed 5-Stage Development Plan / اكتمال خطة التطوير الخمس مراحل

**Stage 1: Architecture** ✅
- Clean Architecture with Data/Domain/Presentation layers
- Hilt Dependency Injection
- Use Case pattern for business logic
- Centralized Navigation with AppNavigator

**Stage 2: Security** ✅
- Android Keystore integration (StrongBox/TEE)
- ECDH key exchange with Forward Secrecy
- AES-256-GCM encryption with random IV
- Message signing and verification
- Security Audit Report available

**Stage 3: Mesh Networking** ✅
- Battery-aware BLE scanning (adaptive intervals)
- Message Router with DHT-based routing
- Store-and-forward with TTL management
- Connection resilience and retry logic

**Stage 4: UI/UX** ✅
- Glass-morphism Design System
- Message animations and transitions
- Full RTL (Arabic) support
- Dark/Light theme with system detection
- TalkBack accessibility (WCAG compliant)

**Stage 5: Testing & Performance** ✅
- Unit tests with MockK
- Performance monitoring
- Memory leak detection
- Battery drain tracking

### New Chat & Group Features / ميزات الدردشة والمجموعات الجديدة:
- **Reply to Message** - الرد على الرسائل
- **Forward Message** - إعادة إرسال الرسائل
- **Edit Message** - تعديل الرسائل
- **Pin Message** - تثبيت الرسائل
- **Admin Roles** - أدوار المشرفين (Owner, Admin, Member)
- **Kick/Ban Members** - طرد/حظر الأعضاء
- **Slow Mode** - تقييد المراسلة
- **Restrict New Members** - تقييد الأعضاء الجدد
- **Polls** - الاستطلاعات

## Current Scope / النطاق الحالي
This codebase focuses on Android-native mesh stability and feature parity with `legacy-flutter/` while preserving Sada's identity (offline, secure, decentralized communication).

**Status**: Production-ready with enhanced security and chat features
