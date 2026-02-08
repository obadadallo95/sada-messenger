<p align="center">
  <img src="assets/images/logo.png" alt="Sada Logo" width="200"/>
</p>

<h1 align="center">Sada (صدى)</h1>
<p align="center">
  <strong>Secure Offline Mesh Messenger for Syria</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Kotlin-1.9+-7F52FF?logo=kotlin&logoColor=white" alt="Kotlin"/>
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"/>
  <img src="https://img.shields.io/badge/Status-Alpha-orange" alt="Status"/>
</p>

> **⚠️ STATUS: ALPHA / WIP**
> 
> This project is currently in active development. Mesh routing algorithms are being optimized.
> 
> **Do not rely on this app for life-critical communications yet.**

---

## 📖 About

**Sada** (صدى) is a **decentralized, offline mesh messenger** that enables secure peer-to-peer communication without requiring central servers or internet infrastructure. Built with humanitarian principles, Sada is designed for communities in Syria and other regions with unreliable internet connectivity.

### 🌍 Mission

In areas where internet access is restricted, unreliable, or censored, Sada provides a resilient communication network that operates entirely offline using **WiFi Direct (P2P)** and **Bluetooth Low Energy (BLE)**. Messages are encrypted end-to-end using **libsodium** (NaCl), ensuring privacy even in hostile environments.

### ⚠️ Alpha Disclaimer

**This is Alpha software (v1.0). Use at your own risk.** Do not rely on this app for life-critical communications yet. Mesh routing algorithms are still being optimized.

---

## ✨ Key Features

### 📡 **Offline Mesh Networking**
- **WiFi Direct (P2P)**: Discover and connect to nearby devices without internet
- **Bluetooth LE**: Fallback mesh networking for extended range
- **Smart Discovery**: Battery-optimized duty cycling for efficient peer discovery

### 🔒 **High-Assurance End-to-End Encryption**
- **End-to-End Encryption**: **X25519** key exchange + **XSalsa20-Poly1305** authenticated encryption (via libsodium)
- **Forward Secrecy**: Session keys derived using ECDH and Blake2b hashing
- **Secure Storage**: Private keys stored in **FlutterSecureStorage** (Android Keystore)
- **QR Key Exchange**: Share your identity and public key via QR code scanning

### 🛡️ **Duress Mode (Plausible Deniability)**
- **Dual PIN System**: Master PIN (real database) and Duress PIN (dummy database)
- **Plausible Deniability**: Identical UI in both modes - no visible indicators
- **Physical Safety**: Designed for scenarios where device inspection is forced
- **Database Separation**: Real data (`sada_encrypted.sqlite`) vs Dummy data (`sada_dummy.sqlite`)

### 💾 **Local Database (Drift)**
- **SQLite Database**: Powered by **Drift** (formerly Moor) for local message storage
- **Offline-First**: All data stored locally on device - no cloud sync
- **Duress Mode Support**: Separate database files for Master/Duress modes

### 🔋 **Battery Optimized**
- **Smart Duty Cycling**: Configurable power modes (High Performance / Balanced / Low Power)
- **Background Service**: Efficient foreground service with minimal battery drain
- **Adaptive Scanning**: Adjusts discovery frequency based on user preference

### 🎨 **Modern UI/UX (Cyber-Stealth Aesthetic)**
- **Neo-Glass Design**: Dark-mode first with glassmorphism effects
- **Mesh Gradient Background**: Subtle animated background with moving color blobs
- **RTL Support**: Full Arabic and English localization
- **Responsive Design**: ScreenUtil-based responsive layouts
- **Smooth Animations**: flutter_animate for cinematic transitions

### 👥 **Group Messaging**
- **Mesh Groups**: Create and discover public/private groups
- **Group Discovery**: Radar-style UI for finding nearby communities
- **Member Management**: Track group members and activity

---

## 📸 Screenshots

| Home Screen | Chat Screen | Groups Discovery | Settings |
|-------------|-------------|------------------|----------|
| *Coming Soon* | *Coming Soon* | *Coming Soon* | *Coming Soon* |

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod (with code generation)
- **Navigation**: GoRouter
- **Database**: Drift (SQLite) - Local message/contact storage
- **Cryptography**: libsodium (NaCl) - X25519 + XSalsa20-Poly1305
- **UI**: Material 3, flutter_animate, ScreenUtil
- **Native**: Kotlin (Android) - WiFi Direct P2P implementation

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.10.4 or higher
- **Dart SDK**: 3.10.4 or higher
- **Android Studio**: Latest version with Android SDK 23+ (for adaptive icons)
- **Kotlin**: 1.9+ (for native Android code)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/sada.git
   cd sada
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate localization files:**
   ```bash
   flutter gen-l10n
   ```

4. **Generate code (if using code generation):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

---

## 🗺️ Roadmap

### ✅ Completed

- [x] **Foundation Layer**
  - [x] UI/UX Architecture (Material 3, Dark/Light themes)
  - [x] Navigation System (GoRouter with ShellRoute)
  - [x] Localization (Arabic & English with RTL support)
  - [x] Responsive Design (ScreenUtil)
  - [x] Logging System

- [x] **Authentication & Security**
  - [x] Offline Authentication (Device-bound User ID)
  - [x] Biometric App Lock (Fingerprint/Face ID)
  - [x] Duress Mode (Dual PIN system)
  - [x] E2E Encryption (libsodium: X25519 + XSalsa20-Poly1305)
  - [x] Secure Key Management (FlutterSecureStorage)

- [x] **Core Features**
  - [x] Onboarding Flow
  - [x] Profile Picture Management
  - [x] QR Code Generation & Scanning
  - [x] Local Notifications
  - [x] Power Management (Duty Cycling)
  - [x] Interactive Feature Discovery Tour

- [x] **Groups**
  - [x] Group Creation UI
  - [x] Group Discovery Screen
  - [x] Local Group Storage

- [x] **Native Android Bridge**
  - [x] WiFi Direct (P2P) Discovery
  - [x] MethodChannel & EventChannel Setup
  - [x] Mesh Debug Screen

### 🚧 In Progress

- [ ] **Native Mesh Implementation**
  - [ ] Complete WiFi P2P Connection Management
  - [ ] Bluetooth LE Mesh Support
  - [ ] Message Routing Protocol
  - [ ] Network Topology Management

- [x] **Database Layer**
  - [x] Drift (SQLite) Integration
  - [x] Message Persistence
  - [x] Contact Storage
  - [x] Duress Mode Database Separation

### 📋 Planned

- [ ] **Message Protocol**
  - [ ] Mesh Message Format
  - [ ] Multi-hop Routing
  - [ ] Message Delivery Confirmation
  - [ ] Offline Message Queue

- [ ] **Advanced Features**
  - [ ] File Sharing (Images, Documents)
  - [ ] Voice Messages
  - [ ] Location Sharing
  - [ ] Mesh Network Map Visualization

- [ ] **Testing & Quality**
  - [ ] Unit Tests
  - [ ] Integration Tests
  - [ ] E2E Tests
  - [ ] Security Audits

---

## 📚 Documentation

For detailed technical documentation, see the [`docs/`](docs/) folder:

### English
- **[Architecture](docs/ARCHITECTURE.md)**: System architecture and design patterns
- **[Security](docs/SECURITY.md)**: Encryption, Duress Mode, and security practices
- **[Tech Stack](docs/TECH_STACK.md)**: Libraries and technologies used
- **[Contributing](docs/CONTRIBUTING.md)**: Guidelines for contributors

### العربية
- **[الهندسة المعمارية](docs/ARCHITECTURE_AR.md)**: بنية النظام وأنماط التصميم
- **[الأمان](docs/SECURITY_AR.md)**: التشفير، وضع الإكراه، وممارسات الأمان
- **[المكدس التقني](docs/TECH_STACK_AR.md)**: المكتبات والتقنيات المستخدمة
- **[المساهمة](docs/CONTRIBUTING_AR.md)**: إرشادات للمساهمين

---

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](docs/CONTRIBUTING.md) before submitting pull requests.

### Quick Start for Contributors

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with ❤️ for the people of Syria
- Inspired by the need for resilient, offline communication networks
- Special thanks to the open-source community for the amazing tools and libraries

---

## 👨‍💻 Author

<div align="center">

<img src="assets/images/Obada.jpg" alt="Obada Dallo" width="100" style="border-radius:50%; border: 3px solid #0D9488;"/>

### Obada Dallo (عبادة دللو)

**Lead Developer & Founder**

[![GitHub](https://img.shields.io/badge/GitHub-181717?logo=github&logoColor=white)](https://github.com/obadadallo95)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/obada-dallo-777a47a9/)
[![Facebook](https://img.shields.io/badge/Facebook-1877F2?logo=facebook&logoColor=white)](https://www.facebook.com/obada.dallo33)
[![Telegram](https://img.shields.io/badge/Telegram-0088CC?logo=telegram&logoColor=white)](https://t.me/obada_dallo95)

</div>

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/sada/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/sada/discussions)

---

<p align="center">
  Made with ❤️ for Syria
</p>
