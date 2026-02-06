import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/log_service.dart';

/// نقطة الدخول الرئيسية للتطبيق
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  LogService.info('بدء تشغيل تطبيق Sada');
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
