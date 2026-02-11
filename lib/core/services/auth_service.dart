import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
enum AuthStatus {
  initializing,
  loggedIn,
  loggedOut,
}

/// نوع المصادقة (Master أو Duress)
enum AuthType {
  master, // المصادقة العادية - قاعدة البيانات الحقيقية
  duress, // المصادقة في حالة الإكراه - قاعدة البيانات الوهمية
  failure, // فشل المصادقة
}

/// Provider لخدمة المصادقة
final authServiceProvider = StateNotifierProvider<AuthService, AuthStatus>(
  (ref) => AuthService(),
);

/// خدمة المصادقة
/// تولد معرف فريد بناءً على توقيع الجهاز
class AuthService extends StateNotifier<AuthStatus> {
  static const String _storageKey = 'user_data';
  static const String _deviceIdKey = 'device_id_fallback';
  static const String _masterPinHashKey = 'master_pin_hash';
  static const String _duressPinHashKey = 'duress_pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _authTypeKey = 'current_auth_type';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences deprecated - removed
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  UserData? _currentUser;
  AuthType? _currentAuthType; // نوع المصادقة الحالي

  AuthService() : super(AuthStatus.initializing) {
    _checkLoginStatus();
  }

  /// التحقق من حالة تسجيل الدخول
  Future<void> _checkLoginStatus() async {
    try {
      LogService.info('🔍 بدء التحقق من حالة تسجيل الدخول...');
      final userDataJson = await _secureStorage.read(key: _storageKey);
      
      if (userDataJson != null) {
        final userData = UserData.fromJson(jsonDecode(userDataJson));
        _currentUser = userData;
        state = AuthStatus.loggedIn;
        LogService.info('✅ تم العثور على بيانات المستخدم: ${userData.displayName}');
      } else {
        state = AuthStatus.loggedOut;
        LogService.info('ℹ️ لا توجد بيانات مستخدم - يجب التسجيل');
      }
    } catch (e) {
      LogService.error('⛔ خطأ في التحقق من حالة تسجيل الدخول', e);
      // في حالة الخطأ، نعتبر المستخدم غير مسجل دخول
      state = AuthStatus.loggedOut;
      LogService.info('ℹ️ تم تعيين الحالة إلى loggedOut بسبب الخطأ');
    }
  }

  /// توليد Hash للجهاز
  /// يستخدم Android ID أو iOS IdentifierForVendor
  /// إذا لم يكن متاحاً، يستخدم UUID محفوظ بشكل آمن
  Future<String> generateDeviceHash() async {
    try {
      String deviceId;

      if (defaultTargetPlatform == TargetPlatform.android) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Android ID
        
        // إذا كان Android ID غير متاح (null أو "9774d56d682e549c")
        if (deviceId.isEmpty || deviceId == '9774d56d682e549c') {
          // محاولة قراءة UUID محفوظ مسبقاً
          final savedDeviceId = await _secureStorage.read(key: _deviceIdKey);
          if (savedDeviceId != null) {
            deviceId = savedDeviceId;
          } else {
            // توليد UUID جديد وحفظه
            deviceId = const Uuid().v4();
            await _secureStorage.write(key: _deviceIdKey, value: deviceId);
            LogService.info('تم توليد Device ID جديد: ${deviceId.substring(0, 8)}...');
          }
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        
        // إذا كان identifierForVendor غير متاح
        if (deviceId.isEmpty) {
          final savedDeviceId = await _secureStorage.read(key: _deviceIdKey);
          if (savedDeviceId != null) {
            deviceId = savedDeviceId;
          } else {
            deviceId = const Uuid().v4();
            await _secureStorage.write(key: _deviceIdKey, value: deviceId);
            LogService.info('تم توليد Device ID جديد: ${deviceId.substring(0, 8)}...');
          }
        }
      } else {
        // منصات أخرى - استخدام UUID
        final savedDeviceId = await _secureStorage.read(key: _deviceIdKey);
        if (savedDeviceId != null) {
          deviceId = savedDeviceId;
        } else {
          deviceId = const Uuid().v4();
          await _secureStorage.write(key: _deviceIdKey, value: deviceId);
        }
      }

      // Hash باستخدام SHA-256
      final bytes = utf8.encode(deviceId);
      final digest = sha256.convert(bytes);
      final deviceHash = digest.toString();

      LogService.info('تم توليد Device Hash: ${deviceHash.substring(0, 16)}...');
      return deviceHash;
    } catch (e) {
      LogService.error('خطأ في توليد Device Hash', e);
      // Fallback: استخدام UUID عشوائي
      final fallbackId = const Uuid().v4();
      final bytes = utf8.encode(fallbackId);
      final digest = sha256.convert(bytes);
      return digest.toString();
    }
  }

  /// تسجيل مستخدم جديد
  Future<bool> register(String displayName) async {
    try {
      if (displayName.trim().isEmpty) {
        LogService.warning('اسم العرض فارغ');
        return false;
      }

      // توليد Device Hash
      final deviceHash = await generateDeviceHash();
      
      // توليد User ID من displayName + deviceHash
      final userIdInput = '$displayName:$deviceHash';
      final userIdBytes = utf8.encode(userIdInput);
      final userIdDigest = sha256.convert(userIdBytes);
      final userId = userIdDigest.toString();

      // إنشاء بيانات المستخدم
      final userData = UserData(
        userId: userId,
        displayName: displayName.trim(),
        deviceHash: deviceHash,
        publicKey: null, // سيتم إضافته لاحقاً عند تنفيذ التشفير
      );

      // حفظ البيانات بشكل آمن
      await _secureStorage.write(
        key: _storageKey,
        value: jsonEncode(userData.toJson()),
      );

      _currentUser = userData;
      state = AuthStatus.loggedIn;

      LogService.info('تم تسجيل المستخدم بنجاح: ${userData.displayName}');
      return true;
    } catch (e) {
      LogService.error('خطأ في تسجيل المستخدم', e);
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: _storageKey);
      _currentUser = null;
      resetAuthType(); // إعادة تعيين AuthType عند تسجيل الخروج
      state = AuthStatus.loggedOut;
      LogService.info('تم تسجيل الخروج');
    } catch (e) {
      LogService.error('خطأ في تسجيل الخروج', e);
    }
  }

  /// الحصول على بيانات المستخدم الحالي
  UserData? get currentUser => _currentUser;

  /// التحقق من حالة تسجيل الدخول
  bool get isLoggedIn => state == AuthStatus.loggedIn;
  
  /// الحصول على نوع المصادقة الحالي
  AuthType? get currentAuthType => _currentAuthType;
  
  /// التحقق من أن المستخدم مصادق عليه (AuthType محدد)
  /// هذا يعني أن المستخدم أدخل PIN بنجاح (Master أو Duress)
  bool get isAuthenticated => _currentAuthType != null && 
                              (_currentAuthType == AuthType.master || 
                               _currentAuthType == AuthType.duress);
  
  /// توليد Salt عشوائي لـ PIN
  Future<String> _generatePinSalt() async {
    final existingSalt = await _secureStorage.read(key: _pinSaltKey);
    if (existingSalt != null) {
      return existingSalt;
    }
    
    // توليد Salt عشوائي (32 bytes)
    final saltBytes = utf8.encode(const Uuid().v4() + const Uuid().v4());
    final salt = base64Encode(saltBytes);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
    return salt;
  }
  
  /// Hash PIN باستخدام SHA-256 مع Salt
  Future<String> _hashPin(String pin, String salt) async {
    final combined = '$pin:$salt';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// تعيين Master PIN
  Future<bool> setMasterPin(String pin) async {
    try {
      if (pin.length < 4) {
        LogService.warning('PIN يجب أن يكون 4 أرقام على الأقل');
        return false;
      }
      
      final salt = await _generatePinSalt();
      final hash = await _hashPin(pin, salt);
      
      await _secureStorage.write(key: _masterPinHashKey, value: hash);
      LogService.info('تم تعيين Master PIN بنجاح');
      return true;
    } catch (e) {
      LogService.error('خطأ في تعيين Master PIN', e);
      return false;
    }
  }
  
  /// تعيين Duress PIN
  Future<bool> setDuressPin(String pin) async {
    try {
      if (pin.length < 4) {
        LogService.warning('PIN يجب أن يكون 4 أرقام على الأقل');
        return false;
      }
      
      final salt = await _generatePinSalt();
      final hash = await _hashPin(pin, salt);
      
      await _secureStorage.write(key: _duressPinHashKey, value: hash);
      LogService.info('تم تعيين Duress PIN بنجاح');
      return true;
    } catch (e) {
      LogService.error('خطأ في تعيين Duress PIN', e);
      return false;
    }
  }
  
  /// التحقق من PIN
  /// Returns: AuthType.master إذا تطابق Master PIN
  ///          AuthType.duress إذا تطابق Duress PIN
  ///          AuthType.failure إذا فشل
  Future<AuthType> verifyPin(String inputPin) async {
    try {
      final salt = await _generatePinSalt();
      final inputHash = await _hashPin(inputPin, salt);
      
      final masterPinHash = await _secureStorage.read(key: _masterPinHashKey);
      final duressPinHash = await _secureStorage.read(key: _duressPinHashKey);
      
      if (masterPinHash != null && inputHash == masterPinHash) {
        _currentAuthType = AuthType.master;
        await _secureStorage.write(key: _authTypeKey, value: 'master');
        LogService.info('تم التحقق من Master PIN بنجاح');
        return AuthType.master;
      }
      
      if (duressPinHash != null && inputHash == duressPinHash) {
        _currentAuthType = AuthType.duress;
        await _secureStorage.write(key: _authTypeKey, value: 'duress');
        LogService.info('تم التحقق من Duress PIN - تم تفعيل Duress Mode');
        return AuthType.duress;
      }
      
      LogService.warning('PIN غير صحيح');
      return AuthType.failure;
    } catch (e) {
      LogService.error('خطأ في التحقق من PIN', e);
      return AuthType.failure;
    }
  }
  
  /// التحقق من وجود PINs محفوظة
  Future<bool> hasMasterPin() async {
    final masterPinHash = await _secureStorage.read(key: _masterPinHashKey);
    return masterPinHash != null;
  }
  
  Future<bool> hasDuressPin() async {
    final duressPinHash = await _secureStorage.read(key: _duressPinHashKey);
    return duressPinHash != null;
  }
  
  /// إعادة تعيين نوع المصادقة (عند تسجيل الخروج)
  /// يجب استدعاؤها عند تسجيل الخروج أو إغلاق التطبيق
  void resetAuthType() async {
    _currentAuthType = null;
    await _secureStorage.delete(key: _authTypeKey);
    LogService.info('تم إعادة تعيين AuthType');
  }
}

