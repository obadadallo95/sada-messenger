import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// نظام الخطوط الجديد
/// يستخدم Cairo للعربي و Inter للإنجليزي
class AppTypography {
  AppTypography._();

  /// الحصول على الخط المناسب حسب اللغة
  static TextStyle _getFontStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required double height,
    BuildContext? context,
  }) {
    // تحديد اللغة من context إذا كان متوفراً، وإلا من platform
    Locale? locale;
    if (context != null) {
      try {
        locale = Localizations.localeOf(context);
      } catch (e) {
        // إذا فشل، نستخدم platform locale
        locale = null;
      }
    }
    
    final isArabic = locale?.languageCode == 'ar' || 
                     (locale == null && 
                      WidgetsBinding.instance.platformDispatcher.locales.isNotEmpty &&
                      WidgetsBinding.instance.platformDispatcher.locales.first.languageCode == 'ar');
    
    final baseStyle = isArabic 
        ? GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
          )
        : GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
          );
    
    return baseStyle.copyWith(color: color);
  }

  // ==================== للعناوين الكبيرة (Bold) ====================
  
  static TextStyle headlineLarge([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: const Color(0xFFFFFFFF),
    height: 1.2,
  );

  static TextStyle headlineMedium([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: const Color(0xFFFFFFFF),
    height: 1.3,
  );

  static TextStyle headlineSmall([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
    color: const Color(0xFFFFFFFF),
    height: 1.3,
  );

  // ==================== للعناوين الفرعية (Semi-bold) ====================
  
  static TextStyle titleLarge([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFFFFFFF),
    height: 1.4,
  );

  static TextStyle titleMedium([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFFFFFFF),
    height: 1.4,
  );

  static TextStyle titleSmall([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFFFFFFF),
    height: 1.4,
  );

  // ==================== للنصوص العادية (Regular) ====================
  
  static TextStyle bodyLarge([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: const Color(0xFF94A3B8),
    height: 1.5,
  );

  static TextStyle bodyMedium([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: const Color(0xFF94A3B8),
    height: 1.5,
  );

  static TextStyle bodySmall([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: const Color(0xFF94A3B8),
    height: 1.5,
  );

  // ==================== للتسميات الصغيرة (Medium) ====================
  
  static TextStyle labelLarge([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFFFFFFFF),
    height: 1.4,
  );

  static TextStyle labelMedium([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF94A3B8),
    height: 1.4,
  );

  static TextStyle labelSmall([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF64748B),
    height: 1.4,
  );

  // ==================== أزرار (Semi-bold) ====================
  
  static TextStyle buttonLarge([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF000000),
    height: 1.4,
  ).copyWith(letterSpacing: 0.5);

  static TextStyle buttonMedium([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF000000),
    height: 1.4,
  ).copyWith(letterSpacing: 0.5);

  static TextStyle buttonSmall([BuildContext? context]) => _getFontStyle(
    context: context,
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF000000),
    height: 1.4,
  ).copyWith(letterSpacing: 0.5);

  // ==================== Helpers ====================
  
  /// الحصول على TextStyle مع لون مخصص
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// الحصول على TextStyle مع opacity
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }
}

