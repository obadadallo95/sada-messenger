import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/log_service.dart';

part 'onboarding_repository.g.dart';

/// Repository لإدارة حالة Onboarding
/// يحفظ حالة إكمال Onboarding في SharedPreferences
@riverpod
class OnboardingRepository extends _$OnboardingRepository {
  static const String _onboardingCompleteKey = 'is_onboarding_complete';

  @override
  Future<bool> build() async {
    return _loadOnboardingStatus();
  }

  /// تحميل حالة Onboarding من SharedPreferences
  Future<bool> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      LogService.error('خطأ في تحميل حالة Onboarding', e);
      return false;
    }
  }

  /// تعيين Onboarding كمكتمل
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      state = AsyncValue.data(true);
      LogService.info('تم إكمال Onboarding');
    } catch (e) {
      LogService.error('خطأ في حفظ حالة Onboarding', e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// إعادة تعيين حالة Onboarding (للتطوير/الاختبار)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, false);
      state = AsyncValue.data(false);
      LogService.info('تم إعادة تعيين Onboarding');
    } catch (e) {
      LogService.error('خطأ في إعادة تعيين Onboarding', e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

