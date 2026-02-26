import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/models/power_mode.dart';
import '../../../../core/services/power_mode_provider.dart';

/// شاشة الإعدادات
/// تسمح بتغيير الثيم واللغة مع الحفظ في SharedPreferences
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeModeAsync = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(localeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final localeNotifier = ref.read(localeNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 16.h,
          ),
          children: [
            // عنوان الشاشة
            Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Text(
                l10n.settings,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            
            // قسم الثيم
            themeModeAsync.when(
              data: (themeMode) => _buildSection(
                context,
                title: l10n.theme,
                children: [
                  // ignore: deprecated_member_use
                  // RadioGroup is not available in current Flutter version
                  RadioListTile<ThemeModeOption>(
                    title: Text(l10n.light),
                    value: ThemeModeOption.light,
                    // ignore: deprecated_member_use
                    groupValue: themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        themeNotifier.setThemeMode(value);
                      }
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<ThemeModeOption>(
                    title: Text(l10n.dark),
                    value: ThemeModeOption.dark,
                    // ignore: deprecated_member_use
                    groupValue: themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        themeNotifier.setThemeMode(value);
                      }
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<ThemeModeOption>(
                    title: Text(l10n.system),
                    value: ThemeModeOption.system,
                    // ignore: deprecated_member_use
                    groupValue: themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        themeNotifier.setThemeMode(value);
                      }
                    },
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text('خطأ في تحميل الثيم'),
            ),
            
            SizedBox(height: 24.h),
            
            // قسم اللغة
            localeAsync.when(
              data: (locale) => _buildSection(
                context,
                title: l10n.language,
                children: [
                  // ignore: deprecated_member_use
                  // RadioGroup is not available in current Flutter version
                  RadioListTile<String>(
                    title: Text(l10n.english),
                    value: 'en',
                    // ignore: deprecated_member_use
                    groupValue: locale.languageCode,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        localeNotifier.setLocale(Locale(value));
                      }
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: Text(l10n.arabic),
                    value: 'ar',
                    // ignore: deprecated_member_use
                    groupValue: locale.languageCode,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        localeNotifier.setLocale(Locale(value));
                      }
                    },
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text('خطأ في تحميل اللغة'),
            ),

            SizedBox(height: 24.h),

            // قسم استهلاك البطارية
            _buildPowerModeSection(context, ref, l10n),

            SizedBox(height: 24.h),

            // زر إلغاء تحسين البطارية
            _buildBatteryOptimizationButton(context, l10n),
          ],
        ),
      ),
    );
  }

  /// بناء قسم وضع استهلاك الطاقة
  Widget _buildPowerModeSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final powerMode = ref.watch(powerModeProvider);
    final powerModeNotifier = ref.read(powerModeProvider.notifier);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return _buildSection(
      context,
      title: l10n.powerUsage,
      children: [
        // ignore: deprecated_member_use
        // RadioGroup is not available in current Flutter version
        RadioListTile<PowerMode>(
          title: Text(
            isArabic
                ? PowerMode.highPerformance.getDisplayNameAr()
                : PowerMode.highPerformance.getDisplayNameEn(),
          ),
          subtitle: Text(
            isArabic
                ? PowerMode.highPerformance.getDescriptionAr()
                : PowerMode.highPerformance.getDescriptionEn(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          value: PowerMode.highPerformance,
          // ignore: deprecated_member_use
          groupValue: powerMode,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) {
              powerModeNotifier.setPowerMode(value);
            }
          },
        ),
        // ignore: deprecated_member_use
        RadioListTile<PowerMode>(
          title: Text(
            isArabic
                ? PowerMode.balanced.getDisplayNameAr()
                : PowerMode.balanced.getDisplayNameEn(),
          ),
          subtitle: Text(
            isArabic
                ? PowerMode.balanced.getDescriptionAr()
                : PowerMode.balanced.getDescriptionEn(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          value: PowerMode.balanced,
          // ignore: deprecated_member_use
          groupValue: powerMode,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) {
              powerModeNotifier.setPowerMode(value);
            }
          },
        ),
        // ignore: deprecated_member_use
        RadioListTile<PowerMode>(
          title: Text(
            isArabic
                ? PowerMode.lowPower.getDisplayNameAr()
                : PowerMode.lowPower.getDisplayNameEn(),
          ),
          subtitle: Text(
            isArabic
                ? PowerMode.lowPower.getDescriptionAr()
                : PowerMode.lowPower.getDescriptionEn(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          value: PowerMode.lowPower,
          // ignore: deprecated_member_use
          groupValue: powerMode,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) {
              powerModeNotifier.setPowerMode(value);
            }
          },
        ),
      ],
    );
  }

  /// بناء زر إلغاء تحسين البطارية
  Widget _buildBatteryOptimizationButton(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        leading: Icon(
          Icons.battery_saver_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.disableBatteryOptimization),
        subtitle: Text(
          l10n.batteryOptimizationDescription,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
        onTap: () async {
          // فتح إعدادات تحسين البطارية
          final opened = await openAppSettings();
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.couldNotOpenSettings),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

