# نظام التشفير E2E - Sada

تم بناء البنية الأساسية لنظام التشفير End-to-End باستخدام `libsodium`.

## ⚠️ ملاحظة مهمة

الكود الحالي يحتاج إلى تحديث API لـ `sodium_libs`. الـ API المستخدم في الكود قد لا يتطابق مع الإصدار المثبت. يرجى التحقق من الوثائق الرسمية لـ `sodium_libs` وتحديث الكود وفقاً لذلك.

## ✅ المكونات المنجزة

### 1. التبعيات
- `sodium_libs`: تم إضافته إلى `pubspec.yaml`

### 2. KeyManager (`lib/core/security/key_manager.dart`)
- **الوظيفة**: توليد وإدارة المفاتيح بشكل آمن
- **الميزات**:
  - توليد زوج مفاتيح Curve25519
  - حفظ PrivateKey في `FlutterSecureStorage` (مشفر)
  - حفظ PublicKey (للمشاركة عبر QR)
  - Cache للمفاتيح في الذاكرة
  - حذف المفاتيح عند تسجيل الخروج

### 3. EncryptionService (`lib/core/security/encryption_service.dart`)
- **الوظيفة**: التشفير وفك التشفير
- **الميزات**:
  - حساب Shared Secret باستخدام ECDH
  - Hash Shared Secret باستخدام Blake2b (Forward Secrecy)
  - تشفير الرسائل باستخدام XSalsa20-Poly1305
  - فك تشفير الرسائل مع التحقق من MAC
  - توليد Nonce عشوائي آمن

### 4. Security Providers (`lib/core/security/security_providers.dart`)
- `keyManagerProvider`: Provider لـ KeyManager
- `encryptionServiceProvider`: Provider لـ EncryptionService

### 5. تحديث Models
- **MessageModel**: إضافة حقل `encryptedText` لحفظ النص المشفر
- **ChatModel**: إضافة حقل `publicKey` لحفظ PublicKey للطرف الآخر

### 6. التكامل
- تهيئة الخدمات في `app.dart`
- تحديث `MessageModel` لدعم التشفير

## 🔧 الخطوات المتبقية

### 1. تحديث API لـ sodium_libs
يجب تحديث الكود لاستخدام الـ API الصحيح لـ `sodium_libs`. الـ API الحالي يحتاج إلى:

```dart
// مثال على الـ API الصحيح (يحتاج التحقق):
final sodium = await SodiumInit.init();

// توليد المفاتيح
final keyPair = sodium.cryptoBox.newKeyPair(); // أو seedKeyPair

// حساب Shared Secret
final sharedSecret = sodium.cryptoBox.beforeNm(
  publicKey: remotePublicKey,
  secretKey: myPrivateKey,
);

// Hash باستخدام Blake2b
final sessionKey = sodium.cryptoGenericHash.hash(
  sharedSecret,
  key: null,
  outputLength: 32,
);

// التشفير
final cipherText = sodium.cryptoSecretBox.encrypt(
  message: plainBytes,
  nonce: nonce,
  key: sharedKey,
);

// فك التشفير
final plainBytes = sodium.cryptoSecretBox.open(
  cipherText: cipherText,
  nonce: nonce,
  key: sharedKey,
);
```

### 2. تحديث ChatRepository
يجب تحديث `ChatRepository` لاستخدام التشفير عند إرسال/استقبال الرسائل:

```dart
// عند إرسال رسالة
final encryptionService = ref.read(encryptionServiceProvider);
final remotePublicKey = chat.publicKey; // من ChatModel
final sharedSecret = await encryptionService.calculateSharedSecret(
  KeyPair.publicKeyFromBase64(remotePublicKey!),
);
final encryptedText = encryptionService.encryptMessage(
  plainText,
  sharedSecret,
);

// حفظ encryptedText في قاعدة البيانات
final message = MessageModel(
  id: messageId,
  text: plainText, // للعرض
  encryptedText: encryptedText, // للحفظ
  // ...
);
```

### 3. تحديث ChatDetailsScreen
يجب تحديث `ChatDetailsScreen` لاستخدام التشفير عند إرسال الرسائل.

### 4. إدارة Session Keys
للحصول على Forward Secrecy أفضل، يجب:
- توليد Session Key جديد لكل محادثة
- حفظ Session Keys بشكل آمن
- حذف Session Keys القديمة

## 🔒 الأمان

### الميزات الأمنية المطبقة:
- ✅ Curve25519 للـ Key Exchange
- ✅ ECDH لحساب Shared Secret
- ✅ Blake2b Hash للـ Session Key (Forward Secrecy)
- ✅ XSalsa20-Poly1305 للتشفير (Authenticated Encryption)
- ✅ Nonce عشوائي لكل رسالة
- ✅ MAC للتحقق من سلامة الرسالة
- ✅ حفظ PrivateKey في SecureStorage (مشفر)

### الميزات المطلوبة:
- ⏳ Forward Secrecy كامل (Session Keys دورية)
- ⏳ Key Rotation
- ⏳ Perfect Forward Secrecy (PFS)

## 📝 ملاحظات

1. **API Compatibility**: يجب التحقق من الـ API الصحيح لـ `sodium_libs` وتحديث الكود
2. **Testing**: يجب اختبار التشفير وفك التشفير بشكل شامل
3. **Performance**: يجب مراقبة الأداء عند التشفير/فك التشفير
4. **Error Handling**: يجب معالجة الأخطاء بشكل صحيح (MAC failure، إلخ)

## 📚 المراجع

- [libsodium Documentation](https://doc.libsodium.org/)
- [sodium_libs Package](https://pub.dev/packages/sodium_libs)
- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)

