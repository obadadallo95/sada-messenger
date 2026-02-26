import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/log_service.dart';

/// خدمة الإشعارات المحلية
/// تتعامل مع الإشعارات المحلية، الصلاحيات، والتنقل
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  GoRouter? _router;

  /// معرف القناة للإشعارات
  static const String _channelId = 'sada_channel';
  static const String _channelName = 'Sada Messages';
  static const String _channelDescription = 'إشعارات الرسائل من Sada';

  /// تهيئة خدمة الإشعارات
  Future<bool> initialize() async {
    if (_isInitialized) {
      LogService.info('خدمة الإشعارات مهيأة بالفعل');
      return true;
    }

    try {
      // إعدادات Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // إعدادات iOS
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // إعدادات التهيئة العامة
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      // تهيئة الإشعارات (API الجديد - flutter_local_notifications 20.0.0)
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      final initialized = true;

      if (initialized == false) {
        LogService.error('فشل تهيئة خدمة الإشعارات');
        return false;
      }

      // إنشاء قناة Android (مطلوبة للإشعارات)
      await _createAndroidChannel();

      _isInitialized = true;
      LogService.info('تم تهيئة خدمة الإشعارات بنجاح');
      return true;
    } catch (e) {
      LogService.error('خطأ في تهيئة خدمة الإشعارات', e);
      return false;
    }
  }

  /// إنشاء قناة Android للإشعارات
  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// طلب صلاحيات الإشعارات
  /// خاصة Android 13+ (API 33+)
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ (API 33+) يتطلب POST_NOTIFICATIONS
        // للبساطة، سنطلب الصلاحية دائماً على Android
        final status = await Permission.notification.status;
        
        if (status.isDenied) {
          final result = await Permission.notification.request();
          if (result.isGranted) {
            LogService.info('تم منح صلاحية الإشعارات');
            return true;
          } else {
            LogService.warning('تم رفض صلاحية الإشعارات');
            return false;
          }
        } else if (status.isGranted) {
          return true;
        }
      } else if (Platform.isIOS) {
        // iOS يطلب الصلاحيات تلقائياً عند أول إشعار
        final result = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return result ?? false;
      }

      return true;
    } catch (e) {
      LogService.error('خطأ في طلب صلاحيات الإشعارات', e);
      return false;
    }
  }


  /// ربط GoRouter للتنقل عند النقر على الإشعار
  void setRouter(GoRouter router) {
    _router = router;
  }

  /// معالجة النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    LogService.info('تم النقر على إشعار: ${response.payload}');
    
    if (response.payload == null || _router == null) return;

    try {
      // payload يجب أن يكون chatId
      final chatId = response.payload!;
      
      // الانتقال إلى شاشة المحادثة
      _router!.go('/chat/$chatId');
    } catch (e) {
      LogService.error('خطأ في التنقل من الإشعار', e);
    }
  }

  /// عرض إشعار محادثة
  /// [id]: معرف فريد للإشعار
  /// [title]: عنوان الإشعار (اسم المرسل)
  /// [body]: نص الرسالة
  /// [payload]: بيانات إضافية (chatId للتنقل)
  Future<bool> showChatNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_isInitialized) {
      LogService.warning('خدمة الإشعارات غير مهيأة');
      return false;
    }

    try {
      // التأكد من الصلاحيات
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        LogService.warning('لا توجد صلاحية لعرض الإشعارات');
        return false;
      }

      // إعدادات Android
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      // إعدادات iOS
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // إعدادات الإشعار
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // عرض الإشعار (API الجديد - flutter_local_notifications 20.0.0)
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );

      LogService.info('تم عرض الإشعار: $title');
      return true;
    } catch (e) {
      LogService.error('خطأ في عرض الإشعار', e);
      return false;
    }
  }

  /// إلغاء إشعار محدد
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// التحقق من حالة التهيئة
  bool get isInitialized => _isInitialized;
}

