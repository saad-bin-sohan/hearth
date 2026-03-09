import 'package:hearth/features/maintenance/domain/entities/asset.dart';

abstract class AssetRepository {
  Stream<List<Asset>> watchAssetsForHousehold(String householdId);
  Future<Asset?> getAssetById(String id);
  Future<void> addAsset(Asset asset);
  Future<void> updateAsset(Asset asset);
  Future<void> deleteAsset(String id);
  Future<List<Asset>> getAssetsWithWarrantyExpiringBefore(
    String householdId,
    DateTime cutoff,
  );
}
