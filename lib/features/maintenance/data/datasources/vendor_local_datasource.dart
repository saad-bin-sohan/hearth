import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart' as db;

class VendorLocalDataSource {
  const VendorLocalDataSource(this._db);

  final db.AppDatabase _db;

  Stream<List<db.Vendor>> watchVendorsForHousehold(String householdId) {
    return (_db.select(_db.vendors)
          ..where((table) => table.householdId.equals(householdId))
          ..orderBy(<OrderingTerm Function(db.$VendorsTable)>[
            (table) => OrderingTerm.desc(table.averageRating),
            (table) => OrderingTerm.asc(table.businessName),
          ]))
        .watch();
  }

  Future<db.Vendor?> getVendorById(String id) {
    return (_db.select(_db.vendors)..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> saveVendor(db.VendorsCompanion companion) {
    return _db.into(_db.vendors).insertOnConflictUpdate(companion);
  }

  Future<void> deleteVendor(String id) async {
    await (_db.delete(_db.vendors)..where((table) => table.id.equals(id))).go();
  }

  Stream<List<db.VendorRating>> watchRatingsForVendor(String vendorId) {
    return (_db.select(_db.vendorRatings)
          ..where((table) => table.vendorId.equals(vendorId))
          ..orderBy(<OrderingTerm Function(db.$VendorRatingsTable)>[
            (table) => OrderingTerm.desc(table.ratedAt),
          ]))
        .watch();
  }

  Future<List<db.VendorRating>> getRatingsForVendor(String vendorId) {
    return (_db.select(_db.vendorRatings)..where((table) => table.vendorId.equals(vendorId)))
        .get();
  }

  Future<db.VendorRating?> getRatingByVendorAndUser(String vendorId, String userId) {
    return (_db.select(_db.vendorRatings)
          ..where(
            (table) =>
                table.vendorId.equals(vendorId) &
                table.ratingByUserId.equals(userId),
          ))
        .getSingleOrNull();
  }

  Future<void> saveRating(db.VendorRatingsCompanion companion) {
    return _db.into(_db.vendorRatings).insertOnConflictUpdate(companion);
  }

  Future<void> updateAverageRating(String vendorId, double value) async {
    await (_db.update(_db.vendors)..where((table) => table.id.equals(vendorId)))
        .write(db.VendorsCompanion(averageRating: Value<double>(value)));
  }
}
