import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_task.freezed.dart';

enum MaintenanceTaskStatus { pending, overdue, completed }

enum MaintenanceRecurrence { none, monthly, quarterly, annually, custom }

extension MaintenanceTaskStatusX on MaintenanceTaskStatus {
  static MaintenanceTaskStatus fromName(String value) {
    return MaintenanceTaskStatus.values.firstWhere(
      (MaintenanceTaskStatus status) => status.name == value,
      orElse: () => MaintenanceTaskStatus.pending,
    );
  }

  String get label => switch (this) {
    MaintenanceTaskStatus.pending => 'Pending',
    MaintenanceTaskStatus.overdue => 'Overdue',
    MaintenanceTaskStatus.completed => 'Completed',
  };
}

extension MaintenanceRecurrenceX on MaintenanceRecurrence {
  static MaintenanceRecurrence fromStorageValue(String? value) {
    if (value == null || value.isEmpty || value == MaintenanceRecurrence.none.name) {
      return MaintenanceRecurrence.none;
    }
    if (value.startsWith('every_') || value.startsWith('custom:')) {
      return MaintenanceRecurrence.custom;
    }
    return MaintenanceRecurrence.values.firstWhere(
      (MaintenanceRecurrence recurrence) => recurrence.name == value,
      orElse: () => MaintenanceRecurrence.none,
    );
  }

  String get label => switch (this) {
    MaintenanceRecurrence.none => 'None',
    MaintenanceRecurrence.monthly => 'Monthly',
    MaintenanceRecurrence.quarterly => 'Quarterly',
    MaintenanceRecurrence.annually => 'Annually',
    MaintenanceRecurrence.custom => 'Custom',
  };
}

@freezed
class MaintenanceTask with _$MaintenanceTask {
  const factory MaintenanceTask({
    required String id,
    required String householdId,
    String? assetId,
    required String title,
    String? description,
    String? assignedToUserId,
    DateTime? dueDate,
    required MaintenanceRecurrence recurrence,
    String? recurrenceRule,
    double? estimatedCost,
    required MaintenanceTaskStatus status,
    DateTime? completedAt,
    String? completedByUserId,
    double? actualCost,
    String? vendorId,
    String? completionNotes,
    String? completionPhotoPath,
    required DateTime createdAt,
    required String createdByUserId,
  }) = _MaintenanceTask;

  const MaintenanceTask._();

  bool get isOverdue =>
      status != MaintenanceTaskStatus.completed &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  String get recurrenceStorageValue {
    if (recurrence == MaintenanceRecurrence.custom) {
      return recurrenceRule?.trim().isNotEmpty == true
          ? recurrenceRule!.trim()
          : 'custom';
    }
    return recurrence.name;
  }
}
