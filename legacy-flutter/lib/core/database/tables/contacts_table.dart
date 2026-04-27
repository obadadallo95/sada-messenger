import 'package:drift/drift.dart';

/// جدول جهات الاتصال (Contacts)
/// يخزن معلومات المستخدمين الذين تمت إضافتهم كأصدقاء
class ContactsTable extends Table {
  /// معرف جهة الاتصال (Primary Key)
  TextColumn get id => text()();

  /// اسم جهة الاتصال
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// المفتاح العام لجهة الاتصال (للتشفير)
  TextColumn get publicKey => text().nullable()();

  /// الصورة الشخصية (Base64 encoded)
  TextColumn get avatar => text().nullable()();

  /// حالة الحظر (Blocked)
  BoolColumn get isBlocked => boolean().withDefault(const Constant(false))();

  /// تاريخ الإضافة
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// تاريخ آخر تحديث
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

