import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app.dart';
import 'core/utils/log_service.dart';

/// نقطة الدخول الرئيسية للتطبيق
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LogService.init();
  LogService.info('بدء تشغيل تطبيق Sada');

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return const ProviderScope(child: App());
      },
    ),
  );
}
