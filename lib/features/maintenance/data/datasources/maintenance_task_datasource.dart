import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart' as db;

class MaintenanceTaskDataSource {
  const MaintenanceTaskDataSource(this._db);

  final db.AppDatabase _db;

  Stream<List<db.MaintenanceTask>> watchTasksForHousehold(String householdId) {
    return (_db.select(_db.maintenanceTasks)
          ..where((table) => table.householdId.equals(householdId))
          ..orderBy(<OrderingTerm Function(db.$MaintenanceTasksTable)>[
            (table) => OrderingTerm.asc(table.dueDate),
            (table) => OrderingTerm.asc(table.title),
          ]))
        .watch();
  }

  Stream<List<db.MaintenanceTask>> watchTasksForAsset(String assetId) {
    return (_db.select(_db.maintenanceTasks)
          ..where((table) => table.assetId.equals(assetId))
          ..orderBy(<OrderingTerm Function(db.$MaintenanceTasksTable)>[
            (table) => OrderingTerm.asc(table.dueDate),
            (table) => OrderingTerm.asc(table.title),
          ]))
        .watch();
  }

  Stream<List<db.MaintenanceTask>> watchOverdueTasks(String householdId) {
    final now = DateTime.now();
    return (_db.select(_db.maintenanceTasks)
          ..where(
            (table) =>
                table.householdId.equals(householdId) &
                table.dueDate.isNotNull() &
                table.dueDate.isSmallerThanValue(now) &
                table.statusEnum.isNotValue('completed'),
          )
          ..orderBy(<OrderingTerm Function(db.$MaintenanceTasksTable)>[
            (table) => OrderingTerm.asc(table.dueDate),
          ]))
        .watch();
  }

  Stream<List<db.MaintenanceTask>> watchUpcomingTasks(
    String householdId, {
    int daysAhead = 30,
  }) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: daysAhead));
    return (_db.select(_db.maintenanceTasks)
          ..where(
            (table) =>
                table.householdId.equals(householdId) &
                table.dueDate.isNotNull() &
                table.dueDate.isBiggerOrEqualValue(now) &
                table.dueDate.isSmallerOrEqualValue(cutoff) &
                table.statusEnum.equals('pending'),
          )
          ..orderBy(<OrderingTerm Function(db.$MaintenanceTasksTable)>[
            (table) => OrderingTerm.asc(table.dueDate),
            (table) => OrderingTerm.asc(table.title),
          ]))
        .watch();
  }

  Future<db.MaintenanceTask?> getTaskById(String id) {
    return (_db.select(_db.maintenanceTasks)..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> saveTask(db.MaintenanceTasksCompanion companion) {
    return _db.into(_db.maintenanceTasks).insertOnConflictUpdate(companion);
  }

  Future<void> updateTask(
    String id,
    db.MaintenanceTasksCompanion companion,
  ) async {
    await (_db.update(_db.maintenanceTasks)..where((table) => table.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteTask(String id) async {
    await (_db.delete(_db.maintenanceTasks)..where((table) => table.id.equals(id)))
        .go();
  }

  Future<List<db.MaintenanceTask>> getCompletedTasksForAsset(String assetId) {
    return (_db.select(_db.maintenanceTasks)
          ..where(
            (table) =>
                table.assetId.equals(assetId) &
                table.statusEnum.equals('completed'),
          )
          ..orderBy(<OrderingTerm Function(db.$MaintenanceTasksTable)>[
            (table) => OrderingTerm.desc(table.completedAt),
          ]))
        .get();
  }

  Future<List<db.MaintenanceTask>> getTasksWithDueDateBetween(
    String householdId,
    DateTime start,
    DateTime end,
  ) {
    return (_db.select(_db.maintenanceTasks)
          ..where(
            (table) =>
                table.householdId.equals(householdId) &
                table.dueDate.isNotNull() &
                table.dueDate.isBiggerOrEqualValue(start) &
                table.dueDate.isSmallerOrEqualValue(end) &
                table.statusEnum.isNotValue('completed'),
          )
          ..orderBy(<OrderingTerm Function(db.$MaintenanceTasksTable)>[
            (table) => OrderingTerm.asc(table.dueDate),
          ]))
        .get();
  }

  Future<List<db.MaintenanceTask>> getCompletedTasksForVendor(String vendorId) {
    return (_db.select(_db.maintenanceTasks)
          ..where(
            (table) =>
                table.vendorId.equals(vendorId) &
                table.statusEnum.equals('completed'),
          )
          ..orderBy(<OrderingTerm Function(db.$MaintenanceTasksTable)>[
            (table) => OrderingTerm.desc(table.completedAt),
          ]))
        .get();
  }

  Future<List<db.MaintenanceTask>> getPendingTasksPastDue(String householdId) {
    final now = DateTime.now();
    return (_db.select(_db.maintenanceTasks)
          ..where(
            (table) =>
                table.householdId.equals(householdId) &
                table.dueDate.isNotNull() &
                table.dueDate.isSmallerThanValue(now) &
                table.statusEnum.equals('pending'),
          )
          ..orderBy(<OrderingTerm Function(db.$MaintenanceTasksTable)>[
            (table) => OrderingTerm.asc(table.dueDate),
          ]))
        .get();
  }

  Future<void> deleteTasksForAsset(String assetId) async {
    await (_db.delete(_db.maintenanceTasks)..where((table) => table.assetId.equals(assetId)))
        .go();
  }
}
