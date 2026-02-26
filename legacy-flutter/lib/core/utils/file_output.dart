import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// مخرج سجلات للملفات (File Output)
class SadaFileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final Encoding encoding;

  SadaFileOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  @override
  Future<void> init() async {
    super.init();
    if (overrideExisting) {
      file.writeAsStringSync('', mode: FileMode.write, encoding: encoding);
    }
  }

  @override
  void output(OutputEvent event) {
    // تنسيق الرسالة: Timestamp - Level - Message
    for (var line in event.lines) {
      try {
        file.writeAsStringSync(
          '${DateTime.now().toIso8601String()} - $line\n',
          mode: FileMode.append,
          encoding: encoding,
        );
      } catch (e) {
        // تجاهل أخطاء الكتابة لتجنب تحطم التطبيق
        debugPrint('Error writing to log file: $e');
      }
    }
  }
}
