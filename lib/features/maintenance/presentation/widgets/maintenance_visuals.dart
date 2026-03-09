import 'package:flutter/widgets.dart';
import 'package:hearth/features/maintenance/domain/entities/asset.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hugeicons/hugeicons.dart';

IconData iconForAssetCategory(AssetCategory category) {
  switch (category) {
    case AssetCategory.appliance:
      return HugeIcons.strokeRoundedFridge;
    case AssetCategory.hvac:
      return HugeIcons.strokeRoundedSnow;
    case AssetCategory.plumbing:
      return HugeIcons.strokeRoundedWrench01;
    case AssetCategory.electrical:
      return HugeIcons.strokeRoundedFlash;
    case AssetCategory.vehicle:
      return HugeIcons.strokeRoundedStartUp01;
    case AssetCategory.furniture:
      return HugeIcons.strokeRoundedHouse03;
    case AssetCategory.electronics:
      return HugeIcons.strokeRoundedComputerSettings;
    case AssetCategory.garden:
      return HugeIcons.strokeRoundedLeaf02;
    case AssetCategory.other:
      return HugeIcons.strokeRoundedWrench01;
  }
}

IconData iconForVendorCategory(VendorCategory category) {
  switch (category) {
    case VendorCategory.plumber:
      return HugeIcons.strokeRoundedWrench01;
    case VendorCategory.electrician:
      return HugeIcons.strokeRoundedFlash;
    case VendorCategory.hvac:
      return HugeIcons.strokeRoundedSnow;
    case VendorCategory.cleaner:
      return HugeIcons.strokeRoundedCleaningBucket;
    case VendorCategory.carpenter:
      return HugeIcons.strokeRoundedTools;
    case VendorCategory.painter:
      return HugeIcons.strokeRoundedPaintBoard;
    case VendorCategory.gardener:
      return HugeIcons.strokeRoundedLeaf02;
    case VendorCategory.applianceRepair:
      return HugeIcons.strokeRoundedFridge;
    case VendorCategory.internet:
      return HugeIcons.strokeRoundedInternet;
    case VendorCategory.other:
      return HugeIcons.strokeRoundedStore01;
  }
}
