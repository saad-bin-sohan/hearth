import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor_rating.dart';

abstract class VendorRepository {
  Stream<List<Vendor>> watchVendorsForHousehold(String householdId);
  Future<Vendor?> getVendorById(String id);
  Future<void> addVendor(Vendor vendor);
  Future<void> updateVendor(Vendor vendor);
  Future<void> deleteVendor(String id);
  Stream<List<VendorRating>> watchRatingsForVendor(String vendorId);
  Future<void> addRating(VendorRating rating);
  Future<void> updateRating(VendorRating rating);
  Future<VendorRating?> getRatingByVendorAndUser(String vendorId, String userId);
  Future<double> updateAverageRating(String vendorId);
  Future<List<MaintenanceTask>> getCompletedTasksForVendor(String vendorId);
}
