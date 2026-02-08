import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// إعدادات الثيم الرئيسية للتطبيق
/// Cyber-Stealth & Neo-Glass Aesthetic (2026 Design Trends)
/// High-tech, Secure, Immersive, Dark-Mode First
class AppTheme {
  AppTheme._();

  // Cyber-Stealth Color Palette
  static const Color _deepMidnightBlue = Color(0xFF050A14);
  static const Color _semiTransparentDarkBlue = Color(0xFF101A26);
  static const Color _electricCyan = Color(0xFF00E5FF);
  // static const Color _neonPurple = Color(0xFFD500F9);
  static const Color _fluorescentRed = Color(0xFFFF1744);

  // Font
  static final TextStyle _baseTextStyle = GoogleFonts.poppins();

  /// إنشاء الثيم الداكن (Cyber-Stealth)
  /// Dark-Mode First Design
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: _electricCyan,
      secondary: _electricCyan, // Unifying accent color
      error: _fluorescentRed,
      surface: _semiTransparentDarkBlue.withValues(alpha: 0.6),
      onSurface: Colors.white,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onError: Colors.white,
      surfaceContainerHighest: _semiTransparentDarkBlue.withValues(alpha: 0.8),
      surfaceContainerHigh: _semiTransparentDarkBlue.withValues(alpha: 0.7),
      surfaceContainer: _semiTransparentDarkBlue.withValues(alpha: 0.6),
      surfaceContainerLow: _semiTransparentDarkBlue.withValues(alpha: 0.5),
      surfaceContainerLowest: _semiTransparentDarkBlue.withValues(alpha: 0.4),
    ),

    // Scaffold Background
    scaffoldBackgroundColor: _deepMidnightBlue,

    // AppBar Theme (Transparent with blur)
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: _baseTextStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),

    // Card Theme (Glassmorphism)
    cardTheme: CardThemeData(
      color: _semiTransparentDarkBlue.withValues(alpha: 0.3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _electricCyan,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _electricCyan,
        side: const BorderSide(color: _electricCyan),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _electricCyan,
        textStyle: _baseTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _semiTransparentDarkBlue.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(
          color: _electricCyan,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.1),
      thickness: 1,
      space: 1,
    ),

    // Text Theme (Overridden with GoogleFonts.poppins)
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );

  /// إنشاء الثيم الفاتح (Fallback - لكن التصميم Dark-Mode First)
  static ThemeData lightTheme = darkTheme.copyWith(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _electricCyan,
      secondary: _electricCyan,
      error: _fluorescentRed,
      surface: Colors.white.withValues(alpha: 0.9),
      onSurface: Colors.black,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey.shade50,
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
  );
}
