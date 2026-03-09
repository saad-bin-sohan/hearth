import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart' as db;

class AssetLocalDataSource {
  const AssetLocalDataSource(this._db);

  final db.AppDatabase _db;

  Stream<List<db.Asset>> watchAssetsForHousehold(String householdId) {
    return (_db.select(_db.assets)
          ..where((table) => table.householdId.equals(householdId))
          ..orderBy(<OrderingTerm Function(db.$AssetsTable)>[
            (table) => OrderingTerm.asc(table.name),
            (table) => OrderingTerm.desc(table.createdAt),
          ]))
        .watch();
  }

  Future<db.Asset?> getAssetById(String id) {
    return (_db.select(_db.assets)..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> saveAsset(db.AssetsCompanion companion) {
    return _db.into(_db.assets).insertOnConflictUpdate(companion);
  }

  Future<void> deleteAsset(String id) async {
    await (_db.delete(_db.assets)..where((table) => table.id.equals(id))).go();
  }

  Future<List<db.Asset>> getAssetsWithWarrantyExpiringBefore(
    String householdId,
    DateTime cutoff,
  ) {
    return (_db.select(_db.assets)
          ..where(
            (table) =>
                table.householdId.equals(householdId) &
                table.warrantyExpiry.isNotNull() &
                table.warrantyExpiry.isSmallerOrEqualValue(cutoff),
          )
          ..orderBy(<OrderingTerm Function(db.$AssetsTable)>[
            (table) => OrderingTerm.asc(table.warrantyExpiry),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();
  }
}
