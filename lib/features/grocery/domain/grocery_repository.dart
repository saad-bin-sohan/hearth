import 'package:hearth/features/grocery/domain/grocery_models.dart';

abstract class GroceryRepository {
  Stream<List<ShoppingItemEntity>> watchItemsForHousehold(String householdId);

  Stream<List<ShoppingItemEntity>> watchUncheckedItems(String householdId);

  Stream<List<ShoppingItemEntity>> watchCheckedItems(String householdId);

  Future<void> addItem(ShoppingItemEntity item);

  Future<void> updateItem(ShoppingItemEntity item);

  Future<void> checkOffItem(String itemId, String checkedByUserId);

  Future<void> uncheckItem(String itemId);

  Future<void> deleteItem(String id);

  Future<void> clearCheckedItems(String householdId);

  Future<void> clearAllItems(String householdId);

  Future<int> getUncheckedCount(String householdId);

  Stream<List<ListTemplateEntity>> watchTemplates(String householdId);

  Future<void> saveTemplate(ListTemplateEntity template);

  Future<void> deleteTemplate(String id);

  Future<void> applyTemplate({
    required String householdId,
    required ListTemplateEntity template,
    required String addedByUserId,
  });

  Stream<List<PantryItemEntity>> watchPantryItemsForHousehold(
    String householdId,
  );

  Stream<List<PantryItemEntity>> watchLowStockItems(String householdId);

  Stream<List<PantryItemEntity>> watchItemsByLocation(
    String householdId,
    PantryLocation location,
  );

  Future<void> addPantryItem(PantryItemEntity item);

  Future<void> updatePantryItem(PantryItemEntity item);

  Future<void> deletePantryItem(String id);

  Future<void> decrementPantryQuantity(String itemId, double amount);

  Future<List<PantryItemEntity>> getItemsExpiringWithin(
    String householdId,
    int days,
  );

  Future<PantryItemEntity?> findByBarcode(String householdId, String barcode);

  Future<GroceryHomeSummary> getHomeSummary(String householdId);
}
