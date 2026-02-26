import 'package:drift/drift.dart';
import 'contacts_table.dart';

/// جدول المحادثات (Chats)
/// يخزن معلومات المحادثات الفردية والجماعية
class ChatsTable extends Table {
  /// معرف المحادثة (Primary Key)
  TextColumn get id => text()();

  /// معرف جهة الاتصال (Foreign Key -> ContactsTable.id)
  /// null إذا كانت المحادثة جماعية
  TextColumn get peerId => text().nullable().references(ContactsTable, #id)();

  /// اسم المحادثة (للمجموعات)
  TextColumn get name => text().nullable()();

  /// آخر رسالة في المحادثة
  TextColumn get lastMessage => text().nullable()();

  /// تاريخ آخر تحديث
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();

  /// هل المحادثة جماعية؟
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();

  /// عدد الأعضاء (للمجموعات)
  IntColumn get memberCount => integer().nullable().withDefault(const Constant(0))();

  /// لون الصورة الشخصية (للمجموعات)
  IntColumn get avatarColor => integer().withDefault(const Constant(0xFF0D9488))();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

