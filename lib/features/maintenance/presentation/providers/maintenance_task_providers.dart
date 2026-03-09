import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart' as db;
import 'package:hearth/core/services/notification_service.dart';
import 'package:hearth/features/maintenance/data/datasources/maintenance_task_datasource.dart';
import 'package:hearth/features/maintenance/data/repositories/maintenance_task_repository_impl.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/repositories/maintenance_task_repository.dart';
import 'package:hearth/features/maintenance/domain/usecases/complete_task_usecase.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final maintenanceTaskDataSourceProvider = Provider<MaintenanceTaskDataSource>((
  Ref ref,
) {
  return MaintenanceTaskDataSource(ref.watch(db.appDatabaseProvider));
});

final maintenanceTaskRepositoryProvider = Provider<MaintenanceTaskRepository>((
  Ref ref,
) {
  return MaintenanceTaskRepositoryImpl(ref.watch(maintenanceTaskDataSourceProvider));
});

final allTasksProvider = StreamProvider.family<List<MaintenanceTask>, String>((
  Ref ref,
  String householdId,
) {
  return ref
      .watch(maintenanceTaskRepositoryProvider)
      .watchTasksForHousehold(householdId);
});

final overdueTasksProvider = StreamProvider.family<List<MaintenanceTask>, String>((
  Ref ref,
  String householdId,
) {
  return ref
      .watch(maintenanceTaskRepositoryProvider)
      .watchOverdueTasks(householdId);
});

final upcomingTasksProvider = StreamProvider.family<List<MaintenanceTask>, String>((
  Ref ref,
  String householdId,
) {
  return ref
      .watch(maintenanceTaskRepositoryProvider)
      .watchUpcomingTasks(householdId);
});

final assetTasksProvider = StreamProvider.family<List<MaintenanceTask>, String>((
  Ref ref,
  String assetId,
) {
  return ref.watch(maintenanceTaskRepositoryProvider).watchTasksForAsset(assetId);
});

final taskDetailProvider = FutureProvider.family<MaintenanceTask?, String>((
  Ref ref,
  String taskId,
) {
  return ref.watch(maintenanceTaskRepositoryProvider).getTaskById(taskId);
});

final maintenanceBootstrapProvider = FutureProvider<void>((Ref ref) async {
  final householdId = ref.watch(maintenanceHouseholdIdProvider);
  if (householdId == null) {
    return;
  }
  final repository = ref.watch(maintenanceTaskRepositoryProvider);
  final overdue = await repository.getPendingTasksPastDue(householdId);
  for (final task in overdue) {
    await repository.markTaskStatus(task.id, MaintenanceTaskStatus.overdue);
  }
  final expiringAssets = await ref.watch(expiringWarrantyAssetsProvider.future);
  final notificationService = ref.watch(notificationServiceProvider);
  await notificationService.scheduleMaintenanceOverdueAlerts(overdue);
  await notificationService.scheduleWarrantyExpiryAlerts(expiringAssets);
  ref.invalidate(overdueTasksProvider(householdId));
  ref.invalidate(upcomingTasksProvider(householdId));
});

class MaintenanceTaskNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addTask(MaintenanceTask task) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(maintenanceTaskRepositoryProvider).addTask(task);
      _invalidate(task);
    });
  }

  Future<void> updateTask(MaintenanceTask task) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(maintenanceTaskRepositoryProvider).updateTask(task);
      _invalidate(task);
    });
  }

  Future<DateTime?> completeTask(
    MaintenanceTask task, {
    double? actualCost,
    String? vendorId,
    String? notes,
    File? photoFile,
  }) async {
    state = const AsyncLoading<void>();
    DateTime? nextDueDate;
    state = await AsyncValue.guard(() async {
      final currentUserId = ref.read(maintenanceCurrentUserIdProvider);
      if (currentUserId == null) {
        throw StateError('You must be signed in to complete a task.');
      }
      final photoPath = photoFile == null
          ? null
          : await _copyCompletionPhoto(
              householdId: task.householdId,
              taskId: task.id,
              file: photoFile,
            );
      nextDueDate = await CompleteTaskUseCase(
        ref.read(maintenanceTaskRepositoryProvider),
      ).execute(
        task,
        completedByUserId: currentUserId,
        actualCost: actualCost,
        vendorId: vendorId,
        notes: notes,
        completionPhotoPath: photoPath,
      );
      _invalidate(task);
    });
    return nextDueDate;
  }

  Future<void> deleteTask(String taskId) async {
    final existing = await ref.read(taskDetailProvider(taskId).future);
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await ref.read(maintenanceTaskRepositoryProvider).deleteTask(taskId);
      if (existing != null) {
        _invalidate(existing);
      } else {
        ref.invalidate(taskDetailProvider(taskId));
      }
    });
  }

  Future<String> _copyCompletionPhoto({
    required String householdId,
    required String taskId,
    required File file,
  }) async {
    final docsDirectory = await getApplicationDocumentsDirectory();
    final destinationDirectory = Directory(
      path.join(docsDirectory.path, 'hearth', 'maintenance', householdId, 'tasks'),
    );
    await destinationDirectory.create(recursive: true);
    final destinationPath = path.join(destinationDirectory.path, '$taskId.jpg');
    final copied = await file.copy(destinationPath);
    return copied.path;
  }

  void _invalidate(MaintenanceTask task) {
    ref.invalidate(taskDetailProvider(task.id));
    ref.invalidate(allTasksProvider(task.householdId));
    ref.invalidate(overdueTasksProvider(task.householdId));
    ref.invalidate(upcomingTasksProvider(task.householdId));
    if (task.assetId != null) {
      ref.invalidate(assetTasksProvider(task.assetId!));
      ref.invalidate(assetDetailProvider(task.assetId!));
    }
    ref.invalidate(maintenanceBootstrapProvider);
  }
}

final maintenanceTaskNotifierProvider =
    AsyncNotifierProvider<MaintenanceTaskNotifier, void>(
      MaintenanceTaskNotifier.new,
    );
