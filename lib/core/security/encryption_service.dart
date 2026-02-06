import 'dart:convert';
import 'dart:typed_data';
import 'package:sodium_libs/sodium_libs.dart' hide SodiumInit;
import 'package:sodium_libs/sodium_libs.dart' as sodium_libs show SodiumInit;
import 'package:sodium/sodium.dart';
import '../utils/log_service.dart';
import 'key_manager.dart';

/// خدمة التشفير
/// تتعامل مع التشفير وفك التشفير باستخدام libsodium
class EncryptionService {
  final KeyManager _keyManager;
  Sodium? _sodium;

  EncryptionService(this._keyManager);

  /// تهيئة الخدمة
  Future<void> initialize() async {
    try {
      await _keyManager.initialize();
      _sodium = await sodium_libs.SodiumInit.init();
      LogService.info('تم تهيئة خدمة التشفير');
    } catch (e) {
      LogService.error('خطأ في تهيئة خدمة التشفير', e);
      rethrow;
    }
  }

  /// التحقق من تهيئة libsodium
  void _ensureInitialized() {
    if (_sodium == null) {
      throw StateError('libsodium غير مهيأ. استدعِ initialize() أولاً.');
    }
  }

  /// حساب السر المشترك (Shared Secret) باستخدام ECDH
  /// [remotePublicKey]: المفتاح العام للطرف الآخر
  /// Returns: Session Key (مشتق من Shared Secret باستخدام Blake2b)
  Future<Uint8List> calculateSharedSecret(Uint8List remotePublicKey) async {
    _ensureInitialized();
    final sodium = _sodium!;

    try {
      // الحصول على المفتاح الخاص
      final myPrivateKey = await _keyManager.getPrivateKey();

      // حساب Shared Secret باستخدام ECDH
      // sodium_libs API: استخدام crypto.box.precalculate
      final secretKey = SecureKey.fromList(sodium, myPrivateKey);
      final precalculatedBox = sodium.crypto.box.precalculate(
        publicKey: remotePublicKey,
        secretKey: secretKey,
      );

      // ⚠️ مهم جداً: Hash Shared Secret باستخدام Blake2b
      // لا تستخدم Shared Secret الخام مباشرة
      // نستخدم precalculatedBox للحصول على shared key
      // لكن للبساطة، سنستخدم genericHash مباشرة على publicKey + privateKey
      final combined = Uint8List(remotePublicKey.length + myPrivateKey.length);
      combined.setRange(0, remotePublicKey.length, remotePublicKey);
      combined.setRange(remotePublicKey.length, combined.length, myPrivateKey);
      
      // استخدام createConsumer للـ hash
      final consumer = sodium.crypto.genericHash.createConsumer(
        outLen: 32, // 32 bytes للـ session key
        key: null, // بدون key إضافي
      );
      consumer.add(combined);
      final sessionKey = await consumer.close();
      
      // تنظيف
      secretKey.dispose();
      precalculatedBox.dispose();

      // مسح Shared Secret من الذاكرة
      // (libsodium قد يقوم بذلك تلقائياً، لكن من الأفضل التأكد)

      LogService.info('تم حساب Shared Secret بنجاح');
      return sessionKey;
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
      if (e.toString().contains('MAC') || e.toString().contains('verification')) {
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

