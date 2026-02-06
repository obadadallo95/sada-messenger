import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/log_service.dart';
import 'app_theme.dart';

part 'theme_provider.g.dart';

/// وضع الثيم الممكن: فاتح، داكن، أو تلقائي
enum ThemeModeOption {
  light,
  dark,
  system,
}

/// Provider لإدارة وضع الثيم
/// يحفظ التفضيلات في SharedPreferences
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Future<ThemeModeOption> build() async {
    return _loadThemeMode();
  }

  /// تحميل وضع الثيم من SharedPreferences
  Future<ThemeModeOption> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(AppConstants.keyThemeMode) ??
          AppConstants.defaultThemeMode;
      
      return ThemeModeOption.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeModeOption.system,
      );
    } catch (e) {
      LogService.error('خطأ في تحميل وضع الثيم', e);
      return ThemeModeOption.system;
    }
  }

  /// تغيير وضع الثيم وحفظه
  Future<void> setThemeMode(ThemeModeOption mode) async {
    try {
      state = AsyncValue.data(mode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyThemeMode, mode.name);
      LogService.info('تم تغيير وضع الثيم إلى: ${mode.name}');
    } catch (e) {
      LogService.error('خطأ في حفظ وضع الثيم', e);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// الحصول على ThemeMode من Flutter
  ThemeMode getThemeMode() {
    return state.maybeWhen(
      data: (mode) {
        switch (mode) {
          case ThemeModeOption.light:
            return ThemeMode.light;
          case ThemeModeOption.dark:
            return ThemeMode.dark;
          case ThemeModeOption.system:
            return ThemeMode.system;
        }
      },
      orElse: () => ThemeMode.system,
    );
  }
}

/// Provider للحصول على الثيم الحالي
@riverpod
ThemeData theme(Ref ref) {
  final themeModeAsync = ref.watch(themeNotifierProvider);
  return themeModeAsync.when(
    data: (mode) {
      final isLight = mode == ThemeModeOption.light;
      return isLight ? AppTheme.lightTheme : AppTheme.darkTheme;
    },
    loading: () => AppTheme.lightTheme,
    error: (_, _) => AppTheme.lightTheme,
  );
}

