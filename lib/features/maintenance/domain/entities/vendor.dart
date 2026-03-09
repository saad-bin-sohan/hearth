import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor.freezed.dart';

enum VendorCategory {
  plumber,
  electrician,
  hvac,
  cleaner,
  carpenter,
  painter,
  gardener,
  applianceRepair,
  internet,
  other,
}

extension VendorCategoryX on VendorCategory {
  String get label => switch (this) {
    VendorCategory.plumber => 'Plumber',
    VendorCategory.electrician => 'Electrician',
    VendorCategory.hvac => 'HVAC',
    VendorCategory.cleaner => 'Cleaner',
    VendorCategory.carpenter => 'Carpenter',
    VendorCategory.painter => 'Painter',
    VendorCategory.gardener => 'Gardener',
    VendorCategory.applianceRepair => 'Appliance Repair',
    VendorCategory.internet => 'Internet',
    VendorCategory.other => 'Other',
  };

  static VendorCategory fromName(String value) {
    if (value == 'appliance_repair') {
      return VendorCategory.applianceRepair;
    }
    return VendorCategory.values.firstWhere(
      (VendorCategory category) => category.name == value,
      orElse: () => VendorCategory.other,
    );
  }

  String get storageValue {
    return this == VendorCategory.applianceRepair
        ? 'appliance_repair'
        : name;
  }
}

@freezed
class Vendor with _$Vendor {
  const factory Vendor({
    required String id,
    required String householdId,
    required String businessName,
    String? contactName,
    String? phone,
    String? email,
    String? website,
    required VendorCategory category,
    String? notes,
    required double averageRating,
    required String createdByUserId,
    required DateTime createdAt,
  }) = _Vendor;
}
