import 'package:flutter/material.dart';

/// لوحة الألوان الجديدة - Cyber-Stealth Modern
/// يعكس الأمان والخصوصية والتقنية اللامركزية
class AppColors {
  AppColors._();

  // ==================== الخلفيات (Backgrounds) ====================
  static const Color background = Color(0xFF050505);        // أسود مطفي
  static const Color surface = Color(0xFF0F1419);          // سطح بطبقة أولى
  static const Color surfaceVariant = Color(0xFF1A1F2E);   // سطح بطبقة ثانية
  static const Color cardBackground = Color(0xFF151921);   // خلفية الكاردات

  // ==================== الألوان الرئيسية (Primary) ====================
  static const Color primary = Color(0xFF00E5CC);          // سماوي نيون
  static const Color primaryContainer = Color(0xFF00332C); // حاوية أغمق
  static const Color onPrimary = Color(0xFF000000);        // نص على primary

  // ==================== الألوان الثانوية (Secondary) ====================
  static const Color secondary = Color(0xFF7C3AED);        // بنفسجي
  static const Color secondaryContainer = Color(0xFF2E1065);

  // ==================== حالات الألوان (State Colors) ====================
  static const Color success = Color(0xFF10B981);          // أخضر
  static const Color warning = Color(0xFFF59E0B);          // برتقالي
  static const Color error = Color(0xFFEF4444);            // أحمر
  static const Color info = Color(0xFF3B82F6);             // أزرق

  // ==================== النصوص (Typography) ====================
  static const Color textPrimary = Color(0xFFFFFFFF);      // أبيض
  static const Color textSecondary = Color(0xFF94A3B8);    // رمادي فاتح
  static const Color textTertiary = Color(0xFF64748B);     // رمادي أغمق
  static const Color textDisabled = Color(0xFF475569);     // معطل

  // ==================== الحدود والفواصل ====================
  static const Color border = Color(0xFF1E293B);           // حدود خفيفة
  static const Color divider = Color(0xFF1E293B);          // فواصل
  static const Color outline = Color(0xFF334155);          // outlines

  // ==================== تأثيرات خاصة (Mesh Network Visualization) ====================
  static const Color meshNode = Color(0xFF00E5CC);         // عقد الشبكة
  static const Color meshConnection = Color(0x3300E5CC);   // خطوط الشبكة شفافة
  static const Color pulseEffect = Color(0x6600E5CC);     // تأثير النبض

  // ==================== Helpers ====================
  
  /// الحصول على لون الخلفية حسب الثيم
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? background
        : Colors.grey.shade50;
  }

  /// الحصول على لون السطح حسب الثيم
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surface
        : Colors.white;
  }
}

