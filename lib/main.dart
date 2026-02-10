import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app.dart';
import 'core/utils/log_service.dart';
import 'core/network/incoming_message_handler.dart';

/// نقطة الدخول الرئيسية للتطبيق
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  LogService.info('بدء تشغيل تطبيق Sada');
  
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ProviderScope(
          overrides: [
            // تهيئة IncomingMessageHandler عند بدء التطبيق
            incomingMessageHandlerProvider.overrideWith((ref) {
              return IncomingMessageHandler(ref);
            }),
          ],
          child: const App(),
        );
      },
    ),
  );
}
