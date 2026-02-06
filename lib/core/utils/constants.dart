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
}

