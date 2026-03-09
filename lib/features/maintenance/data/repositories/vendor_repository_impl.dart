import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart' as db;
import 'package:hearth/features/maintenance/data/datasources/maintenance_task_datasource.dart';
import 'package:hearth/features/maintenance/data/datasources/vendor_local_datasource.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor_rating.dart';
import 'package:hearth/features/maintenance/domain/repositories/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  const VendorRepositoryImpl({
    required VendorLocalDataSource vendorDataSource,
    required MaintenanceTaskDataSource taskDataSource,
  }) : _vendorDataSource = vendorDataSource,
       _taskDataSource = taskDataSource;

  final VendorLocalDataSource _vendorDataSource;
  final MaintenanceTaskDataSource _taskDataSource;

  @override
  Stream<List<Vendor>> watchVendorsForHousehold(String householdId) {
    return _vendorDataSource.watchVendorsForHousehold(householdId).map(
      (List<db.Vendor> rows) => rows.map(_mapVendor).toList(),
    );
  }

  @override
  Future<Vendor?> getVendorById(String id) async {
    final row = await _vendorDataSource.getVendorById(id);
    return row == null ? null : _mapVendor(row);
  }

  @override
  Future<void> addVendor(Vendor vendor) {
    return _vendorDataSource.saveVendor(_toVendorCompanion(vendor));
  }

  @override
  Future<void> updateVendor(Vendor vendor) {
    return _vendorDataSource.saveVendor(_toVendorCompanion(vendor));
  }

  @override
  Future<void> deleteVendor(String id) async {
    await _vendorDataSource.deleteVendor(id);
  }

  @override
  Stream<List<VendorRating>> watchRatingsForVendor(String vendorId) {
    return _vendorDataSource.watchRatingsForVendor(vendorId).map(
      (List<db.VendorRating> rows) => rows.map(_mapRating).toList(),
    );
  }

  @override
  Future<void> addRating(VendorRating rating) {
    return _vendorDataSource.saveRating(_toRatingCompanion(rating));
  }

  @override
  Future<void> updateRating(VendorRating rating) {
    return _vendorDataSource.saveRating(_toRatingCompanion(rating));
  }

  @override
  Future<VendorRating?> getRatingByVendorAndUser(
    String vendorId,
    String userId,
  ) async {
    final row = await _vendorDataSource.getRatingByVendorAndUser(vendorId, userId);
    return row == null ? null : _mapRating(row);
  }

  @override
  Future<double> updateAverageRating(String vendorId) async {
    final ratings = await _vendorDataSource.getRatingsForVendor(vendorId);
    if (ratings.isEmpty) {
      await _vendorDataSource.updateAverageRating(vendorId, 0);
      return 0;
    }
    final total = ratings.fold<int>(
      0,
      (int sum, db.VendorRating rating) => sum + rating.stars,
    );
    final average = double.parse((total / ratings.length).toStringAsFixed(1));
    await _vendorDataSource.updateAverageRating(vendorId, average);
    return average;
  }

  @override
  Future<List<MaintenanceTask>> getCompletedTasksForVendor(String vendorId) async {
    final rows = await _taskDataSource.getCompletedTasksForVendor(vendorId);
    return rows
        .map(
          (db.MaintenanceTask row) => MaintenanceTask(
            id: row.id,
            householdId: row.householdId,
            assetId: row.assetId,
            title: row.title,
            description: row.description,
            assignedToUserId: row.assignedToUserId,
            dueDate: row.dueDate,
            recurrence: MaintenanceRecurrenceX.fromStorageValue(row.recurrenceRule),
            recurrenceRule: row.recurrenceRule,
            estimatedCost: row.estimatedCost,
            status: MaintenanceTaskStatusX.fromName(row.statusEnum),
            completedAt: row.completedAt,
            completedByUserId: row.completedByUserId,
            actualCost: row.actualCost,
            vendorId: row.vendorId,
            completionNotes: row.completionNotes,
            completionPhotoPath: row.completionPhotoPath,
            createdAt: row.createdAt,
            createdByUserId: row.createdByUserId,
          ),
        )
        .toList();
  }

  db.VendorsCompanion _toVendorCompanion(Vendor vendor) {
    return db.VendorsCompanion(
      id: Value<String>(vendor.id),
      householdId: Value<String>(vendor.householdId),
      businessName: Value<String>(vendor.businessName.trim()),
      contactName: Value<String?>(vendor.contactName?.trim().isEmpty ?? true ? null : vendor.contactName?.trim()),
      phone: Value<String?>(vendor.phone?.trim().isEmpty ?? true ? null : vendor.phone?.trim()),
      email: Value<String?>(vendor.email?.trim().isEmpty ?? true ? null : vendor.email?.trim()),
      website: Value<String?>(vendor.website?.trim().isEmpty ?? true ? null : vendor.website?.trim()),
      categoryEnum: Value<String>(vendor.category.storageValue),
      notes: Value<String?>(vendor.notes?.trim().isEmpty ?? true ? null : vendor.notes?.trim()),
      averageRating: Value<double>(vendor.averageRating),
      createdByUserId: Value<String>(vendor.createdByUserId),
      createdAt: Value<DateTime>(vendor.createdAt),
    );
  }

  db.VendorRatingsCompanion _toRatingCompanion(VendorRating rating) {
    return db.VendorRatingsCompanion(
      id: Value<String>(rating.id),
      vendorId: Value<String>(rating.vendorId),
      ratingByUserId: Value<String>(rating.ratingByUserId),
      stars: Value<int>(rating.stars),
      notes: Value<String?>(rating.notes?.trim().isEmpty ?? true ? null : rating.notes?.trim()),
      ratedAt: Value<DateTime>(rating.ratedAt),
    );
  }

  Vendor _mapVendor(db.Vendor row) {
    return Vendor(
      id: row.id,
      householdId: row.householdId,
      businessName: row.businessName,
      contactName: row.contactName,
      phone: row.phone,
      email: row.email,
      website: row.website,
      category: VendorCategoryX.fromName(row.categoryEnum),
      notes: row.notes,
      averageRating: row.averageRating,
      createdByUserId: row.createdByUserId,
      createdAt: row.createdAt,
    );
  }

  VendorRating _mapRating(db.VendorRating row) {
    return VendorRating(
      id: row.id,
      vendorId: row.vendorId,
      ratingByUserId: row.ratingByUserId,
      stars: row.stars,
      notes: row.notes,
      ratedAt: row.ratedAt,
    );
  }
}
