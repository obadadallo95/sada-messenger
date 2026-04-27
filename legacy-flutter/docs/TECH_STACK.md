# Technology Stack

This document details all major libraries, frameworks, and tools used in Sada, along with the rationale for each choice.

---

## 🎯 Core Framework

### Flutter 3.10+

**Why Flutter?**
- ✅ **Cross-platform**: Single codebase for Android and iOS (iOS support planned)
- ✅ **Performance**: Native performance with Dart compilation
- ✅ **Rich Ecosystem**: Extensive package ecosystem
- ✅ **Hot Reload**: Fast development iteration
- ✅ **Material Design**: Built-in Material 3 support

---

## 📦 State Management

### flutter_riverpod (^2.6.1)

**Purpose**: State management and dependency injection

**Why Riverpod?**
- ✅ **Type-Safe**: Compile-time safety with code generation
- ✅ **Testable**: Easy to mock and test
- ✅ **Performance**: Efficient rebuilds with fine-grained updates
- ✅ **DevTools**: Excellent debugging tools
- ✅ **Reactive**: Automatic state updates

**Usage:**
- Provider-based dependency injection
- StateNotifier for complex state
- FutureProvider/StreamProvider for async data

**Alternatives Considered:**
- ❌ Provider: Less type-safe
- ❌ Bloc: More boilerplate
- ❌ GetX: Less maintainable

---

## 🧭 Navigation

### go_router (^14.6.2)

**Purpose**: Declarative routing and navigation

**Why GoRouter?**
- ✅ **Type-Safe Routes**: Compile-time route checking
- ✅ **Deep Linking**: Built-in support for deep links
- ✅ **Redirect Logic**: Powerful redirect capabilities for auth
- ✅ **ShellRoute**: Perfect for persistent navigation bars
- ✅ **URL-Based**: Routes are URL-based (better for web)

**Usage:**
- ShellRoute for Bottom Navigation Bar
- GoRoute for individual screens
- Redirect logic for authentication

**Alternatives Considered:**
- ❌ Navigator 2.0: Too verbose
- ❌ AutoRoute: Less flexible

---

## 🎨 Theming

### flex_color_scheme (^7.3.0)

**Purpose**: Material Design 3 theming with color schemes

**Why FlexColorScheme?**
- ✅ **Material 3**: Full Material Design 3 support
- ✅ **Dark Mode**: Automatic dark mode generation
- ✅ **Color Schemes**: Pre-built beautiful color schemes
- ✅ **Customization**: Easy to customize primary/secondary colors
- ✅ **Accessibility**: Built-in contrast checking

**Configuration:**
- Primary: Teal (Deep Teal #0D9488)
- Theme Modes: Light, Dark, System

---

## 📱 Responsiveness

### flutter_screenutil (^5.9.3)

**Purpose**: Responsive UI across different screen sizes

**Why ScreenUtil?**
- ✅ **Consistent Sizing**: `.w`, `.h`, `.sp` extensions
- ✅ **No Hardcoded Pixels**: All dimensions responsive
- ✅ **Font Scaling**: Automatic font scaling
- ✅ **Easy Migration**: Simple to adopt

**Usage:**
```dart
Container(
  width: 100.w,  // Responsive width
  height: 50.h,  // Responsive height
  child: Text('Hello', style: TextStyle(fontSize: 16.sp)),
)
```

**Alternatives Considered:**
- ❌ MediaQuery: More verbose
- ❌ Responsive Framework: Overkill for mobile-first

---

## 🌐 Localization

### flutter_localizations + intl (^0.20.2)

**Purpose**: Multi-language support (Arabic & English)

**Why Flutter Localizations?**
- ✅ **Official**: Official Flutter localization solution
- ✅ **ARB Files**: Industry-standard ARB format
- ✅ **RTL Support**: Built-in RTL support
- ✅ **Pluralization**: Built-in plural rules
- ✅ **Code Generation**: Type-safe generated code

**Structure:**
```
l10n/
├── app_en.arb
└── app_ar.arb
```

---

## 💾 Storage

### shared_preferences (^2.3.3)

**Purpose**: Simple key-value storage for preferences

**Why SharedPreferences?**
- ✅ **Simple**: Easy-to-use API
- ✅ **Persistent**: Data survives app restarts
- ✅ **Lightweight**: No database overhead
- ✅ **Cross-platform**: Works on Android and iOS

**Usage:**
- Theme mode preference
- Language preference
- Power mode preference
- Onboarding completion flag

### flutter_secure_storage (^9.2.2)

**Purpose**: Encrypted storage for sensitive data

**Why FlutterSecureStorage?**
- ✅ **Encrypted**: Uses Android Keystore / iOS Keychain
- ✅ **Hardware-Backed**: Android hardware-backed encryption
- ✅ **Secure**: Industry-standard secure storage
- ✅ **Cross-platform**: Works on Android and iOS

**Usage:**
- Private keys
- PIN hashes
- User credentials
- Profile pictures (Master/Duress)

### drift (^2.18.0) + sqlite3_flutter_libs (^0.5.20)

**Purpose**: Local SQLite database for messages, contacts, and chats

**Why Drift?**
- ✅ **Type-Safe**: Compile-time type safety with code generation
- ✅ **Reactive**: Stream-based queries for real-time updates
- ✅ **SQLite**: Industry-standard SQLite database
- ✅ **Migrations**: Built-in migration support
- ✅ **Offline-First**: Perfect for offline mesh messaging

**Features:**
- **Duress Mode Support**: Separate database files (`sada_encrypted.sqlite` vs `sada_dummy.sqlite`)
- **Tables**: Contacts, Chats, Messages
- **Relationships**: Foreign keys and joins
- **Streams**: Reactive queries with `watchChats()`, `watchMessages()`

**Usage:**
```dart
// Get database instance
final database = await ref.read(appDatabaseProvider.future);

// Insert contact
await database.insertContact(ContactsTableCompanion.insert(...));

// Watch chats (reactive)
final chatsStream = database.watchChats();
```

**Alternatives Considered:**
- ❌ Hive: Less SQL-like, harder migrations
- ❌ sqflite: More boilerplate, less type-safe

---

## 🔐 Cryptography

### sodium_libs (^2.0.0)

**Purpose**: Cryptographic operations (E2E encryption)

**Why libsodium?**
- ✅ **Well-Audited**: Extensively audited cryptographic library
- ✅ **Modern**: Uses modern cryptographic algorithms
- ✅ **Safe**: Protection against timing attacks
- ✅ **Complete**: All crypto primitives in one library

**Algorithms Used:**
- X25519 (Key Exchange)
- XSalsa20-Poly1305 (Encryption)
- Blake2b (Hashing)
- Secure Random

**Alternatives Considered:**
- ❌ pointycastle: More complex API
- ❌ crypto: Limited algorithms

---

## 🔔 Notifications

### flutter_local_notifications (^17.2.3)

**Purpose**: Local notifications (no FCM needed)

**Why Local Notifications?**
- ✅ **Offline**: Works without internet
- ✅ **Privacy**: No third-party servers
- ✅ **Control**: Full control over notification behavior
- ✅ **Customizable**: Custom notification channels

**Features:**
- High-importance channel for messages
- Custom notification UI
- Navigation on tap

---

## 🔋 Background Services

### flutter_background_service (^5.0.5)

**Purpose**: Foreground service for mesh discovery

**Why flutter_background_service?**
- ✅ **Foreground Service**: Required for Android background work
- ✅ **Persistent**: Keeps service alive
- ✅ **Battery Efficient**: Can be optimized with duty cycling
- ✅ **Notification**: Shows persistent notification

**Usage:**
- Mesh discovery duty cycle
- Power mode management
- Background scanning

---

## 📸 Image Handling

### image_picker (^1.1.2)

**Purpose**: Select images from gallery

**Why image_picker?**
- ✅ **Official**: Well-maintained Flutter plugin
- ✅ **Cross-platform**: Works on Android and iOS
- ✅ **Permissions**: Handles permissions automatically

### flutter_image_compress (^2.3.0)

**Purpose**: Compress images for mesh transmission

**Why flutter_image_compress?**
- ✅ **Efficient**: Aggressive compression
- ✅ **Fast**: Quick compression times
- ✅ **Formats**: Supports WebP, JPEG, PNG
- ✅ **Quality Control**: Adjustable quality settings

**Usage:**
- Profile pictures: 150x150px, 50% quality, WebP
- Base64 encoding for storage/transmission

---

## 🎯 UI Components

### smooth_page_indicator (^1.1.0)

**Purpose**: Page indicators for onboarding

**Why smooth_page_indicator?**
- ✅ **Smooth Animations**: Beautiful transitions
- ✅ **Customizable**: Highly customizable
- ✅ **Lightweight**: Small package size

### animate_do (^3.3.4)

**Purpose**: Animations (radar effect, fade in)

**Why animate_do?**
- ✅ **Easy API**: Simple animation API
- ✅ **Pre-built**: Pre-built animation widgets
- ✅ **Performance**: Optimized animations

### flutter_animate (^4.5.0)

**Purpose**: Advanced animations (shake effect)

**Why flutter_animate?**
- ✅ **Declarative**: Declarative animation API
- ✅ **Powerful**: Advanced animation features
- ✅ **Performance**: Efficient animation system

### showcaseview (^3.0.0)

**Purpose**: Interactive feature discovery tours

**Why showcaseview?**
- ✅ **User-Friendly**: Guides users through features
- ✅ **Customizable**: Customizable tooltips
- ✅ **Lightweight**: Small package size

---

## 🔍 QR Code & Scanning

### qr_flutter (^4.1.0)

**Purpose**: Generate QR codes

**Why qr_flutter?**
- ✅ **Customizable**: Customizable QR code appearance
- ✅ **Performance**: Fast QR code generation
- ✅ **Reliable**: Well-maintained package

### mobile_scanner (^5.2.3)

**Purpose**: Scan QR codes

**Why mobile_scanner?**
- ✅ **Modern**: Modern camera API
- ✅ **Performance**: Fast scanning
- ✅ **Features**: Flashlight, overlay support

---

## 🔐 Authentication

### local_auth (^2.3.0)

**Purpose**: Biometric authentication

**Why local_auth?**
- ✅ **Official**: Well-maintained Flutter plugin
- ✅ **Biometrics**: Fingerprint, Face ID support
- ✅ **Secure**: Uses platform security APIs

### device_info_plus (^11.1.0)

**Purpose**: Get device identifiers

**Why device_info_plus?**
- ✅ **Cross-platform**: Works on Android and iOS
- ✅ **Reliable**: Stable device ID access
- ✅ **Privacy**: Respects privacy restrictions

### crypto (^3.0.6)

**Purpose**: SHA-256 hashing

**Why crypto?**
- ✅ **Standard**: Dart standard library
- ✅ **Reliable**: Well-tested
- ✅ **Lightweight**: Small package size

### uuid (^4.5.1)

**Purpose**: Generate UUIDs

**Why uuid?**
- ✅ **Standard**: RFC 4122 compliant
- ✅ **Random**: Cryptographically secure random
- ✅ **Reliable**: Well-tested

---

## 🛠️ Development Tools

### build_runner (^2.4.13)

**Purpose**: Code generation

**Why build_runner?**
- ✅ **Code Generation**: Generates boilerplate code
- ✅ **Riverpod**: Required for Riverpod code generation
- ✅ **Freezed**: Required for Freezed code generation

### riverpod_generator (^2.6.4)

**Purpose**: Generate Riverpod providers

**Why riverpod_generator?**
- ✅ **Type-Safe**: Compile-time type safety
- ✅ **Less Boilerplate**: Reduces code duplication
- ✅ **Performance**: Optimized generated code

### custom_lint + riverpod_lint (^2.6.4)

**Purpose**: Linting rules

**Why Custom Lint?**
- ✅ **Riverpod Rules**: Riverpod-specific linting
- ✅ **Best Practices**: Enforces best practices
- ✅ **IDE Integration**: Works with IDE

---

## 📊 Logging

### logger (^2.4.0)

**Purpose**: Structured logging

**Why logger?**
- ✅ **Formatted**: Beautiful formatted logs
- ✅ **Levels**: Log levels (debug, info, warning, error)
- ✅ **Customizable**: Customizable log output

**Usage:**
- Centralized LogService wrapper
- Consistent log format across app

---

## 🎨 Icons & Assets

### flutter_launcher_icons (^0.13.1)

**Purpose**: Generate app launcher icons

**Why flutter_launcher_icons?**
- ✅ **Automated**: Automates icon generation
- ✅ **Multi-platform**: Android and iOS support
- ✅ **Adaptive**: Adaptive icon support

---

## 📋 Package Summary

| Category | Package | Version | Purpose |
|----------|---------|---------|---------|
| **State** | flutter_riverpod | ^2.6.1 | State management |
| **Navigation** | go_router | ^14.6.2 | Routing |
| **Theme** | flex_color_scheme | ^7.3.0 | Theming |
| **Responsive** | flutter_screenutil | ^5.9.3 | Responsive UI |
| **Crypto** | sodium_libs | ^2.0.0 | Encryption |
| **Storage** | shared_preferences | ^2.3.3 | Preferences |
| **Storage** | flutter_secure_storage | ^10.0.0 | Secure storage |
| **Database** | drift | ^2.18.0 | SQLite database (local storage) |
| **Database** | sqlite3_flutter_libs | ^0.5.20 | SQLite native libraries |
| **Notifications** | flutter_local_notifications | ^20.0.0 | Local notifications |
| **Background** | flutter_background_service | ^5.0.5 | Background service |
| **Images** | image_picker | ^1.1.2 | Image selection |
| **Images** | flutter_image_compress | ^2.3.0 | Image compression |
| **QR** | qr_flutter | ^4.1.0 | QR generation |
| **QR** | mobile_scanner | ^7.1.4 | QR scanning |
| **Auth** | local_auth | ^3.0.0 | Biometrics |
| **UI** | showcaseview | ^5.0.1 | Feature tours |
| **UI** | flutter_animate | ^4.5.0 | Animations |
| **UI** | flutter_markdown | ^0.6.18 | Markdown rendering |
| **App Info** | package_info_plus | ^9.0.0 | App version info |
| **Links** | url_launcher | ^6.3.1 | External links |

---

## 🔄 Future Considerations

### Planned Additions

- **Testing**: mockito, flutter_test for comprehensive testing
- **Analytics**: Privacy-respecting analytics (if needed)
- **Crash Reporting**: Sentry or similar (if needed)

---

## 📚 References

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [libsodium Documentation](https://doc.libsodium.org/)

