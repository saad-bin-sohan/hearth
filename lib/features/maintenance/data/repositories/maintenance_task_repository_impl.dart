import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart' as db;
import 'package:hearth/features/maintenance/data/datasources/maintenance_task_datasource.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/repositories/maintenance_task_repository.dart';

class MaintenanceTaskRepositoryImpl implements MaintenanceTaskRepository {
  const MaintenanceTaskRepositoryImpl(this._dataSource);

  final MaintenanceTaskDataSource _dataSource;

  @override
  Stream<List<MaintenanceTask>> watchTasksForHousehold(String householdId) {
    return _dataSource.watchTasksForHousehold(householdId).map(
      (List<db.MaintenanceTask> rows) => rows.map(_mapTask).toList(),
    );
  }

  @override
  Stream<List<MaintenanceTask>> watchTasksForAsset(String assetId) {
    return _dataSource.watchTasksForAsset(assetId).map(
      (List<db.MaintenanceTask> rows) => rows.map(_mapTask).toList(),
    );
  }

  @override
  Stream<List<MaintenanceTask>> watchOverdueTasks(String householdId) {
    return _dataSource.watchOverdueTasks(householdId).map(
      (List<db.MaintenanceTask> rows) => rows.map(_mapTask).toList(),
    );
  }

  @override
  Stream<List<MaintenanceTask>> watchUpcomingTasks(
    String householdId, {
    int daysAhead = 30,
  }) {
    return _dataSource
        .watchUpcomingTasks(householdId, daysAhead: daysAhead)
        .map((List<db.MaintenanceTask> rows) => rows.map(_mapTask).toList());
  }

  @override
  Future<MaintenanceTask?> getTaskById(String id) async {
    final row = await _dataSource.getTaskById(id);
    return row == null ? null : _mapTask(row);
  }

  @override
  Future<void> addTask(MaintenanceTask task) {
    return _dataSource.saveTask(_toCompanion(task));
  }

  @override
  Future<void> updateTask(MaintenanceTask task) {
    return _dataSource.saveTask(_toCompanion(task));
  }

  @override
  Future<void> deleteTask(String id) {
    return _dataSource.deleteTask(id);
  }

  @override
  Future<void> completeTask(
    String taskId, {
    required String completedByUserId,
    double? actualCost,
    String? vendorId,
    String? notes,
    String? completionPhotoPath,
  }) async {
    await _dataSource.updateTask(
      taskId,
      db.MaintenanceTasksCompanion(
        statusEnum: const Value<String>('completed'),
        completedAt: Value<DateTime>(DateTime.now()),
        completedByUserId: Value<String>(completedByUserId),
        actualCost: Value<double?>(actualCost),
        vendorId: Value<String?>(vendorId),
        completionNotes: Value<String?>(notes),
        completionPhotoPath: Value<String?>(completionPhotoPath),
      ),
    );
  }

  @override
  Future<List<MaintenanceTask>> getCompletedTasksForAsset(String assetId) async {
    final rows = await _dataSource.getCompletedTasksForAsset(assetId);
    return rows.map(_mapTask).toList();
  }

  @override
  Future<List<MaintenanceTask>> getTasksWithDueDateBetween(
    String householdId,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _dataSource.getTasksWithDueDateBetween(
      householdId,
      start,
      end,
    );
    return rows.map(_mapTask).toList();
  }

  @override
  Future<List<MaintenanceTask>> getCompletedTasksForVendor(String vendorId) async {
    final rows = await _dataSource.getCompletedTasksForVendor(vendorId);
    return rows.map(_mapTask).toList();
  }

  @override
  Future<List<MaintenanceTask>> getPendingTasksPastDue(String householdId) async {
    final rows = await _dataSource.getPendingTasksPastDue(householdId);
    return rows.map(_mapTask).toList();
  }

  @override
  Future<void> markTaskStatus(String taskId, MaintenanceTaskStatus status) {
    return _dataSource.updateTask(
      taskId,
      db.MaintenanceTasksCompanion(statusEnum: Value<String>(status.name)),
    );
  }

  db.MaintenanceTasksCompanion _toCompanion(MaintenanceTask task) {
    return db.MaintenanceTasksCompanion(
      id: Value<String>(task.id),
      householdId: Value<String>(task.householdId),
      assetId: Value<String?>(task.assetId),
      title: Value<String>(task.title.trim()),
      description: Value<String?>(task.description?.trim().isEmpty ?? true ? null : task.description?.trim()),
      assignedToUserId: Value<String?>(task.assignedToUserId),
      dueDate: Value<DateTime?>(task.dueDate),
      recurrenceRule: Value<String?>(task.recurrenceStorageValue == MaintenanceRecurrence.none.name ? null : task.recurrenceStorageValue),
      estimatedCost: Value<double?>(task.estimatedCost),
      statusEnum: Value<String>(task.status.name),
      completedAt: Value<DateTime?>(task.completedAt),
      completedByUserId: Value<String?>(task.completedByUserId),
      actualCost: Value<double?>(task.actualCost),
      vendorId: Value<String?>(task.vendorId),
      completionNotes: Value<String?>(task.completionNotes?.trim().isEmpty ?? true ? null : task.completionNotes?.trim()),
      completionPhotoPath: Value<String?>(task.completionPhotoPath),
      createdAt: Value<DateTime>(task.createdAt),
      createdByUserId: Value<String>(task.createdByUserId),
    );
  }

  MaintenanceTask _mapTask(db.MaintenanceTask row) {
    final recurrence = MaintenanceRecurrenceX.fromStorageValue(row.recurrenceRule);
    return MaintenanceTask(
      id: row.id,
      householdId: row.householdId,
      assetId: row.assetId,
      title: row.title,
      description: row.description,
      assignedToUserId: row.assignedToUserId,
      dueDate: row.dueDate,
      recurrence: recurrence,
      recurrenceRule: row.recurrenceRule,
      estimatedCost: row.estimatedCost,
      status: MaintenanceTaskStatusX.fromName(row.statusEnum),
      completedAt: row.completedAt,
      completedByUserId: row.completedByUserId,
      actualCost: row.actualCost,
      vendorId: row.vendorId,
      completionNotes: row.completionNotes,
      completionPhotoPath: row.completionPhotoPath,
      createdAt: row.createdAt,
      createdByUserId: row.createdByUserId,
    );
  }
}
