import 'package:drift/drift.dart';

/// جدول قائمة الانتظار للرسائل المرحلية (Relay Queue)
/// يخزن الرسائل المشفرة التي يجب إعادة توجيهها إلى أجهزة أخرى
/// 
/// Store-Carry-Forward Protocol:
/// - عندما يستقبل الجهاز رسالة ليست موجهة إليه، يحفظها هنا
/// - عند الاتصال بجهاز جديد، يرسل جميع الرسائل من هذا الجدول
/// - هذا يجعل الجهاز يعمل كـ "Data Mule" (حامل بيانات)
class RelayQueueTable extends Table {
  /// معرف فريد للرسالة (Primary Key)
  /// يستخدم messageId من MeshMessage
  TextColumn get messageId => text()();

  /// معرف المرسل الأصلي
  TextColumn get originalSenderId => text()();

  /// معرف الوجهة النهائية
  TextColumn get finalDestinationId => text()();

  /// المحتوى المشفر (Base64) - لا يتم فك التشفير هنا
  TextColumn get encryptedContent => text()();

  /// عدد القفزات الحالي
  IntColumn get hopCount => integer().withDefault(const Constant(0))();

  /// الحد الأقصى للقفزات (TTL)
  IntColumn get maxHops => integer().withDefault(const Constant(10))();

  /// قائمة معرفات الأجهزة التي مرت بها الرسالة (JSON array)
  TextColumn get trace => text().withDefault(const Constant('[]'))();

  /// الطابع الزمني للرسالة الأصلية
  DateTimeColumn get timestamp => dateTime()();

  /// نوع الرسالة (message, friend_added, etc.)
  TextColumn get type => text().nullable()();

  /// بيانات إضافية (JSON)
  TextColumn get metadata => text().nullable()();

  /// تاريخ إضافة الرسالة إلى قائمة الانتظار
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();

  /// عدد المحاولات لإرسال الرسالة
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// آخر محاولة إرسال
  DateTimeColumn get lastRetryAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {messageId};
}

