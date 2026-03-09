import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart';

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get title => text()();
  IntColumn get amountCents => integer()();
  TextColumn get category => text()();
  TextColumn get paidByUserId => text()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get splitRuleJson => text()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  BoolColumn get isRecurringTemplate =>
      boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRuleJson => text().nullable()();
  TextColumn get receiptReference => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  TextColumn get sourceRecurringExpenseId => text().nullable()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
  DateTimeColumn get lastGeneratedAt => dateTime().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class Balances extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get debtorUserId => text()();
  TextColumn get creditorUserId => text()();
  IntColumn get amountCents => integer()();
  DateTimeColumn get lastUpdatedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class CategoryBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get category => text()();
  IntColumn get limitCents => integer()();
  TextColumn get createdByUserId => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class Settlements extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get debtorUserId => text()();
  TextColumn get creditorUserId => text()();
  IntColumn get amountCents => integer()();
  TextColumn get status => text()();
  TextColumn get initiatedByUserId => text()();
  TextColumn get confirmedByUserId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get sourceExpenseId => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

List<TableInfo<Table, Object?>> financeTables(AppDatabase db) =>
    <TableInfo<Table, Object?>>[
      db.expenses,
      db.balances,
      db.categoryBudgets,
      db.settlements,
    ];
