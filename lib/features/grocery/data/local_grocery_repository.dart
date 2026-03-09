import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/grocery/data/tables.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/domain/grocery_repository.dart';
import 'package:uuid/uuid.dart';

final groceryRepositoryProvider = Provider<GroceryRepository>((Ref ref) {
  return LocalGroceryRepository(
    database: ref.read(appDatabaseProvider),
    uuid: const Uuid(),
  );
});

class LocalGroceryRepository implements GroceryRepository {
  LocalGroceryRepository({required AppDatabase database, required Uuid uuid})
    : _database = database,
      _uuid = uuid;

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Stream<List<ShoppingItemEntity>> watchItemsForHousehold(String householdId) {
    final query =
        (_database.select(_database.shoppingListItems)
              ..where(
                (ShoppingListItems row) => row.householdId.equals(householdId),
              )
              ..orderBy(<OrderingTerm Function(ShoppingListItems)>[
                (ShoppingListItems row) => OrderingTerm.asc(row.isChecked),
                (ShoppingListItems row) => OrderingTerm.asc(row.createdAt),
                (ShoppingListItems row) => OrderingTerm.asc(row.name),
              ]))
            .watch();
    return query.map(
      (List<ShoppingListItem> rows) => rows.map(_mapShoppingItem).toList(),
    );
  }

  @override
  Stream<List<ShoppingItemEntity>> watchUncheckedItems(String householdId) {
    final query =
        (_database.select(_database.shoppingListItems)
              ..where(
                (ShoppingListItems row) =>
                    row.householdId.equals(householdId) &
                    row.isChecked.equals(false),
              )
              ..orderBy(<OrderingTerm Function(ShoppingListItems)>[
                (ShoppingListItems row) => OrderingTerm.asc(row.createdAt),
                (ShoppingListItems row) => OrderingTerm.asc(row.name),
              ]))
            .watch();
    return query.map(
      (List<ShoppingListItem> rows) => rows.map(_mapShoppingItem).toList(),
    );
  }

  @override
  Stream<List<ShoppingItemEntity>> watchCheckedItems(String householdId) {
    final query =
        (_database.select(_database.shoppingListItems)
              ..where(
                (ShoppingListItems row) =>
                    row.householdId.equals(householdId) &
                    row.isChecked.equals(true),
              )
              ..orderBy(<OrderingTerm Function(ShoppingListItems)>[
                (ShoppingListItems row) => OrderingTerm.desc(row.checkedAt),
                (ShoppingListItems row) => OrderingTerm.asc(row.name),
              ]))
            .watch();
    return query.map(
      (List<ShoppingListItem> rows) => rows.map(_mapShoppingItem).toList(),
    );
  }

  @override
  Future<void> addItem(ShoppingItemEntity item) async {
    await _database
        .into(_database.shoppingListItems)
        .insertOnConflictUpdate(
          ShoppingListItemsCompanion(
            id: Value<String>(item.id),
            householdId: Value<String>(item.householdId),
            name: Value<String>(item.name.trim()),
            quantity: Value<double>(item.quantity),
            unit: Value<String?>(_trimmedOrNull(item.unit)),
            section: Value<String>(item.section.name),
            addedByUserId: Value<String>(item.addedByUserId),
            assignedToUserId: Value<String?>(item.assignedToUserId),
            isChecked: Value<bool>(item.isChecked),
            checkedByUserId: Value<String?>(item.checkedByUserId),
            checkedAt: Value<DateTime?>(item.checkedAt),
            note: Value<String?>(_trimmedOrNull(item.note)),
            createdAt: Value<DateTime>(item.createdAt),
          ),
        );
  }

  @override
  Future<void> updateItem(ShoppingItemEntity item) {
    return addItem(item);
  }

  @override
  Future<void> checkOffItem(String itemId, String checkedByUserId) async {
    await (_database.update(
      _database.shoppingListItems,
    )..where((ShoppingListItems row) => row.id.equals(itemId))).write(
      ShoppingListItemsCompanion(
        isChecked: const Value<bool>(true),
        checkedByUserId: Value<String>(checkedByUserId),
        checkedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> uncheckItem(String itemId) async {
    await (_database.update(
      _database.shoppingListItems,
    )..where((ShoppingListItems row) => row.id.equals(itemId))).write(
      const ShoppingListItemsCompanion(
        isChecked: Value<bool>(false),
        checkedByUserId: Value<String?>(null),
        checkedAt: Value<DateTime?>(null),
      ),
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    await (_database.delete(
      _database.shoppingListItems,
    )..where((ShoppingListItems row) => row.id.equals(id))).go();
  }

  @override
  Future<void> clearCheckedItems(String householdId) async {
    await (_database.delete(_database.shoppingListItems)..where(
          (ShoppingListItems row) =>
              row.householdId.equals(householdId) & row.isChecked.equals(true),
        ))
        .go();
  }

  @override
  Future<void> clearAllItems(String householdId) async {
    await (_database.delete(_database.shoppingListItems)..where(
          (ShoppingListItems row) => row.householdId.equals(householdId),
        ))
        .go();
  }

  @override
  Future<int> getUncheckedCount(String householdId) {
    final countExpression = _database.shoppingListItems.id.count();
    return (_database.selectOnly(_database.shoppingListItems)
          ..addColumns(<Expression<Object>>[countExpression])
          ..where(
            _database.shoppingListItems.householdId.equals(householdId) &
                _database.shoppingListItems.isChecked.equals(false),
          ))
        .map((TypedResult row) => row.read(countExpression) ?? 0)
        .getSingle();
  }

  @override
  Stream<List<ListTemplateEntity>> watchTemplates(String householdId) {
    final query =
        (_database.select(_database.listTemplates)
              ..where(
                (ListTemplates row) => row.householdId.equals(householdId),
              )
              ..orderBy(<OrderingTerm Function(ListTemplates)>[
                (ListTemplates row) => OrderingTerm.asc(row.name),
                (ListTemplates row) => OrderingTerm.desc(row.createdAt),
              ]))
            .watch();
    return query.map(
      (List<ListTemplate> rows) => rows.map(_mapTemplate).toList(),
    );
  }

  @override
  Future<void> saveTemplate(ListTemplateEntity template) async {
    await _database
        .into(_database.listTemplates)
        .insertOnConflictUpdate(
          ListTemplatesCompanion(
            id: Value<String>(template.id),
            householdId: Value<String>(template.householdId),
            name: Value<String>(template.name.trim()),
            itemsJson: Value<String>(template.itemsJson),
            createdByUserId: Value<String>(template.createdByUserId),
            createdAt: Value<DateTime>(template.createdAt),
          ),
        );
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await (_database.delete(
      _database.listTemplates,
    )..where((ListTemplates row) => row.id.equals(id))).go();
  }

  @override
  Future<void> applyTemplate({
    required String householdId,
    required ListTemplateEntity template,
    required String addedByUserId,
  }) async {
    final now = DateTime.now();
    await _database.transaction(() async {
      for (var index = 0; index < template.items.length; index += 1) {
        final item = template.items[index];
        await _database
            .into(_database.shoppingListItems)
            .insert(
              ShoppingListItemsCompanion.insert(
                id: _uuid.v4(),
                householdId: householdId,
                name: item.name.trim(),
                quantity: Value<double>(item.quantity),
                unit: Value<String?>(_trimmedOrNull(item.unit)),
                section: Value<String>(item.section.name),
                addedByUserId: addedByUserId,
                note: Value<String?>(_trimmedOrNull(item.note)),
                createdAt: now.add(Duration(milliseconds: index)),
              ),
            );
      }
    });
  }

  @override
  Stream<List<PantryItemEntity>> watchPantryItemsForHousehold(
    String householdId,
  ) {
    final query =
        (_database.select(_database.pantryItems)
              ..where((PantryItems row) => row.householdId.equals(householdId))
              ..orderBy(<OrderingTerm Function(PantryItems)>[
                (PantryItems row) => OrderingTerm.asc(row.location),
                (PantryItems row) => OrderingTerm.asc(row.expiryDate),
                (PantryItems row) => OrderingTerm.asc(row.name),
              ]))
            .watch();
    return query.map(
      (List<PantryItem> rows) => rows.map(_mapPantryItem).toList(),
    );
  }

  @override
  Stream<List<PantryItemEntity>> watchLowStockItems(String householdId) {
    final query =
        (_database.select(_database.pantryItems)
              ..where(
                (PantryItems row) =>
                    row.householdId.equals(householdId) &
                    row.quantity.isSmallerOrEqual(row.lowStockThreshold),
              )
              ..orderBy(<OrderingTerm Function(PantryItems)>[
                (PantryItems row) => OrderingTerm.asc(row.quantity),
                (PantryItems row) => OrderingTerm.asc(row.name),
              ]))
            .watch();
    return query.map(
      (List<PantryItem> rows) => rows.map(_mapPantryItem).toList(),
    );
  }

  @override
  Stream<List<PantryItemEntity>> watchItemsByLocation(
    String householdId,
    PantryLocation location,
  ) {
    final query =
        (_database.select(_database.pantryItems)
              ..where(
                (PantryItems row) =>
                    row.householdId.equals(householdId) &
                    row.location.equals(location.name),
              )
              ..orderBy(<OrderingTerm Function(PantryItems)>[
                (PantryItems row) => OrderingTerm.asc(row.expiryDate),
                (PantryItems row) => OrderingTerm.asc(row.name),
              ]))
            .watch();
    return query.map(
      (List<PantryItem> rows) => rows.map(_mapPantryItem).toList(),
    );
  }

  @override
  Future<void> addPantryItem(PantryItemEntity item) async {
    await _database
        .into(_database.pantryItems)
        .insertOnConflictUpdate(
          PantryItemsCompanion(
            id: Value<String>(item.id),
            householdId: Value<String>(item.householdId),
            name: Value<String>(item.name.trim()),
            category: Value<String>(item.category.name),
            quantity: Value<double>(item.quantity),
            unit: Value<String?>(_trimmedOrNull(item.unit)),
            location: Value<String>(item.location.name),
            expiryDate: Value<DateTime?>(item.expiryDate),
            purchaseDate: Value<DateTime?>(item.purchaseDate),
            barcode: Value<String?>(_trimmedOrNull(item.barcode)),
            lowStockThreshold: Value<double>(item.lowStockThreshold),
            addedByUserId: Value<String>(item.addedByUserId),
            createdAt: Value<DateTime>(item.createdAt),
          ),
        );
  }

  @override
  Future<void> updatePantryItem(PantryItemEntity item) {
    return addPantryItem(item);
  }

  @override
  Future<void> deletePantryItem(String id) async {
    await (_database.delete(
      _database.pantryItems,
    )..where((PantryItems row) => row.id.equals(id))).go();
  }

  @override
  Future<void> decrementPantryQuantity(String itemId, double amount) async {
    final row = await (_database.select(
      _database.pantryItems,
    )..where((PantryItems item) => item.id.equals(itemId))).getSingleOrNull();
    if (row == null) {
      return;
    }
    final updatedQuantity = row.quantity - amount;
    if (updatedQuantity <= 0) {
      await deletePantryItem(itemId);
      return;
    }
    await (_database.update(_database.pantryItems)
          ..where((PantryItems item) => item.id.equals(itemId)))
        .write(PantryItemsCompanion(quantity: Value<double>(updatedQuantity)));
  }

  @override
  Future<List<PantryItemEntity>> getItemsExpiringWithin(
    String householdId,
    int days,
  ) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final cutoff = DateTime.now().add(Duration(days: days));
    final rows =
        await (_database.select(_database.pantryItems)
              ..where(
                (PantryItems row) =>
                    row.householdId.equals(householdId) &
                    row.expiryDate.isNotNull() &
                    row.expiryDate.isBiggerOrEqualValue(startOfToday) &
                    row.expiryDate.isSmallerOrEqualValue(cutoff),
              )
              ..orderBy(<OrderingTerm Function(PantryItems)>[
                (PantryItems row) => OrderingTerm.asc(row.expiryDate),
                (PantryItems row) => OrderingTerm.asc(row.name),
              ]))
            .get();
    return rows.map(_mapPantryItem).toList();
  }

  @override
  Future<PantryItemEntity?> findByBarcode(
    String householdId,
    String barcode,
  ) async {
    final row =
        await (_database.select(_database.pantryItems)..where(
              (PantryItems item) =>
                  item.householdId.equals(householdId) &
                  item.barcode.equals(barcode),
            ))
            .getSingleOrNull();
    return row == null ? null : _mapPantryItem(row);
  }

  @override
  Future<GroceryHomeSummary> getHomeSummary(String householdId) async {
    final uncheckedItemCount = await getUncheckedCount(householdId);
    final lowStockCount =
        await (_database.select(_database.pantryItems)..where(
              (PantryItems row) =>
                  row.householdId.equals(householdId) &
                  row.quantity.isSmallerOrEqual(row.lowStockThreshold),
            ))
            .get()
            .then((List<PantryItem> rows) => rows.length);
    final expiringSoonCount = await getItemsExpiringWithin(
      householdId,
      2,
    ).then((List<PantryItemEntity> items) => items.length);
    return GroceryHomeSummary(
      uncheckedItemCount: uncheckedItemCount,
      lowStockCount: lowStockCount,
      expiringSoonCount: expiringSoonCount,
    );
  }

  ShoppingItemEntity _mapShoppingItem(ShoppingListItem row) {
    return ShoppingItemEntity(
      id: row.id,
      householdId: row.householdId,
      name: row.name,
      quantity: row.quantity,
      unit: row.unit,
      section: ShoppingSectionX.fromName(row.section),
      addedByUserId: row.addedByUserId,
      assignedToUserId: row.assignedToUserId,
      isChecked: row.isChecked,
      checkedByUserId: row.checkedByUserId,
      checkedAt: row.checkedAt,
      note: row.note,
      createdAt: row.createdAt,
    );
  }

  PantryItemEntity _mapPantryItem(PantryItem row) {
    return PantryItemEntity(
      id: row.id,
      householdId: row.householdId,
      name: row.name,
      category: PantryCategoryX.fromName(row.category),
      quantity: row.quantity,
      unit: row.unit,
      location: PantryLocationX.fromName(row.location),
      expiryDate: row.expiryDate,
      purchaseDate: row.purchaseDate,
      barcode: row.barcode,
      lowStockThreshold: row.lowStockThreshold,
      addedByUserId: row.addedByUserId,
      createdAt: row.createdAt,
    );
  }

  ListTemplateEntity _mapTemplate(ListTemplate row) {
    return ListTemplateEntity(
      id: row.id,
      householdId: row.householdId,
      name: row.name,
      items: ListTemplateEntity.itemsFromJson(row.itemsJson),
      createdByUserId: row.createdByUserId,
      createdAt: row.createdAt,
    );
  }

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
