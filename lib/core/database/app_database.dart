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
import '../utils/constants.dart';

part 'app_database.g.dart';

/// قاعدة بيانات التطبيق الرئيسية
/// تدعم Duress Mode (قاعدة بيانات حقيقية ووهمية)
/// تدعم Store-Carry-Forward Mesh Routing
@DriftDatabase(tables: [ContactsTable, ChatsTable, MessagesTable, RelayQueueTable])
class AppDatabase extends _$AppDatabase {
  /// اسم ملف قاعدة البيانات
  // ignore: unused_field
  final String _databaseFileName;

  AppDatabase._(this._databaseFileName) : super(_openConnection(_databaseFileName));

  /// Constructor for testing with in-memory database
  AppDatabase.forTesting(QueryExecutor executor) : _databaseFileName = 'memory', super(executor);

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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        LogService.info('تم إنشاء جميع الجداول');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        LogService.info('ترقية قاعدة البيانات من schema $from إلى $to');
        // When upgrading from schema 1 to 2
        if (from < 2) {
          LogService.info('تم الترقية إلى schema 2');
        }
        // When upgrading from schema 2 or 3 to 4 (RelayQueueTable changes)
        if (from < 4) {
          LogService.info('تحديث RelayQueueTable لدعم Blind Relaying (Schema v4)');
          await m.deleteTable('relay_queue_table');
          await m.createTable(relayQueueTable);
        }
        // When upgrading to schema 5 (Add retryCount)
        if (from < 5) {
          LogService.info('إضافة retryCount لتعقب محاولات الإرسال (Schema v5)');
          await m.addColumn(relayQueueTable, relayQueueTable.retryCount);
          await m.addColumn(messagesTable, messagesTable.retryCount);
        }
        // When upgrading to schema 6 (Add priority)
        if (from < 6) {
          LogService.info('إضافة priority لدعم Congestion Control (Schema v6)');
          await m.addColumn(relayQueueTable, relayQueueTable.priority);
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
  /// إدراج رسالة جديدة (Atomic Transaction)
  Future<void> insertMessage(MessagesTableCompanion message) async {
    await transaction(() async {
      await into(messagesTable).insert(message, mode: InsertMode.replace);
      LogService.info('تم إدراج رسالة: ${message.id.value}');
      
      // تحديث آخر رسالة في المحادثة
      final content = message.content.value;
      await updateLastMessage(message.chatId.value, content);
    });
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

  /// Add a packet to the relay queue.
  /// Add a packet to the relay queue.
  Future<void> enqueueRelayPacket(RelayQueueTableCompanion packet) async {
    // 1. Check if packet already exists (Deduplication)
    final existing = await hasPacket(packet.packetId.value);
    if (existing) {
       // If it exists but new one has higher priority or is newer, maybe update?
       // For now, simpler to just skip.
       return;
    }

    // 2. Check limits and make space if needed
    // Calculate size of new packet
    final newPacketSize = packet.payload.value.length;
    final maxBytes = AppConstants.relayQueueMaxBytes;
    
    final currentBytes = await getRelayQueueByteSize();
    final currentCount = await getRelayStorageSize();
    
    bool needsTrim = (currentBytes + newPacketSize > maxBytes) || 
                     (currentCount >= AppConstants.relayQueueMaxCount);

    if (needsTrim) {
       // Try to trim LOWER priority packets first
       final incomingPriority = packet.priority.value;
       
       // Trim strategy:
       // 1. Delete expired packets first (always good)
       await cleanupExpiredPackets();
       
       // 2. Delete lowest priority packets (priority < incomingPriority)
       // until we have space.
       // Only if incoming is high priority (>=1), we aggressively delete lower ones.
       
       // 3. If still full, and incoming is low priority, drop incoming.
       
       // Let's implement a unified trim function that respects priority
       await _makeSpaceForPacket(newPacketSize, incomingPriority);
       
       // Re-check space
       final spaceAfterTrim = await getRelayQueueByteSize();
       final countAfterTrim = await getRelayStorageSize();
       
       if (spaceAfterTrim + newPacketSize > maxBytes || countAfterTrim >= AppConstants.relayQueueMaxCount) {
         LogService.warning('⚠️ Relay Queue ممتلئ - تم رفض الحزمة (أولوية منخفضة أو لا توجد مساحة): ${packet.packetId.value}');
         return;
       }
    }

    await into(relayQueueTable).insert(packet, mode: InsertMode.replace);
    LogService.info('📦 تم تخزين Relay Packet: ${packet.packetId.value} (الأولوية: ${packet.priority.value})');
  }

  /// Get all relay packets for syncing with another device.
  /// Returns packets that are not expired and valid to send.
  Future<List<RelayQueueTableData>> getRelayPacketsForSync() async {
    // TODO: Implement bloom filter or vector summary check logic if needed here
    // For now, return all valid packets
    return await (select(relayQueueTable)
          ..orderBy([(t) => OrderingTerm(expression: t.queuedAt)]))
        .get();
  }

  /// Check if we have a packet for this specific target hash.
  /// Used when checking "Is this for me?".
  Future<List<RelayQueueTableData>> getPacketsForTargetHash(String targetHash) async {
    return await (select(relayQueueTable)
          ..where((t) => t.toHash.equals(targetHash)))
        .get();
  }

  /// Check if a packet already exists in the queue (Deduplication).
  Future<bool> hasPacket(String packetId) async {
    final result = await (select(relayQueueTable)
          ..where((t) => t.packetId.equals(packetId)))
        .getSingleOrNull();
    return result != null;
  }

  /// Get a single relay packet by ID, or null if it does not exist.
  Future<RelayQueueTableData?> getRelayPacketById(String packetId) async {
    return await (select(relayQueueTable)
          ..where((t) => t.packetId.equals(packetId)))
        .getSingleOrNull();
  }

  /// Delete a packet from the queue.
  Future<bool> deletePacket(String packetId) async {
    final rows = await (delete(relayQueueTable)
          ..where((t) => t.packetId.equals(packetId)))
        .go();
    return rows > 0;
  }

  /// Cleanup expired packets (TTL check).
  /// This should be run periodically.
  Future<int> cleanupExpiredPackets() async {
    // Determine cutoff based on TTL?
    // Since TTL is per-packet (in hops or hours), we might need a more complex query
    // or iterate. For simplicity/performance, let's assume a hard global limit for now
    // or rely on the application logic to check `isExpired()` and delete.
    
    // Efficient approach: Delete packets older than global max limit (e.g. 7 days)
    // regardless of internal TTL to save space.
    final hardLimit = DateTime.now().subtract(const Duration(days: 7));
    final rows = await (delete(relayQueueTable)
          ..where((t) => t.createdAt.isSmallerThanValue(hardLimit)))
        .go();
    
    if (rows > 0) LogService.info('🧹 تم تنظيف $rows حزم منتهية الصلاحية');
    return rows;
  }

  /// Get total size of relay storage (optional constraint check).
  Future<int> getRelayStorageSize() async {
    // Drift doesn't have direct "size" query easily without custom SQL.
    // Count is a proxy.
    final count = await (selectOnly(relayQueueTable)..addColumns([relayQueueTable.packetId.count()])).getSingle();
    return count.read(relayQueueTable.packetId.count()) ?? 0;
  }

  /// Get total byte size of relay storage (approximate).
  Future<int> getRelayQueueByteSize() async {
    final packets = await (select(relayQueueTable)).get();
    int totalBytes = 0;
    for (final packet in packets) {
      totalBytes += packet.payload.length; // Approximate based on payload size
    }
    return totalBytes;
  }

  /// إخلاء مساحة لحزمة جديدة بناءً على الأولوية
  Future<void> _makeSpaceForPacket(int requiredBytes, int incomingPriority) async {
    final maxBytes = AppConstants.relayQueueMaxBytes;
    final maxCount = AppConstants.relayQueueMaxCount;
    
    // الحصول بسرعة على الحجم الحالي والعدد
    int currentBytes = await getRelayQueueByteSize();
    int currentCount = await getRelayStorageSize();
    
    bool bytesOk = (currentBytes + requiredBytes <= maxBytes);
    bool countOk = (currentCount < maxCount); // Must be strictly less to add 1

    if (bytesOk && countOk) return; // يوجد مساحة كافية
    
    // جلب جميع الحزم مرتبة:
    // 1. الأقل أولوية أولاً (ASC)
    // 2. الأقدم أولاً (ASC)
    // لضمان حذف الأقل أهمية ثم الأقدم
    final packets = await (select(relayQueueTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.queuedAt, mode: OrderingMode.asc),
          ]))
        .get();
        
    int bytesFreed = 0;
    int deletedCount = 0;
    
    for (final packet in packets) {
      if (packet.priority > incomingPriority) {
        // We reached packets that are more important than the new one.
        // If we still don't have space, we can't make space. Stop.
        break;
      }
      
      await deletePacket(packet.packetId);
      bytesFreed += packet.payload.length;
      deletedCount++;
      
      currentBytes -= packet.payload.length;
      currentCount--;
      
      bytesOk = (currentBytes + requiredBytes <= maxBytes);
      countOk = (currentCount < maxCount);
      
      if (bytesOk && countOk) {
        break; // Done
      }
    }
    
    if (deletedCount > 0) {
      LogService.info('🧹 تم إخلاء مساحة: حذف $deletedCount حزم للحفاظ على الأولوية (Count: $countOk, Bytes: $bytesOk)');
    }
  }

  /// حذف عدد محدد من أقدم الحزم (Legacy - used only if needed directly)
  Future<void> _trimRelayQueue(int deleteCount) async {
     // Use unified logic or keep for simple count trimming
     // For now, let's just delegate to makeSpace logic or keep simple FIFO for count limit
     // Strict FIFO for count limit might kill High Priority packets.
     // Better adapt this too.
     
     // For now, just call _makeSpaceForPacket with dummy byte size to force eviction?
     // No, count limit is separate.
     
     // Let's reimplement trim to respect priority for count limit too.
     if (deleteCount <= 0) return;
     
      final packets = await (select(relayQueueTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.asc), // Delete low prio first
            (t) => OrderingTerm(expression: t.queuedAt, mode: OrderingMode.asc), // Delete old first
          ])
          ..limit(deleteCount)) // Use cascade for limit
        .get();

     for (final p in packets) {
       await deletePacket(p.packetId);
     }
  }

  /// حذف أقدم الحزم (Legacy - replaced by _makeSpaceForPacket logic mostly)
  Future<void> _trimRelayQueueByBytes(int maxBytes) async {
      // Replaced by logic in enqueueRelayPacket
  }

  /// تنظيف الرسائل القديمة في Relay Queue (Congestion Control)
  Future<int> cleanupOldRelayMessages() async {
    // حذف الرسائل التي تجاوزت مدة معينة (مثلاً 7 أيام)
    final expirationDate = DateTime.now().subtract(const Duration(days: 7));
    
    final rowsDeleted = await (delete(relayQueueTable)
      ..where((t) => t.queuedAt.isSmallerThanValue(expirationDate)))
      .go();
      
    if (rowsDeleted > 0) {
      LogService.info('🧹 تم تنظيف $rowsDeleted رسائل Relay قديمة');
    }
    return rowsDeleted;
  }

  /// حذف الرسائل التي فشل إرسالها (status = failed)
  /// ملاحظة: عادة لا نحذف الرسائل الفاشلة فوراً، لكن قد نحتاج لتنظيفها إذا تراكمت
  Future<int> removeFailedMessages() async {
    final rowsDeleted = await (delete(messagesTable)
      ..where((t) => t.status.equals('failed')))
      .go();
      
    if (rowsDeleted > 0) {
      LogService.info('🧹 تم حذف $rowsDeleted رسائل فاشلة');
    }
    return rowsDeleted;
  }

  /// زيادة عدد محاولات الإرسال (Retry Count) لرسالة
  Future<void> incrementRetryCount(String messageId) async {
    // 1. Check Relay Queue
    final relayPacket = await (select(relayQueueTable)..where((t) => t.packetId.equals(messageId))).getSingleOrNull();
    if (relayPacket != null) {
      final newCount = relayPacket.retryCount + 1;
      await (update(relayQueueTable)..where((t) => t.packetId.equals(messageId)))
          .write(RelayQueueTableCompanion(retryCount: Value(newCount)));
      return; 
    }

    // 2. Check Messages Table
    final message = await (select(messagesTable)..where((t) => t.id.equals(messageId))).getSingleOrNull();
    if (message != null) {
      final newCount = message.retryCount + 1;
      await (update(messagesTable)..where((t) => t.id.equals(messageId)))
          .write(MessagesTableCompanion(retryCount: Value(newCount)));
    }
  }
  // ==================== Metrics ====================

  /// الحصول على إحصائيات Relay Queue
  Future<Map<String, dynamic>> getRelayQueueMetrics() async {
    final count = await getRelayStorageSize();
    final bytes = await getRelayQueueByteSize();
    
    // Breakdown by Priority
    final highPriorityCount = await (selectOnly(relayQueueTable)
      ..addColumns([relayQueueTable.packetId.count()])
      ..where(relayQueueTable.priority.equals(2)))
      .getSingle();
      
    final standardPriorityCount = await (selectOnly(relayQueueTable)
      ..addColumns([relayQueueTable.packetId.count()])
      ..where(relayQueueTable.priority.equals(1)))
      .getSingle();
      
    final lowPriorityCount = await (selectOnly(relayQueueTable)
      ..addColumns([relayQueueTable.packetId.count()])
      ..where(relayQueueTable.priority.equals(0)))
      .getSingle();

    return {
      'totalCount': count,
      'totalBytes': bytes,
      'highPriority': highPriorityCount.read(relayQueueTable.packetId.count()) ?? 0,
      'standardPriority': standardPriorityCount.read(relayQueueTable.packetId.count()) ?? 0,
      'lowPriority': lowPriorityCount.read(relayQueueTable.packetId.count()) ?? 0,
      'limitBytes': AppConstants.relayQueueMaxBytes,
      'limitCount': AppConstants.relayQueueMaxCount,
    };
  }

  /// الحصول على جميع معرفات الرسائل المعروفة (من الرسائل و Relay Queue)
  /// يستخدم لبناء Bloom Filter للمزامنة
  Future<List<String>> getAllKnownMessageIds() async {
    final allIds = <String>[];
    
    // Get message IDs using raw SQL to avoid code generation issues
    final messageResult = await customSelect(
      'SELECT id FROM messages_table',
      readsFrom: {messagesTable},
    ).get();
    
    for (final row in messageResult) {
      final id = row.read<String>('id');
      allIds.add(id);
    }
    
    // Get relay packet IDs
    final relayResult = await customSelect(
      'SELECT packet_id FROM relay_queue_table',
      readsFrom: {relayQueueTable},
    ).get();
    
    for (final row in relayResult) {
      final id = row.read<String>('packet_id');
      allIds.add(id);
    }
    
    return allIds;
  }
}

