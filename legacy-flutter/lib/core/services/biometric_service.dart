import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/log_service.dart';

/// Provider لخدمة البصمة
final biometricServiceProvider =
    StateNotifierProvider<BiometricService, BiometricState>(
  (ref) => BiometricService(),
);

/// حالة خدمة البصمة
class BiometricState {
  final bool isAppLockEnabled;
  final bool isAvailable;
  final List<BiometricType> availableTypes;

  BiometricState({
    required this.isAppLockEnabled,
    required this.isAvailable,
    required this.availableTypes,
  });

  BiometricState copyWith({
    bool? isAppLockEnabled,
    bool? isAvailable,
    List<BiometricType>? availableTypes,
  }) {
    return BiometricState(
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isAvailable: isAvailable ?? this.isAvailable,
      availableTypes: availableTypes ?? this.availableTypes,
    );
  }
}

/// خدمة البصمة
/// تتعامل مع المصادقة البيومترية وقفل التطبيق
class BiometricService extends StateNotifier<BiometricState> {
  static const String _prefKey = 'is_app_lock_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();

  BiometricService()
      : super(BiometricState(
          isAppLockEnabled: false,
          isAvailable: false,
          availableTypes: [],
        )) {
    _initialize();
  }

  /// تهيئة الخدمة
  Future<void> _initialize() async {
    try {
      // تحميل حالة القفل
      final prefs = await SharedPreferences.getInstance();
      final isLockEnabled = prefs.getBool(_prefKey) ?? false;

      // التحقق من توفر البصمة
      final isAvailable = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      // الحصول على أنواع البصمة المتاحة
      List<BiometricType> availableTypes = [];
      if (isAvailable) {
        try {
          availableTypes = await _localAuth.getAvailableBiometrics();
        } catch (e) {
          LogService.warning('خطأ في الحصول على أنواع البصمة: $e');
        }
      }

      state = state.copyWith(
        isAppLockEnabled: isLockEnabled,
        isAvailable: isAvailable,
        availableTypes: availableTypes,
      );

      LogService.info(
        'تم تهيئة خدمة البصمة - متاحة: $isAvailable, مفعلة: $isLockEnabled',
      );
    } catch (e) {
      LogService.error('خطأ في تهيئة خدمة البصمة', e);
    }
  }

  /// التحقق من توفر البصمة
  bool get isAvailable => state.isAvailable;

  /// الحصول على أنواع البصمة المتاحة
  List<BiometricType> get availableBiometrics => state.availableTypes;

  /// تفعيل/إلغاء تفعيل قفل التطبيق
  /// يتطلب مصادقة قبل التغيير
  Future<bool> toggleAppLock(bool enable) async {
    try {
      // التحقق من توفر البصمة أولاً
      if (!state.isAvailable) {
        LogService.warning('البصمة غير متاحة على هذا الجهاز');
        return false;
      }

      // طلب المصادقة قبل التغيير
      final authenticated = await authenticate(
        reason: enable
            ? 'Scan your fingerprint to enable app lock'
            : 'Scan your fingerprint to disable app lock',
      );

      if (!authenticated) {
        LogService.info('فشلت المصادقة - تم إلغاء التغيير');
        return false;
      }

      // حفظ الحالة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enable);

      state = state.copyWith(isAppLockEnabled: enable);

      LogService.info('تم ${enable ? 'تفعيل' : 'إلغاء تفعيل'} قفل التطبيق');
      return true;
    } catch (e) {
      LogService.error('خطأ في تغيير حالة قفل التطبيق', e);
      return false;
    }
  }

  /// المصادقة البيومترية
  /// [reason]: السبب المعروض للمستخدم
  Future<bool> authenticate({String? reason}) async {
    try {
      if (!state.isAvailable) {
        LogService.warning('البصمة غير متاحة');
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: reason ??
            'Scan your fingerprint to enter Sada',
      );

      if (result) {
        LogService.info('تمت المصادقة بنجاح');
      } else {
        LogService.info('تم إلغاء المصادقة');
      }

      return result;
    } on PlatformException catch (e) {
      LogService.error('خطأ في المصادقة البيومترية', e);
      return false;
    } catch (e) {
      LogService.error('خطأ غير متوقع في المصادقة', e);
      return false;
    }
  }

  /// التحقق من حالة قفل التطبيق
  bool get isAppLockEnabled => state.isAppLockEnabled;
}

