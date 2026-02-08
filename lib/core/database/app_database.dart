import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/contacts_table.dart';
import 'tables/chats_table.dart';
import 'tables/messages_table.dart';
import 'tables/relay_queue_table.dart';
import '../utils/log_service.dart';

part 'app_database.g.dart';

/// قاعدة بيانات التطبيق الرئيسية
/// تدعم Duress Mode (قاعدة بيانات حقيقية ووهمية)
/// تدعم Store-Carry-Forward Mesh Routing
@DriftDatabase(tables: [ContactsTable, ChatsTable, MessagesTable, RelayQueueTable])
class AppDatabase extends _$AppDatabase {
  /// اسم ملف قاعدة البيانات
  final String _databaseFileName;

  AppDatabase._(this._databaseFileName) : super(_openConnection(_databaseFileName));

  /// إنشاء instance جديد من قاعدة البيانات
  /// [filename]: اسم ملف قاعدة البيانات (مثل 'sada_encrypted.sqlite' أو 'sada_dummy.sqlite')
  factory AppDatabase.create(String filename) {
    return AppDatabase._(filename);
  }

  /// فتح اتصال قاعدة البيانات
  static LazyDatabase _openConnection(String filename) {
    return LazyDatabase(() async {
      // الحصول على مجلد قاعدة البيانات
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, filename));

      LogService.info('فتح قاعدة البيانات: ${file.path}');

      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        LogService.info('تم إنشاء جميع الجداول');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        LogService.info('ترقية قاعدة البيانات من schema $from إلى $to');
        // عند الترقية من schema 1 إلى 2
        if (from < 2) {
          // لا نعيد إنشاء الجداول - فقط نحدث schema version
          // الجداول موجودة بالفعل، لا حاجة لإعادة إنشائها
          LogService.info('تم الترقية إلى schema 2 - الجداول موجودة بالفعل');
        }
        // عند الترقية من schema 2 إلى 3 - إضافة RelayQueueTable
        if (from < 3) {
          LogService.info('إضافة RelayQueueTable للـ Store-Carry-Forward Mesh Routing');
          await m.createTable(relayQueueTable);
        }
      },
    );
  }

  // ==================== DAOs (Data Access Objects) ====================

  /// إدراج جهة اتصال جديدة
  Future<void> insertContact(ContactsTableCompanion contact) async {
    await into(contactsTable).insert(contact, mode: InsertMode.replace);
    LogService.info('تم إدراج جهة اتصال: ${contact.id.value}');
  }

  /// الحصول على جميع جهات الاتصال
  Future<List<ContactsTableData>> getAllContacts() async {
    return await (select(contactsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  /// الحصول على جهة اتصال بواسطة ID
  Future<ContactsTableData?> getContactById(String id) async {
    try {
      return await (select(contactsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    } catch (e) {
      LogService.warning('فشل الحصول على جهة الاتصال: $id - $e');
      return null;
    }
  }

  /// تحديث جهة اتصال
  Future<bool> updateContact(String id, ContactsTableCompanion contact) async {
    final rowsAffected = await (update(contactsTable)..where((t) => t.id.equals(id))).write(contact);
    return rowsAffected > 0;
  }

  /// حظر/إلغاء حظر جهة اتصال
  Future<bool> toggleBlockContact(String id, bool isBlocked) async {
    final rowsAffected = await (update(contactsTable)..where((t) => t.id.equals(id)))
        .write(ContactsTableCompanion(isBlocked: Value(isBlocked)));
    return rowsAffected > 0;
  }

  /// حذف جهة اتصال
  Future<bool> deleteContact(String id) async {
    final rowsAffected = await (delete(contactsTable)..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  // ==================== Chats DAOs ====================

  /// إدراج محادثة جديدة
  Future<void> insertChat(ChatsTableCompanion chat) async {
    await into(chatsTable).insert(chat, mode: InsertMode.replace);
    LogService.info('تم إدراج محادثة: ${chat.id.value}');
  }

  /// الحصول على جميع المحادثات
  Future<List<ChatsTableData>> getAllChats() async {
    try {
      return await (select(chatsTable)
            ..orderBy([(t) => OrderingTerm(expression: t.lastUpdated, mode: OrderingMode.desc)]))
          .get();
    } catch (e) {
      LogService.error('فشل الحصول على المحادثات من قاعدة البيانات', e);
      // إرجاع قائمة فارغة بدلاً من رمي خطأ
      return [];
    }
  }

  /// الحصول على محادثة بواسطة ID
  Future<ChatsTableData?> getChatById(String id) async {
    return await (select(chatsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// الحصول على محادثة بواسطة peerId
  Future<ChatsTableData?> getChatByPeerId(String peerId) async {
    return await (select(chatsTable)..where((t) => t.peerId.equals(peerId))).getSingleOrNull();
  }

  /// تحديث آخر رسالة في المحادثة
  Future<bool> updateLastMessage(String chatId, String lastMessage) async {
    final rowsAffected = await (update(chatsTable)..where((t) => t.id.equals(chatId)))
        .write(ChatsTableCompanion(
      lastMessage: Value(lastMessage),
      lastUpdated: Value(DateTime.now()),
    ));
    return rowsAffected > 0;
  }

  /// حذف محادثة
  Future<bool> deleteChat(String id) async {
    // حذف جميع الرسائل المرتبطة أولاً
    await (delete(messagesTable)..where((t) => t.chatId.equals(id))).go();
    
    // ثم حذف المحادثة
    final rowsAffected = await (delete(chatsTable)..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  // ==================== Messages DAOs ====================

  /// إدراج رسالة جديدة
  Future<void> insertMessage(MessagesTableCompanion message) async {
    await into(messagesTable).insert(message, mode: InsertMode.replace);
    LogService.info('تم إدراج رسالة: ${message.id.value}');
    
    // تحديث آخر رسالة في المحادثة
    final content = message.content.value;
    await updateLastMessage(message.chatId.value, content);
  }

  /// الحصول على جميع الرسائل في محادثة معينة
  Future<List<MessagesTableData>> getMessagesForChat(String chatId, {int? limit, int? offset}) async {
    final query = select(messagesTable)
      ..where((t) => t.chatId.equals(chatId))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]);

    if (limit != null) {
      query.limit(limit, offset: offset ?? 0);
    }

    return await query.get();
  }

  /// مراقبة الرسائل في محادثة معينة (Stream)
  Stream<List<MessagesTableData>> watchMessagesForChat(String chatId) {
    return (select(messagesTable)
          ..where((t) => t.chatId.equals(chatId))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .watch();
  }

  /// الحصول على رسالة بواسطة ID
  Future<MessagesTableData?> getMessageById(String id) async {
    return await (select(messagesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// تحديث حالة الرسالة
  Future<bool> updateMessageStatus(String id, String status) async {
    final rowsAffected = await (update(messagesTable)..where((t) => t.id.equals(id)))
        .write(MessagesTableCompanion(status: Value(status)));
    return rowsAffected > 0;
  }

  /// حذف رسالة
  Future<bool> deleteMessage(String id) async {
    final rowsAffected = await (delete(messagesTable)..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// حذف جميع الرسائل في محادثة
  Future<int> deleteMessagesForChat(String chatId) async {
    return await (delete(messagesTable)..where((t) => t.chatId.equals(chatId))).go();
  }

  /// الحصول على عدد الرسائل غير المقروءة في محادثة
  Future<int> getUnreadMessageCount(String chatId) async {
    try {
      final query = selectOnly(messagesTable)
        ..addColumns([messagesTable.id.count()])
        ..where(messagesTable.chatId.equals(chatId) &
            messagesTable.isFromMe.equals(false) &
            messagesTable.status.isNotValue('read'));

      final result = await query.getSingle();
      return result.read(messagesTable.id.count()) ?? 0;
    } catch (e) {
      LogService.warning('فشل حساب الرسائل غير المقروءة: $chatId - $e');
      // إرجاع 0 بدلاً من رمي خطأ
      return 0;
    }
  }

  // ==================== Relay Queue DAOs ====================

  /// إضافة رسالة إلى قائمة الانتظار للترحيل
  Future<void> enqueueRelayMessage(RelayQueueTableCompanion message) async {
    await into(relayQueueTable).insert(message, mode: InsertMode.replace);
    LogService.info('تم إضافة رسالة إلى RelayQueue: ${message.messageId.value}');
  }

  /// الحصول على جميع الرسائل في قائمة الانتظار
  Future<List<RelayQueueTableData>> getRelayQueue() async {
    return await (select(relayQueueTable)
          ..orderBy([(t) => OrderingTerm(expression: t.queuedAt)]))
        .get();
  }

  /// الحصول على رسائل قائمة الانتظار الموجهة لجهاز معين
  Future<List<RelayQueueTableData>> getRelayQueueForDestination(String destinationId) async {
    return await (select(relayQueueTable)
          ..where((t) => t.finalDestinationId.equals(destinationId))
          ..orderBy([(t) => OrderingTerm(expression: t.queuedAt)]))
        .get();
  }

  /// التحقق من وجود رسالة في قائمة الانتظار (deduplication)
  Future<bool> isMessageInQueue(String messageId) async {
    final result = await (select(relayQueueTable)
          ..where((t) => t.messageId.equals(messageId)))
        .getSingleOrNull();
    return result != null;
  }

  /// حذف رسالة من قائمة الانتظار (بعد إرسالها بنجاح)
  Future<bool> removeFromRelayQueue(String messageId) async {
    final rowsAffected = await (delete(relayQueueTable)
          ..where((t) => t.messageId.equals(messageId)))
        .go();
    if (rowsAffected > 0) {
      LogService.info('تم حذف رسالة من RelayQueue: $messageId');
    }
    return rowsAffected > 0;
  }

  /// حذف الرسائل القديمة (أكثر من 24 ساعة)
  Future<int> cleanupOldRelayMessages() async {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    final rowsAffected = await (delete(relayQueueTable)
          ..where((t) => t.timestamp.isSmallerThanValue(cutoffTime)))
        .go();
    if (rowsAffected > 0) {
      LogService.info('تم حذف $rowsAffected رسالة قديمة من RelayQueue');
    }
    return rowsAffected;
  }

  /// تحديث عدد المحاولات
  Future<void> incrementRetryCount(String messageId) async {
    final message = await (select(relayQueueTable)
          ..where((t) => t.messageId.equals(messageId)))
        .getSingleOrNull();
    
    if (message != null) {
      await (update(relayQueueTable)..where((t) => t.messageId.equals(messageId)))
          .write(RelayQueueTableCompanion(
        retryCount: Value(message.retryCount + 1),
        lastRetryAt: Value(DateTime.now()),
      ));
    }
  }

  /// حذف الرسائل التي تجاوزت الحد الأقصى للمحاولات (5 محاولات)
  Future<int> removeFailedMessages() async {
    const maxRetries = 5;
    final rowsAffected = await (delete(relayQueueTable)
          ..where((t) => t.retryCount.isBiggerThanValue(maxRetries)))
        .go();
    if (rowsAffected > 0) {
      LogService.info('تم حذف $rowsAffected رسالة فاشلة من RelayQueue');
    }
    return rowsAffected;
  }

  @override
  Future<void> close() {
    LogService.info('إغلاق قاعدة البيانات: $_databaseFileName');
    return super.close();
  }
}

