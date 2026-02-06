import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium_libs/sodium_libs.dart' hide SodiumInit;
import 'package:sodium_libs/sodium_libs.dart' as sodium_libs show SodiumInit;
import 'package:sodium/sodium.dart';
import '../utils/log_service.dart';

/// زوج المفاتيح (Public/Private)
class KeyPair {
  final Uint8List publicKey;
  final Uint8List privateKey;

  KeyPair({
    required this.publicKey,
    required this.privateKey,
  });

  /// تحويل PublicKey إلى Base64 للشارة
  String get publicKeyBase64 => base64Encode(publicKey);

  /// إنشاء PublicKey من Base64
  static Uint8List publicKeyFromBase64(String base64) {
    return base64Decode(base64);
  }
}

/// مدير المفاتيح
/// يولد ويخزن المفاتيح بشكل آمن
class KeyManager {
  static const String _privateKeyStorageKey = 'user_private_key';
  static const String _publicKeyStorageKey = 'user_public_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Sodium? _sodium;
  KeyPair? _cachedKeyPair;

  /// تهيئة libsodium
  Future<void> initialize() async {
    try {
      _sodium = await sodium_libs.SodiumInit.init();
      LogService.info('تم تهيئة libsodium بنجاح');
    } catch (e) {
      LogService.error('خطأ في تهيئة libsodium', e);
      rethrow;
    }
  }

  /// التحقق من تهيئة libsodium
  void _ensureInitialized() {
    if (_sodium == null) {
      throw StateError('libsodium غير مهيأ. استدعِ initialize() أولاً.');
    }
  }

  /// توليد زوج مفاتيح جديد
  /// يستخدم Curve25519 (crypto_box)
  Future<KeyPair> generateKeyPair() async {
    _ensureInitialized();
    final sodium = _sodium!;

    try {
      // توليد زوج المفاتيح باستخدام Curve25519
      // sodium_libs API: استخدام crypto.box
      final seedBytes = sodium.randombytes.buf(sodium.crypto.box.seedBytes);
      final seed = SecureKey.fromList(sodium, seedBytes);
      final keyPair = sodium.crypto.box.seedKeyPair(seed);

      // حفظ PrivateKey بشكل آمن
      final privateKeyBytes = keyPair.secretKey.runUnlockedSync((bytes) => Uint8List.fromList(bytes));
      await _secureStorage.write(
        key: _privateKeyStorageKey,
        value: base64Encode(privateKeyBytes),
      );

      // حفظ PublicKey في SharedPreferences العادية (للمشاركة عبر QR)
      // سنستخدم SecureStorage أيضاً للأمان الإضافي
      await _secureStorage.write(
        key: _publicKeyStorageKey,
        value: base64Encode(keyPair.publicKey),
      );

      _cachedKeyPair = KeyPair(
        publicKey: keyPair.publicKey,
        privateKey: privateKeyBytes,
      );
      
      seed.dispose();

      LogService.info('تم توليد زوج المفاتيح بنجاح');
      return _cachedKeyPair!;
    } catch (e) {
      LogService.error('خطأ في توليد زوج المفاتيح', e);
      rethrow;
    }
  }

  /// الحصول على زوج المفاتيح
  /// يحاول التحميل من التخزين، وإذا لم يكن موجوداً يولد واحداً جديداً
  Future<KeyPair> getKeyPair() async {
    if (_cachedKeyPair != null) {
      return _cachedKeyPair!;
    }

    _ensureInitialized();

    try {
      // محاولة تحميل المفاتيح من التخزين
      final privateKeyBase64 = await _secureStorage.read(key: _privateKeyStorageKey);
      final publicKeyBase64 = await _secureStorage.read(key: _publicKeyStorageKey);

      if (privateKeyBase64 != null && publicKeyBase64 != null) {
        _cachedKeyPair = KeyPair(
          publicKey: base64Decode(publicKeyBase64),
          privateKey: base64Decode(privateKeyBase64),
        );
        LogService.info('تم تحميل المفاتيح من التخزين');
        return _cachedKeyPair!;
      } else {
        // لا توجد مفاتيح محفوظة - توليد جديد
        LogService.info('لا توجد مفاتيح محفوظة - توليد جديد');
        return await generateKeyPair();
      }
    } catch (e) {
      LogService.error('خطأ في تحميل المفاتيح', e);
      // في حالة الخطأ، توليد مفاتيح جديدة
      return await generateKeyPair();
    }
  }

  /// الحصول على PublicKey فقط
  Future<Uint8List> getPublicKey() async {
    final keyPair = await getKeyPair();
    return keyPair.publicKey;
  }

  /// الحصول على PrivateKey فقط
  /// ⚠️ حساس - استخدم بحذر
  Future<Uint8List> getPrivateKey() async {
    final keyPair = await getKeyPair();
    return keyPair.privateKey;
  }

  /// حذف المفاتيح (للتسجيل الخروج)
  Future<void> deleteKeys() async {
    try {
      await _secureStorage.delete(key: _privateKeyStorageKey);
      await _secureStorage.delete(key: _publicKeyStorageKey);
      _cachedKeyPair = null;
      LogService.info('تم حذف المفاتيح');
    } catch (e) {
      LogService.error('خطأ في حذف المفاتيح', e);
    }
  }

  /// مسح المفاتيح من الذاكرة
  void clearCache() {
    if (_cachedKeyPair != null) {
      // محاولة مسح الذاكرة (libsodium قد يقوم بذلك تلقائياً)
      _cachedKeyPair = null;
    }
  }
}

