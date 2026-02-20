// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sada/core/utils/log_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('LogService initializes and creates log file', () async {
    await LogService.init();

    final logFile = LogService.logFile;
    expect(logFile, isNotNull);
    expect(logFile!.path, contains('sada_log_'));

    // Cleanup
    if (logFile.existsSync()) {
      logFile.deleteSync();
    }
    final logDir = Directory('./logs');
    if (logDir.existsSync()) {
      logDir.deleteSync(recursive: true);
    }
  });

  test('LogService writes to file', () async {
    await LogService.init();
    final logFile = LogService.logFile;

    LogService.info('Test Log Message');

    // Small delay for async write if any (though FileOutput uses writeAsStringSync)
    await Future.delayed(const Duration(milliseconds: 100));

    expect(logFile!.existsSync(), isTrue);
    final content = logFile.readAsStringSync();
    expect(content, contains('Test Log Message'));

    // Cleanup
    if (logFile.existsSync()) {
      logFile.deleteSync();
    }
    final logDir = Directory('./logs');
    if (logDir.existsSync()) {
      logDir.deleteSync(recursive: true);
    }
  });
}
