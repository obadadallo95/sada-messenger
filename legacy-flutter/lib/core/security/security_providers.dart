import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'key_manager.dart';
import 'encryption_service.dart';

/// Provider لـ KeyManager
final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager();
});

/// Provider لـ EncryptionService
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  final keyManager = ref.watch(keyManagerProvider);
  return EncryptionService(keyManager);
});

