import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// إعدادات الثيم الرئيسية للتطبيق
/// Cyber-Stealth Modern Design System
/// High-tech, Secure, Immersive, Dark-Mode First
class AppTheme {
  AppTheme._();

  /// إنشاء الثيم الداكن (Cyber-Stealth)
  /// Dark-Mode First Design
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.textPrimary,
      onError: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      surfaceContainerHigh: AppColors.surfaceVariant,
      surfaceContainer: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      surfaceContainerLowest: AppColors.background,
    ),

    // Scaffold Background
    scaffoldBackgroundColor: AppColors.background,

    // AppBar Theme (Transparent with blur)
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppDimensions.iconSizeMd,
      ),
      titleTextStyle: AppTypography.titleLarge(),
    ),

    // Card Theme (Glassmorphism)
    cardTheme: CardThemeData(
      color: AppColors.surface.withValues(alpha: 0.7),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: AppDimensions.borderWidth,
        ),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        minimumSize: const Size(0, AppDimensions.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        textStyle: AppTypography.buttonLarge(),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(0, AppDimensions.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        textStyle: AppTypography.buttonLarge(),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.buttonLarge(),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        borderSide: BorderSide(
          color: AppColors.border,
          width: AppDimensions.borderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        borderSide: BorderSide(
          color: AppColors.border,
          width: AppDimensions.borderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.borderWidthThick,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.paddingMd,
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: AppDimensions.iconSizeMd,
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: AppColors.divider,
      thickness: AppDimensions.dividerThickness,
      space: AppDimensions.spacingSm,
    ),

    // Text Theme
    // Note: Typography will use locale-aware fonts (Cairo for AR, Inter for EN)
    // The locale is detected automatically from platform when no context is available
    textTheme: TextTheme(
      displayLarge: AppTypography.headlineLarge(),
      displayMedium: AppTypography.headlineMedium(),
      displaySmall: AppTypography.headlineSmall(),
      headlineLarge: AppTypography.headlineLarge(),
      headlineMedium: AppTypography.headlineMedium(),
      headlineSmall: AppTypography.headlineSmall(),
      titleLarge: AppTypography.titleLarge(),
      titleMedium: AppTypography.titleMedium(),
      titleSmall: AppTypography.titleSmall(),
      bodyLarge: AppTypography.bodyLarge(),
      bodyMedium: AppTypography.bodyMedium(),
      bodySmall: AppTypography.bodySmall(),
      labelLarge: AppTypography.labelLarge(),
      labelMedium: AppTypography.labelMedium(),
      labelSmall: AppTypography.labelSmall(),
    ),
  );

  /// إنشاء الثيم الفاتح (Fallback - لكن التصميم Dark-Mode First)
  static ThemeData lightTheme = darkTheme.copyWith(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: Colors.white,
      onSurface: Colors.black,
      onPrimary: AppColors.onPrimary,
      onSecondary: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey.shade50,
    textTheme: TextTheme(
      displayLarge: AppTypography.headlineLarge().copyWith(color: Colors.black),
      displayMedium: AppTypography.headlineMedium().copyWith(color: Colors.black),
      displaySmall: AppTypography.headlineSmall().copyWith(color: Colors.black),
      headlineLarge: AppTypography.headlineLarge().copyWith(color: Colors.black),
      headlineMedium: AppTypography.headlineMedium().copyWith(color: Colors.black),
      headlineSmall: AppTypography.headlineSmall().copyWith(color: Colors.black),
      titleLarge: AppTypography.titleLarge().copyWith(color: Colors.black),
      titleMedium: AppTypography.titleMedium().copyWith(color: Colors.black),
      titleSmall: AppTypography.titleSmall().copyWith(color: Colors.black),
      bodyLarge: AppTypography.bodyLarge().copyWith(color: Colors.black87),
      bodyMedium: AppTypography.bodyMedium().copyWith(color: Colors.black87),
      bodySmall: AppTypography.bodySmall().copyWith(color: Colors.black87),
      labelLarge: AppTypography.labelLarge().copyWith(color: Colors.black),
      labelMedium: AppTypography.labelMedium().copyWith(color: Colors.black87),
      labelSmall: AppTypography.labelSmall().copyWith(color: Colors.black54),
    ),
  );
}

