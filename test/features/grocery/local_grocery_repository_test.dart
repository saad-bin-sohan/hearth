import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/grocery/data/local_grocery_repository.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:uuid/uuid.dart';

import '../../test_helpers.dart';

void main() {
  late AppDatabase database;
  late LocalGroceryRepository repository;

  setUp(() {
    database = createTestDatabase();
    repository = LocalGroceryRepository(database: database, uuid: const Uuid());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'shopping list add, update, check, uncheck, clear, and apply template work',
    () async {
      const householdId = 'household-1';
      final milk = _shoppingItem(
        id: 'shopping-1',
        householdId: householdId,
        name: 'Milk',
        section: ShoppingSection.dairy,
      );

      await repository.addItem(milk);
      await repository.updateItem(milk.copyWith(quantity: 2));
      expect(await repository.getUncheckedCount(householdId), 1);

      await repository.checkOffItem(milk.id, 'user-2');
      final checked = await repository.watchCheckedItems(householdId).first;
      expect(checked.single.isChecked, isTrue);
      expect(checked.single.checkedByUserId, 'user-2');

      await repository.uncheckItem(milk.id);
      final unchecked = await repository.watchUncheckedItems(householdId).first;
      expect(unchecked.single.quantity, 2);
      expect(unchecked.single.isChecked, isFalse);

      final template = ListTemplateEntity(
        id: 'template-1',
        householdId: householdId,
        name: 'Weekly restock',
        items: const <TemplateItem>[
          TemplateItem(
            name: 'Bread',
            quantity: 1,
            unit: 'loaf',
            section: ShoppingSection.bakery,
          ),
          TemplateItem(
            name: 'Apples',
            quantity: 6,
            section: ShoppingSection.produce,
          ),
        ],
        createdByUserId: 'user-1',
        createdAt: DateTime(2026, 3, 9),
      );

      await repository.saveTemplate(template);
      expect(await repository.watchTemplates(householdId).first, hasLength(1));

      await repository.clearAllItems(householdId);
      await repository.applyTemplate(
        householdId: householdId,
        template: template,
        addedByUserId: 'user-1',
      );

      final applied = await repository
          .watchItemsForHousehold(householdId)
          .first;
      expect(
        applied.map((item) => item.name),
        containsAll(<String>['Bread', 'Apples']),
      );

      await repository.clearCheckedItems(householdId);
      expect(
        await repository.watchItemsForHousehold(householdId).first,
        hasLength(2),
      );

      await repository.deleteTemplate(template.id);
      await repository.deleteItem(applied.first.id);
      await repository.deleteItem(applied.last.id);
      expect(await repository.watchTemplates(householdId).first, isEmpty);
      expect(
        await repository.watchItemsForHousehold(householdId).first,
        isEmpty,
      );
    },
  );

  test(
    'pantry add, update, low stock, barcode lookup, expiring query, and decrement work',
    () async {
      const householdId = 'household-1';
      final now = DateTime.now();
      final yogurt = _pantryItem(
        id: 'pantry-1',
        householdId: householdId,
        name: 'Yogurt',
        quantity: 1,
        lowStockThreshold: 2,
        barcode: '12345',
        expiryDate: now.add(const Duration(days: 2)),
        category: PantryCategory.dairy,
        location: PantryLocation.fridge,
      );
      final rice = _pantryItem(
        id: 'pantry-2',
        householdId: householdId,
        name: 'Rice',
        quantity: 4,
        lowStockThreshold: 1,
        expiryDate: now.add(const Duration(days: 20)),
        category: PantryCategory.other,
        location: PantryLocation.pantry,
      );
      final expired = _pantryItem(
        id: 'pantry-3',
        householdId: householdId,
        name: 'Old lettuce',
        quantity: 1,
        lowStockThreshold: 1,
        expiryDate: now.subtract(const Duration(days: 1)),
        category: PantryCategory.produce,
        location: PantryLocation.fridge,
      );

      await repository.addPantryItem(yogurt);
      await repository.addPantryItem(rice);
      await repository.addPantryItem(expired);
      await repository.updatePantryItem(rice.copyWith(quantity: 3));

      final lowStock = await repository.watchLowStockItems(householdId).first;
      expect(lowStock.map((item) => item.id).toSet(), <String>{
        'pantry-1',
        'pantry-3',
      });

      final barcodeMatch = await repository.findByBarcode(householdId, '12345');
      expect(barcodeMatch?.name, 'Yogurt');

      final expiring = await repository.getItemsExpiringWithin(householdId, 7);
      expect(expiring.map((item) => item.id), <String>['pantry-1']);

      await repository.decrementPantryQuantity('pantry-2', 1);
      expect(
        (await repository
                .watchItemsByLocation(householdId, PantryLocation.pantry)
                .first)
            .single
            .quantity,
        2,
      );

      await repository.decrementPantryQuantity('pantry-1', 1);
      final allItems = await repository
          .watchPantryItemsForHousehold(householdId)
          .first;
      expect(allItems.any((item) => item.id == 'pantry-1'), isFalse);
    },
  );
}

ShoppingItemEntity _shoppingItem({
  required String id,
  required String householdId,
  required String name,
  required ShoppingSection section,
}) {
  return ShoppingItemEntity(
    id: id,
    householdId: householdId,
    name: name,
    quantity: 1,
    unit: 'pcs',
    section: section,
    addedByUserId: 'user-1',
    assignedToUserId: null,
    isChecked: false,
    checkedByUserId: null,
    checkedAt: null,
    note: null,
    createdAt: DateTime(2026, 3, 9),
  );
}

PantryItemEntity _pantryItem({
  required String id,
  required String householdId,
  required String name,
  required double quantity,
  required double lowStockThreshold,
  required PantryCategory category,
  required PantryLocation location,
  String? barcode,
  DateTime? expiryDate,
}) {
  return PantryItemEntity(
    id: id,
    householdId: householdId,
    name: name,
    category: category,
    quantity: quantity,
    unit: 'pcs',
    location: location,
    expiryDate: expiryDate,
    purchaseDate: DateTime(2026, 3, 9),
    barcode: barcode,
    lowStockThreshold: lowStockThreshold,
    addedByUserId: 'user-1',
    createdAt: DateTime(2026, 3, 9),
  );
}
