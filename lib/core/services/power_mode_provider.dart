import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/power_mode.dart';
import '../utils/log_service.dart';
import 'background_service.dart';

/// Provider لإدارة وضع استهلاك الطاقة
final powerModeProvider = StateNotifierProvider<PowerModeNotifier, PowerMode>(
  (ref) => PowerModeNotifier(),
);

/// StateNotifier لإدارة وضع الطاقة
class PowerModeNotifier extends StateNotifier<PowerMode> {
  static const String _storageKey = 'power_mode';

  PowerModeNotifier() : super(PowerMode.balanced) {
    _loadPowerMode();
  }

  /// تحميل وضع الطاقة من SharedPreferences
  Future<void> _loadPowerMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString(_storageKey);
      
      if (storedValue != null) {
        state = PowerModeExtension.fromStorageString(storedValue);
        LogService.info('تم تحميل وضع الطاقة: ${state.toStorageString()}');
      } else {
        // القيمة الافتراضية
        state = PowerMode.balanced;
        await _savePowerMode();
      }
    } catch (e) {
      LogService.error('خطأ في تحميل وضع الطاقة', e);
      state = PowerMode.balanced;
    }
  }

  /// حفظ وضع الطاقة في SharedPreferences
  Future<void> _savePowerMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, state.toStorageString());
      LogService.info('تم حفظ وضع الطاقة: ${state.toStorageString()}');
    } catch (e) {
      LogService.error('خطأ في حفظ وضع الطاقة', e);
    }
  }

  /// تغيير وضع الطاقة
  Future<void> setPowerMode(PowerMode mode) async {
    if (state == mode) return;
    
    state = mode;
    await _savePowerMode();
    LogService.info('تم تغيير وضع الطاقة إلى: ${mode.toStorageString()}');
    
    // إشعار Background Service بالتغيير
    try {
      BackgroundService.instance.updatePowerMode(mode);
    } catch (e) {
      LogService.warning('تعذر تحديث Background Service: $e');
    }
  }
}

