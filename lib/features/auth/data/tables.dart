import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get passwordHash => text()();
  TextColumn get passwordSalt => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

List<TableInfo<Table, Object?>> authTables(AppDatabase db) =>
    <TableInfo<Table, Object?>>[db.users];
