import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/log_service.dart';

part 'locale_provider.g.dart';

/// Provider لإدارة اللغة الحالية
/// يدعم العربية والإنجليزية مع RTL تلقائي
/// يتعرف تلقائياً على لغة الجهاز عند أول تشغيل
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Future<Locale> build() async {
    return _loadLocale();
  }

  /// تحميل اللغة من SharedPreferences أو استخدام لغة الجهاز
  Future<Locale> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // التحقق من وجود اختيار سابق من المستخدم
      final savedLocaleCode = prefs.getString(AppConstants.keyLocale);
      
      if (savedLocaleCode != null) {
        // إذا كان المستخدم قد اختار لغة يدوياً، نستخدمها
        LogService.info('استخدام اللغة المحفوظة: $savedLocaleCode');
        return Locale(savedLocaleCode);
      }
      
      // إذا لم يكن هناك اختيار سابق، نستخدم لغة الجهاز
      final deviceLocale = _getDeviceLocale();
      LogService.info('استخدام لغة الجهاز: ${deviceLocale.languageCode}');
      
      // حفظ لغة الجهاز كاختيار افتراضي (للمرة الأولى فقط)
      await prefs.setString(AppConstants.keyLocale, deviceLocale.languageCode);
      
      return deviceLocale;
    } catch (e) {
      LogService.error('خطأ في تحميل اللغة', e);
      // في حالة الخطأ، نستخدم لغة الجهاز كبديل
      return _getDeviceLocale();
    }
  }

  /// الحصول على لغة الجهاز
  /// إذا كانت العربية → نستخدم العربية
  /// إذا كانت لغة أخرى → نستخدم الإنجليزية
  Locale _getDeviceLocale() {
    try {
      // الحصول على لغة الجهاز من النظام
      final deviceLocales = ui.PlatformDispatcher.instance.locales;
      
      if (deviceLocales.isNotEmpty) {
        final deviceLanguageCode = deviceLocales.first.languageCode.toLowerCase();
        
        // إذا كانت اللغة العربية، نستخدم العربية
        if (deviceLanguageCode == 'ar') {
          return const Locale('ar');
        }
      }
      
      // لأي لغة أخرى، نستخدم الإنجليزية
      return const Locale('en');
    } catch (e) {
      LogService.error('خطأ في الحصول على لغة الجهاز', e);
      // في حالة الخطأ، نستخدم الإنجليزية كبديل افتراضي
      return const Locale('en');
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

