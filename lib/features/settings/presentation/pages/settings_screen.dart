import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/router/routes.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/models/power_mode.dart';
import '../../../../core/services/power_mode_provider.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/settings_widgets.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/profile_service.dart';
import '../../../../core/services/app_share_service.dart';

/// شاشة الإعدادات المحدثة
/// تصميم Material 3 مع Grouped Cards
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
            horizontal: 16.w,
            vertical: 16.h,
          ),
          children: [
            // عنوان الشاشة
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 24.h),
              child: Text(
                l10n.settings,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            
            // Avatar Section
            _buildAvatarSection(context, ref),
            SizedBox(height: 32.h),

            // قسم المظهر
            themeModeAsync.when(
              data: (themeMode) => SettingsSection(
                title: l10n.appearance,
                children: [
                  _buildThemeModeTile(
                    context,
                    themeMode,
                    themeNotifier,
                    l10n,
                  ),
                  _buildLanguageTile(
                    context,
                    localeAsync,
                    localeNotifier,
                    l10n,
                  ),
                ],
              ),
              loading: () => SettingsSection(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.h),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
              error: (_, _) => SettingsSection(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text('خطأ في تحميل الإعدادات'),
                  ),
                ],
              ),
            ),

            // قسم الأداء
            SettingsSection(
              title: l10n.performance,
              children: [
                _buildPowerModeTile(context, ref, l10n),
                _buildBatteryOptimizationTile(context, l10n),
              ],
            ),

            // قسم الخصوصية والأمان
            SettingsSection(
              title: l10n.privacyAndSecurity,
              children: [
                _buildAppLockTile(context, ref, l10n),
                _buildChangeMasterPinTile(context, ref, l10n),
                _buildSetDuressPinTile(context, ref, l10n),
              ],
            ),

            // قسم حول التطبيق
            SettingsSection(
              title: l10n.aboutAndLegal,
              children: [
                SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: Colors.blue,
                  iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                  title: l10n.aboutUs,
                  onTap: () => context.push(AppRoutes.about),
                ),
                SettingsTile(
                  icon: Icons.share,
                  iconColor: Colors.teal,
                  iconBackgroundColor: Colors.teal.withValues(alpha: 0.1),
                  title: l10n.shareAppOffline,
                  subtitle: l10n.shareAppOfflineDescription,
                  onTap: () => _shareApp(context, ref),
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.purple,
                  iconBackgroundColor: Colors.purple.withValues(alpha: 0.1),
                  title: l10n.privacyPolicy,
                  onTap: () => context.push(AppRoutes.privacy),
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: Colors.orange,
                  iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
                  title: l10n.openSourceLicenses,
                  onTap: () => _showLicensePage(context),
                ),
              ],
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  /// بناء قسم Avatar
  Widget _buildAvatarSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(profileServiceProvider);
    final authService = ref.read(authServiceProvider.notifier);
    final currentUser = authService.currentUser;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(
                base64Image: profileState.avatarBase64,
                userName: currentUser?.displayName ?? 'User',
                radius: 60.r,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 3.w,
                    ),
                  ),
                  child: IconButton(
                    icon: profileState.isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                    onPressed: profileState.isLoading
                        ? null
                        : () async {
                            final profileService = ref.read(profileServiceProvider.notifier);
                            final success = await profileService.setAvatar();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'تم تحديث الصورة الشخصية'
                                        : 'فشل تحديث الصورة الشخصية',
                                  ),
                                  backgroundColor: success
                                      ? Colors.green
                                      : theme.colorScheme.error,
                                ),
                              );
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // User Name
          if (currentUser != null)
            Text(
              currentUser.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          SizedBox(height: 16.h),
          // Show My QR Button
          OutlinedButton.icon(
            onPressed: () {
              context.push(AppRoutes.myQr);
            },
            icon: Icon(Icons.qr_code, size: 18.sp),
            label: Text(l10n.myQrCode),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر وضع الثيم
  Widget _buildThemeModeTile(
    BuildContext context,
    ThemeModeOption currentMode,
    ThemeNotifier notifier,
    AppLocalizations l10n,
  ) {
    return SettingsTile(
      icon: Icons.palette_outlined,
      iconColor: Colors.pink,
      iconBackgroundColor: Colors.pink.withValues(alpha: 0.1),
      title: l10n.theme,
      trailing: SegmentedButton<ThemeModeOption>(
        segments: [
          ButtonSegment(
            value: ThemeModeOption.light,
            label: Text(l10n.light),
            icon: Icon(Icons.light_mode, size: 16.sp),
          ),
          ButtonSegment(
            value: ThemeModeOption.system,
            label: Text(l10n.system),
            icon: Icon(Icons.brightness_auto, size: 16.sp),
          ),
          ButtonSegment(
            value: ThemeModeOption.dark,
            label: Text(l10n.dark),
            icon: Icon(Icons.dark_mode, size: 16.sp),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (Set<ThemeModeOption> newSelection) {
          notifier.setThemeMode(newSelection.first);
        },
      ),
      showArrow: false,
    );
  }

  /// بناء عنصر اللغة
  Widget _buildLanguageTile(
    BuildContext context,
    AsyncValue<Locale> localeAsync,
    LocaleNotifier localeNotifier,
    AppLocalizations l10n,
  ) {
    return localeAsync.when(
      data: (locale) => SettingsTile(
        icon: Icons.language_outlined,
        iconColor: Colors.green,
        iconBackgroundColor: Colors.green.withValues(alpha: 0.1),
        title: l10n.language,
        trailing: SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'ar',
              label: Text(l10n.arabic),
            ),
            ButtonSegment(
              value: 'en',
              label: Text(l10n.english),
            ),
          ],
          selected: {locale.languageCode},
          onSelectionChanged: (Set<String> newSelection) {
            localeNotifier.setLocale(Locale(newSelection.first));
          },
        ),
        showArrow: false,
      ),
      loading: () => SettingsTile(
        icon: Icons.language_outlined,
        title: l10n.language,
        trailing: CircularProgressIndicator(),
        showArrow: false,
      ),
      error: (_, _) => SettingsTile(
        icon: Icons.language_outlined,
        title: l10n.language,
        trailing: Icon(Icons.error_outline),
        showArrow: false,
      ),
    );
  }

  /// بناء عنصر وضع الطاقة
  Widget _buildPowerModeTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final powerMode = ref.watch(powerModeProvider);
    final powerModeNotifier = ref.read(powerModeProvider.notifier);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    String getPowerModeName(PowerMode mode) {
      return isArabic ? mode.getDisplayNameAr() : mode.getDisplayNameEn();
    }

    return SettingsTile(
      icon: Icons.battery_charging_full_outlined,
      iconColor: Colors.amber,
      iconBackgroundColor: Colors.amber.withValues(alpha: 0.1),
      title: l10n.powerUsage,
      subtitle: getPowerModeName(powerMode),
      trailing: PopupMenuButton<PowerMode>(
        icon: Icon(Icons.arrow_drop_down),
        onSelected: (PowerMode mode) async {
          // تحديث الوضع
          await powerModeNotifier.setPowerMode(mode);
          
          // عرض رسالة نجاح
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic
                      ? 'تم تغيير وضع الطاقة إلى: ${mode.getDisplayNameAr()}'
                      : 'Power mode changed to: ${mode.getDisplayNameEn()}',
                ),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: PowerMode.highPerformance,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.speed,
                size: 20.sp,
                color: powerMode == PowerMode.highPerformance
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(getPowerModeName(PowerMode.highPerformance)),
              subtitle: Text(
                isArabic
                    ? PowerMode.highPerformance.getDescriptionAr()
                    : PowerMode.highPerformance.getDescriptionEn(),
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
          PopupMenuItem(
            value: PowerMode.balanced,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.balance,
                size: 20.sp,
                color: powerMode == PowerMode.balanced
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(getPowerModeName(PowerMode.balanced)),
              subtitle: Text(
                isArabic
                    ? PowerMode.balanced.getDescriptionAr()
                    : PowerMode.balanced.getDescriptionEn(),
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
          PopupMenuItem(
            value: PowerMode.lowPower,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.battery_saver,
                size: 20.sp,
                color: powerMode == PowerMode.lowPower
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(getPowerModeName(PowerMode.lowPower)),
              subtitle: Text(
                isArabic
                    ? PowerMode.lowPower.getDescriptionAr()
                    : PowerMode.lowPower.getDescriptionEn(),
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
        ],
      ),
      showArrow: false,
    );
  }

  /// بناء عنصر إلغاء تحسين البطارية
  Widget _buildBatteryOptimizationTile(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return SettingsTile(
      icon: Icons.battery_saver_outlined,
      iconColor: Colors.red,
      iconBackgroundColor: Colors.red.withValues(alpha: 0.1),
      title: l10n.disableBatteryOptimization,
      subtitle: l10n.batteryOptimizationDescription,
      onTap: () async {
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
    );
  }

  /// بناء عنصر قفل التطبيق
  Widget _buildAppLockTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final biometricState = ref.watch(biometricServiceProvider);
    final biometricService = ref.read(biometricServiceProvider.notifier);

    // إذا لم تكن البصمة متاحة، لا نعرض الخيار
    if (!biometricState.isAvailable) {
      return SettingsTile(
        icon: Icons.fingerprint_outlined,
        iconColor: Colors.grey,
        iconBackgroundColor: Colors.grey.withValues(alpha: 0.1),
        title: l10n.appLock,
        subtitle: l10n.biometricNotAvailable,
        showArrow: false,
      );
    }

    return SettingsSwitchTile(
      icon: Icons.fingerprint,
      iconColor: Colors.indigo,
      iconBackgroundColor: Colors.indigo.withValues(alpha: 0.1),
      title: l10n.appLock,
      subtitle: l10n.appLockDescription,
      value: biometricState.isAppLockEnabled,
      onChanged: (value) async {
        final success = await biometricService.toggleAppLock(value);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToChangeLock),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  /// بناء عنصر تغيير Master PIN
  Widget _buildChangeMasterPinTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return SettingsTile(
      icon: Icons.lock,
      iconColor: Colors.blue,
      iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
      title: l10n.changeMasterPin,
      onTap: () => _showChangePinDialog(context, ref, l10n, isMaster: true),
    );
  }

  /// بناء عنصر تعيين Duress PIN
  Widget _buildSetDuressPinTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return SettingsTile(
      icon: Icons.security,
      iconColor: Colors.red,
      iconBackgroundColor: Colors.red.withValues(alpha: 0.1),
      title: l10n.setDuressPin,
      onTap: () => _showSetDuressPinDialog(context, ref, l10n),
    );
  }

  /// عرض حوار تغيير PIN
  Future<void> _showChangePinDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required bool isMaster,
  }) async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMaster ? l10n.changeMasterPin : l10n.setDuressPin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: InputDecoration(
                labelText: isMaster ? l10n.enterMasterPin : l10n.enterDuressPin,
                hintText: '••••••',
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: confirmPinController,
              decoration: InputDecoration(
                labelText: l10n.confirmPin,
                hintText: '••••••',
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == confirmPinController.text &&
                  pinController.text.length >= 4) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pinMismatch),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == true) {
      final authService = ref.read(authServiceProvider.notifier);
      final success = isMaster
          ? await authService.setMasterPin(pinController.text)
          : await authService.setDuressPin(pinController.text);
      
      pinController.dispose();
      confirmPinController.dispose();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (isMaster ? l10n.pinChangedSuccessfully : l10n.pinSetSuccessfully)
                  : 'فشل تعيين PIN',
            ),
            backgroundColor:
                success ? Colors.green : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// عرض حوار تعيين Duress PIN مع تحذير
  Future<void> _showSetDuressPinDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    // عرض تحذير أولاً
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ تحذير'),
        content: Text(l10n.duressPinWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('متابعة'),
          ),
        ],
      ),
    );

    if (proceed == true && context.mounted) {
      await _showChangePinDialog(context, ref, l10n, isMaster: false);
    }
  }

  /// عرض صفحة التراخيص
  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Sada',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/images/logo.png',
        width: 48.w,
        height: 48.h,
      ),
    );
  }

  /// مشاركة التطبيق
  Future<void> _shareApp(BuildContext context, WidgetRef ref) async {
    final appShareService = AppShareService();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // عرض مؤشر التحميل
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(l10n.preparingApk),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await appShareService.shareApk();

      if (!context.mounted) return;
      
      Navigator.of(context).pop(); // إغلاق dialog التحميل

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? l10n.apkShareSuccess
                : l10n.apkShareError,
          ),
          backgroundColor: success ? Colors.green : theme.colorScheme.error,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      Navigator.of(context).pop(); // إغلاق dialog التحميل
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.apkShareError),
          backgroundColor: theme.colorScheme.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

