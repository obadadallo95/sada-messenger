/// ملف الثوابت العامة للتطبيق
/// يحتوي على القيم الثابتة المستخدمة في جميع أنحاء التطبيق
class AppConstants {
  AppConstants._();

  // مفاتيح SharedPreferences
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';

  // قيم الوضع الافتراضي
  static const String defaultLocale = 'en';
  static const String defaultThemeMode = 'system';

  // ==================== Relay / DTN Constants ====================

  /// الحد الأقصى لعدد الحزم المخزنة في Relay Queue لكل جهاز.
  /// هذا حد عددي مبدئي لمنع امتلاء التخزين (يمكن ضبطه لاحقاً أو استبداله بحساب حجمي بالـ MB).
  static const int relayQueueMaxCount = 5000;
}

