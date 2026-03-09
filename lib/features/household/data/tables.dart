import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart';

class Households extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text()();
  TextColumn get avatarColorKey => text()();
  TextColumn get currencyCode => text()();
  TextColumn get inviteCode => text().unique()();
  TextColumn get createdByUserId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class HouseholdMemberships extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  DateTimeColumn get joinedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

List<TableInfo<Table, Object?>> householdTables(AppDatabase db) =>
    <TableInfo<Table, Object?>>[db.households, db.householdMemberships];
