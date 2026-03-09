import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';

abstract class MaintenanceTaskRepository {
  Stream<List<MaintenanceTask>> watchTasksForHousehold(String householdId);
  Stream<List<MaintenanceTask>> watchTasksForAsset(String assetId);
  Stream<List<MaintenanceTask>> watchOverdueTasks(String householdId);
  Stream<List<MaintenanceTask>> watchUpcomingTasks(
    String householdId, {
    int daysAhead = 30,
  });
  Future<MaintenanceTask?> getTaskById(String id);
  Future<void> addTask(MaintenanceTask task);
  Future<void> updateTask(MaintenanceTask task);
  Future<void> deleteTask(String id);
  Future<void> completeTask(
    String taskId, {
    required String completedByUserId,
    double? actualCost,
    String? vendorId,
    String? notes,
    String? completionPhotoPath,
  });
  Future<List<MaintenanceTask>> getCompletedTasksForAsset(String assetId);
  Future<List<MaintenanceTask>> getTasksWithDueDateBetween(
    String householdId,
    DateTime start,
    DateTime end,
  );
  Future<List<MaintenanceTask>> getCompletedTasksForVendor(String vendorId);
  Future<List<MaintenanceTask>> getPendingTasksPastDue(String householdId);
  Future<void> markTaskStatus(String taskId, MaintenanceTaskStatus status);
}
