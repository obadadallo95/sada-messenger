import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/power_mode.dart';
import '../utils/log_service.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../network/router/epidemic_router.dart';

/// خدمة الخلفية لإدارة Mesh Networking
/// تتبع Duty Cycle بناءً على وضع الطاقة المحدد
class BackgroundService {
  static BackgroundService? _instance;
  static BackgroundService get instance {
    _instance ??= BackgroundService._();
    return _instance!;
  }

  BackgroundService._();

  static const String _notificationChannelId = 'sada_background_service';
  static const int _notificationId = 999;
  static const String _diagLastStageKey = 'bg_diag_last_stage';
  static const String _diagLastReasonKey = 'bg_diag_last_reason';
  static const String _diagLastErrorKey = 'bg_diag_last_error';
  static const String _diagLastUpdatedAtKey = 'bg_diag_last_updated_at';

  PowerMode _currentPowerMode = PowerMode.balanced;
  Timer? _dutyCycleTimer;
  bool _isConfigured = false;
  Future<void>? _configureInFlight;

  /// تهيئة الخدمة الخلفية
  Future<void> initialize() async {
    // 1. إنشاء قناة الإشعارات (يجب أن تكون موجودة قبل بدء الخدمة)
    await _initializeBackgroundNotifications();
    
    // 2. ضمان تشغيل الخدمة
    await _ensureServiceRunning();
  }

  Future<void> _configureIfNeeded() async {
    if (_isConfigured) return;
    if (_configureInFlight != null) {
      await _configureInFlight;
      return;
    }

    _configureInFlight = _configureInternal();
    try {
      await _configureInFlight;
    } finally {
      _configureInFlight = null;
    }
  }

  Future<void> _configureInternal() async {
    try {
      await _recordBackgroundDiag(
        stage: 'configure',
        reason: 'configuring background service',
      );
      final service = FlutterBackgroundService();
      
      // تأكد من إنشاء القناة مرة أخرى هنا (للاحتياط)
      await _initializeBackgroundNotifications();

      final configured = await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          autoStartOnBoot: true,
          isForegroundMode: true,
          notificationChannelId: _notificationChannelId,
          initialNotificationTitle: 'Sada',
          initialNotificationContent: 'Sada is active',
          foregroundServiceNotificationId: _notificationId,
          foregroundServiceTypes: const [
            AndroidForegroundType.connectedDevice,
            AndroidForegroundType.dataSync,
          ],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );

      if (!configured) {
        throw StateError('فشل تهيئة flutter_background_service');
      }

      _isConfigured = true;
      await _recordBackgroundDiag(
        stage: 'configured',
        reason: 'background service configured successfully',
      );
      LogService.info('تم تهيئة الخدمة الخلفية');
    } catch (e) {
      await _recordBackgroundDiag(
        stage: 'configure_failed',
        reason: 'exception during service configuration',
        error: e.toString(),
      );
      LogService.error('خطأ في تهيئة الخدمة الخلفية', e);
      rethrow;
    }
  }

  Future<bool> _ensureServiceRunning() async {
    try {
      await _recordBackgroundDiag(
        stage: 'ensure_running',
        reason: 'checking service running state',
      );
      await _configureIfNeeded();

      final service = FlutterBackgroundService();
      var isRunning = await service.isRunning();
      if (isRunning) {
        await _recordBackgroundDiag(
          stage: 'already_running',
          reason: 'service is already running',
        );
      }
      if (!isRunning) {
        final started = await service.startService();
        if (!started) {
          await _recordBackgroundDiag(
            stage: 'start_failed',
            reason: 'startService returned false',
          );
          LogService.warning('فشل بدء الخدمة الخلفية');
          return false;
        }
        // Verify the service actually became active.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        isRunning = await service.isRunning();
        if (!isRunning) {
          await _recordBackgroundDiag(
            stage: 'start_not_effective',
            reason: 'startService returned true but service is still not running',
          );
          return false;
        }
        await _recordBackgroundDiag(
          stage: 'started',
          reason: 'service started successfully and verified running',
        );
      }

      return true;
    } catch (e) {
      await _recordBackgroundDiag(
        stage: 'ensure_running_failed',
        reason: 'exception while ensuring service running',
        error: e.toString(),
      );
      LogService.error('خطأ في ضمان تشغيل الخدمة الخلفية', e);
      return false;
    }
  }

  /// بدء الخدمة الخلفية
  Future<bool> start() async {
    return _ensureServiceRunning();
  }

  Future<bool> restart() async {
    await _recordBackgroundDiag(
      stage: 'restart_requested',
      reason: 'manual restart requested from debug screen',
    );
    await stop();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _ensureServiceRunning();
  }

  /// إيقاف الخدمة الخلفية
  Future<void> stop() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (isRunning) {
        service.invoke('stop');
        _dutyCycleTimer?.cancel();
        _dutyCycleTimer = null;
        await _recordBackgroundDiag(
          stage: 'stop_requested',
          reason: 'stop invoked from foreground app',
        );
        LogService.info('تم إيقاف الخدمة الخلفية');
      }
    } catch (e) {
      await _recordBackgroundDiag(
        stage: 'stop_failed',
        reason: 'exception during stop request',
        error: e.toString(),
      );
      LogService.error('خطأ في إيقاف الخدمة الخلفية', e);
    }
  }

  /// تحديث وضع الطاقة
  void updatePowerMode(PowerMode mode) {
    if (_currentPowerMode == mode) {
      LogService.info('وضع الطاقة لم يتغير: ${mode.toStorageString()}');
      return;
    }

    _currentPowerMode = mode;
    LogService.info('تم تحديث وضع الطاقة إلى: ${mode.toStorageString()}');

    unawaited(_pushPowerModeUpdate(mode));
  }

  Future<void> _pushPowerModeUpdate(PowerMode mode) async {
    final running = await _ensureServiceRunning();
    if (!running) {
      LogService.warning('تعذر تطبيق وضع الطاقة: الخدمة الخلفية غير متاحة');
      return;
    }
    try {
      final service = FlutterBackgroundService();
      service.invoke('updatePowerMode', {'mode': mode.toStorageString()});
    } catch (e) {
      LogService.error('خطأ في إرسال تحديث وضع الطاقة للخدمة الخلفية', e);
    }
  }

  /// تحميل وضع الطاقة الحالي من SharedPreferences
  Future<void> loadCurrentPowerMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString('power_mode');

      if (storedValue != null) {
        final mode = PowerModeExtension.fromStorageString(storedValue);
        _currentPowerMode = mode;
        LogService.info(
          'تم تحميل وضع الطاقة الحالي: ${mode.toStorageString()}',
        );
        unawaited(_pushPowerModeUpdate(mode));
      }
    } catch (e) {
      LogService.error('خطأ في تحميل وضع الطاقة الحالي', e);
    }
  }

  /// تقرير تشخيصي سريع لحالة خدمة الخلفية.
  /// يساعد على معرفة سبب "Unknown" في الواجهة.
  Future<Map<String, dynamic>> diagnose() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      final authTypeStr = await secureStorage.read(key: 'current_auth_type');
      final userDataJson = await secureStorage.read(key: 'user_data');
      final userDataBackup = prefs.getString('user_data_backup');
      final hasUserData =
          (userDataJson != null && userDataJson.isNotEmpty) ||
          (userDataBackup != null && userDataBackup.isNotEmpty);

      String? blockingReason;
      if (!hasUserData) {
        blockingReason = 'Background service blocked: missing user_data';
      } else if (authTypeStr == 'duress') {
        blockingReason = 'Background service blocked in duress mode';
      }

      return {
        'isConfigured': _isConfigured,
        'isRunning': isRunning,
        'notificationChannelId': _notificationChannelId,
        'foregroundNotificationId': _notificationId,
        'authType': authTypeStr ?? 'null',
        'hasUserData': hasUserData,
        'canStartMesh': blockingReason == null,
        'blockingReason': blockingReason ?? '',
        'lastStage': prefs.getString(_diagLastStageKey) ?? '',
        'lastReason': prefs.getString(_diagLastReasonKey) ?? '',
        'lastError': prefs.getString(_diagLastErrorKey) ?? '',
        'lastUpdatedAt': prefs.getString(_diagLastUpdatedAtKey) ?? '',
        'effectiveStatus': isRunning ? 'running' : 'stopped',
      };
    } catch (e) {
      return {
        'isConfigured': _isConfigured,
        'isRunning': false,
        'authType': 'unknown',
        'hasUserData': false,
        'canStartMesh': false,
        'blockingReason': 'diagnose_error: $e',
      };
    }
  }
}

Future<void> _recordBackgroundDiag({
  required String stage,
  required String reason,
  String? error,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BackgroundService._diagLastStageKey, stage);
    await prefs.setString(BackgroundService._diagLastReasonKey, reason);
    await prefs.setString(
      BackgroundService._diagLastUpdatedAtKey,
      DateTime.now().toIso8601String(),
    );
    if (error != null && error.isNotEmpty) {
      await prefs.setString(BackgroundService._diagLastErrorKey, error);
    } else {
      await prefs.remove(BackgroundService._diagLastErrorKey);
    }
  } catch (_) {
    // Ignore diagnostics write failures
  }
}

/// متغيرات عامة للـ Duty Cycle
Timer? _dutyCycleTimer;
int _dutyCycleCounter = 0;
bool _isScanning = false;
int _peerCount = 0;
EpidemicRouter? _router; // Epidemic Router instance in background
ProviderContainer? _backgroundContainer;
AppDatabase? _backgroundDatabase;

/// FlutterLocalNotificationsPlugin للإشعارات المتقدمة
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// تهيئة إشعارات الخدمة الخلفية
Future<void> _initializeBackgroundNotifications() async {
  if (!Platform.isAndroid) return;

  try {
    // إنشاء قناة إشعارات للخدمة الخلفية
    const androidChannel = AndroidNotificationChannel(
      'sada_background_service',
      'Sada Background Service',
      description: 'إشعارات خدمة الخلفية لـ Sada',
      importance: Importance.low, // Low importance لتجنب الصوت/الاهتزاز
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    // تهيئة الإضافة مع أيقونة التطبيق الافتراضية
    // لاحظ: @mipmap/ic_launcher هو المسار الصحيح للموارد في Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    LogService.info('تم تهيئة إشعارات الخدمة الخلفية');
  } catch (e) {
    LogService.error('خطأ في تهيئة إشعارات الخدمة الخلفية', e);
  }
}

/// تحديث إشعار الخدمة الخلفية مع الحالة الديناميكية
Future<void> _updateBackgroundNotification({
  required String title,
  required String content,
  required bool isScanning,
  int peerCount = 0,
}) async {
  if (!Platform.isAndroid) return;

  try {
    // إعدادات Android مع ongoing و actions
    final androidDetails = AndroidNotificationDetails(
      'sada_background_service',
      'Sada Background Service',
      channelDescription: 'إشعارات خدمة الخلفية لـ Sada',
      importance: Importance.low,
      priority: Priority.defaultPriority,
      ongoing: true, // Sticky notification - لا يمكن إلغاؤها
      autoCancel: false,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          'stop_service',
          'إيقاف',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
    );

    // بناء المحتوى مع Peer Count إذا كان متاحاً
    String finalContent = content;
    if (peerCount > 0) {
      finalContent += ' • $peerCount ${peerCount == 1 ? 'peer' : 'peers'}';
    }

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: 999, // نفس ID المستخدم في flutter_background_service
      title: title,
      body: finalContent,
      notificationDetails: notificationDetails,
    );

    LogService.info('تم تحديث إشعار الخدمة: $title - $finalContent');
  } catch (e) {
    LogService.error('خطأ في تحديث إشعار الخدمة الخلفية', e);
  }
}

/// نقطة البداية للخدمة الخلفية (Android)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  await _recordBackgroundDiag(
    stage: 'onStart',
    reason: 'background isolate entry-point started',
  );
  // 1. تهيئة WidgetsBinding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة إشعارات الخدمة الخلفية (يجب أن تكون أولاً لضمان وجود القناة)
  await _initializeBackgroundNotifications();

  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      await service.setForegroundNotificationInfo(
        title: '📡 Sada Active',
        content: 'Preparing secure mesh service...',
      );
    }
  }

  const secureStorage = FlutterSecureStorage();
  final authTypeStr = await secureStorage.read(key: 'current_auth_type');
  var userDataJson = await secureStorage.read(key: 'user_data');
  if (userDataJson == null || userDataJson.isEmpty) {
    final prefs = await SharedPreferences.getInstance();
    final backup = prefs.getString('user_data_backup');
    if (backup != null && backup.isNotEmpty) {
      userDataJson = backup;
      await _recordBackgroundDiag(
        stage: 'using_user_data_backup',
        reason: 'secure user_data missing, fallback from shared preferences',
      );
    }
  }

  // 🔒 لا تبدأ شبكة/قاعدة بيانات حقيقية إذا كانت الجلسة Duress أو لا يوجد مستخدم.
  if (authTypeStr == 'duress' || userDataJson == null || userDataJson.isEmpty) {
    await _recordBackgroundDiag(
      stage: 'blocked_auth',
      reason:
          'blocked by auth/user_data (authType=$authTypeStr, hasUser=${userDataJson != null && userDataJson.isNotEmpty})',
    );
    LogService.info(
      'Background service blocked (authType: $authTypeStr, hasUser: ${userDataJson != null && userDataJson.isNotEmpty})',
    );
    if (service is AndroidServiceInstance) {
      await service.stopSelf();
    }
    return;
  }

  String? userId;
  try {
    final userData = jsonDecode(userDataJson);
    userId = userData['userId'] as String?;
  } catch (e) {
    await _recordBackgroundDiag(
      stage: 'invalid_user_data',
      reason: 'failed decoding user_data json',
      error: e.toString(),
    );
    LogService.error('Invalid user_data payload in secure storage', e);
    if (service is AndroidServiceInstance) {
      await service.stopSelf();
    }
    return;
  }

  if (userId == null || userId.isEmpty) {
    await _recordBackgroundDiag(
      stage: 'missing_user_id',
      reason: 'user_data decoded but userId was null/empty',
    );
    LogService.warning('Background service stopped: missing userId');
    if (service is AndroidServiceInstance) {
      await service.stopSelf();
    }
    return;
  }

  // 2. تهيئة إشعارات الخدمة الخلفية
  await _initializeBackgroundNotifications();

  // 3. Setup Riverpod container with Database
  try {
    final database = AppDatabase.create(primaryDatabaseFileName);
    _backgroundDatabase = database;
    _backgroundContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => Future.value(database)),
      ],
    );
    LogService.info('Database Initialized in Background Service');
  } catch (e) {
    await _recordBackgroundDiag(
      stage: 'db_init_failed',
      reason: 'failed to initialize app database in background',
      error: e.toString(),
    );
    LogService.error('CRITICAL: Failed to initialize Database in onStart', e);
    if (service is AndroidServiceInstance) {
      await service.stopSelf();
    }
    return;
  }

  // 4. Initialize Epidemic Router
  if (_backgroundContainer != null) {
    try {
      _router = _backgroundContainer!.read(epidemicRouterProvider.notifier);
      await _router!.initialize(
        userId,
        onPeerCountChanged: (count) {
          _peerCount = count;
          service.invoke('updatePeerCount', {'count': count});
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: '📡 Sada Active',
              content:
                  'Scanning... ${_peerCount > 0 ? ' • $_peerCount peers' : ''}',
            );
          }
        },
        onMetricsUpdated: (s, r, d) {
          _updateMetrics(service, sent: s, received: r, dropped: d);
        },
      );
      LogService.info(
        'EpidemicRouter initialized in background for user: $userId',
      );
    } catch (e) {
      await _recordBackgroundDiag(
        stage: 'router_init_failed',
        reason: 'failed to initialize EpidemicRouter',
        error: e.toString(),
      );
      LogService.error('Error initializing EpidemicRouter in background', e);
    }
  }

  if (service is AndroidServiceInstance) {
    // معالج إيقاف الخدمة
    service.on('stop').listen((event) {
      _shutdownService(service);
    });

    // معالج إيقاف التطبيق بالكامل
    service.on('exit_app').listen((event) {
      _shutdownService(service);
      if (Platform.isAndroid) {
        exit(0);
      }
    });

    // معالج تحديث وضع الطاقة
    service.on('updatePowerMode').listen((event) {
      if (event != null) {
        final modeString = event['mode'] as String?;
        if (modeString != null) {
          final mode = PowerModeExtension.fromStorageString(modeString);
          _startDutyCycle(service, mode);
        }
      }
    });

    // معالج تحديث عدد الأقران
    service.on('updatePeerCount').listen((dynamic event) {
      if (event == null) return;
      if (event is Map<String, dynamic>) {
        final countValue = event['count'];
        if (countValue is int) {
          _peerCount = countValue;
        }
      } else if (event is int) {
        _peerCount = event;
      }
    });

    // معالج النقر على الإشعار (فتح التطبيق)
    service.on('notification_clicked').listen((event) {
      _bringAppToForeground(service);
    });
  }

  // 5. تحميل وضع الطاقة المحفوظ وبدء Duty Cycle
  PowerMode initialMode = PowerMode.balanced;
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString('power_mode');
    if (storedValue != null) {
      initialMode = PowerModeExtension.fromStorageString(storedValue);
      LogService.info(
        'Loaded stored PowerMode: ${initialMode.toStorageString()}',
      );
    }
  } catch (e) {
    LogService.error('Error loading stored PowerMode', e);
  }

  // بدء Duty Cycle
  _startDutyCycle(service, initialMode);
  await _recordBackgroundDiag(
    stage: 'running',
    reason: 'background service started and duty cycle initialized',
  );
}

/// إيقاف الخدمة بشكل صحيح
void _shutdownService(AndroidServiceInstance service) async {
  await _recordBackgroundDiag(
    stage: 'stopped',
    reason: 'background service shutdown invoked',
  );
  _dutyCycleTimer?.cancel();
  _dutyCycleTimer = null;

  // Stop Network Logic
  await _router?.stopService();
  _router = null;
  await _deactivateWakeLock(service);

  await _backgroundDatabase?.close();
  _backgroundDatabase = null;
  _backgroundContainer?.dispose();
  _backgroundContainer = null;

  // إلغاء الإشعار
  _localNotifications.cancel(id: 999);

  // إيقاف الخدمة
  service.stopSelf();

  LogService.info('تم إيقاف الخدمة الخلفية');
}

/// جلب التطبيق إلى المقدمة
void _bringAppToForeground(AndroidServiceInstance service) {
  try {
    // استخدام MethodChannel لإرسال intent لفتح التطبيق
    const platform = MethodChannel('org.sada.messenger/app');
    platform.invokeMethod('bringToForeground');
    LogService.info('تم جلب التطبيق إلى المقدمة');
  } catch (e) {
    LogService.error('خطأ في جلب التطبيق إلى المقدمة', e);
  }
}

/// بدء Duty Cycle مع إلغاء Timer القديم
void _startDutyCycle(ServiceInstance service, PowerMode mode) {
  // إلغاء Timer القديم إذا كان موجوداً
  _dutyCycleTimer?.cancel();
  _dutyCycleTimer = null;

  // إعادة تعيين العدادات
  _dutyCycleCounter = 0;
  _isScanning = false;

  LogService.info('🔄 بدء Duty Cycle مع وضع: ${mode.toStorageString()}');

  if (mode == PowerMode.highPerformance) {
    // وضع الأداء العالي: مسح مستمر
    _isScanning = true;
    _router?.startService(); // Start Router

    _dutyCycleTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        // تحديث إشعار متقدم
        await _updateBackgroundNotification(
          title: '📡 Sada Active',
          content: 'Scanning for peers...',
          isScanning: true,
          peerCount: _peerCount,
        );

        // تحديث إشعار flutter_background_service أيضاً
        service.setForegroundNotificationInfo(
          title: '📡 Sada Active',
          content:
              'Scanning for peers...${_peerCount > 0 ? ' • $_peerCount peers' : ''}',
        );
        service.invoke('updateStatus', {
          'status': 'Scanning',
          'peerCount': _peerCount,
        });
      }
    });
    LogService.info('🔋 وضع الأداء العالي: مسح مستمر');
  } else {
    // وضع متوازن أو توفير الطاقة: Duty Cycle
    final scanDuration = mode.scanDurationSeconds;
    final sleepDuration = mode.sleepDurationSeconds;

    _dutyCycleTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      _dutyCycleCounter++;

      if (service is AndroidServiceInstance) {
        if (_isScanning) {
          // فترة المسح
          final remainingScan = scanDuration - _dutyCycleCounter;
          await _updateBackgroundNotification(
            title: '📡 Sada Active',
            content: 'Scanning for peers... (${remainingScan}s)',
            isScanning: true,
            peerCount: _peerCount,
          );

          service.setForegroundNotificationInfo(
            title: '📡 Sada Active',
            content:
                'Scanning... (${remainingScan}s)${_peerCount > 0 ? ' • $_peerCount peers' : ''}',
          );
          service.invoke('updateStatus', {
            'status': 'Scanning ($remainingScan)',
            'peerCount': _peerCount,
          });

          // انتهاء فترة المسح
          if (_dutyCycleCounter >= scanDuration) {
            _isScanning = false;
            _router?.stopService(); // STOP Router
            _dutyCycleCounter = 0;
            LogService.info(
              '💤 الانتقال إلى النوم لمدة ${mode.sleepDurationMinutes} دقيقة',
            );

            // Release WakeLock
            _deactivateWakeLock(service);
          }
        } else {
          // فترة النوم
          final remainingSleep = sleepDuration - _dutyCycleCounter;
          final remainingMinutes = remainingSleep ~/ 60;
          final remainingSeconds = remainingSleep % 60;

          await _updateBackgroundNotification(
            title: '🌙 Power Saving',
            content:
                'Sleeping for ${remainingMinutes}m ${remainingSeconds}s...',
            isScanning: false,
            peerCount: _peerCount,
          );

          service.setForegroundNotificationInfo(
            title: '🌙 Power Saving',
            content: 'Sleeping... (${remainingMinutes}m ${remainingSeconds}s)',
          );
          service.invoke('updateStatus', {
            'status': 'Sleeping ($remainingMinutes:$remainingSeconds)',
            'peerCount': _peerCount,
          });

          // انتهاء فترة النوم
          if (_dutyCycleCounter >= sleepDuration) {
            _isScanning = true;
            _router?.startService(); // START Router
            _dutyCycleCounter = 0;
            LogService.info('🔋 الاستيقاظ والبدء بالمسح');

            // Acquire WakeLock
            _activateWakeLock(service);
          }
        }
      }
    });

    // بدء المسح فوراً
    _isScanning = true;
    _router?.startService(); // START Router
    LogService.info('🔋 بدء المسح لمدة $scanDuration ثانية');

    // Acquire WakeLock (Partial)
    _activateWakeLock(service);
  }
}

/// تفعيل WakeLock (Partial) عبر Native MethodChannel
Future<void> _activateWakeLock(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    try {
      const platform = MethodChannel('org.sada.messenger/mesh');
      await platform.invokeMethod('acquireWakeLock');
      LogService.info('✅ Partial WakeLock Acquired');
    } catch (e) {
      LogService.error('خطأ في تفعيل WakeLock', e);
    }
  }
}

/// تعطيل WakeLock (Partial)
Future<void> _deactivateWakeLock(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    try {
      const platform = MethodChannel('org.sada.messenger/mesh');
      await platform.invokeMethod('releaseWakeLock');
      LogService.info('🛑 Partial WakeLock Released');
    } catch (e) {
      LogService.error('خطأ في تعطيل WakeLock', e);
    }
  }
}

// --- Metrics ---
int _totalSent = 0;
int _totalReceived = 0;
int _totalDropped = 0;

void _updateMetrics(
  ServiceInstance service, {
  int sent = 0,
  int received = 0,
  int dropped = 0,
}) {
  _totalSent += sent;
  _totalReceived += received;
  _totalDropped += dropped;

  if (service is AndroidServiceInstance) {
    service.invoke('updateMetrics', {
      'sent': _totalSent,
      'received': _totalReceived,
      'dropped': _totalDropped,
    });
  }
}

/// نقطة البداية للخدمة الخلفية (iOS)
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
