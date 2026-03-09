import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/services/notification_service.dart';
import 'package:hearth/features/maintenance/domain/entities/asset.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';

void main() {
  test('maintenance overdue notifications stay in the 1000 range', () {
    final planned = LocalNotificationService.plannedMaintenanceOverdueEntries(
      <MaintenanceTask>[
        _task(
          id: 'task-1',
          title: 'Replace filter',
          dueDate: DateTime(2026, 3, 2),
        ),
        _task(
          id: 'task-2',
          title: 'Clean vents',
          dueDate: DateTime(2026, 3, 3),
        ),
        _task(
          id: 'task-3',
          title: 'No date',
          dueDate: null,
        ),
      ],
    );

    expect(planned.map((entry) => entry.id), <int>[1000, 1001]);
    expect(planned.map((entry) => entry.task.title), <String>[
      'Replace filter',
      'Clean vents',
    ]);
  });

  test('warranty notifications stay in the 1500 range for expiring assets only', () {
    final now = DateTime.now();
    final planned = LocalNotificationService.plannedWarrantyNotificationEntries(
      <Asset>[
        _asset(
          id: 'safe',
          name: 'Dryer',
          warrantyExpiry: now.add(const Duration(days: 90)),
        ),
        _asset(
          id: 'soon',
          name: 'Boiler',
          warrantyExpiry: now.add(const Duration(days: 45)),
        ),
        _asset(
          id: 'week',
          name: 'Dishwasher',
          warrantyExpiry: now.add(const Duration(days: 6)),
        ),
      ],
    );

    expect(planned.map((entry) => entry.id), <int>[1500, 1501]);
    expect(planned.map((entry) => entry.asset.name), <String>[
      'Boiler',
      'Dishwasher',
    ]);
  });
}

Asset _asset({
  required String id,
  required String name,
  required DateTime warrantyExpiry,
}) {
  return Asset(
    id: id,
    householdId: 'household-1',
    name: name,
    category: AssetCategory.appliance,
    warrantyExpiry: warrantyExpiry,
    createdByUserId: 'user-1',
    createdAt: DateTime(2026, 3, 9),
  );
}

MaintenanceTask _task({
  required String id,
  required String title,
  required DateTime? dueDate,
}) {
  return MaintenanceTask(
    id: id,
    householdId: 'household-1',
    title: title,
    dueDate: dueDate,
    recurrence: MaintenanceRecurrence.none,
    status: MaintenanceTaskStatus.pending,
    createdAt: DateTime(2026, 3, 9),
    createdByUserId: 'user-1',
  );
}
