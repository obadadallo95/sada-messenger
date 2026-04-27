import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sada/core/database/tables/contacts_table.dart';
import 'package:sada/core/database/tables/chats_table.dart';
import 'package:sada/core/database/tables/messages_table.dart';

part 'test_helpers.g.dart';

/// قاعدة بيانات للاختبار (in-memory)
@DriftDatabase(tables: [ContactsTable, ChatsTable, MessagesTable])
class TestDatabase extends _$TestDatabase {
  TestDatabase() : super(_openConnection());

  static LazyDatabase _openConnection() {
    // استخدام in-memory database
    return LazyDatabase(() async {
      // إنشاء اتصال SQLite في الذاكرة
      // NativeDatabase.memory() يعيد QueryExecutor مباشرة
      return NativeDatabase.memory();
    });
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }

  // نفس الدوال من AppDatabase
  Future<void> insertContact(ContactsTableCompanion contact) async {
    await into(contactsTable).insert(contact, mode: InsertMode.replace);
  }

  Future<List<ContactsTableData>> getAllContacts() async {
    return await (select(contactsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<void> insertChat(ChatsTableCompanion chat) async {
    await into(chatsTable).insert(chat, mode: InsertMode.replace);
  }

  Future<void> insertMessage(MessagesTableCompanion message) async {
    await into(messagesTable).insert(message, mode: InsertMode.replace);
    
    // تحديث آخر رسالة في المحادثة
    final content = message.content.value;
    await updateLastMessage(message.chatId.value, content);
  }

  Future<bool> updateLastMessage(String chatId, String lastMessage) async {
    final rowsAffected = await (update(chatsTable)..where((t) => t.id.equals(chatId)))
        .write(ChatsTableCompanion(
      lastMessage: Value(lastMessage),
      lastUpdated: Value(DateTime.now()),
    ));
    return rowsAffected > 0;
  }

  Future<List<MessagesTableData>> getMessagesForChat(String chatId, {int? limit, int? offset}) async {
    final query = select(messagesTable)
      ..where((t) => t.chatId.equals(chatId))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]);

    if (limit != null) {
      query.limit(limit, offset: offset ?? 0);
    }

    return await query.get();
  }
}

