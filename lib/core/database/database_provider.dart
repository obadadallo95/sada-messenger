import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../utils/log_service.dart';
import 'app_database.dart';

/// حالة قاعدة البيانات
enum DatabaseMode {
  real, // قاعدة البيانات الحقيقية
  dummy, // قاعدة البيانات الوهمية
}

/// Provider لحالة قاعدة البيانات
final databaseModeProvider = StateProvider<DatabaseMode?>((ref) => null);

/// Provider لحالة AuthType الحالية
final currentAuthTypeProvider = StateProvider<AuthType?>((ref) => null);

/// Provider لاسم ملف قاعدة البيانات
final databaseFileNameProvider = Provider<String>((ref) {
  final authType = ref.watch(currentAuthTypeProvider);
  final mode = ref.watch(databaseModeProvider);
  
  // تحديد نوع قاعدة البيانات بناءً على AuthType
  if (authType == AuthType.master) {
    return 'sada_encrypted.sqlite'; // قاعدة البيانات الحقيقية
  } else if (authType == AuthType.duress) {
    return 'sada_dummy.sqlite'; // قاعدة البيانات الوهمية
  }
  
  // إذا لم يكن هناك AuthType، استخدام القيمة الافتراضية
  if (mode == DatabaseMode.dummy) {
    return 'sada_dummy.sqlite';
  }
  
  return 'sada_encrypted.sqlite';
});

/// Provider لـ AppDatabase
/// ينتظر AuthType ثم يهيئ قاعدة البيانات المناسبة
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final authType = ref.watch(currentAuthTypeProvider);
  
  if (authType == null) {
    throw Exception('AuthType غير محدد. يجب تسجيل الدخول أولاً.');
  }
  
  final filename = ref.read(databaseFileNameProvider);
  final database = AppDatabase.create(filename);
  
  // تهيئة قاعدة البيانات (إنشاء الجداول)
  await database.customStatement('PRAGMA foreign_keys = ON');
  
  LogService.info('تم تهيئة قاعدة البيانات: $filename');
  
  return database;
});

/// Provider لتهيئة قاعدة البيانات
final databaseInitializerProvider = Provider<DatabaseInitializer>((ref) {
  return DatabaseInitializer(ref);
});

/// مدير قاعدة البيانات
/// يتعامل مع تهيئة قاعدة البيانات الحقيقية والوهمية
class DatabaseInitializer {
  final Ref _ref;
  
  DatabaseInitializer(this._ref);
  
  /// تهيئة قاعدة البيانات بناءً على AuthType
  Future<void> initializeDatabase(AuthType authType) async {
    try {
      // حفظ AuthType في Provider
      _ref.read(currentAuthTypeProvider.notifier).state = authType;
      
      if (authType == AuthType.master) {
        // تهيئة قاعدة البيانات الحقيقية
        await _initializeRealDatabase();
        _ref.read(databaseModeProvider.notifier).state = DatabaseMode.real;
        LogService.info('تم تهيئة قاعدة البيانات الحقيقية');
      } else if (authType == AuthType.duress) {
        // تهيئة قاعدة البيانات الوهمية
        await _initializeDummyDatabase();
        _ref.read(databaseModeProvider.notifier).state = DatabaseMode.dummy;
        LogService.info('تم تهيئة قاعدة البيانات الوهمية (Duress Mode)');
      }
    } catch (e) {
      LogService.error('خطأ في تهيئة قاعدة البيانات', e);
      rethrow;
    }
  }
  
  /// تهيئة قاعدة البيانات الحقيقية
  Future<void> _initializeRealDatabase() async {
    LogService.info('تهيئة قاعدة البيانات الحقيقية...');
    
    // الحصول على قاعدة البيانات
    final databaseAsync = _ref.read(appDatabaseProvider);
    await databaseAsync.when(
      data: (db) async {
        // قاعدة البيانات الحقيقية - فارغة (لا بيانات وهمية)
        LogService.info('قاعدة البيانات الحقيقية جاهزة');
      },
      loading: () async {
        // انتظار التهيئة
        await Future.delayed(const Duration(milliseconds: 100));
      },
      error: (error, stack) {
        LogService.error('خطأ في تهيئة قاعدة البيانات الحقيقية', error);
        throw error;
      },
    );
  }
  
  /// تهيئة قاعدة البيانات الوهمية
  /// تملأ قاعدة البيانات ببيانات وهمية
  Future<void> _initializeDummyDatabase() async {
    LogService.info('تهيئة قاعدة البيانات الوهمية...');
    
    // الحصول على قاعدة البيانات
    final databaseAsync = _ref.read(appDatabaseProvider);
    await databaseAsync.when(
      data: (db) async {
        // التحقق من وجود بيانات وهمية
        final existingChats = await db.getAllChats();
        
        if (existingChats.isEmpty) {
          LogService.info('إدراج بيانات وهمية...');
          await _populateDummyData(db);
          LogService.info('تم إدراج البيانات الوهمية بنجاح');
        } else {
          LogService.info('قاعدة البيانات الوهمية تحتوي بالفعل على بيانات');
        }
      },
      loading: () async {
        // انتظار التهيئة
        await Future.delayed(const Duration(milliseconds: 100));
      },
      error: (error, stack) {
        LogService.error('خطأ في تهيئة قاعدة البيانات الوهمية', error);
        throw error;
      },
    );
  }
  
  /// ملء قاعدة البيانات الوهمية ببيانات وهمية
  Future<void> _populateDummyData(AppDatabase db) async {
    final uuid = const Uuid();
    
    // 1. إدراج جهات اتصال وهمية
    final momContactId = uuid.v4();
    await db.insertContact(ContactsTableCompanion.insert(
      id: momContactId,
      name: 'Mom',
      publicKey: const Value.absent(),
      avatar: const Value.absent(),
      isBlocked: const Value(false),
    ));
    
    final footballGroupId = uuid.v4();
    await db.insertContact(ContactsTableCompanion.insert(
      id: footballGroupId,
      name: 'Football Group',
      publicKey: const Value.absent(),
      avatar: const Value.absent(),
      isBlocked: const Value(false),
    ));
    
    // 2. إدراج محادثات وهمية
    final momChatId = uuid.v4();
    await db.insertChat(ChatsTableCompanion.insert(
      id: momChatId,
      peerId: Value(momContactId),
      name: const Value.absent(),
      lastMessage: const Value('Don\'t forget to buy bread.'),
      lastUpdated: Value(DateTime.now().subtract(const Duration(hours: 2))),
      isGroup: const Value(false),
      memberCount: const Value.absent(),
      avatarColor: const Value(0xFF4CAF50),
    ));
    
    final footballChatId = uuid.v4();
    await db.insertChat(ChatsTableCompanion.insert(
      id: footballChatId,
      peerId: Value(footballGroupId),
      name: const Value('Football Group'),
      lastMessage: const Value('Match is at 5 PM.'),
      lastUpdated: Value(DateTime.now().subtract(const Duration(hours: 1))),
      isGroup: const Value(true),
      memberCount: const Value(12),
      avatarColor: const Value(0xFF2196F3),
    ));
    
    // 3. إدراج رسائل وهمية
    await db.insertMessage(MessagesTableCompanion.insert(
      id: uuid.v4(),
      chatId: momChatId,
      senderId: momContactId,
      content: 'Don\'t forget to buy bread.',
      type: const Value('text'),
      status: const Value('read'),
      timestamp: Value(DateTime.now().subtract(const Duration(hours: 2))),
      isFromMe: const Value(false),
      replyToId: const Value.absent(),
    ));
    
    await db.insertMessage(MessagesTableCompanion.insert(
      id: uuid.v4(),
      chatId: footballChatId,
      senderId: footballGroupId,
      content: 'Match is at 5 PM.',
      type: const Value('text'),
      status: const Value('read'),
      timestamp: Value(DateTime.now().subtract(const Duration(hours: 1))),
      isFromMe: const Value(false),
      replyToId: const Value.absent(),
    ));
    
    LogService.info('تم إدراج البيانات الوهمية: 2 جهات اتصال، 2 محادثات، 2 رسائل');
  }
  
  /// التحقق من وجود قاعدة البيانات الوهمية
  Future<bool> dummyDatabaseExists() async {
    try {
      final databaseAsync = _ref.read(appDatabaseProvider);
      return await databaseAsync.when(
        data: (db) async {
          final chats = await db.getAllChats();
          return chats.isNotEmpty;
        },
        loading: () => false,
        error: (_, _) => false,
      );
    } catch (e) {
      return false;
    }
  }
  
  /// إنشاء قاعدة البيانات الوهمية إذا لم تكن موجودة
  Future<void> ensureDummyDatabase() async {
    final exists = await dummyDatabaseExists();
    if (!exists) {
      await _initializeDummyDatabase();
    }
  }
}
