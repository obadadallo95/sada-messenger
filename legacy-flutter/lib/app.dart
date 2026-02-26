import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sada/l10n/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/notification_service.dart';
import 'core/security/security_providers.dart';
import 'core/utils/log_service.dart';
import 'core/network/mesh_connection_manager.dart';
import 'core/network/mesh_service.dart';
import 'core/network/incoming_message_handler.dart';
import 'core/services/background_service.dart';
import 'core/services/mesh_permissions_service.dart';

/// نقطة دخول التطبيق الرئيسية
/// تهيئة جميع الخدمات الأساسية والـ Providers
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapServices();
    });
  }

  Future<void> _bootstrapServices() async {
    if (!mounted || _bootstrapped) return;
    _bootstrapped = true;

    final router = ref.read(appRouterProvider);

    // تهيئة خدمة الإشعارات
    final notificationService = NotificationService();
    final initialized = await notificationService.initialize();

    if (initialized) {
      await notificationService.requestPermissions();
      LogService.info('تم تهيئة خدمة الإشعارات');
    } else {
      LogService.warning('فشل تهيئة خدمة الإشعارات');
    }

    notificationService.setRouter(router);

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

    // تهيئة MeshConnectionManager
    try {
      ref.read(meshConnectionManagerProvider);
      LogService.info('تم تهيئة MeshConnectionManager');
    } catch (e) {
      LogService.error('خطأ في تهيئة MeshConnectionManager', e);
    }

    // تهيئة receive pipeline مرة واحدة فقط
    try {
      ref.read(incomingMessageHandlerProvider);
      LogService.info('تم تهيئة IncomingMessageHandler');
    } catch (e) {
      LogService.error('خطأ في تهيئة IncomingMessageHandler', e);
    }

    // تهيئة Transport & Discovery Layer
    try {
      final meshPermissionsService = MeshPermissionsService();
      final meshPermissionsGranted =
          await meshPermissionsService.ensureMeshPermissions();
      if (!meshPermissionsGranted) {
        LogService.warning(
          'يجب منح صلاحيات WiFi/Bluetooth/Location لعمل شبكة Sada',
        );
      }

      final meshService = ref.read(meshServiceProvider);
      await meshService.initializeTransportLayer();
      LogService.info('تم تهيئة Transport & Discovery Layer');
    } catch (e) {
      LogService.error('خطأ في تهيئة Transport & Discovery Layer', e);
    }

    // تهيئة وتشغيل Background Service
    try {
      await BackgroundService.instance.initialize();
      LogService.info('تم تهيئة وتشغيل Background Service');
    } catch (e) {
      LogService.error('خطأ في تهيئة Background Service', e);
    }

    LogService.info('تم تهيئة التطبيق');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(themeProvider);
    final themeModeAsync = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(localeNotifierProvider);

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
              themeMode: ref
                  .read(themeNotifierProvider.notifier)
                  .getThemeMode(),

              // الترجمة
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,

              // التوجيه
              routerConfig: router,
            );
          },
          loading: () => MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
          error: (_, _) => MaterialApp(
            home: Scaffold(body: Center(child: Text('خطأ في تحميل اللغة'))),
          ),
        );
      },
      loading: () => MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('خطأ في تحميل الثيم'))),
      ),
    );
  }
}
