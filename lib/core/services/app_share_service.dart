import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/log_service.dart';

/// خدمة مشاركة التطبيق
/// تسمح للمستخدمين بمشاركة ملف APK مباشرة عبر Bluetooth أو تطبيقات المشاركة الأخرى
class AppShareService {
  static const MethodChannel _methodChannel = MethodChannel('org.sada.messenger/mesh');
  static const String _apkFileName = 'Sada_Messenger.apk';

  /// مشاركة ملف APK
  /// يقوم بنسخ ملف APK إلى مجلد مؤقت ثم مشاركته
  Future<bool> shareApk() async {
    try {
      LogService.info('بدء عملية مشاركة APK');

      // 1. الحصول على مسار APK الأصلي من Native
      final String? apkPath = await _getApkPath();
      if (apkPath == null || apkPath.isEmpty) {
        LogService.error('فشل الحصول على مسار APK', null);
        return false;
      }

      LogService.info('مسار APK الأصلي: $apkPath');

      // 2. الحصول على المجلد المؤقت
      final Directory tempDir = await getTemporaryDirectory();
      final File tempApkFile = File('${tempDir.path}/$_apkFileName');

      LogService.info('مسار APK المؤقت: ${tempApkFile.path}');

      // 3. نسخ ملف APK إلى المجلد المؤقت
      await _copyApkFile(apkPath, tempApkFile.path);

      LogService.info('تم نسخ ملف APK بنجاح');

      // 4. مشاركة الملف
      await Share.shareXFiles(
        [XFile(tempApkFile.path)],
        text: 'Install Sada - The Offline Mesh Messenger for Syria.',
        subject: 'Sada Messenger APK',
      );

      LogService.info('تم فتح شاشة المشاركة بنجاح');

      // 5. تنظيف الملف المؤقت بعد فترة (اختياري)
      // يمكن حذف الملف بعد المشاركة، لكن نتركه للمستخدم لاستخدامه لاحقاً

      return true;
    } catch (e) {
      LogService.error('خطأ في مشاركة APK', e);
      return false;
    }
  }

  /// الحصول على مسار APK الأصلي من Native Android
  Future<String?> _getApkPath() async {
    try {
      final String? apkPath = await _methodChannel.invokeMethod<String>('getApkPath');
      return apkPath;
    } catch (e) {
      LogService.error('خطأ في الحصول على مسار APK من Native', e);
      return null;
    }
  }

  /// نسخ ملف APK من المسار الأصلي إلى المسار المؤقت
  /// يتم التنفيذ بشكل غير متزامن لتجنب حجب UI
  Future<void> _copyApkFile(String sourcePath, String destinationPath) async {
    try {
      final File sourceFile = File(sourcePath);
      final File destinationFile = File(destinationPath);

      // التحقق من وجود الملف المصدر
      if (!await sourceFile.exists()) {
        throw Exception('ملف APK الأصلي غير موجود: $sourcePath');
      }

      // حذف الملف الوجهة إذا كان موجوداً
      if (await destinationFile.exists()) {
        await destinationFile.delete();
        LogService.info('تم حذف ملف APK المؤقت القديم');
      }

      // نسخ الملف
      await sourceFile.copy(destinationPath);

      // التحقق من نجاح النسخ
      final copiedFile = File(destinationPath);
      if (!await copiedFile.exists()) {
        throw Exception('فشل نسخ ملف APK');
      }

      final sourceSize = await sourceFile.length();
      final copiedSize = await copiedFile.length();

      if (sourceSize != copiedSize) {
        throw Exception('حجم الملف المنسوخ غير متطابق: $sourceSize vs $copiedSize');
      }

      LogService.info('تم نسخ ملف APK بنجاح: ${sourceSize / 1024 / 1024} MB');
    } catch (e) {
      LogService.error('خطأ في نسخ ملف APK', e);
      rethrow;
    }
  }

  /// حذف ملف APK المؤقت
  /// يمكن استدعاؤها لتنظيف الملفات المؤقتة
  Future<void> cleanupTempApk() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File tempApkFile = File('${tempDir.path}/$_apkFileName');

      if (await tempApkFile.exists()) {
        await tempApkFile.delete();
        LogService.info('تم حذف ملف APK المؤقت');
      }
    } catch (e) {
      LogService.error('خطأ في حذف ملف APK المؤقت', e);
    }
  }
}

