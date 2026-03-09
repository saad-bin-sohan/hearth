import 'dart:io';

import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart' as db;
import 'package:hearth/features/maintenance/data/datasources/asset_local_datasource.dart';
import 'package:hearth/features/maintenance/data/datasources/maintenance_task_datasource.dart';
import 'package:hearth/features/maintenance/domain/entities/asset.dart';
import 'package:hearth/features/maintenance/domain/repositories/asset_repository.dart';

class AssetRepositoryImpl implements AssetRepository {
  const AssetRepositoryImpl({
    required db.AppDatabase database,
    required AssetLocalDataSource assetDataSource,
    required MaintenanceTaskDataSource taskDataSource,
  }) : _database = database,
       _assetDataSource = assetDataSource,
       _taskDataSource = taskDataSource;

  final db.AppDatabase _database;
  final AssetLocalDataSource _assetDataSource;
  final MaintenanceTaskDataSource _taskDataSource;

  @override
  Stream<List<Asset>> watchAssetsForHousehold(String householdId) {
    return _assetDataSource.watchAssetsForHousehold(householdId).map(
      (List<db.Asset> rows) => rows.map(_mapAsset).toList(),
    );
  }

  @override
  Future<Asset?> getAssetById(String id) async {
    final row = await _assetDataSource.getAssetById(id);
    return row == null ? null : _mapAsset(row);
  }

  @override
  Future<void> addAsset(Asset asset) {
    return _assetDataSource.saveAsset(_toCompanion(asset));
  }

  @override
  Future<void> updateAsset(Asset asset) {
    return _assetDataSource.saveAsset(_toCompanion(asset));
  }

  @override
  Future<void> deleteAsset(String id) async {
    final asset = await _assetDataSource.getAssetById(id);
    if (asset == null) {
      return;
    }
    final linkedTasks = await _taskDataSource.getCompletedTasksForAsset(id);
    final activeTasks = await _taskDataSource.watchTasksForAsset(id).first;
    await _database.transaction(() async {
      await _taskDataSource.deleteTasksForAsset(id);
      await (_database.update(_database.documents)
            ..where((table) => table.linkedAssetId.equals(id)))
          .write(const db.DocumentsCompanion(linkedAssetId: Value<String?>(null)));
      await _assetDataSource.deleteAsset(id);
    });

    final photoPaths = <String?>[
      asset.photoLocalPath,
      ...linkedTasks.map((db.MaintenanceTask task) => task.completionPhotoPath),
      ...activeTasks.map((db.MaintenanceTask task) => task.completionPhotoPath),
    ];
    for (final path in photoPaths) {
      if (path == null || path.isEmpty) {
        continue;
      }
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  Future<List<Asset>> getAssetsWithWarrantyExpiringBefore(
    String householdId,
    DateTime cutoff,
  ) async {
    final rows = await _assetDataSource.getAssetsWithWarrantyExpiringBefore(
      householdId,
      cutoff,
    );
    return rows.map(_mapAsset).toList();
  }

  db.AssetsCompanion _toCompanion(Asset asset) {
    return db.AssetsCompanion(
      id: Value<String>(asset.id),
      householdId: Value<String>(asset.householdId),
      name: Value<String>(asset.name.trim()),
      categoryEnum: Value<String>(asset.category.name),
      brand: Value<String?>(asset.brand?.trim().isEmpty ?? true ? null : asset.brand?.trim()),
      modelNumber: Value<String?>(asset.modelNumber?.trim().isEmpty ?? true ? null : asset.modelNumber?.trim()),
      serialNumber: Value<String?>(asset.serialNumber?.trim().isEmpty ?? true ? null : asset.serialNumber?.trim()),
      purchaseDate: Value<DateTime?>(asset.purchaseDate),
      purchasePrice: Value<double?>(asset.purchasePrice),
      warrantyExpiry: Value<DateTime?>(asset.warrantyExpiry),
      photoLocalPath: Value<String?>(asset.photoLocalPath),
      locationNote: Value<String?>(asset.locationNote?.trim().isEmpty ?? true ? null : asset.locationNote?.trim()),
      createdByUserId: Value<String>(asset.createdByUserId),
      createdAt: Value<DateTime>(asset.createdAt),
    );
  }

  Asset _mapAsset(db.Asset row) {
    return Asset(
      id: row.id,
      householdId: row.householdId,
      name: row.name,
      category: AssetCategoryX.fromName(row.categoryEnum),
      brand: row.brand,
      modelNumber: row.modelNumber,
      serialNumber: row.serialNumber,
      purchaseDate: row.purchaseDate,
      purchasePrice: row.purchasePrice,
      warrantyExpiry: row.warrantyExpiry,
      photoLocalPath: row.photoLocalPath,
      locationNote: row.locationNote,
      createdByUserId: row.createdByUserId,
      createdAt: row.createdAt,
    );
  }
}
