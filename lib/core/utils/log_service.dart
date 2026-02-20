import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'file_output.dart';

/// خدمة السجلات (Logging) للتطبيق
/// توفر واجهة موحدة لتسجيل الأحداث والأخطاء
class LogService {
  LogService._();

  static Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// تسجيل معلومات عامة
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل تحذير
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل خطأ
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل تصحيح الأخطاء
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// تسجيل معلومات حرجة
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  static File? _logFile;

  /// تهيئة LogService مع ملف السجلات
  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }

      // اسم الملف بناءً على التاريخ الحالي (بشكل يومي)
      final now = DateTime.now();
      final fileName =
          'sada_log_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.txt';
      _logFile = File('${logDir.path}/$fileName');

      // إعادة تهيئة Logger بـ MultiOutput (Console + File)
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0, // تقليل الضوضاء في Console
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
        output: MultiOutput([ConsoleOutput(), SadaFileOutput(file: _logFile!)]),
      );

      info('✅ تم تهيئة LogService مع ملف السجلات: ${_logFile!.path}');
    } catch (e) {
      debugPrint('Failed to initialize file logging: $e');
    }
  }

  /// الحصول على مسار ملف السجلات الحالي
  static String? get currentLogFilePath => _logFile?.path;

  /// الحصول على ملف السجلات
  static File? get logFile => _logFile;
}
