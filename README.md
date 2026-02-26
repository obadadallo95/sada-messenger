# Sada Android Native / صدى (نسخة أندرويد الأصلية)

Sada is an offline-first DTN mesh messenger for Android (Kotlin + Jetpack Compose).  
صدى هو تطبيق مراسلة شبكي لا مركزي يعمل بدون إنترنت على أندرويد.

This repository is the **native Android rewrite** of Sada, designed for stronger platform control over networking, battery, permissions, and background execution.  
هذا المستودع هو إعادة بناء أصلية بـ Kotlin بهدف تحكم أفضل بالشبكة والبطارية والصلاحيات والخلفية.

## What Sada does / ماذا يفعل صدى
- Works without internet using LAN/mesh discovery and peer-to-peer transport.
- Uses Store-Carry-Forward relay behavior for delayed delivery.
- Applies end-to-end encryption with libsodium.
- Keeps mesh core alive via foreground service.
- Supports Arabic/English with RTL/LTR handling.

## Documentation Index / فهرس التوثيق
- System architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Transport, routing, and handshake: [docs/TRANSPORT_AND_ROUTING.md](docs/TRANSPORT_AND_ROUTING.md)
- Security & privacy model: [docs/SECURITY_AND_PRIVACY.md](docs/SECURITY_AND_PRIVACY.md)
- UI screens and feature map: [docs/UI_SCREENS_AND_FLOWS.md](docs/UI_SCREENS_AND_FLOWS.md)
- Code style + i18n rules: [docs/CODE_STYLE_AND_I18N.md](docs/CODE_STYLE_AND_I18N.md)
- Delivery checklist for GitHub/release: [docs/DELIVERY_CHECKLIST.md](docs/DELIVERY_CHECKLIST.md)

## Tech Stack / التقنيات
- Kotlin (JVM 21), Android SDK 35
- Jetpack Compose (Material 3)
- Room Database
- Coroutines + Flow
- libsodium (LazySodium Android)
- ZXing (QR)

## Build / البناء
```bash
./gradlew :app:assembleDebug
./gradlew :app:installDebug
```

## Current Scope / النطاق الحالي
This codebase focuses on Android-native mesh stability and feature parity with `legacy-flutter/` while preserving Sada's identity (offline, secure, decentralized communication).
