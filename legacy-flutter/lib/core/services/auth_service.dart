import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart'
    as sodium_sumo_libs
    show SodiumSumo, SodiumSumoInit;
import 'package:uuid/uuid.dart';
import '../utils/log_service.dart';

/// بيانات المستخدم
class UserData {
  final String userId;
  final String displayName;
  final String deviceHash;
  final String? publicKey;

  UserData({
    required this.userId,
    required this.displayName,
    required this.deviceHash,
    this.publicKey,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'deviceHash': deviceHash,
    'publicKey': publicKey,
  };

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    deviceHash: json['deviceHash'] as String,
    publicKey: json['publicKey'] as String?,
  );
}

/// حالة المصادقة
enum AuthStatus { initializing, loggedIn, loggedOut }

/// Provider لحالة قفل التطبيق
final isAppUnlockedProvider = StateProvider<bool>((ref) => false);

/// Provider لخدمة المصادقة
final authServiceProvider = StateNotifierProvider<AuthService, AuthStatus>(
  (ref) => AuthService(),
);

/// خدمة المصادقة
class AuthService extends StateNotifier<AuthStatus> {
  static const int pinLength = 6;
  static const int _maxFailedAttemptsBeforeLockout = 5;
  static const int _baseLockoutSeconds = 60;
  static const int _maxLockoutSeconds = 15 * 60;

  static const String _storageKey = 'user_data';
  static const String _storageBackupKey = 'user_data_backup';
  static const String _deviceIdKey = 'device_id_fallback';
  static const String _masterPinHashKey = 'master_pin_hash';
  static const String _failedPinAttemptsKey = 'failed_pin_attempts';
  static const String _pinLockUntilKey = 'pin_lock_until_epoch_ms';
  static const String _pinSaltKey = 'pin_salt';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  UserData? _currentUser;
  sodium_sumo_libs.SodiumSumo? _sodiumSumo;

  AuthService() : super(AuthStatus.initializing) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      LogService.info('🔍 بدء التحقق من حالة تسجيل الدخول...');
      final userDataJson = await _secureStorage.read(key: _storageKey);

      if (userDataJson != null) {
        final userData = UserData.fromJson(jsonDecode(userDataJson));
        _currentUser = userData;
        state = AuthStatus.loggedIn;
        LogService.info(
          '✅ تم العثور على بيانات المستخدم: ${userData.displayName}',
        );
      } else {
        state = AuthStatus.loggedOut;
        LogService.info('ℹ️ لا توجد بيانات مستخدم - يجب التسجيل');
      }
    } catch (e) {
      LogService.error('⛔ خطأ في التحقق من حالة تسجيل الدخول', e);
      state = AuthStatus.loggedOut;
      LogService.info('ℹ️ تم تعيين الحالة إلى loggedOut بسبب الخطأ');
    }
  }

  Future<void> _ensureSodium() async {
    _sodiumSumo ??= await sodium_sumo_libs.SodiumSumoInit.init();
  }

  bool _isValidPin(String pin) => RegExp(r'^\d{6}$').hasMatch(pin);

  String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> generateDeviceHash() async {
    try {
      String deviceId;

      if (defaultTargetPlatform == TargetPlatform.android) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;

        if (deviceId.isEmpty || deviceId == '9774d56d682e549c') {
          final savedDeviceId = await _secureStorage.read(key: _deviceIdKey);
          if (savedDeviceId != null) {
            deviceId = savedDeviceId;
          } else {
            deviceId = const Uuid().v4();
            await _secureStorage.write(key: _deviceIdKey, value: deviceId);
            LogService.info(
              'تم توليد Device ID جديد: ${deviceId.substring(0, 8)}...',
            );
          }
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';

        if (deviceId.isEmpty) {
          final savedDeviceId = await _secureStorage.read(key: _deviceIdKey);
          if (savedDeviceId != null) {
            deviceId = savedDeviceId;
          } else {
            deviceId = const Uuid().v4();
            await _secureStorage.write(key: _deviceIdKey, value: deviceId);
            LogService.info(
              'تم توليد Device ID جديد: ${deviceId.substring(0, 8)}...',
            );
          }
        }
      } else {
        final savedDeviceId = await _secureStorage.read(key: _deviceIdKey);
        if (savedDeviceId != null) {
          deviceId = savedDeviceId;
        } else {
          deviceId = const Uuid().v4();
          await _secureStorage.write(key: _deviceIdKey, value: deviceId);
        }
      }

      final deviceHash = _sha256Hex(deviceId);
      LogService.info('تم توليد Device Hash: ${deviceHash.substring(0, 8)}...');
      return deviceHash;
    } catch (e) {
      LogService.error('خطأ في توليد Device Hash', e);
      return _sha256Hex(const Uuid().v4());
    }
  }

  Future<bool> register(String displayName) async {
    try {
      if (displayName.trim().isEmpty) {
        LogService.warning('اسم العرض فارغ');
        return false;
      }

      final deviceHash = await generateDeviceHash();
      final userId = _sha256Hex('$displayName:$deviceHash');

      final userData = UserData(
        userId: userId,
        displayName: displayName.trim(),
        deviceHash: deviceHash,
        publicKey: null,
      );

      await _secureStorage.write(
        key: _storageKey,
        value: jsonEncode(userData.toJson()),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageBackupKey, jsonEncode(userData.toJson()));

      _currentUser = userData;
      state = AuthStatus.loggedIn;

      LogService.info('تم تسجيل المستخدم بنجاح: ${userData.displayName}');
      return true;
    } catch (e) {
      LogService.error('خطأ في تسجيل المستخدم', e);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: _storageKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageBackupKey);
      _currentUser = null;
      resetAuthType();
      state = AuthStatus.loggedOut;
      LogService.info('تم تسجيل الخروج');
    } catch (e) {
      LogService.error('خطأ في تسجيل الخروج', e);
    }
  }

  UserData? get currentUser => _currentUser;
  bool get isLoggedIn => state == AuthStatus.loggedIn;

  Future<String> _generatePinSalt() async {
    final existingSalt = await _secureStorage.read(key: _pinSaltKey);
    if (existingSalt != null) {
      return existingSalt;
    }

    final saltBytes = utf8.encode(const Uuid().v4() + const Uuid().v4());
    final salt = base64Encode(saltBytes);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
    return salt;
  }

  String _hashPinLegacy(String pin, String salt) {
    return _sha256Hex('$pin:$salt');
  }

  Future<String> _hashPinStrong(String pin) async {
    await _ensureSodium();
    final pwhash = _sodiumSumo!.crypto.pwhash;
    return pwhash.str(
      password: pin,
      opsLimit: pwhash.opsLimitInteractive,
      memLimit: pwhash.memLimitInteractive,
    );
  }

  Future<bool> _verifyPinHash(String pin, String storedHash) async {
    await _ensureSodium();
    final pwhash = _sodiumSumo!.crypto.pwhash;

    if (storedHash.startsWith(r'$argon2')) {
      return pwhash.strVerify(passwordHash: storedHash, password: pin);
    }

    final salt = await _generatePinSalt();
    return _hashPinLegacy(pin, salt) == storedHash;
  }

  Future<void> _migrateLegacyPinIfNeeded(
    String pin,
    String storedHash,
    String storageKey,
  ) async {
    if (storedHash.startsWith(r'$argon2')) return;
    final upgradedHash = await _hashPinStrong(pin);
    await _secureStorage.write(key: storageKey, value: upgradedHash);
    LogService.info('تمت ترقية تجزئة PIN إلى Argon2id');
  }

  Future<int> getRemainingLockoutSeconds() async {
    final lockUntilRaw = await _secureStorage.read(key: _pinLockUntilKey);
    if (lockUntilRaw == null) return 0;

    final lockUntilMs = int.tryParse(lockUntilRaw) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = lockUntilMs - nowMs;

    if (remainingMs <= 0) {
      await _secureStorage.delete(key: _pinLockUntilKey);
      return 0;
    }

    return (remainingMs / 1000).ceil();
  }

  Future<void> _clearPinFailures() async {
    await _secureStorage.delete(key: _failedPinAttemptsKey);
    await _secureStorage.delete(key: _pinLockUntilKey);
  }

  Future<void> _registerPinFailure() async {
    final attemptsRaw = await _secureStorage.read(key: _failedPinAttemptsKey);
    final attempts = (int.tryParse(attemptsRaw ?? '0') ?? 0) + 1;
    await _secureStorage.write(
      key: _failedPinAttemptsKey,
      value: attempts.toString(),
    );

    if (attempts < _maxFailedAttemptsBeforeLockout) {
      return;
    }

    final stage =
        ((attempts - _maxFailedAttemptsBeforeLockout) ~/
            _maxFailedAttemptsBeforeLockout) +
        1;
    final lockoutSeconds = (_baseLockoutSeconds * (1 << (stage - 1))).clamp(
      _baseLockoutSeconds,
      _maxLockoutSeconds,
    );
    final lockUntil = DateTime.now()
        .add(Duration(seconds: lockoutSeconds))
        .millisecondsSinceEpoch;

    await _secureStorage.write(
      key: _pinLockUntilKey,
      value: lockUntil.toString(),
    );
    LogService.warning(
      'PIN locked for ${lockoutSeconds}s after $attempts failures',
    );
  }

  Future<bool> setMasterPin(String pin) async {
    try {
      if (!_isValidPin(pin)) {
        LogService.warning('PIN يجب أن يكون 6 أرقام بالضبط');
        return false;
      }

      final hash = await _hashPinStrong(pin);
      await _secureStorage.write(key: _masterPinHashKey, value: hash);
      await _clearPinFailures();
      LogService.info('تم تعيين Master PIN بنجاح');
      return true;
    } catch (e) {
      LogService.error('خطأ في تعيين Master PIN', e);
      return false;
    }
  }

  Future<bool> verifyPin(String inputPin) async {
    try {
      if (!_isValidPin(inputPin)) {
        await _registerPinFailure();
        LogService.warning('PIN format invalid');
        return false;
      }

      final remainingLockout = await getRemainingLockoutSeconds();
      if (remainingLockout > 0) {
        LogService.warning('PIN locked. Remaining: ${remainingLockout}s');
        return false;
      }

      final masterPinHash = await _secureStorage.read(key: _masterPinHashKey);

      if (masterPinHash != null &&
          await _verifyPinHash(inputPin, masterPinHash)) {
        await _migrateLegacyPinIfNeeded(
          inputPin,
          masterPinHash,
          _masterPinHashKey,
        );
        await _clearPinFailures();
        LogService.info('تم التحقق من Master PIN بنجاح');
        return true;
      }

      await _registerPinFailure();
      LogService.warning('PIN غير صحيح');
      return false;
    } catch (e) {
      LogService.error('خطأ في التحقق من PIN', e);
      return false;
    }
  }

  Future<bool> hasMasterPin() async {
    final masterPinHash = await _secureStorage.read(key: _masterPinHashKey);
    return masterPinHash != null;
  }

  void resetAuthType() async {
    await _clearPinFailures();
    LogService.info('تم إعادة تعيين حالة قفل التطبيق');
  }
}
