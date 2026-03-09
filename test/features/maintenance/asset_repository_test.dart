import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/maintenance/data/datasources/asset_local_datasource.dart';
import 'package:hearth/features/maintenance/data/datasources/maintenance_task_datasource.dart';
import 'package:hearth/features/maintenance/data/repositories/asset_repository_impl.dart';
import 'package:path/path.dart' as path;

void main() {
  late AppDatabase database;
  late AssetRepositoryImpl repository;
  late Directory tempDirectory;

  setUp(() async {
    database = AppDatabase.test(NativeDatabase.memory());
    repository = AssetRepositoryImpl(
      database: database,
      assetDataSource: AssetLocalDataSource(database),
      taskDataSource: MaintenanceTaskDataSource(database),
    );
    tempDirectory = await Directory.systemTemp.createTemp(
      'hearth-maintenance-assets-',
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('deleteAsset removes tasks, unlinks documents, and deletes stored files', () async {
    final assetPhoto = await _writeFile(tempDirectory, 'asset.jpg');
    final pendingPhoto = await _writeFile(tempDirectory, 'pending.jpg');
    final completedPhoto = await _writeFile(tempDirectory, 'completed.jpg');

    await database.into(database.assets).insert(
          AssetsCompanion.insert(
            id: 'asset-1',
            householdId: 'household-1',
            name: 'Water Heater',
            categoryEnum: 'hvac',
            photoLocalPath: Value<String?>(assetPhoto.path),
            createdByUserId: 'user-1',
            createdAt: DateTime(2026, 3, 9),
          ),
        );
    await database.into(database.maintenanceTasks).insert(
          MaintenanceTasksCompanion.insert(
            id: 'task-pending',
            householdId: 'household-1',
            assetId: const Value<String?>('asset-1'),
            title: 'Flush tank',
            completionPhotoPath: Value<String?>(pendingPhoto.path),
            createdAt: DateTime(2026, 3, 9),
            createdByUserId: 'user-1',
          ),
        );
    await database.into(database.maintenanceTasks).insert(
          MaintenanceTasksCompanion.insert(
            id: 'task-completed',
            householdId: 'household-1',
            assetId: const Value<String?>('asset-1'),
            title: 'Replace valve',
            statusEnum: const Value<String>('completed'),
            completedAt: Value<DateTime?>(DateTime(2026, 3, 8)),
            completionPhotoPath: Value<String?>(completedPhoto.path),
            createdAt: DateTime(2026, 3, 8),
            createdByUserId: 'user-1',
          ),
        );
    await database.into(database.documents).insert(
          DocumentsCompanion.insert(
            id: 'document-1',
            householdId: 'household-1',
            title: 'Warranty Card',
            docType: 'warranty',
            linkedAssetId: const Value<String?>('asset-1'),
            localFilePath: '/tmp/warranty.pdf',
            fileSizeBytes: 128,
            mimeType: 'application/pdf',
            uploadedByUserId: 'user-1',
            uploadedAt: DateTime(2026, 3, 9),
          ),
        );

    await repository.deleteAsset('asset-1');

    expect(await database.select(database.assets).get(), isEmpty);
    expect(await database.select(database.maintenanceTasks).get(), isEmpty);
    final document = await (database.select(database.documents)
          ..where((table) => table.id.equals('document-1')))
        .getSingle();
    expect(document.linkedAssetId, isNull);
    expect(assetPhoto.existsSync(), isFalse);
    expect(pendingPhoto.existsSync(), isFalse);
    expect(completedPhoto.existsSync(), isFalse);
  });
}

Future<File> _writeFile(Directory directory, String name) async {
  final file = File(path.join(directory.path, name));
  await file.writeAsString(name);
  return file;
}
