import 'dart:convert';
import 'dart:typed_data';
import 'package:sodium_libs/sodium_libs.dart' hide SodiumInit;
import 'package:sodium_libs/sodium_libs.dart' as sodium_libs show SodiumInit;
import 'package:sodium_libs/sodium_libs_sumo.dart'
    as sodium_sumo_libs
    show SodiumSumo, SodiumSumoInit;
import '../utils/log_service.dart';
import 'key_manager.dart';

/// خدمة التشفير
/// تتعامل مع التشفير وفك التشفير باستخدام libsodium
class EncryptionService {
  final KeyManager _keyManager;
  Sodium? _sodium;
  sodium_sumo_libs.SodiumSumo? _sodiumSumo;

  EncryptionService(this._keyManager);

  /// تهيئة الخدمة
  Future<void> initialize() async {
    try {
      await _keyManager.initialize();
      _sodium = await sodium_libs.SodiumInit.init();
      _sodiumSumo = await sodium_sumo_libs.SodiumSumoInit.init();
      LogService.info('تم تهيئة خدمة التشفير');
    } catch (e) {
      LogService.error('خطأ في تهيئة خدمة التشفير', e);
      rethrow;
    }
  }

  /// التحقق من تهيئة libsodium
  void _ensureInitialized() {
    if (_sodium == null || _sodiumSumo == null) {
      throw StateError('libsodium غير مهيأ. استدعِ initialize() أولاً.');
    }
  }

  /// حساب السر المشترك (Shared Secret) باستخدام ECDH
  /// [remotePublicKey]: المفتاح العام للطرف الآخر
  /// Returns: Session Key (مشتق من Shared Secret باستخدام Blake2b)
  Future<Uint8List> calculateSharedSecret(Uint8List remotePublicKey) async {
    _ensureInitialized();
    final sodium = _sodium!;
    final sodiumSumo = _sodiumSumo!;

    try {
      if (remotePublicKey.length != sodium.crypto.box.publicKeyBytes) {
        throw ArgumentError(
          'طول المفتاح العام غير صالح: ${remotePublicKey.length} '
          '(expected ${sodium.crypto.box.publicKeyBytes})',
        );
      }

      // الحصول على المفتاح الخاص
      final myPrivateKey = await _keyManager.getPrivateKey();
      if (myPrivateKey.length != sodium.crypto.box.secretKeyBytes) {
        throw StateError(
          'طول المفتاح الخاص غير صالح: ${myPrivateKey.length} '
          '(expected ${sodium.crypto.box.secretKeyBytes})',
        );
      }

      // 🔐 اشتقاق صحيح عبر ECDH:
      // crypto_scalarmult(remotePublicKey, myPrivateKey) ثم Blake2b KDF.
      final myPrivateSecureKey = SecureKey.fromList(sodium, myPrivateKey);
      SecureKey? sharedSecretSecureKey;
      try {
        sharedSecretSecureKey = sodiumSumo.crypto.scalarmult(
          n: myPrivateSecureKey,
          p: remotePublicKey,
        );

        final ecdhSharedSecret = sharedSecretSecureKey.runUnlockedSync(
          (bytes) => Uint8List.fromList(bytes),
        );

        const derivationContext = 'sada-e2e-session-key-v1';
        final contextBytes = utf8.encode(derivationContext);
        final keyMaterial = Uint8List(
          ecdhSharedSecret.length + contextBytes.length,
        );
        keyMaterial.setRange(0, ecdhSharedSecret.length, ecdhSharedSecret);
        keyMaterial.setRange(
          ecdhSharedSecret.length,
          keyMaterial.length,
          contextBytes,
        );

        final sessionKey = sodium.crypto.genericHash(
          message: keyMaterial,
          outLen: sodium.crypto.secretBox.keyBytes,
        );

        LogService.info('تم اشتقاق Shared Secret (ECDH) بنجاح');
        return sessionKey;
      } finally {
        sharedSecretSecureKey?.dispose();
        myPrivateSecureKey.dispose();
      }
    } catch (e) {
      LogService.error('خطأ في حساب Shared Secret', e);
      rethrow;
    }
  }

  /// تشفير رسالة
  /// [plainText]: النص العادي
  /// [sharedKey]: Session Key (من calculateSharedSecret)
  /// Returns: Base64 encoded string (Nonce + CipherText)
  String encryptMessage(String plainText, Uint8List sharedKey) {
    _ensureInitialized();
    final sodium = _sodium!;

    try {
      // تحويل النص إلى bytes
      final plainBytes = utf8.encode(plainText);

      // توليد Nonce عشوائي (24 bytes لـ XSalsa20)
      final nonce = sodium.randombytes.buf(24);

      // تشفير باستخدام crypto.secretBox (XSalsa20-Poly1305)
      final key = SecureKey.fromList(sodium, sharedKey);
      final cipherText = sodium.crypto.secretBox.easy(
        message: plainBytes,
        nonce: nonce,
        key: key,
      );
      key.dispose();

      // دمج Nonce + CipherText
      final combined = Uint8List(nonce.length + cipherText.length);
      combined.setRange(0, nonce.length, nonce);
      combined.setRange(nonce.length, combined.length, cipherText);

      // تحويل إلى Base64
      final encoded = base64Encode(combined);

      LogService.info('تم تشفير الرسالة بنجاح');
      return encoded;
    } catch (e) {
      LogService.error('خطأ في تشفير الرسالة', e);
      rethrow;
    }
  }

  /// فك تشفير رسالة
  /// [encryptedPayload]: Base64 encoded string (Nonce + CipherText)
  /// [sharedKey]: Session Key (من calculateSharedSecret)
  /// Returns: النص العادي
  /// Throws: Exception إذا فشل MAC (الرسالة تم التلاعب بها)
  String decryptMessage(String encryptedPayload, Uint8List sharedKey) {
    _ensureInitialized();
    final sodium = _sodium!;

    try {
      // فك ترميز Base64
      final combined = base64Decode(encryptedPayload);

      // استخراج Nonce (أول 24 bytes)
      final nonce = combined.sublist(0, 24);

      // استخراج CipherText (الباقي)
      final cipherText = combined.sublist(24);

      // فك التشفير
      final key = SecureKey.fromList(sodium, sharedKey);
      final plainBytes = sodium.crypto.secretBox.openEasy(
        cipherText: cipherText,
        nonce: nonce,
        key: key,
      );
      key.dispose();

      // تحويل إلى String
      final plainText = utf8.decode(plainBytes);

      LogService.info('تم فك تشفير الرسالة بنجاح');
      return plainText;
    } catch (e) {
      // فشل MAC - الرسالة تم التلاعب بها أو المفتاح خاطئ
      if (e.toString().contains('MAC') ||
          e.toString().contains('verification')) {
        LogService.error('فشل فك التشفير - MAC غير صحيح', e);
        throw Exception('فشل فك التشفير: الرسالة قد تكون تم التلاعب بها');
      }
      LogService.error('خطأ في فك تشفير الرسالة', e);
      rethrow;
    }
  }

  /// توليد Nonce عشوائي (للاستخدام الخارجي إذا لزم الأمر)
  Uint8List generateNonce() {
    _ensureInitialized();
    final sodium = _sodium!;
    return sodium.randombytes.buf(24);
  }

  /// توليد bytes عشوائية (للاستخدام في المفاتيح، إلخ)
  Uint8List randomBytes(int length) {
    _ensureInitialized();
    final sodium = _sodium!;
    return sodium.randombytes.buf(length);
  }
}
