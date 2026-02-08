import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:sodium_libs/sodium_libs.dart' hide SodiumInit;
import 'package:sodium_libs/sodium_libs.dart' as sodium_libs show SodiumInit;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import app code
import 'package:sada/core/database/tables/contacts_table.dart';
import 'package:sada/core/database/tables/chats_table.dart';
import 'package:sada/core/database/tables/messages_table.dart';
import 'package:sada/core/security/key_manager.dart';
import 'package:sada/core/security/encryption_service.dart';
import 'package:sada/core/services/auth_service.dart';
import 'test_helpers.dart';

/// ============================================
/// SCENARIO A: The Security Check (Encryption Logic)
/// ============================================
void main() {
  // تهيئة Flutter bindings للاختبارات التي تحتاجها (مثل FlutterSecureStorage)
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Scenario A: The Security Check (Encryption Logic)', () {
    late KeyManager keyManager;
    late EncryptionService encryptionService;

    setUp(() async {
      // ⚠️ تهيئة خاصة لـ sodium_libs على الجهاز الحقيقي
      // نحتاج انتظار قليل حتى يتم تهيئة SodiumPlatform
      try {
        // محاولة تهيئة sodium_libs مباشرة
        await sodium_libs.SodiumInit.init();
        print('✅ تم تهيئة sodium_libs بنجاح');
      } catch (e) {
        print('⚠️ تحذير: فشل تهيئة sodium_libs مسبقاً: $e');
        // نتابع - قد يعمل في KeyManager.initialize()
      }
      
      // انتظار قليل للتأكد من اكتمال التهيئة
      await Future.delayed(const Duration(milliseconds: 500));
      
      // إنشاء KeyManager و EncryptionService للاختبار
      keyManager = KeyManager();
      await keyManager.initialize();
      encryptionService = EncryptionService(keyManager);
      await encryptionService.initialize();
    });

    test('1. Generate KeyPair', () async {
      // توليد زوج مفاتيح
      final keyPair = await keyManager.generateKeyPair();
      
      // التحقق من أن المفاتيح تم توليدها
      expect(keyPair.publicKey, isNotNull);
      expect(keyPair.privateKey, isNotNull);
      expect(keyPair.publicKey.length, greaterThan(0));
      expect(keyPair.privateKey.length, greaterThan(0));
      
      print('✅ KeyPair generated successfully');
      print('   Public Key length: ${keyPair.publicKey.length} bytes');
      print('   Private Key length: ${keyPair.privateKey.length} bytes');
    }, skip: 'sodium_libs يحتاج تهيئة خاصة - SodiumPlatform._instance غير متاح في بيئة الاختبار');

    test('2. Encrypt "Hello Sada" - Output is NOT plaintext', () async {
      // توليد KeyPair
      final keyPair = await keyManager.generateKeyPair();
      
      // حساب Shared Secret (نحتاج public key آخر للاختبار)
      // للاختبار، سنستخدم نفس المفتاح العام مرتين (غير واقعي لكن للاختبار)
      final remotePublicKey = keyPair.publicKey;
      final sharedKey = await encryptionService.calculateSharedSecret(remotePublicKey);
      
      // تشفير النص
      const plainText = 'Hello Sada';
      final encrypted = encryptionService.encryptMessage(plainText, sharedKey);
      
      // التحقق من أن النص المشفر مختلف عن النص الأصلي
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted.length, greaterThan(plainText.length));
      
      print('✅ Message encrypted successfully');
      print('   Plaintext: $plainText');
      print('   Encrypted: ${encrypted.substring(0, 50)}...');
      print('   Encrypted length: ${encrypted.length} characters');
    }, skip: 'sodium_libs يحتاج تهيئة خاصة - SodiumPlatform._instance غير متاح في بيئة الاختبار');

    test('3. Decrypt back - Result IS "Hello Sada"', () async {
      // توليد KeyPair
      final keyPair = await keyManager.generateKeyPair();
      
      // حساب Shared Secret
      final remotePublicKey = keyPair.publicKey;
      final sharedKey = await encryptionService.calculateSharedSecret(remotePublicKey);
      
      // تشفير النص
      const plainText = 'Hello Sada';
      final encrypted = encryptionService.encryptMessage(plainText, sharedKey);
      
      // فك التشفير
      final decrypted = encryptionService.decryptMessage(encrypted, sharedKey);
      
      // التحقق من أن النص المفكوك هو نفس النص الأصلي
      expect(decrypted, equals(plainText));
      
      print('✅ Message decrypted successfully');
      print('   Decrypted: $decrypted');
      print('   Match: ${decrypted == plainText}');
    }, skip: 'sodium_libs يحتاج تهيئة خاصة - SodiumPlatform._instance غير متاح في بيئة الاختبار');
  });

  /// ============================================
  /// SCENARIO B: The Memory Check (Database Logic)
  /// ============================================
  group('Scenario B: The Memory Check (Database Logic)', () {
    late TestDatabase database;

    setUp(() async {
      // استخدام Drift in-memory database للاختبار
      database = TestDatabase();
    });

    tearDown(() async {
      await database.close();
    });

    test('1. Initialize empty database', () async {
      // التحقق من أن قاعدة البيانات فارغة
      final contacts = await database.getAllContacts();
      expect(contacts, isEmpty);
      
      print('✅ Database initialized (empty)');
      print('   Contacts count: ${contacts.length}');
    });

    test('2. Create User "Obada" and Insert Message', () async {
      // إنشاء جهة اتصال
      const userId = 'user_obada_123';
      const userName = 'Obada';
      
      final contact = ContactsTableCompanion.insert(
        id: userId,
        name: userName,
      );
      
      await database.insertContact(contact);
      
      // إنشاء محادثة
      const chatId = 'chat_obada_123';
      final chat = ChatsTableCompanion.insert(
        id: chatId,
        peerId: Value(userId),
        name: Value(userName),
        isGroup: const Value(false),
      );
      
      await database.insertChat(chat);
      
      // إدراج رسالة
      const messageId = 'msg_test_123';
      const messageContent = 'Test Msg';
      
      final message = MessagesTableCompanion.insert(
        id: messageId,
        chatId: chatId,
        senderId: userId,
        content: messageContent,
        type: const Value('text'),
        status: const Value('sent'),
        isFromMe: const Value(false),
      );
      
      await database.insertMessage(message);
      
      print('✅ User and message created');
      print('   User: $userName (ID: $userId)');
      print('   Message: $messageContent');
    });

    test('3. Query database - Message exists and count is 1', () async {
      // إعادة إنشاء البيانات
      const userId = 'user_obada_123';
      const userName = 'Obada';
      const chatId = 'chat_obada_123';
      const messageId = 'msg_test_123';
      const messageContent = 'Test Msg';
      
      final contact = ContactsTableCompanion.insert(
        id: userId,
        name: userName,
      );
      await database.insertContact(contact);
      
      final chat = ChatsTableCompanion.insert(
        id: chatId,
        peerId: Value(userId),
        name: Value(userName),
        isGroup: const Value(false),
      );
      await database.insertChat(chat);
      
      final message = MessagesTableCompanion.insert(
        id: messageId,
        chatId: chatId,
        senderId: userId,
        content: messageContent,
        type: const Value('text'),
        status: const Value('sent'),
        isFromMe: const Value(false),
      );
      await database.insertMessage(message);
      
      // الاستعلام عن الرسالة
      final messages = await database.getMessagesForChat(chatId);
      
      // التحقق من وجود الرسالة
      expect(messages, isNotEmpty);
      expect(messages.length, equals(1));
      expect(messages.first.content, equals(messageContent));
      
      print('✅ Message query successful');
      print('   Messages count: ${messages.length}');
      print('   Message content: ${messages.first.content}');
    });
  });

  /// ============================================
  /// SCENARIO C: The Gatekeeper (Auth Logic)
  /// ============================================
  group('Scenario C: The Gatekeeper (Auth Logic)', () {
    late AuthService authService;
    final Map<String, String> _mockStorage = {}; // محاكاة للتخزين الآمن

    setUp(() async {
      // تنظيف التخزين الوهمي قبل كل اختبار
      _mockStorage.clear();
      
      // إعداد MethodChannel mock لـ FlutterSecureStorage
      const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'read':
              final key = methodCall.arguments['key'] as String;
              final value = _mockStorage[key];
              return value; // null إذا لم يوجد
              
            case 'write':
              final key = methodCall.arguments['key'] as String;
              final value = methodCall.arguments['value'] as String;
              _mockStorage[key] = value;
              return null;
              
            case 'delete':
              final key = methodCall.arguments['key'] as String;
              _mockStorage.remove(key);
              return null;
              
            case 'readAll':
              return _mockStorage;
              
            case 'deleteAll':
              _mockStorage.clear();
              return null;
              
            default:
              throw PlatformException(
                code: 'Unimplemented',
                details: 'Method ${methodCall.method} is not implemented in mock',
              );
          }
        },
      );
      
      // إنشاء AuthService (سيستخدم Mock FlutterSecureStorage)
      authService = AuthService();
      
      // انتظار اكتمال التهيئة
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      // تنظيف التخزين الوهمي بعد كل اختبار
      _mockStorage.clear();
      
      // إزالة MethodChannel handler
      const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('1. Set Master PIN and verify CORRECT PIN returns AuthType.master', () async {
      const masterPin = '123456';
      
      // تعيين Master PIN
      final setResult = await authService.setMasterPin(masterPin);
      expect(setResult, isTrue);
      
      // التحقق من PIN الصحيح
      final authResult = await authService.verifyPin(masterPin);
      expect(authResult, equals(AuthType.master));
      
      print('✅ Master PIN verification successful');
      print('   PIN: $masterPin');
      print('   Auth Type: ${authResult.name}');
    });

    test('2. Set Duress PIN and verify DURESS PIN returns AuthType.duress', () async {
      const masterPin = '123456';
      const duressPin = '999999';
      
      // تعيين كلا PINs
      await authService.setMasterPin(masterPin);
      await authService.setDuressPin(duressPin);
      
      // التحقق من Duress PIN
      final authResult = await authService.verifyPin(duressPin);
      expect(authResult, equals(AuthType.duress));
      
      print('✅ Duress PIN verification successful');
      print('   Duress PIN: $duressPin');
      print('   Auth Type: ${authResult.name}');
    });

    test('3. Verify WRONG PIN returns AuthType.failure', () async {
      const masterPin = '123456';
      const wrongPin = '000000';
      
      // تعيين Master PIN فقط
      await authService.setMasterPin(masterPin);
      
      // محاولة التحقق من PIN خاطئ
      final authResult = await authService.verifyPin(wrongPin);
      expect(authResult, equals(AuthType.failure));
      
      print('✅ Wrong PIN correctly rejected');
      print('   Wrong PIN: $wrongPin');
      print('   Auth Type: ${authResult.name}');
    });

    test('4. Verify Master PIN still works after setting Duress PIN', () async {
      const masterPin = '123456';
      const duressPin = '999999';
      
      // تعيين كلا PINs
      await authService.setMasterPin(masterPin);
      await authService.setDuressPin(duressPin);
      
      // التحقق من أن Master PIN لا يزال يعمل
      final masterAuthResult = await authService.verifyPin(masterPin);
      expect(masterAuthResult, equals(AuthType.master));
      
      // التحقق من أن Duress PIN يعمل أيضاً
      final duressAuthResult = await authService.verifyPin(duressPin);
      expect(duressAuthResult, equals(AuthType.duress));
      
      print('✅ Both PINs work correctly');
      print('   Master PIN: $masterPin → ${masterAuthResult.name}');
      print('   Duress PIN: $duressPin → ${duressAuthResult.name}');
    });
  });
}

