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

  PowerMode _currentPowerMode = PowerMode.balanced;
  Timer? _dutyCycleTimer;

  /// تهيئة الخدمة الخلفية
  Future<void> initialize() async {
    try {
      final service = FlutterBackgroundService();

      // تهيئة الإشعارات المحلية (سيتم التعامل معها من خلال flutter_background_service)

      // تهيئة الخدمة الخلفية
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _notificationChannelId,
          initialNotificationTitle: 'Sada',
          initialNotificationContent: 'Sada is active',
          foregroundServiceNotificationId: _notificationId,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );

      LogService.info('تم تهيئة الخدمة الخلفية');
    } catch (e) {
      LogService.error('خطأ في تهيئة الخدمة الخلفية', e);
    }
  }


  /// بدء الخدمة الخلفية
  Future<bool> start() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (!isRunning) {
        final started = await service.startService();
        if (started) {
          LogService.info('تم بدء الخدمة الخلفية');
          return true;
        } else {
          LogService.warning('فشل بدء الخدمة الخلفية');
          return false;
        }
      } else {
        LogService.info('الخدمة الخلفية تعمل بالفعل');
        return true;
      }
    } catch (e) {
      LogService.error('خطأ في بدء الخدمة الخلفية', e);
      return false;
    }
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
        LogService.info('تم إيقاف الخدمة الخلفية');
      }
    } catch (e) {
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

    // إعادة تشغيل Duty Cycle مع الوضع الجديد
    try {
      final service = FlutterBackgroundService();
      service.invoke('updatePowerMode', {
        'mode': mode.toStorageString(),
      });
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
        LogService.info('تم تحميل وضع الطاقة الحالي: ${mode.toStorageString()}');
      }
    } catch (e) {
      LogService.error('خطأ في تحميل وضع الطاقة الحالي', e);
    }
  }

}

/// متغيرات عامة للـ Duty Cycle
Timer? _dutyCycleTimer;
int _dutyCycleCounter = 0;
bool _isScanning = false;
int _peerCount = 0;
EpidemicRouter? _router; // Epidemic Router instance in background

/// FlutterLocalNotificationsPlugin للإشعارات المتقدمة
final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

/// تهيئة إشعارات الخدمة الخلفية
Future<void> _initializeBackgroundNotifications(ServiceInstance service) async {
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

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    LogService.info('تم تهيئة قناة إشعارات الخدمة الخلفية');
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
  // 1. تهيئة WidgetsBinding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة إشعارات الخدمة الخلفية
  await _initializeBackgroundNotifications(service);

  // 3. Setup Riverpod container with Database
  // استخدام try-catch لضمان عدم انهيار الخدمة عند فشل قاعدة البيانات
  ProviderContainer? container;
  try {
    final database = AppDatabase.create('sada.sqlite');
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => Future.value(database)),
      ],
    );
    LogService.info('Database Initialized in Background Service');
  } catch (e) {
     LogService.error('CRITICAL: Failed to initialize Database in onStart', e);
     // قد نحتاج لإعادة المحاولة أو إيقاف الخدمة
  }

  // 4. Initialize Epidemic Router
  if (container != null) {
    try {
      const secureStorage = FlutterSecureStorage();
      final userDataJson = await secureStorage.read(key: 'user_data');
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        final String userId = userData['userId'];
        
        // التحقق من Duress Mode - لا نبدأ الشبكة في وضع الإكراه
        final authTypeStr = await secureStorage.read(key: 'current_auth_type');
        if (authTypeStr == 'duress') {
          LogService.info('🔒 Duress Mode active - mesh service disabled for security');
          // لا نبدأ EpidemicRouter في Duress Mode لمنع أي نشاط شبكي حقيقي
          // هذا يحمي هوية جهات الاتصال الحقيقية
          return;
        }
        
        _router = container.read(epidemicRouterProvider.notifier);
        
        // ربط Metrics Callbacks
        // (سنحتاج لتحديث EpidemicRouter لدعم هذه الـ callbacks)
        /*
        _router!.onMetricsUpdated = (s, r, d) {
             _updateMetrics(service, sent: s, received: r, dropped: d);
        };
        */

        await _router!.initialize(userId, onPeerCountChanged: (count) {
           _peerCount = count;
           service.invoke('updatePeerCount', {'count': count});
           if (service is AndroidServiceInstance) {
             service.setForegroundNotificationInfo(
               title: '📡 Sada Active',
               content: 'Scanning... ${_peerCount > 0 ? ' • $_peerCount peers' : ''}',
             );
           }
        }, onMetricsUpdated: (s, r, d) {
             _updateMetrics(service, sent: s, received: r, dropped: d);
        });
        LogService.info('EpidemicRouter initialized in background for user: $userId');
      } else {
        LogService.warning('Cannot initialize EpidemicRouter: No user data found.');
      }
    } catch (e) {
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
      LogService.info('Loaded stored PowerMode: ${initialMode.toStorageString()}');
    }
  } catch (e) {
    LogService.error('Error loading stored PowerMode', e);
  }

  // بدء Duty Cycle
  _startDutyCycle(service, initialMode);
}

/// إيقاف الخدمة بشكل صحيح
void _shutdownService(AndroidServiceInstance service) async {
  _dutyCycleTimer?.cancel();
  _dutyCycleTimer = null;
  
  // Stop Network Logic
  await _router?.stopService();

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
          content: 'Scanning for peers...${_peerCount > 0 ? ' • $_peerCount peers' : ''}',
        );
        service.invoke('updateStatus', {'status': 'Scanning', 'peerCount': _peerCount});
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
            content: 'Scanning... (${remainingScan}s)${_peerCount > 0 ? ' • $_peerCount peers' : ''}',
          );
          service.invoke('updateStatus', {'status': 'Scanning ($remainingScan)', 'peerCount': _peerCount});

          // انتهاء فترة المسح
          if (_dutyCycleCounter >= scanDuration) {
            _isScanning = false;
            _router?.stopService(); // STOP Router
            _dutyCycleCounter = 0;
            LogService.info('💤 الانتقال إلى النوم لمدة ${mode.sleepDurationMinutes} دقيقة');
            
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
            content: 'Sleeping for ${remainingMinutes}m ${remainingSeconds}s...',
            isScanning: false,
            peerCount: _peerCount,
          );
          
          service.setForegroundNotificationInfo(
            title: '🌙 Power Saving',
            content: 'Sleeping... (${remainingMinutes}m ${remainingSeconds}s)',
          );
          service.invoke('updateStatus', {'status': 'Sleeping ($remainingMinutes:$remainingSeconds)', 'peerCount': _peerCount});

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

void _updateMetrics(ServiceInstance service, {int sent = 0, int received = 0, int dropped = 0}) {
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

