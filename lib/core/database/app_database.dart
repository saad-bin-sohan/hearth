import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/features/auth/data/tables.dart';
import 'package:hearth/features/chores/data/tables.dart';
import 'package:hearth/features/finance/data/tables.dart';
import 'package:hearth/features/household/data/tables.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((Ref ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

@DriftDatabase(
  tables: <Type>[
    Users,
    Households,
    HouseholdMemberships,
    Chores,
    ChoreCompletions,
    ChoreDeferrals,
    Expenses,
    Balances,
    CategoryBudgets,
    Settlements,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.test(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(expenses);
        await migrator.createTable(balances);
        await migrator.createTable(categoryBudgets);
        await migrator.createTable(settlements);
      }
      if (from < 3) {
        await migrator.createTable(chores);
        await migrator.createTable(choreCompletions);
        await migrator.createTable(choreDeferrals);
      }
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'hearth_v1');
}
