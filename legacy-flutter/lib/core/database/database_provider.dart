import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../utils/log_service.dart';
import 'app_database.dart';

const String primaryDatabaseFileName = 'app_cache_v1.db';

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final authStatus = ref.watch(authServiceProvider);

  if (authStatus != AuthStatus.loggedIn) {
    throw Exception('المستخدم غير مسجل الدخول. لم يتم تهيئة قاعدة البيانات.');
  }

  final database = AppDatabase.create(primaryDatabaseFileName);
  
  await database.customStatement('PRAGMA foreign_keys = ON');
  LogService.info('تم تهيئة قاعدة البيانات الأساسية: $primaryDatabaseFileName');

  return database;
});

final databaseInitializerProvider = Provider<DatabaseInitializer>((ref) {
  return DatabaseInitializer(ref);
});

class DatabaseInitializer {
  final Ref _ref;

  DatabaseInitializer(this._ref);

  Future<void> initializeDatabase() async {
    try {
      final authStatus = _ref.read(authServiceProvider);
      if (authStatus != AuthStatus.loggedIn) {
        throw Exception('المستخدم غير مسجل الدخول.');
      }
      LogService.info('تم استدعاء تهيئة قاعدة البيانات يدوياً');
      // The actual initialization is handled by appDatabaseProvider dependency evaluation.
    } catch (e) {
      LogService.error('خطأ في تهيئة قاعدة البيانات', e);
      rethrow;
    }
  }
}
