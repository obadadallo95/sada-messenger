import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/power_mode.dart';
import '../utils/log_service.dart';

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
    if (_currentPowerMode == mode) return;

    _currentPowerMode = mode;
    LogService.info('تم تحديث وضع الطاقة إلى: ${mode.toStorageString()}');

    // إعادة تشغيل Duty Cycle مع الوضع الجديد
    final service = FlutterBackgroundService();
    service.invoke('updatePowerMode', {
      'mode': mode.toStorageString(),
    });
  }

}

/// نقطة البداية للخدمة الخلفية (Android)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('stop').listen((event) {
      service.stopSelf();
    });

    service.on('updatePowerMode').listen((event) {
      if (event != null) {
        final modeString = event['mode'] as String?;
        if (modeString != null) {
          final mode = PowerModeExtension.fromStorageString(modeString);
          _startDutyCycle(service, mode);
        }
      }
    });
  }

  // بدء Duty Cycle
  _startDutyCycle(service, PowerMode.balanced);
}

/// بدء Duty Cycle
void _startDutyCycle(ServiceInstance service, PowerMode mode) {
  bool isScanning = false;

  // بدء Timer للـ Duty Cycle
  Timer.periodic(Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      // تحديث الإشعار
      if (isScanning) {
        service.setForegroundNotificationInfo(
          title: 'Sada',
          content: 'Sada: Scanning...',
        );
      } else {
        service.setForegroundNotificationInfo(
          title: 'Sada',
          content: 'Sada: Sleeping',
        );
      }
    }

    // منطق Duty Cycle
    final scanDuration = mode.scanDurationSeconds;
    final sleepDuration = mode.sleepDurationMinutes;

    if (mode == PowerMode.highPerformance) {
      // مسح مستمر
      if (!isScanning) {
        isScanning = true;
        LogService.info('🔋 Service Waking Up... Scanning...');
      }
    } else {
      // Duty Cycle: مسح ثم نوم
      // هذا منطق مبسط - في التطبيق الحقيقي سيتم استخدام Timer منفصل
      if (!isScanning) {
        // بدء المسح
        isScanning = true;
        LogService.info('🔋 Service Waking Up... Scanning...');
        
        // انتظار مدة المسح
        await Future.delayed(Duration(seconds: scanDuration));
        
        // الانتقال إلى النوم
        isScanning = false;
        LogService.info('💤 Service Sleeping for $sleepDuration minutes...');
        
        // انتظار مدة النوم
        await Future.delayed(Duration(minutes: sleepDuration));
      }
    }
  });
}

/// نقطة البداية للخدمة الخلفية (iOS)
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

