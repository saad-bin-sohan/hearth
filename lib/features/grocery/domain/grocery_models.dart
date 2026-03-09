import 'dart:convert';

import 'package:equatable/equatable.dart';

enum ShoppingSection {
  produce,
  dairy,
  meat,
  bakery,
  frozen,
  canned,
  beverages,
  household,
  personal,
  other,
}

const List<ShoppingSection> kSectionOrder = <ShoppingSection>[
  ShoppingSection.produce,
  ShoppingSection.dairy,
  ShoppingSection.meat,
  ShoppingSection.bakery,
  ShoppingSection.frozen,
  ShoppingSection.canned,
  ShoppingSection.beverages,
  ShoppingSection.household,
  ShoppingSection.personal,
  ShoppingSection.other,
];

extension ShoppingSectionX on ShoppingSection {
  String get label => switch (this) {
    ShoppingSection.produce => 'Produce',
    ShoppingSection.dairy => 'Dairy',
    ShoppingSection.meat => 'Meat',
    ShoppingSection.bakery => 'Bakery',
    ShoppingSection.frozen => 'Frozen',
    ShoppingSection.canned => 'Canned',
    ShoppingSection.beverages => 'Beverages',
    ShoppingSection.household => 'Household',
    ShoppingSection.personal => 'Personal',
    ShoppingSection.other => 'Other',
  };

  static ShoppingSection fromName(String value) {
    return ShoppingSection.values.firstWhere(
      (ShoppingSection section) => section.name == value,
      orElse: () => ShoppingSection.other,
    );
  }
}

enum PantryCategory {
  produce,
  dairy,
  meat,
  bakery,
  frozen,
  canned,
  beverages,
  condiments,
  snacks,
  other,
}

extension PantryCategoryX on PantryCategory {
  String get label => switch (this) {
    PantryCategory.produce => 'Produce',
    PantryCategory.dairy => 'Dairy',
    PantryCategory.meat => 'Meat',
    PantryCategory.bakery => 'Bakery',
    PantryCategory.frozen => 'Frozen',
    PantryCategory.canned => 'Canned',
    PantryCategory.beverages => 'Beverages',
    PantryCategory.condiments => 'Condiments',
    PantryCategory.snacks => 'Snacks',
    PantryCategory.other => 'Other',
  };

  static PantryCategory fromName(String value) {
    return PantryCategory.values.firstWhere(
      (PantryCategory category) => category.name == value,
      orElse: () => PantryCategory.other,
    );
  }
}

enum PantryLocation { fridge, freezer, pantry, cabinet, counter, other }

extension PantryLocationX on PantryLocation {
  String get label => switch (this) {
    PantryLocation.fridge => 'Fridge',
    PantryLocation.freezer => 'Freezer',
    PantryLocation.pantry => 'Pantry',
    PantryLocation.cabinet => 'Cabinet',
    PantryLocation.counter => 'Counter',
    PantryLocation.other => 'Other',
  };

  static PantryLocation fromName(String value) {
    return PantryLocation.values.firstWhere(
      (PantryLocation location) => location.name == value,
      orElse: () => PantryLocation.other,
    );
  }
}

enum PantryExpiryUrgency { none, safe, warning, critical, expired }

enum ShoppingSortMode { section, dateAdded }

class ShoppingItemEntity extends Equatable {
  const ShoppingItemEntity({
    required this.id,
    required this.householdId,
    required this.name,
    required this.quantity,
    this.unit,
    required this.section,
    required this.addedByUserId,
    this.assignedToUserId,
    required this.isChecked,
    this.checkedByUserId,
    this.checkedAt,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String name;
  final double quantity;
  final String? unit;
  final ShoppingSection section;
  final String addedByUserId;
  final String? assignedToUserId;
  final bool isChecked;
  final String? checkedByUserId;
  final DateTime? checkedAt;
  final String? note;
  final DateTime createdAt;

  String get quantityDisplay {
    final quantityText = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    return unit == null || unit!.trim().isEmpty
        ? quantityText
        : '$quantityText ${unit!.trim()}';
  }

  ShoppingItemEntity copyWith({
    String? id,
    String? householdId,
    String? name,
    double? quantity,
    String? unit,
    bool clearUnit = false,
    ShoppingSection? section,
    String? addedByUserId,
    String? assignedToUserId,
    bool clearAssignedToUserId = false,
    bool? isChecked,
    String? checkedByUserId,
    bool clearCheckedByUserId = false,
    DateTime? checkedAt,
    bool clearCheckedAt = false,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
  }) {
    return ShoppingItemEntity(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: clearUnit ? null : unit ?? this.unit,
      section: section ?? this.section,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      assignedToUserId: clearAssignedToUserId
          ? null
          : assignedToUserId ?? this.assignedToUserId,
      isChecked: isChecked ?? this.isChecked,
      checkedByUserId: clearCheckedByUserId
          ? null
          : checkedByUserId ?? this.checkedByUserId,
      checkedAt: clearCheckedAt ? null : checkedAt ?? this.checkedAt,
      note: clearNote ? null : note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    name,
    quantity,
    unit,
    section,
    addedByUserId,
    assignedToUserId,
    isChecked,
    checkedByUserId,
    checkedAt,
    note,
    createdAt,
  ];
}

class PantryItemEntity extends Equatable {
  const PantryItemEntity({
    required this.id,
    required this.householdId,
    required this.name,
    required this.category,
    required this.quantity,
    this.unit,
    required this.location,
    this.expiryDate,
    this.purchaseDate,
    this.barcode,
    required this.lowStockThreshold,
    required this.addedByUserId,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String name;
  final PantryCategory category;
  final double quantity;
  final String? unit;
  final PantryLocation location;
  final DateTime? expiryDate;
  final DateTime? purchaseDate;
  final String? barcode;
  final double lowStockThreshold;
  final String addedByUserId;
  final DateTime createdAt;

  bool get isLowStock => quantity <= lowStockThreshold;

  int? get daysUntilExpiry {
    final value = expiryDate;
    if (value == null) {
      return null;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    return target.difference(today).inDays;
  }

  PantryExpiryUrgency get expiryUrgency {
    final days = daysUntilExpiry;
    if (days == null) {
      return PantryExpiryUrgency.none;
    }
    if (days < 0) {
      return PantryExpiryUrgency.expired;
    }
    if (days <= 2) {
      return PantryExpiryUrgency.critical;
    }
    if (days <= 6) {
      return PantryExpiryUrgency.warning;
    }
    return PantryExpiryUrgency.safe;
  }

  String get quantityDisplay {
    final quantityText = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    return unit == null || unit!.trim().isEmpty
        ? quantityText
        : '$quantityText ${unit!.trim()}';
  }

  PantryItemEntity copyWith({
    String? id,
    String? householdId,
    String? name,
    PantryCategory? category,
    double? quantity,
    String? unit,
    bool clearUnit = false,
    PantryLocation? location,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    DateTime? purchaseDate,
    bool clearPurchaseDate = false,
    String? barcode,
    bool clearBarcode = false,
    double? lowStockThreshold,
    String? addedByUserId,
    DateTime? createdAt,
  }) {
    return PantryItemEntity(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: clearUnit ? null : unit ?? this.unit,
      location: location ?? this.location,
      expiryDate: clearExpiryDate ? null : expiryDate ?? this.expiryDate,
      purchaseDate: clearPurchaseDate
          ? null
          : purchaseDate ?? this.purchaseDate,
      barcode: clearBarcode ? null : barcode ?? this.barcode,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    name,
    category,
    quantity,
    unit,
    location,
    expiryDate,
    purchaseDate,
    barcode,
    lowStockThreshold,
    addedByUserId,
    createdAt,
  ];
}

class TemplateItem extends Equatable {
  const TemplateItem({
    required this.name,
    required this.quantity,
    this.unit,
    required this.section,
    this.note,
  });

  final String name;
  final double quantity;
  final String? unit;
  final ShoppingSection section;
  final String? note;

  String get quantityDisplay {
    final quantityText = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    return unit == null || unit!.trim().isEmpty
        ? quantityText
        : '$quantityText ${unit!.trim()}';
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'section': section.name,
      'note': note,
    };
  }

  factory TemplateItem.fromMap(Map<String, dynamic> map) {
    return TemplateItem(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] as String?,
      section: ShoppingSectionX.fromName(map['section'] as String? ?? 'other'),
      note: map['note'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[name, quantity, unit, section, note];
}

class ListTemplateEntity extends Equatable {
  const ListTemplateEntity({
    required this.id,
    required this.householdId,
    required this.name,
    required this.items,
    required this.createdByUserId,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String name;
  final List<TemplateItem> items;
  final String createdByUserId;
  final DateTime createdAt;

  String get itemsJson =>
      jsonEncode(items.map((TemplateItem item) => item.toMap()).toList());

  ListTemplateEntity copyWith({
    String? id,
    String? householdId,
    String? name,
    List<TemplateItem>? items,
    String? createdByUserId,
    DateTime? createdAt,
  }) {
    return ListTemplateEntity(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      items: items ?? this.items,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<TemplateItem> itemsFromJson(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! List<dynamic>) {
      return const <TemplateItem>[];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TemplateItem.fromMap)
        .toList();
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    name,
    items,
    createdByUserId,
    createdAt,
  ];
}

class OpenFoodProduct extends Equatable {
  const OpenFoodProduct({
    required this.name,
    required this.brand,
    required this.quantityString,
    required this.inferredSection,
    this.imageUrl,
  });

  final String name;
  final String brand;
  final String quantityString;
  final ShoppingSection inferredSection;
  final String? imageUrl;

  @override
  List<Object?> get props => <Object?>[
    name,
    brand,
    quantityString,
    inferredSection,
    imageUrl,
  ];
}

class GroceryHomeSummary extends Equatable {
  const GroceryHomeSummary({
    required this.uncheckedItemCount,
    required this.lowStockCount,
    required this.expiringSoonCount,
  });

  final int uncheckedItemCount;
  final int lowStockCount;
  final int expiringSoonCount;

  @override
  List<Object?> get props => <Object?>[
    uncheckedItemCount,
    lowStockCount,
    expiringSoonCount,
  ];
}
