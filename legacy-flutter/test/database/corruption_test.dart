// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sada/core/database/app_database.dart';

void main() {
  group('Database Corruption Tests', () {
    late File corruptFile;

    setUp(() async {
      // Create a temporary file path
      final tempDir = Directory.systemTemp.createTempSync('sada_db_test');
      corruptFile = File('${tempDir.path}/corrupt.db');

      // Write garbage data to simulate corruption
      await corruptFile.writeAsString(
        'THIS IS NOT A SQLITE FILE. GARBAGE DATA HERE.',
      );
    });

    tearDown(() {
      if (corruptFile.existsSync()) {
        corruptFile.deleteSync();
      }
    });

    test(
      'Should throw generic DatabaseException when opening corrupted file',
      () async {
        // Use NativeDatabase to point to our corrupt file
        final executor = NativeDatabase(corruptFile);
        final db = AppDatabase.forTesting(executor);

        // Attempting to run a query should fail
        // We expect a Drift-wrapped exception, often wrapping the underlying SqliteException
        expect(
          () async => await db.getAllContacts(),
          throwsA(isA<Exception>()),
        );

        await db.close();
      },
    );

    test(
      'Should recover by deleting file and recreating (Manual Recovery Logic)',
      () async {
        // Simulate the "Recovery" logic:
        // 1. Try to open -> Fail
        final executor1 = NativeDatabase(corruptFile);
        final db1 = AppDatabase.forTesting(executor1);

        try {
          await db1.getAllContacts();
          fail('Should have failed');
        } catch (e) {
          // Expected failure
          await db1.close();
        }

        // 2. "User" triggers reset -> Delete file
        if (corruptFile.existsSync()) {
          corruptFile.deleteSync();
        }

        // 3. Re-initialize -> Should work (create new DB)
        final executor2 = NativeDatabase(
          corruptFile,
        ); // Same path, but file is gone
        final db2 = AppDatabase.forTesting(executor2);

        // Should succeed now (creates new tables)
        final contacts = await db2.getAllContacts();
        expect(contacts, isEmpty);

        await db2.close();
      },
    );
  });
}
