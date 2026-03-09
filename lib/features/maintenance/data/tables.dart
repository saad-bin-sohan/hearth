import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart';

class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  TextColumn get categoryEnum => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get modelNumber => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  RealColumn get purchasePrice => real().nullable()();
  DateTimeColumn get warrantyExpiry => dateTime().nullable()();
  TextColumn get photoLocalPath => text().nullable()();
  TextColumn get locationNote => text().nullable()();
  TextColumn get createdByUserId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class MaintenanceTasks extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get assetId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get assignedToUserId => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get recurrenceRule => text().nullable()();
  RealColumn get estimatedCost => real().nullable()();
  TextColumn get statusEnum => text().withDefault(const Constant('pending'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get completedByUserId => text().nullable()();
  RealColumn get actualCost => real().nullable()();
  TextColumn get vendorId => text().nullable()();
  TextColumn get completionNotes => text().nullable()();
  TextColumn get completionPhotoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdByUserId => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class Vendors extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get businessName => text()();
  TextColumn get contactName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get categoryEnum => text()();
  TextColumn get notes => text().nullable()();
  RealColumn get averageRating => real().withDefault(const Constant(0.0))();
  TextColumn get createdByUserId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class VendorRatings extends Table {
  TextColumn get id => text()();
  TextColumn get vendorId => text()();
  TextColumn get ratingByUserId => text()();
  IntColumn get stars => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get ratedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

List<TableInfo<Table, Object?>> maintenanceTables(AppDatabase db) =>
    <TableInfo<Table, Object?>>[
      db.assets,
      db.maintenanceTasks,
      db.vendors,
      db.vendorRatings,
    ];
