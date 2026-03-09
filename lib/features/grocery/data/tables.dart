import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart';

class ShoppingListItems extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
  TextColumn get section => text().withDefault(const Constant('other'))();
  TextColumn get addedByUserId => text()();
  TextColumn get assignedToUserId => text().nullable()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  TextColumn get checkedByUserId => text().nullable()();
  DateTimeColumn get checkedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class PantryItems extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
  TextColumn get location => text().withDefault(const Constant('pantry'))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  TextColumn get barcode => text().nullable()();
  RealColumn get lowStockThreshold => real().withDefault(const Constant(1.0))();
  TextColumn get addedByUserId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class ListTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  TextColumn get itemsJson => text()();
  TextColumn get createdByUserId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

List<TableInfo<Table, Object?>> groceryTables(AppDatabase db) =>
    <TableInfo<Table, Object?>>[
      db.shoppingListItems,
      db.pantryItems,
      db.listTemplates,
    ];
