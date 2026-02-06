import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/log_service.dart';

part 'locale_provider.g.dart';

/// Provider لإدارة اللغة الحالية
/// يدعم العربية والإنجليزية مع RTL تلقائي
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Future<Locale> build() async {
    return _loadLocale();
  }

  /// تحميل اللغة من SharedPreferences
  Future<Locale> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(AppConstants.keyLocale) ??
          AppConstants.defaultLocale;
      
      return Locale(localeCode);
    } catch (e) {
      LogService.error('خطأ في تحميل اللغة', e);
      return const Locale(AppConstants.defaultLocale);
    }
  }

  /// تغيير اللغة وحفظها
  Future<void> setLocale(Locale locale) async {
    try {
      state = AsyncValue.data(locale);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLocale, locale.languageCode);
      LogService.info('تم تغيير اللغة إلى: ${locale.languageCode}');
    } catch (e) {
      LogService.error('خطأ في حفظ اللغة', e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// التبديل بين العربية والإنجليزية
  Future<void> toggleLocale() async {
    final currentLocale = await future;
    final newLocale = currentLocale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(newLocale);
  }
}

