import 'package:flutter/widgets.dart';
import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hugeicons/hugeicons.dart';

IconData shoppingSectionIcon(ShoppingSection section) {
  return switch (section) {
    ShoppingSection.produce => HugeIcons.strokeRoundedLeaf02,
    ShoppingSection.dairy => HugeIcons.strokeRoundedMilkBottle,
    ShoppingSection.meat => HugeIcons.strokeRoundedSteak,
    ShoppingSection.bakery => HugeIcons.strokeRoundedBread01,
    ShoppingSection.frozen => HugeIcons.strokeRoundedSnow,
    ShoppingSection.canned => HugeIcons.strokeRoundedSodaCan,
    ShoppingSection.beverages => HugeIcons.strokeRoundedDrink,
    ShoppingSection.household => HugeIcons.strokeRoundedCleaningBucket,
    ShoppingSection.personal => HugeIcons.strokeRoundedShampoo,
    ShoppingSection.other => HugeIcons.strokeRoundedShoppingBag01,
  };
}

IconData pantryLocationIcon(PantryLocation location) {
  return switch (location) {
    PantryLocation.fridge => HugeIcons.strokeRoundedFridge,
    PantryLocation.freezer => HugeIcons.strokeRoundedSnow,
    PantryLocation.pantry => HugeIcons.strokeRoundedStore01,
    PantryLocation.cabinet => HugeIcons.strokeRoundedCabinet01,
    PantryLocation.counter => HugeIcons.strokeRoundedKitchenUtensils,
    PantryLocation.other => HugeIcons.strokeRoundedPackage,
  };
}

IconData pantryCategoryIcon(PantryCategory category) {
  return switch (category) {
    PantryCategory.produce => HugeIcons.strokeRoundedLeaf02,
    PantryCategory.dairy => HugeIcons.strokeRoundedMilkBottle,
    PantryCategory.meat => HugeIcons.strokeRoundedSteak,
    PantryCategory.bakery => HugeIcons.strokeRoundedBread01,
    PantryCategory.frozen => HugeIcons.strokeRoundedSnow,
    PantryCategory.canned => HugeIcons.strokeRoundedSodaCan,
    PantryCategory.beverages => HugeIcons.strokeRoundedDrink,
    PantryCategory.condiments => HugeIcons.strokeRoundedJar,
    PantryCategory.snacks => HugeIcons.strokeRoundedCookie,
    PantryCategory.other => HugeIcons.strokeRoundedPackage,
  };
}

ExpiryBadgeUrgency pantryBadgeUrgency(PantryExpiryUrgency urgency) {
  return switch (urgency) {
    PantryExpiryUrgency.none => ExpiryBadgeUrgency.none,
    PantryExpiryUrgency.safe => ExpiryBadgeUrgency.safe,
    PantryExpiryUrgency.warning => ExpiryBadgeUrgency.warning,
    PantryExpiryUrgency.critical => ExpiryBadgeUrgency.critical,
    PantryExpiryUrgency.expired => ExpiryBadgeUrgency.expired,
  };
}
