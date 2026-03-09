import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart';

class Chores extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get areaTag => text()();
  IntColumn get estimatedMinutes => integer()();
  TextColumn get frequency => text()();
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get assignmentType => text()();
  TextColumn get assignedToUserIds => text()();
  IntColumn get currentAssigneeIndex =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get nextDueAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdByUserId => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class ChoreCompletions extends Table {
  TextColumn get id => text()();
  TextColumn get choreId => text()();
  TextColumn get completedByUserId => text()();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get photoLocalPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get wasOnTime => boolean()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class ChoreDeferrals extends Table {
  TextColumn get id => text()();
  TextColumn get choreId => text()();
  TextColumn get deferredByUserId => text()();
  DateTimeColumn get deferredAt => dateTime()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get newDueAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

List<TableInfo<Table, Object?>> choreTables(AppDatabase db) =>
    <TableInfo<Table, Object?>>[
      db.chores,
      db.choreCompletions,
      db.choreDeferrals,
    ];
