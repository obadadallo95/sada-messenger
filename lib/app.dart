import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/notification_service.dart';
import 'core/security/security_providers.dart';
import 'core/utils/log_service.dart';

/// نقطة دخول التطبيق الرئيسية
/// تهيئة جميع الخدمات الأساسية والـ Providers
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// تهيئة الخدمات الأساسية
  Future<void> _initializeServices() async {
    // تهيئة خدمة الإشعارات
    final notificationService = NotificationService();
    final initialized = await notificationService.initialize();
    
    if (initialized) {
      // طلب الصلاحيات
      await notificationService.requestPermissions();
      
      LogService.info('تم تهيئة خدمة الإشعارات');
    } else {
      LogService.warning('فشل تهيئة خدمة الإشعارات');
    }

    // تهيئة خدمات التشفير
    try {
      final keyManager = ref.read(keyManagerProvider);
      await keyManager.initialize();
      
      final encryptionService = ref.read(encryptionServiceProvider);
      await encryptionService.initialize();
      
      LogService.info('تم تهيئة خدمات التشفير');
    } catch (e) {
      LogService.error('خطأ في تهيئة خدمات التشفير', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(themeProvider);
    final themeModeAsync = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(localeNotifierProvider);

    // ربط GoRouter بخدمة الإشعارات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = NotificationService();
      notificationService.setRouter(router);
    });

    LogService.info('تم تهيئة التطبيق');

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return themeModeAsync.when(
          data: (themeMode) {
            return localeAsync.when(
              data: (locale) {
                return MaterialApp.router(
                  title: 'Sada',
                  debugShowCheckedModeBanner: false,
                  
                  // الثيم
                  theme: theme,
                  darkTheme: theme,
                  themeMode: ref.read(themeNotifierProvider.notifier).getThemeMode(),
                  
                  // الترجمة
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: locale,
                  
                  // التوجيه
                  routerConfig: router,
                );
              },
              loading: () => MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, _) => MaterialApp(
                home: Scaffold(
                  body: Center(child: Text('خطأ في تحميل اللغة')),
                ),
              ),
            );
          },
          loading: () => MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, _) => MaterialApp(
            home: Scaffold(
              body: Center(child: Text('خطأ في تحميل الثيم')),
            ),
          ),
        );
      },
    );
  }
}

