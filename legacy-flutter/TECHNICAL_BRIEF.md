# 📋 التقرير التقني الشامل - تطبيق Sada (صدى)

**تاريخ التقرير:** 2025-01-XX  
**الإصدار:** 1.0.0 (Alpha)  
**المطور:** Obada Dallo (عبادة دللو)

---

## 🎯 1. نظرة عامة (Overview)

### فكرة التطبيق
**Sada (صدى)** هو تطبيق مراسلة لامركزي يعمل بدون إنترنت باستخدام تقنيات **Mesh Networking** عبر **WiFi Direct** و **Bluetooth LE**. التطبيق مصمم خصيصاً للمجتمعات في المناطق التي تعاني من انقطاع الإنترنت أو الرقابة، مع التركيز على سوريا كحالة استخدام رئيسية.

### المشكلة التي يحلها
- **انقطاع الإنترنت:** يوفر اتصالاً بديلاً عند انقطاع البنية التحتية للإنترنت
- **الرقابة والمراقبة:** شبكة لامركزية بدون خوادم مركزية يمكن مراقبتها
- **الأمان في البيئات المعادية:** تشفير من طرف إلى طرف مع وضع الإكراه (Duress Mode) للحماية من التفتيش القسري
- **التواصل في حالات الطوارئ:** يعمل في المناطق النائية أو أثناء الكوارث الطبيعية

### الفئة المستهدفة (Target Audience)
- **المجتمعات في المناطق النائية:** سوريا والمناطق التي تعاني من انقطاع الإنترنت
- **النشطاء والصحفيين:** يحتاجون اتصالاً آمناً في البيئات المعادية
- **المنظمات الإنسانية:** التواصل أثناء الكوارث أو في المناطق المحرومة
- **المستخدمون المهتمون بالخصوصية:** يفضلون حلول لامركزية بدون خوادم

### القيمة المضافة (Value Proposition)
- ✅ **100% بدون إنترنت:** يعمل بالكامل عبر WiFi Direct و Bluetooth
- ✅ **تشفير قوي:** X25519 + XSalsa20-Poly1305 (libsodium)
- ✅ **وضع الإكراه:** حماية من التفتيش القسري (Plausible Deniability)
- ✅ **Store-Carry-Forward:** الرسائل تنتقل عبر الأجهزة المتوسطة
- ✅ **مفتوح المصدر:** شفافية كاملة في الكود

---

## 🏗️ 2. الهيكل التقني (Technical Stack)

### لغات البرمجة والأطر المستخدمة

#### Frontend Framework
- **Flutter:** 3.10.4+
- **Dart:** 3.10.4+
- **Material 3:** نظام التصميم الحديث

#### State Management
- **Riverpod:** 2.6.1 (مع Code Generation)
  - `riverpod_annotation`: 2.6.1
  - `riverpod_generator`: 2.6.4
- **Pattern:** Provider-based reactive state management

#### Navigation
- **GoRouter:** 17.1.0
  - Declarative routing
  - ShellRoute للـ BottomNavBar
  - Deep linking support

### قاعدة البيانات والـ Backend

#### Database
- **Drift:** 2.18.0 (SQLite ORM)
  - Type-safe database queries
  - Code generation
  - Migration support
- **SQLite:** Local database
  - `sqlite3_flutter_libs`: 0.5.20
- **Database Files:**
  - `sada_encrypted.sqlite` (Master Mode)
  - `sada_dummy.sqlite` (Duress Mode)

#### Backend Architecture
- **Offline-First:** لا يوجد backend server
- **P2P Networking:** WiFi Direct + Bluetooth LE
- **Native Android Bridge:** Kotlin للـ WiFi Direct

### المكتبات الخارجية المهمة (Dependencies)

#### Security & Cryptography
```yaml
flutter_secure_storage: ^10.0.0    # Android Keystore
crypto: ^3.0.6                      # Cryptographic utilities
sodium_libs: ^2.0.0                # libsodium (X25519, XSalsa20-Poly1305)
local_auth: ^3.0.0                 # Biometric authentication
uuid: ^4.5.1                       # UUID generation
```

#### Networking & Mesh
```yaml
mobile_scanner: ^7.1.4             # QR Code scanning
qr_flutter: ^4.1.0                 # QR Code generation
permission_handler: ^12.0.1        # Runtime permissions
```

#### UI/UX
```yaml
flex_color_scheme: ^8.4.0          # Theme management
google_fonts: ^6.2.1               # Typography (Poppins)
flutter_screenutil: ^5.9.3         # Responsive design
smooth_page_indicator: ^2.0.1      # Page indicators
animate_do: ^4.2.0                 # Animations
flutter_animate: ^4.5.0            # Advanced animations
showcaseview: ^5.0.1               # Feature discovery tour
```

#### Storage & Persistence
```yaml
shared_preferences: ^2.3.3         # App preferences
path_provider: ^2.1.4              # File system paths
```

#### Notifications & Background
```yaml
flutter_local_notifications: ^20.0.0  # Local notifications
timezone: ^0.10.1                     # Timezone handling
flutter_background_service: ^5.0.5    # Background service
flutter_background_service_android: ^6.0.0
android_alarm_manager_plus: ^5.0.0
```

#### Media & Files
```yaml
image_picker: ^1.1.2               # Image selection
flutter_image_compress: ^2.3.0     # Image compression
cached_network_image: ^3.4.1       # Image caching
lottie: ^3.3.2                     # Lottie animations
```

#### Localization
```yaml
intl: ^0.20.2                      # Internationalization
flutter_localizations: SDK         # Flutter localization
```

#### Utilities
```yaml
logger: ^2.4.0                     # Logging
package_info_plus: ^9.0.0          # App info
url_launcher: ^6.3.1               # URL launching
share_plus: ^12.0.1                # Sharing
device_info_plus: ^12.3.0          # Device information
flash: ^3.0.0                      # Flash messages
flutter_markdown: ^0.6.18          # Markdown rendering
```

### هيكل الملفات (Folder Structure)

```
lib/
├── app.dart                        # App entry point
├── main.dart                       # Main function
├── core/                           # Core functionality
│   ├── constants/                  # App constants
│   ├── database/                   # Database layer
│   │   ├── app_database.dart       # Main database class
│   │   ├── database_provider.dart  # Database provider
│   │   └── tables/                 # Database tables
│   │       ├── contacts_table.dart
│   │       ├── chats_table.dart
│   │       ├── messages_table.dart
│   │       └── relay_queue_table.dart
│   ├── localization/               # Localization
│   ├── models/                     # Core models
│   ├── network/                    # Mesh networking
│   │   ├── discovery_service.dart
│   │   ├── mesh_service.dart
│   │   ├── mesh_channel.dart
│   │   ├── mesh_connection_manager.dart
│   │   └── protocols/
│   ├── power/                      # Power management
│   ├── router/                     # Navigation
│   │   ├── app_router.dart
│   │   └── routes.dart
│   ├── security/                   # Security & encryption
│   │   ├── encryption_service.dart
│   │   ├── key_manager.dart
│   │   └── security_providers.dart
│   ├── services/                   # Core services
│   │   ├── auth_service.dart
│   │   ├── biometric_service.dart
│   │   ├── notification_service.dart
│   │   └── background_service.dart
│   ├── theme/                      # Theming
│   ├── utils/                      # Utilities
│   └── widgets/                    # Reusable widgets
├── features/                       # Feature modules
│   ├── auth/                       # Authentication
│   ├── chat/                       # Chat functionality
│   │   ├── application/            # Controllers
│   │   ├── data/                   # Repositories
│   │   ├── domain/                 # Models
│   │   └── presentation/            # UI
│   ├── contacts/                   # Contacts management
│   ├── groups/                     # Groups feature
│   ├── home/                       # Home screen
│   ├── mesh/                       # Mesh debug
│   ├── notifications/              # Notifications
│   ├── onboarding/                 # Onboarding
│   ├── profile/                    # Profile
│   ├── settings/                   # Settings
│   ├── splash/                     # Splash screen
│   └── ...
└── l10n/                           # Localization files
    ├── app_ar.arb                  # Arabic
    ├── app_en.arb                  # English
    └── generated/                  # Generated files
```

---

## 📱 3. الصفحات والشاشات (Pages & Screens)

### 3.1. صفحات المصادقة والتهيئة

#### Splash Screen (`/splash`)
- **Route:** `AppRoutes.splash`
- **الغرض:** شاشة البداية مع تحميل التطبيق
- **المكونات:**
  - Logo animation (Fade + Scale)
  - Gradient background
- **البيانات:**
  - يتحقق من `AuthStatus` (loggedIn/notLoggedIn)
  - يتحقق من `OnboardingStatus`
- **التوجيه:**
  - إذا لم يكن مسجل دخول → `/register`
  - إذا كان مسجل دخول → `/lock` أو `/home`
  - إذا لم يكمل Onboarding → `/onboarding`
- **حالات الحافة:**
  - ⚠️ لا يوجد timeout handling للتهيئة الطويلة

#### Onboarding Screen (`/onboarding`)
- **Route:** `AppRoutes.onboarding`
- **الغرض:** تعريف المستخدم بالتطبيق
- **المكونات:**
  - `OnboardingSlide` (3 slides)
  - `SmoothPageIndicator`
  - Skip button
- **البيانات:**
  - يخزن `onboardingCompleted` في SharedPreferences
- **حالات الحافة:**
  - ⚠️ لا يوجد إمكانية للرجوع للخلف

#### Register Screen (`/register`)
- **Route:** `AppRoutes.register`
- **الغرض:** تسجيل المستخدم الجديد
- **المكونات:**
  - Form fields (Display Name)
  - Profile picture picker
  - Security note
  - Register button
- **البيانات:**
  - `displayName` (String)
  - `profilePicture` (Base64 image)
  - `userId` (generated from device hash + display name)
- **التحقق:**
  - ✅ Form validation
  - ✅ Error handling
- **حالات الحافة:**
  - ⚠️ لا يوجد Terms of Service checkbox
  - ⚠️ لا يوجد Privacy Policy link

#### Lock Screen (`/lock`)
- **Route:** `AppRoutes.lock`
- **الغرض:** قفل التطبيق بالمصادقة البيومترية أو PIN
- **المكونات:**
  - Biometric authentication button
  - PIN pad (6 digits)
  - Duress PIN support
- **البيانات:**
  - `AuthType` (Master/Duress)
  - `PIN` (encrypted in FlutterSecureStorage)
- **المنطق:**
  - إذا كان PIN = Master PIN → `AuthType.master` → `sada_encrypted.sqlite`
  - إذا كان PIN = Duress PIN → `AuthType.duress` → `sada_dummy.sqlite`
- **حالات الحافة:**
  - ⚠️ لا يوجد retry limit للـ Biometric
  - ✅ Database initialization بناءً على AuthType

### 3.2. الصفحات الرئيسية (مع BottomNavBar)

#### Home Screen (`/home`)
- **Route:** `AppRoutes.home`
- **الغرض:** الشاشة الرئيسية مع نظرة عامة
- **المكونات:**
  - `SliverAppBar` (Material 3)
  - `FAB Speed Dial` (Add Friend, Create Group)
  - Mesh status indicator
  - Quick actions
- **البيانات:**
  - Mesh connection status
  - Nearby peers count
- **حالات الحافة:**
  - ✅ Responsive design
  - ✅ RTL support

#### Chat Page (`/chat`)
- **Route:** `AppRoutes.chat`
- **الغرض:** قائمة المحادثات
- **المكونات:**
  - `ChatTile` / `GlassChatTile`
  - Search bar
  - Empty state
- **البيانات:**
  - `List<ChatModel>` من `ChatRepository`
  - Stream-based updates
- **حالات الحافة:**
  - ✅ Real-time updates
  - ✅ Unread message count

#### Chat Details Screen (`/chat/:chatId`)
- **Route:** `AppRoutes.chat/:chatId`
- **الغرض:** شاشة المحادثة الفردية
- **المكونات:**
  - `MessageBubble` (sent/received)
  - Message input field
  - Send button
- **البيانات:**
  - `ChatModel` (passed via `state.extra`)
  - `List<MessageModel>` (stream from database)
- **حالات الحافة:**
  - ✅ Message encryption قبل الإرسال
  - ✅ Message decryption عند الاستقبال
  - ⚠️ لا يوجد message status indicators (sent/delivered/read)

#### Groups Screen (`/groups`)
- **Route:** `AppRoutes.groups`
- **الغرض:** اكتشاف المجموعات القريبة
- **المكونات:**
  - Radar-style UI
  - Group cards
  - Create group button
- **البيانات:**
  - `List<GroupModel>` من `GroupsRepository`
- **حالات الحافة:**
  - ✅ Group discovery via mesh
  - ⚠️ لا يوجد group member management UI

#### Create Group Screen (`/create_group`)
- **Route:** `AppRoutes.createGroup`
- **الغرض:** إنشاء مجموعة جديدة
- **المكونات:**
  - Group name input
  - Group description
  - Privacy settings (Public/Private)
  - Create button
- **البيانات:**
  - `groupName` (String)
  - `description` (String)
  - `isPublic` (bool)
- **حالات الحافة:**
  - ✅ Local group storage
  - ⚠️ لا يوجد group member invitation UI

#### Add Friend Screen (`/add_friend`)
- **Route:** `AppRoutes.addFriend`
- **الغرض:** إضافة صديق جديد
- **المكونات:**
  - QR Scanner button
  - Manual entry (future)
- **البيانات:**
  - QR code data (JSON with userId + publicKey)
- **حالات الحافة:**
  - ✅ QR code validation
  - ✅ Contact deduplication

#### Scan QR Screen (`/scan_qr`)
- **Route:** `AppRoutes.scanQr`
- **الغرض:** مسح رمز QR لإضافة صديق
- **المكونات:**
  - `MobileScanner` widget
  - Camera permission handling
- **البيانات:**
  - QR code result (JSON)
  - Parsing: `userId`, `publicKey`, `displayName`
- **حالات الحافة:**
  - ✅ Permission handling
  - ✅ Invalid QR code handling

#### My QR Screen (`/my_qr`)
- **Route:** `AppRoutes.myQr`
- **الغرض:** عرض رمز QR الخاص بالمستخدم
- **المكونات:**
  - `QrImageView` widget
  - Share button
- **البيانات:**
  - User ID
  - Public key
  - Display name
- **حالات الحافة:**
  - ✅ QR code generation
  - ✅ Share functionality

#### Settings Screen (`/settings`)
- **Route:** `AppRoutes.settings`
- **الغرض:** إعدادات التطبيق
- **المكونات:**
  - Theme toggle (Dark/Light)
  - Language selector (AR/EN)
  - Biometric lock toggle
  - Power mode selector (High/Balanced/Low)
  - About & Privacy links
- **البيانات:**
  - Theme preference
  - Locale preference
  - Biometric enabled
  - Power mode
- **حالات الحافة:**
  - ✅ Real-time theme switching
  - ✅ RTL/LTR switching

#### About Screen (`/settings/about`)
- **Route:** `AppRoutes.about`
- **الغرض:** معلومات عن التطبيق
- **المكونات:**
  - App version
  - Developer info
  - License info
- **البيانات:**
  - `package_info_plus` للـ version

#### Privacy Screen (`/settings/privacy`)
- **Route:** `AppRoutes.privacy`
- **الغرض:** سياسة الخصوصية
- **المكونات:**
  - Markdown content renderer
- **البيانات:**
  - Static markdown content

#### Mesh Debug Screen (`/mesh_debug`)
- **Route:** `AppRoutes.meshDebug`
- **الغرض:** شاشة debug للـ mesh networking
- **المكونات:**
  - Connected peers list
  - Message queue status
  - Network topology
- **البيانات:**
  - Mesh connection status
  - Peer discovery logs
- **حالات الحافة:**
  - ⚠️ Development-only screen

#### Notifications Screen (`/notifications`)
- **Route:** `AppRoutes.notifications`
- **الغرض:** قائمة الإشعارات
- **المكونات:**
  - Notification list
  - Clear all button
- **البيانات:**
  - `List<NotificationModel>`
- **حالات الحافة:**
  - ✅ Local notifications support

---

## ⚡ 4. الميزات الرئيسية (Core Features)

### 4.1. الميزات المكتملة ✅

#### Foundation Layer
- [x] **UI/UX Architecture**
  - Material 3 design system
  - Dark/Light theme support
  - Cyber-Stealth aesthetic (Neo-Glass design)
  - Mesh gradient background animations

- [x] **Navigation System**
  - GoRouter with ShellRoute
  - BottomNavBar persistent navigation
  - Deep linking support
  - Route guards (authentication)

- [x] **Localization**
  - Arabic & English support
  - RTL/LTR switching
  - `flutter_localizations` integration

- [x] **Responsive Design**
  - ScreenUtil-based layouts
  - Adaptive UI for different screen sizes

- [x] **Logging System**
  - Structured logging with `logger` package
  - Log levels (info, warning, error)

#### Authentication & Security
- [x] **Offline Authentication**
  - Device-bound User ID (device hash + display name)
  - No server-side authentication

- [x] **Biometric App Lock**
  - Fingerprint/Face ID support
  - `local_auth` integration
  - Toggle on/off in settings

- [x] **Duress Mode (Plausible Deniability)**
  - Dual PIN system (Master/Duress)
  - Separate database files
  - Identical UI in both modes
  - No visible indicators

- [x] **End-to-End Encryption**
  - X25519 key exchange (ECDH)
  - XSalsa20-Poly1305 authenticated encryption
  - libsodium integration
  - Forward secrecy (session keys)

- [x] **Secure Key Management**
  - Private keys in FlutterSecureStorage (Android Keystore)
  - Public keys in database
  - QR code key exchange

#### Core Features
- [x] **Onboarding Flow**
  - 3-slide introduction
  - Skip functionality
  - Completion tracking

- [x] **Profile Picture Management**
  - Image picker
  - Image compression
  - Base64 storage

- [x] **QR Code Generation & Scanning**
  - QR code generation for contact sharing
  - QR code scanning for adding friends
  - JSON format (userId + publicKey + displayName)

- [x] **Local Notifications**
  - `flutter_local_notifications` integration
  - Notification permissions handling
  - In-app notification display

- [x] **Power Management**
  - Duty cycling for mesh discovery
  - Power modes (High/Balanced/Low)
  - Battery optimization

- [x] **Interactive Feature Discovery Tour**
  - `showcaseview` integration
  - Guided tour for new users

#### Groups
- [x] **Group Creation UI**
  - Create group screen
  - Group name & description
  - Privacy settings

- [x] **Group Discovery Screen**
  - Radar-style UI
  - Nearby groups list

- [x] **Local Group Storage**
  - Groups stored in database
  - Group metadata management

#### Database Layer
- [x] **Drift (SQLite) Integration**
  - Type-safe queries
  - Code generation
  - Migration support

- [x] **Message Persistence**
  - Messages stored locally
  - Encrypted content storage
  - Message status tracking

- [x] **Contact Storage**
  - Contacts table
  - Public key storage
  - Block/unblock functionality

- [x] **Duress Mode Database Separation**
  - `sada_encrypted.sqlite` (Master)
  - `sada_dummy.sqlite` (Duress)

- [x] **Relay Queue (Store-Carry-Forward)**
  - `RelayQueueTable` for mesh routing
  - Message queuing for offline delivery
  - Hop count & TTL tracking

#### Native Android Bridge
- [x] **WiFi Direct (P2P) Discovery**
  - Kotlin implementation
  - MethodChannel & EventChannel setup
  - Peer discovery events

- [x] **Mesh Debug Screen**
  - Connection status display
  - Peer list visualization

### 4.2. الميزات تحت التطوير 🚧

- [ ] **Native Mesh Implementation**
  - [ ] Complete WiFi P2P connection management
  - [ ] Bluetooth LE mesh support
  - [ ] Message routing protocol
  - [ ] Network topology management

- [ ] **Message Protocol**
  - [ ] Mesh message format standardization
  - [ ] Multi-hop routing implementation
  - [ ] Message delivery confirmation
  - [ ] Offline message queue processing

### 4.3. الميزات المخططة 📋

- [ ] **Advanced Features**
  - [ ] File sharing (Images, Documents)
  - [ ] Voice messages
  - [ ] Location sharing
  - [ ] Mesh network map visualization

- [ ] **Testing & Quality**
  - [ ] Unit tests
  - [ ] Integration tests
  - [ ] E2E tests
  - [ ] Security audits

### 4.4. التكاملات الخارجية (APIs & Third-party Services)

#### لا توجد تكاملات خارجية
- ✅ **100% Offline:** التطبيق يعمل بالكامل بدون خوادم خارجية
- ✅ **No Cloud Sync:** جميع البيانات محلية
- ✅ **No Analytics:** لا يوجد تتبع للمستخدمين
- ✅ **No Crash Reporting:** لا يوجد إرسال تقارير أخطاء

---

## 🎨 5. التصميم وتجربة المستخدم (UI/UX)

### نظام الألوان والتصميم (Color Palette)

#### Cyber-Stealth Color Scheme
```dart
// Primary Colors
Deep Midnight Blue: #050A14      // Background
Semi-Transparent Dark Blue: #101A26  // Surface
Electric Cyan: #00E5FF           // Primary/Accent
Fluorescent Red: #FF1744         // Error

// Material 3 Color Scheme
Primary: Electric Cyan (#00E5FF)
Secondary: Electric Cyan (unified accent)
Error: Fluorescent Red (#FF1744)
Surface: Semi-Transparent Dark Blue (60% opacity)
```

#### Typography
- **Font Family:** Google Fonts - Poppins
- **Base Style:** `GoogleFonts.poppins()`
- **Headings:** Bold, 24px, letter-spacing 0.5
- **Body:** Regular, 16px
- **Buttons:** Semi-bold, 16px, letter-spacing 0.5

### التصميم متجاوب (Responsive Design)

- ✅ **ScreenUtil Integration**
  - Design size: 375x812 (iPhone X)
  - `minTextAdapt: true`
  - `splitScreenMode: true`
- ✅ **Adaptive Layouts**
  - Responsive padding/margins
  - Flexible widgets
  - Screen size detection

### دعم اللغات/الاتجاهات (RTL/LTR)

- ✅ **Full RTL Support**
  - Arabic (RTL) & English (LTR)
  - `flutter_localizations` integration
  - Locale switching in settings
  - Text direction auto-detection

#### Localization Files
- `l10n/app_ar.arb` (Arabic)
- `l10n/app_en.arb` (English)
- Generated files in `l10n/generated/`

### عناصر التفاعل (Animations & Micro-interactions)

#### Animation Libraries
- **flutter_animate:** 4.5.0 (Advanced animations)
- **animate_do:** 4.2.0 (Simple animations)

#### Animation Types
- ✅ **Splash Screen:** Fade + Scale animation
- ✅ **Page Transitions:** Smooth navigation animations
- ✅ **Mesh Gradient Background:** Animated color blobs
- ✅ **Button Interactions:** Ripple effects
- ✅ **List Animations:** Staggered list items

#### Micro-interactions
- ✅ **FAB Speed Dial:** Expandable floating action button
- ✅ **PIN Pad:** Haptic feedback (future)
- ✅ **Message Bubbles:** Slide-in animations
- ✅ **Loading States:** Circular progress indicators

### Design System Components

#### Glassmorphism Effects
- ✅ **Card Theme:** Semi-transparent cards with blur
- ✅ **Border:** 1px white border (10% opacity)
- ✅ **Border Radius:** 24px (consistent)

#### Material 3 Components
- ✅ **NavigationBar:** Bottom navigation (5 tabs)
- ✅ **SliverAppBar:** Collapsible app bar
- ✅ **Cards:** Glassmorphism style
- ✅ **Buttons:** Elevated, Outlined, Text variants

---

## 🔒 6. الأمان والأداء (Security & Performance)

### آلية المصادقة (Authentication)

#### Offline Authentication Flow
1. **User Registration:**
   - User enters display name
   - System generates `userId` = hash(deviceId + displayName)
   - Creates key pair (X25519)
   - Stores private key in FlutterSecureStorage
   - Stores public key in database

2. **App Lock:**
   - Biometric authentication (optional)
   - PIN authentication (required)
   - Duress PIN support

3. **Session Management:**
   - `AuthType` (Master/Duress) determines database
   - Session persists until app close
   - Re-authentication on app resume (if biometric enabled)

#### Duress Mode Implementation
```dart
// Master PIN → AuthType.master → sada_encrypted.sqlite
// Duress PIN → AuthType.duress → sada_dummy.sqlite

// No visible difference in UI
// Identical experience in both modes
```

### حماية البيانات

#### Encryption Stack
- **Key Exchange:** X25519 (Curve25519 ECDH)
- **Encryption:** XSalsa20-Poly1305
- **Hashing:** BLAKE2b (for session key derivation)
- **Library:** libsodium (sodium_libs)

#### Key Management
- **Private Keys:** FlutterSecureStorage (Android Keystore)
- **Public Keys:** Database (encrypted at rest)
- **Session Keys:** Derived per conversation (forward secrecy)

#### Message Encryption Flow
1. Calculate shared secret (ECDH)
2. Derive session key (BLAKE2b hash)
3. Generate random nonce (24 bytes)
4. Encrypt message (XSalsa20-Poly1305)
5. Store: Base64(nonce + ciphertext)

#### Database Security
- **Encryption at Rest:** SQLite encryption (future)
- **Duress Mode:** Separate database files
- **No Cloud Sync:** All data local

### تحسينات الأداء المطبقة

#### Database Optimization
- ✅ **Indexes:** Primary keys on all tables
- ✅ **Lazy Loading:** Stream-based queries
- ✅ **Pagination:** Limit/offset for message lists
- ✅ **Connection Pooling:** Drift handles connections

#### Memory Management
- ✅ **Image Compression:** `flutter_image_compress`
- ✅ **Cached Images:** `cached_network_image`
- ✅ **Dispose Resources:** Proper cleanup in widgets

#### Network Optimization
- ✅ **Duty Cycling:** Configurable mesh discovery frequency
- ✅ **Power Modes:** High/Balanced/Low performance modes
- ✅ **Background Service:** Efficient foreground service

#### UI Performance
- ✅ **Code Generation:** Riverpod generators reduce runtime overhead
- ✅ **Lazy Loading:** Widgets loaded on demand
- ✅ **Animation Optimization:** Hardware-accelerated animations

---

## 🐛 7. المشاكل المعروفة والتحسينات المقترحة

### المشاكل المعروفة (Known Issues)

#### Critical Issues
- ⚠️ **Mesh Routing:** خوارزميات التوجيه قيد التحسين
- ⚠️ **WiFi P2P Connection:** إدارة الاتصال غير مكتملة
- ⚠️ **Bluetooth LE:** الدعم غير مطبق بعد

#### Medium Priority Issues
- ⚠️ **Splash Screen:** لا يوجد timeout handling للتهيئة الطويلة
- ⚠️ **Onboarding:** لا يوجد إمكانية للرجوع للخلف
- ⚠️ **Register Screen:** لا يوجد Terms of Service checkbox
- ⚠️ **Lock Screen:** لا يوجد retry limit للـ Biometric
- ⚠️ **Message Status:** لا يوجد indicators (sent/delivered/read)
- ⚠️ **Group Management:** لا يوجد UI لإدارة أعضاء المجموعة

#### Low Priority Issues
- ⚠️ **Haptic Feedback:** غير مطبق في PIN pad
- ⚠️ **Error Messages:** بعض الرسائل غير مترجمة
- ⚠️ **Accessibility:** دعم محدود للوصولية

### اقتراحات لتحسين الأداء

#### Database
- [ ] **Add Indexes:** على `chatId` في `messages_table`
- [ ] **Add Indexes:** على `peerId` في `chats_table`
- [ ] **Query Optimization:** تحسين queries المعقدة
- [ ] **Database Encryption:** SQLCipher integration

#### Network
- [ ] **Connection Pooling:** تحسين إدارة الاتصالات
- [ ] **Message Batching:** تجميع الرسائل قبل الإرسال
- [ ] **Compression:** ضغط الرسائل قبل التشفير
- [ ] **Retry Logic:** تحسين آلية إعادة المحاولة

#### UI/UX
- [ ] **Skeleton Loaders:** أثناء تحميل البيانات
- [ ] **Optimistic Updates:** تحديثات فورية في UI
- [ ] **Image Lazy Loading:** تحميل الصور عند الحاجة
- [ ] **Animation Performance:** تحسين أداء الرسوم المتحركة

### ميزات مقترحة للإضافة مستقبلاً

#### Short-term (v1.1)
- [ ] **Message Status Indicators:** sent/delivered/read
- [ ] **Group Member Management:** إضافة/حذف أعضاء
- [ ] **File Sharing:** صور ومستندات
- [ ] **Message Search:** البحث في الرسائل

#### Medium-term (v1.2)
- [ ] **Voice Messages:** تسجيل وإرسال رسائل صوتية
- [ ] **Location Sharing:** مشاركة الموقع الجغرافي
- [ ] **Message Reactions:** تفاعلات على الرسائل
- [ ] **Message Forwarding:** إعادة توجيه الرسائل

#### Long-term (v2.0)
- [ ] **Mesh Network Map:** تصور طوبولوجيا الشبكة
- [ ] **Multi-device Sync:** (محدود - بدون خوادم)
- [ ] **End-to-End Encrypted Groups:** تشفير المجموعات
- [ ] **Disappearing Messages:** رسائل تختفي تلقائياً

---

## 📊 8. مخطط قاعدة البيانات (Database Schema)

### الجداول المستخدمة

#### 1. ContactsTable (جهات الاتصال)

```dart
ContactsTable {
  id: String (Primary Key)           // User ID
  name: String (1-100 chars)         // Display name
  publicKey: String? (nullable)      // X25519 public key (Base64)
  avatar: String? (nullable)         // Profile picture (Base64)
  isBlocked: Bool (default: false)   // Block status
  createdAt: DateTime                // Creation timestamp
  updatedAt: DateTime                // Last update timestamp
}
```

**العلاقات:**
- One-to-Many مع `ChatsTable` (via `peerId`)

**الفهارس:**
- Primary Key: `id`
- Index on: `name` (for sorting)

#### 2. ChatsTable (المحادثات)

```dart
ChatsTable {
  id: String (Primary Key)           // Chat ID
  peerId: String? (nullable, FK)    // Contact ID (null for groups)
  name: String? (nullable)           // Group name (for groups)
  lastMessage: String? (nullable)    // Last message preview
  lastUpdated: DateTime              // Last activity timestamp
  isGroup: Bool (default: false)    // Is group chat?
  memberCount: Int (default: 0)      // Group member count
  avatarColor: Int (default: 0xFF0D9488)  // Group avatar color
  createdAt: DateTime                // Creation timestamp
}
```

**العلاقات:**
- Foreign Key: `peerId` → `ContactsTable.id`
- One-to-Many مع `MessagesTable` (via `chatId`)

**الفهارس:**
- Primary Key: `id`
- Index on: `peerId` (for lookups)
- Index on: `lastUpdated` (for sorting)

#### 3. MessagesTable (الرسائل)

```dart
MessagesTable {
  id: String (Primary Key)           // Message ID (UUID)
  chatId: String (FK)                // Chat ID
  senderId: String                   // Sender User ID
  content: String                    // Encrypted message (Base64)
  type: String (default: 'text')     // Message type (text/image/voice/file)
  status: String (default: 'sending') // Status (sending/sent/delivered/read/failed)
  timestamp: DateTime                // Message timestamp
  isFromMe: Bool (default: false)   // Is from current user?
  replyToId: String? (nullable)     // Reply to message ID
}
```

**العلاقات:**
- Foreign Key: `chatId` → `ChatsTable.id`
- Self-reference: `replyToId` → `MessagesTable.id`

**الفهارس:**
- Primary Key: `id`
- Index on: `chatId` (for message queries)
- Index on: `timestamp` (for sorting)
- Index on: `status` (for unread count)

**Message Types:**
- `text`: Plain text message
- `image`: Image message
- `voice`: Voice message
- `file`: File/document message

**Message Status:**
- `sending`: قيد الإرسال
- `sent`: تم الإرسال
- `delivered`: تم التسليم
- `read`: تم القراءة
- `failed`: فشل الإرسال

#### 4. RelayQueueTable (قائمة انتظار الترحيل)

```dart
RelayQueueTable {
  messageId: String (Primary Key)    // Message ID (UUID)
  originalSenderId: String           // Original sender User ID
  finalDestinationId: String         // Final destination User ID
  encryptedContent: String           // Encrypted message (Base64)
  hopCount: Int (default: 0)         // Current hop count
  maxHops: Int (default: 10)         // Maximum hops (TTL)
  trace: String (default: '[]')      // JSON array of device IDs
  timestamp: DateTime                // Original message timestamp
  type: String? (nullable)           // Message type
  metadata: String? (nullable)       // Additional JSON data
  queuedAt: DateTime                 // Queue timestamp
  retryCount: Int (default: 0)      // Retry attempts
  lastRetryAt: DateTime? (nullable) // Last retry timestamp
}
```

**الغرض:**
- Store-Carry-Forward protocol
- Messages queued for relay to other devices
- TTL tracking (maxHops)
- Retry logic (max 5 retries)

**الفهارس:**
- Primary Key: `messageId`
- Index on: `finalDestinationId` (for destination lookups)
- Index on: `queuedAt` (for sorting)
- Index on: `retryCount` (for cleanup)

### العلاقات بين الجداول

```
ContactsTable (1) ──< (Many) ChatsTable
                           │
                           │ (1)
                           │
                           │ (Many)
                           ▼
                    MessagesTable
                           │
                           │ (self-reference)
                           │
                           ▼
                    MessagesTable.replyToId

RelayQueueTable (standalone - no foreign keys)
```

### مخطط قاعدة البيانات (ER Diagram)

```
┌─────────────────┐
│ ContactsTable   │
├─────────────────┤
│ id (PK)         │
│ name            │
│ publicKey       │
│ avatar          │
│ isBlocked       │
│ createdAt       │
│ updatedAt       │
└────────┬────────┘
         │
         │ (1:Many)
         │
         ▼
┌─────────────────┐
│ ChatsTable      │
├─────────────────┤
│ id (PK)         │
│ peerId (FK)     │──┐
│ name            │  │
│ lastMessage     │  │
│ lastUpdated     │  │
│ isGroup         │  │
│ memberCount     │  │
│ avatarColor     │  │
│ createdAt       │  │
└────────┬────────┘  │
         │            │
         │ (1:Many)   │
         │            │
         ▼            │
┌─────────────────┐  │
│ MessagesTable   │  │
├─────────────────┤  │
│ id (PK)         │  │
│ chatId (FK)     │──┘
│ senderId        │
│ content         │
│ type            │
│ status          │
│ timestamp       │
│ isFromMe        │
│ replyToId (FK)  │──┐ (self-reference)
└─────────────────┘  │
                     │
                     └──┘

┌─────────────────┐
│ RelayQueueTable │
├─────────────────┤
│ messageId (PK)  │
│ originalSenderId│
│ finalDestId     │
│ encryptedContent│
│ hopCount        │
│ maxHops         │
│ trace           │
│ timestamp       │
│ type            │
│ metadata        │
│ queuedAt        │
│ retryCount      │
│ lastRetryAt     │
└─────────────────┘
```

### Database Files

#### Master Mode
- **File:** `sada_encrypted.sqlite`
- **Location:** `getApplicationDocumentsDirectory()`
- **Content:** Real user data (contacts, chats, messages)

#### Duress Mode
- **File:** `sada_dummy.sqlite`
- **Location:** `getApplicationDocumentsDirectory()`
- **Content:** Dummy data (fake contacts, fake chats, fake messages)

### Migration Strategy

#### Schema Version: 3
- **Version 1:** Initial schema (Contacts, Chats, Messages)
- **Version 2:** Added fields (no table recreation)
- **Version 3:** Added RelayQueueTable for Store-Carry-Forward

#### Migration Logic
```dart
onUpgrade: (Migrator m, int from, int to) async {
  if (from < 2) {
    // Schema 1 → 2: No table recreation needed
  }
  if (from < 3) {
    // Schema 2 → 3: Add RelayQueueTable
    await m.createTable(relayQueueTable);
  }
}
```

---

## 📝 ملخص التنفيذ

### الحالة الحالية: **Alpha (v1.0.0)**

#### ✅ المكتمل
- Foundation layer (UI, Navigation, Localization)
- Authentication & Security (Duress Mode, E2E Encryption)
- Core features (Onboarding, Profile, QR Codes)
- Database layer (Drift, Tables, Migrations)
- Groups UI (Creation, Discovery)
- Native Android bridge (WiFi Direct discovery)

#### 🚧 قيد التطوير
- Mesh networking implementation
- Message routing protocol
- Bluetooth LE support

#### 📋 مخطط
- File sharing
- Voice messages
- Location sharing
- Network map visualization

---

## 📞 معلومات الاتصال

**المطور:** Obada Dallo (عبادة دللو)  
**GitHub:** [obadadallo95](https://github.com/obadadallo95)  
**LinkedIn:** [Obada Dallo](https://www.linkedin.com/in/obada-dallo-777a47a9/)  
**Telegram:** [@obada_dallo95](https://t.me/obada_dallo95)

---

**تم إنشاء هذا التقرير تلقائياً من تحليل الكود المصدري**  
**آخر تحديث:** 2025-01-XX

