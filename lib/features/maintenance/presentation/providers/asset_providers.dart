import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart' as db;
import 'package:hearth/features/maintenance/data/datasources/asset_local_datasource.dart';
import 'package:hearth/features/maintenance/data/datasources/maintenance_task_datasource.dart';
import 'package:hearth/features/maintenance/data/repositories/asset_repository_impl.dart';
import 'package:hearth/features/maintenance/domain/entities/asset.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/repositories/asset_repository.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

typedef LinkedAssetDocument =
    ({String id, String title, String localFilePath, String mimeType});

final assetLocalDataSourceProvider = Provider<AssetLocalDataSource>((Ref ref) {
  return AssetLocalDataSource(ref.watch(db.appDatabaseProvider));
});

final assetRepositoryProvider = Provider<AssetRepository>((Ref ref) {
  final database = ref.watch(db.appDatabaseProvider);
  return AssetRepositoryImpl(
    database: database,
    assetDataSource: ref.watch(assetLocalDataSourceProvider),
    taskDataSource: MaintenanceTaskDataSource(database),
  );
});

final assetsProvider = StreamProvider.family<List<Asset>, String>((
  Ref ref,
  String householdId,
) {
  return ref.watch(assetRepositoryProvider).watchAssetsForHousehold(householdId);
});

final assetDetailProvider = FutureProvider.family<Asset?, String>((
  Ref ref,
  String assetId,
) {
  return ref.watch(assetRepositoryProvider).getAssetById(assetId);
});

final expiringWarrantyAssetsProvider = FutureProvider<List<Asset>>((Ref ref) async {
  final householdId = ref.watch(maintenanceHouseholdIdProvider);
  if (householdId == null) {
    return const <Asset>[];
  }
  return ref.watch(assetRepositoryProvider).getAssetsWithWarrantyExpiringBefore(
        householdId,
        DateTime.now().add(const Duration(days: 60)),
      );
});

final linkedDocumentsForAssetProvider =
    FutureProvider.family<List<LinkedAssetDocument>, String>((
      Ref ref,
      String assetId,
    ) async {
      final database = ref.watch(db.appDatabaseProvider);
      final rows = await (database.select(database.documents)
            ..where((table) => table.linkedAssetId.equals(assetId))
            ..orderBy(<OrderingTerm Function(db.$DocumentsTable)>[
              (table) => OrderingTerm.desc(table.uploadedAt),
            ]))
          .get();
      return rows
          .map(
            (db.Document row) => (
              id: row.id,
              title: row.title,
              localFilePath: row.localFilePath,
              mimeType: row.mimeType,
            ),
          )
          .toList();
    });

final completedTasksForAssetProvider =
    FutureProvider.family<List<MaintenanceTask>, String>((
      Ref ref,
      String assetId,
    ) {
      return ref
          .watch(maintenanceTaskRepositoryProvider)
          .getCompletedTasksForAsset(assetId);
    });

class AssetNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addAsset(Asset asset, File? photoFile) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final saved = photoFile == null ? asset : asset.copyWith(
        photoLocalPath: await _copyPhoto(
          householdId: asset.householdId,
          assetId: asset.id,
          file: photoFile,
        ),
      );
      await ref.read(assetRepositoryProvider).addAsset(saved);
      _invalidate(saved);
    });
  }

  Future<void> updateAsset(Asset asset, File? newPhotoFile) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      String? photoPath = asset.photoLocalPath;
      if (newPhotoFile != null) {
        photoPath = await _copyPhoto(
          householdId: asset.householdId,
          assetId: asset.id,
          file: newPhotoFile,
        );
      }
      await ref
          .read(assetRepositoryProvider)
          .updateAsset(asset.copyWith(photoLocalPath: photoPath));
      _invalidate(asset);
    });
  }

  Future<void> deleteAsset(Asset asset) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(assetRepositoryProvider).deleteAsset(asset.id);
      _invalidate(asset);
    });
  }

  Future<String> _copyPhoto({
    required String householdId,
    required String assetId,
    required File file,
  }) async {
    final docsDirectory = await getApplicationDocumentsDirectory();
    final destinationDirectory = Directory(
      path.join(docsDirectory.path, 'hearth', 'assets', householdId),
    );
    await destinationDirectory.create(recursive: true);
    final destinationPath = path.join(destinationDirectory.path, '$assetId.jpg');
    final copied = await file.copy(destinationPath);
    return copied.path;
  }

  void _invalidate(Asset asset) {
    ref.invalidate(assetDetailProvider(asset.id));
    ref.invalidate(expiringWarrantyAssetsProvider);
    ref.invalidate(assetsProvider(asset.householdId));
  }
}

final assetNotifierProvider = AsyncNotifierProvider<AssetNotifier, void>(
  AssetNotifier.new,
);
