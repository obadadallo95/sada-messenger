import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// إعدادات الثيم الرئيسية للتطبيق
/// يستخدم FlexColorScheme لإنشاء ثيم حديث ونظيف
class AppTheme {
  AppTheme._();

  /// إنشاء الثيم الفاتح
  static ThemeData lightTheme = FlexThemeData.light(
    scheme: FlexScheme.tealM3,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    fontFamily: 'Roboto',
  );

  /// إنشاء الثيم الداكن
  static ThemeData darkTheme = FlexThemeData.dark(
    scheme: FlexScheme.tealM3,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    fontFamily: 'Roboto',
  );
}

