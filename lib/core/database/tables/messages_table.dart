import 'package:drift/drift.dart';
import 'chats_table.dart';

/// نوع الرسالة
enum MessageType {
  text,
  image,
  voice,
  file,
}

/// حالة الرسالة
enum MessageStatus {
  sending,   // قيد الإرسال
  sent,      // تم الإرسال
  delivered, // تم التسليم
  read,      // تم القراءة
  failed,    // فشل الإرسال
}

/// جدول الرسائل (Messages)
/// يخزن جميع الرسائل في المحادثات
class MessagesTable extends Table {
  /// معرف الرسالة (Primary Key)
  TextColumn get id => text()();

  /// معرف المحادثة (Foreign Key -> ChatsTable.id)
  TextColumn get chatId => text().references(ChatsTable, #id)();

  /// معرف المرسل
  TextColumn get senderId => text()();

  /// محتوى الرسالة (مشفّر)
  TextColumn get content => text()();

  /// نوع الرسالة (text, image, voice, file)
  TextColumn get type => text().withDefault(const Constant('text'))();

  /// حالة الرسالة (sending, sent, delivered, read, failed)
  TextColumn get status => text().withDefault(const Constant('sending'))();

  /// الطابع الزمني
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  /// هل الرسالة من المستخدم الحالي؟
  BoolColumn get isFromMe => boolean().withDefault(const Constant(false))();

  /// معرف الرسالة المرجعية (للرد على رسالة)
  TextColumn get replyToId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

