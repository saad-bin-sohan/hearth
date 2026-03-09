import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hearth/core/utils/expiry_status.dart';

part 'asset.freezed.dart';

enum AssetCategory {
  appliance,
  hvac,
  plumbing,
  electrical,
  vehicle,
  furniture,
  electronics,
  garden,
  other,
}

extension AssetCategoryX on AssetCategory {
  String get label => switch (this) {
    AssetCategory.appliance => 'Appliance',
    AssetCategory.hvac => 'HVAC',
    AssetCategory.plumbing => 'Plumbing',
    AssetCategory.electrical => 'Electrical',
    AssetCategory.vehicle => 'Vehicle',
    AssetCategory.furniture => 'Furniture',
    AssetCategory.electronics => 'Electronics',
    AssetCategory.garden => 'Garden',
    AssetCategory.other => 'Other',
  };

  static AssetCategory fromName(String value) {
    return AssetCategory.values.firstWhere(
      (AssetCategory category) => category.name == value,
      orElse: () => AssetCategory.other,
    );
  }
}

@freezed
class Asset with _$Asset {
  const factory Asset({
    required String id,
    required String householdId,
    required String name,
    required AssetCategory category,
    String? brand,
    String? modelNumber,
    String? serialNumber,
    DateTime? purchaseDate,
    double? purchasePrice,
    DateTime? warrantyExpiry,
    String? photoLocalPath,
    String? locationNote,
    required String createdByUserId,
    required DateTime createdAt,
  }) = _Asset;

  const Asset._();

  DateExpiryUrgency get warrantyUrgency {
    return ExpiryStatus.urgencyForDate(warrantyExpiry);
  }

  int? get daysUntilWarranty {
    return ExpiryStatus.daysUntil(warrantyExpiry);
  }
}
