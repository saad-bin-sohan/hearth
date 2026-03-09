import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/repositories/maintenance_task_repository.dart';
import 'package:uuid/uuid.dart';

class CompleteTaskUseCase {
  CompleteTaskUseCase(
    this._repository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final MaintenanceTaskRepository _repository;
  final Uuid _uuid;

  Future<DateTime?> execute(
    MaintenanceTask task, {
    required String completedByUserId,
    double? actualCost,
    String? vendorId,
    String? notes,
    String? completionPhotoPath,
  }) async {
    await _repository.completeTask(
      task.id,
      completedByUserId: completedByUserId,
      actualCost: actualCost,
      vendorId: vendorId,
      notes: notes,
      completionPhotoPath: completionPhotoPath,
    );

    if (task.recurrence == MaintenanceRecurrence.none) {
      return null;
    }

    final nextDueDate = _calculateNextDueDate(task);
    if (nextDueDate == null) {
      return null;
    }

    final nextTask = task.copyWith(
      id: _uuid.v4(),
      dueDate: nextDueDate,
      status: MaintenanceTaskStatus.pending,
      completedAt: null,
      completedByUserId: null,
      actualCost: null,
      vendorId: task.vendorId,
      completionNotes: null,
      completionPhotoPath: null,
      createdAt: DateTime.now(),
    );
    await _repository.addTask(nextTask);
    return nextDueDate;
  }

  DateTime? _calculateNextDueDate(MaintenanceTask task) {
    final base = task.dueDate ?? DateTime.now();
    switch (task.recurrence) {
      case MaintenanceRecurrence.none:
        return null;
      case MaintenanceRecurrence.monthly:
        return DateTime(base.year, base.month + 1, base.day);
      case MaintenanceRecurrence.quarterly:
        return DateTime(base.year, base.month + 3, base.day);
      case MaintenanceRecurrence.annually:
        return DateTime(base.year + 1, base.month, base.day);
      case MaintenanceRecurrence.custom:
        final raw = task.recurrenceRule ?? '';
        final everyPattern = RegExp(r'every_(\d+)_days');
        final customPattern = RegExp(r'custom:(\d+)');
        final match = everyPattern.firstMatch(raw) ?? customPattern.firstMatch(raw);
        final days = int.tryParse(match?.group(1) ?? '');
        return base.add(Duration(days: days ?? 30));
    }
  }
}
