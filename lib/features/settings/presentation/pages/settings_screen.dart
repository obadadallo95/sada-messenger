import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/glass_card.dart';
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            // عنوان الشاشة
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 24.h),
              child: Text(
                l10n.settings,
                style: AppTypography.headlineMedium(context),
              ),
            ),

            // Avatar Section
            _buildAvatarSection(context, ref),
            SizedBox(height: AppDimensions.spacingXl),
            _buildDuressQuickSetupCard(context, ref, l10n),
            SizedBox(height: AppDimensions.spacingLg),

            // قسم المظهر - GlassCard
            themeModeAsync.when(
              data: (themeMode) => GlassCard(
                margin: EdgeInsets.only(bottom: AppDimensions.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: AppDimensions.paddingMd),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppDimensions.paddingSm),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                            ),
                            child: Icon(
                              Icons.palette_outlined,
                              color: AppColors.primary,
                              size: AppDimensions.iconSizeMd,
                            ),
                          ),
                          SizedBox(width: AppDimensions.spacingMd),
                          Flexible(
                            child: Text(
                              l10n.appearance,
                              style: AppTypography.titleMedium(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildThemeModeTile(
                      context,
                      themeMode,
                      themeNotifier,
                      l10n,
                    ),
                    Divider(height: AppDimensions.spacingLg),
                    _buildLanguageTile(
                      context,
                      localeAsync,
                      localeNotifier,
                      l10n,
                    ),
                  ],
                ),
              ),
              loading: () => GlassCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.paddingXl),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (_, _) => GlassCard(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingMd),
                  child: Text('خطأ في تحميل الإعدادات'),
                ),
              ),
            ),

            // قسم الأمان - GlassCard
            GlassCard(
              margin: EdgeInsets.only(bottom: AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.paddingMd),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppDimensions.paddingSm),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Icon(
                            Icons.security,
                            color: AppColors.error,
                            size: AppDimensions.iconSizeMd,
                          ),
                        ),
                        SizedBox(width: AppDimensions.spacingMd),
                        Flexible(
                          child: Text(
                            l10n.privacyAndSecurity,
                            style: AppTypography.titleMedium(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildAppLockTile(context, ref, l10n),
                  Divider(height: AppDimensions.spacingLg),
                  _buildChangeMasterPinTile(context, ref, l10n),
                  Divider(height: AppDimensions.spacingLg),
                  _buildSetDuressPinTile(context, ref, l10n),
                ],
              ),
            ),

            // قسم الشبكة - GlassCard
            GlassCard(
              margin: EdgeInsets.only(bottom: AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.paddingMd),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppDimensions.paddingSm),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Icon(
                            Icons.wifi,
                            color: AppColors.info,
                            size: AppDimensions.iconSizeMd,
                          ),
                        ),
                        SizedBox(width: AppDimensions.spacingMd),
                        Flexible(
                          child: Text(
                            l10n.performance,
                            style: AppTypography.titleMedium(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPowerModeTile(context, ref, l10n),
                  Divider(height: AppDimensions.spacingLg),
                  _buildBatteryOptimizationTile(context, l10n),
                  Divider(height: AppDimensions.spacingLg),
                  _buildBatteryGuideTile(context, l10n),
                  Divider(height: AppDimensions.spacingLg),
                  SettingsTile(
                    icon: Icons.bug_report_outlined,
                    iconColor: Colors.deepPurple,
                    iconBackgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                    title: 'Mesh Debug',
                    subtitle: 'View connection status & logs',
                    onTap: () => context.push(AppRoutes.meshDebug),
                  ),
                ],
              ),
            ),

            // قسم حول التطبيق - GlassCard
            GlassCard(
              margin: EdgeInsets.only(bottom: AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.paddingMd),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppDimensions.paddingSm),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: AppColors.secondary,
                            size: AppDimensions.iconSizeMd,
                          ),
                        ),
                        SizedBox(width: AppDimensions.spacingMd),
                        Flexible(
                          child: Text(
                            l10n.aboutAndLegal,
                            style: AppTypography.titleMedium(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.info_outline,
                    iconColor: Colors.blue,
                    iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                    title: l10n.aboutUs,
                    onTap: () => context.push(AppRoutes.about),
                  ),
                  Divider(height: AppDimensions.spacingLg),
                  SettingsTile(
                    icon: Icons.share,
                    iconColor: Colors.teal,
                    iconBackgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: l10n.shareAppOffline,
                    subtitle: l10n.shareAppOfflineDescription,
                    onTap: () => _shareApp(context, ref),
                  ),
                  Divider(height: AppDimensions.spacingLg),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.purple,
                    iconBackgroundColor: Colors.purple.withValues(alpha: 0.1),
                    title: l10n.privacyPolicy,
                    onTap: () => context.push(AppRoutes.privacy),
                  ),
                  Divider(height: AppDimensions.spacingLg),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    iconColor: Colors.orange,
                    iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
                    title: l10n.openSourceLicenses,
                    onTap: () => _showLicensePage(context),
                  ),
                ],
              ),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(Icons.edit, color: Colors.white, size: 20.sp),
                    onPressed: profileState.isLoading
                        ? null
                        : () async {
                            final profileService = ref.read(
                              profileServiceProvider.notifier,
                            );
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
              style: AppTypography.titleLarge(context).copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
            ButtonSegment(value: 'ar', label: Text(l10n.arabic)),
            ButtonSegment(value: 'en', label: Text(l10n.english)),
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

  /// بناء عنصر دليل تحسين البطارية
  Widget _buildBatteryGuideTile(BuildContext context, AppLocalizations l10n) {
    return SettingsTile(
      icon: Icons.tips_and_updates_outlined,
      iconColor: Colors.orange,
      iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
      title: Localizations.localeOf(context).languageCode == 'ar'
          ? 'دليل تحسين الأداء'
          : 'Performance Guide',
      subtitle: Localizations.localeOf(context).languageCode == 'ar'
          ? 'كيف تحافظ على اتصال الشبكة مستقراً'
          : 'How to keep mesh connection stable',
      onTap: () => _showBatteryGuideDialog(context),
    );
  }

  /// عرض حوار دليل البطارية
  void _showBatteryGuideDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.tips_and_updates, color: Colors.orange),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                isArabic ? 'نصائح لشبكة مستقرة' : 'Stable Mesh Tips',
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideItem(
                context,
                icon: Icons.history,
                title: isArabic ? 'لا تغلق التطبيق' : 'Don\'t Kill the App',
                description: isArabic
                    ? 'لتعمل الشبكة، يجب أن يبقى التطبيق في الخلفية. لا تقم بإزالته من قائمة "التطبيقات الحديثة" (Recent Apps).'
                    : 'For the mesh to work, the app must stay in the background. Do not swipe it away from Recent Apps.',
              ),
              SizedBox(height: 16.h),
              _buildGuideItem(
                context,
                icon: Icons.battery_alert,
                title: isArabic
                    ? 'تعطيل تحسين البطارية'
                    : 'Disable Battery Optimization',
                description: isArabic
                    ? 'تأكد من استثناء التطبيق من "تحسين البطارية" في إعدادات النظام لضمان عدم قتل النظام للخدمة.'
                    : 'Ensure the app is excluded from "Battery Optimization" in system settings so the OS doesn\'t kill the service.',
              ),
              SizedBox(height: 16.h),
              _buildGuideItem(
                context,
                icon: Icons.speed,
                title: isArabic ? 'اختر الوضع المناسب' : 'Choose Right Mode',
                description: isArabic
                    ? 'استخدم "أداء عالي" للمحادثات النشطة الفورية، و"متوازن" لتوفير البطارية مع استقبال الرسائل بتأخير بسيط.'
                    : 'Use "High Performance" for instant active chats, and "Balanced" to save battery with slight delay in receiving messages.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isArabic ? 'حسناً' : 'Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24.sp, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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

  /// بطاقة بارزة لإعداد Duress PIN بسرعة.
  Widget _buildDuressQuickSetupCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.35),
          ),
        ),
        padding: EdgeInsets.all(AppDimensions.paddingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.shield_outlined,
              color: theme.colorScheme.error,
              size: AppDimensions.iconSizeLg,
            ),
            SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.setDuressPin,
                    style: AppTypography.titleSmall(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    l10n.duressPinWarning,
                    style: AppTypography.bodySmall(
                      context,
                    ).copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showSetDuressPinDialog(context, ref, l10n),
                    icon: const Icon(Icons.lock_open),
                    label: Text(l10n.setDuressPin),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                  ? (isMaster
                        ? l10n.pinChangedSuccessfully
                        : l10n.pinSetSuccessfully)
                  : 'فشل تعيين PIN',
            ),
            backgroundColor: success
                ? Colors.green
                : Theme.of(context).colorScheme.error,
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
    final l10n = AppLocalizations.of(context)!;
    showLicensePage(
      context: context,
      applicationName: l10n.appName,
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
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  l10n.preparingApk,
                  style: AppTypography.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await appShareService.shareApk();

      if (!context.mounted) return;

      // إغلاق dialog التحميل إذا كان مفتوحاً
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.apkShareSuccess : l10n.apkShareError),
          backgroundColor: success ? Colors.green : theme.colorScheme.error,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // إغلاق dialog التحميل إذا كان مفتوحاً
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

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
