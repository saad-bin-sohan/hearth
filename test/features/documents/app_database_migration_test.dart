import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:path/path.dart' as path;

void main() {
  test('schema version 4 upgrade creates document tables', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'hearth-docs-migration-',
    );
    addTearDown(() async {
      await tempDirectory.delete(recursive: true);
    });
    final databaseFile = File(path.join(tempDirectory.path, 'hearth.sqlite'));

    final initialDatabase = AppDatabase.test(NativeDatabase(databaseFile));
    await initialDatabase.customStatement('DROP TABLE IF EXISTS documents');
    await initialDatabase.customStatement('DROP TABLE IF EXISTS vault_folders');
    await initialDatabase.customStatement('PRAGMA user_version = 3');
    await initialDatabase.close();

    final upgradedDatabase = AppDatabase.test(NativeDatabase(databaseFile));
    addTearDown(upgradedDatabase.close);

    final documentTables = await upgradedDatabase.customSelect(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('documents', 'vault_folders')
      ORDER BY name
      ''',
    ).get();

    expect(documentTables.map((row) => row.read<String>('name')), <String>[
      'documents',
      'vault_folders',
    ]);

    await upgradedDatabase.into(upgradedDatabase.documents).insert(
          DocumentsCompanion.insert(
            id: 'document-1',
            householdId: 'household-1',
            title: 'Passport',
            docType: 'passport',
            localFilePath: '/tmp/passport.pdf',
            fileSizeBytes: 512,
            mimeType: 'application/pdf',
            uploadedByUserId: 'user-1',
            uploadedAt: DateTime(2026, 3, 9),
          ),
        );

    final rows = await upgradedDatabase.select(
      upgradedDatabase.documents,
    ).get();
    expect(rows, hasLength(1));
    expect(rows.single.title, 'Passport');
  });
}
