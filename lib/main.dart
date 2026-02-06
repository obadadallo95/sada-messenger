import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/log_service.dart';
import 'core/network/incoming_message_handler.dart';

/// نقطة الدخول الرئيسية للتطبيق
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  LogService.info('بدء تشغيل تطبيق Sada');
  
  runApp(
    ProviderScope(
      overrides: [
        // تهيئة IncomingMessageHandler عند بدء التطبيق
        incomingMessageHandlerProvider.overrideWith((ref) {
          return IncomingMessageHandler(ref);
        }),
      ],
      child: const App(),
    ),
  );
}
