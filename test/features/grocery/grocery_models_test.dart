import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';

void main() {
  test('template items round-trip through template json', () {
    final template = ListTemplateEntity(
      id: 'template-1',
      householdId: 'household-1',
      name: 'Weekend run',
      items: const <TemplateItem>[
        TemplateItem(
          name: 'Bread',
          quantity: 1,
          unit: 'loaf',
          section: ShoppingSection.bakery,
        ),
        TemplateItem(
          name: 'Milk',
          quantity: 2,
          unit: 'L',
          section: ShoppingSection.dairy,
          note: 'Whole milk',
        ),
      ],
      createdByUserId: 'user-1',
      createdAt: DateTime(2026, 3, 9),
    );

    final decoded = ListTemplateEntity.itemsFromJson(template.itemsJson);

    expect(decoded, template.items);
  });

  test('pantry expiry urgency uses pantry thresholds', () {
    final now = DateTime.now();

    expect(
      _pantryItem(expiryDate: null).expiryUrgency,
      PantryExpiryUrgency.none,
    );
    expect(
      _pantryItem(expiryDate: now.add(const Duration(days: 8))).expiryUrgency,
      PantryExpiryUrgency.safe,
    );
    expect(
      _pantryItem(expiryDate: now.add(const Duration(days: 6))).expiryUrgency,
      PantryExpiryUrgency.warning,
    );
    expect(
      _pantryItem(expiryDate: now.add(const Duration(days: 2))).expiryUrgency,
      PantryExpiryUrgency.critical,
    );
    expect(
      _pantryItem(
        expiryDate: now.subtract(const Duration(days: 1)),
      ).expiryUrgency,
      PantryExpiryUrgency.expired,
    );
  });
}

PantryItemEntity _pantryItem({required DateTime? expiryDate}) {
  return PantryItemEntity(
    id: 'pantry-1',
    householdId: 'household-1',
    name: 'Milk',
    category: PantryCategory.dairy,
    quantity: 1,
    unit: 'L',
    location: PantryLocation.fridge,
    expiryDate: expiryDate,
    purchaseDate: DateTime(2026, 3, 9),
    barcode: null,
    lowStockThreshold: 1,
    addedByUserId: 'user-1',
    createdAt: DateTime(2026, 3, 9),
  );
}
