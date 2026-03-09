import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';

void main() {
  late AppDatabase database;
  late CalendarRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    repository = CalendarRepositoryImpl(database, 'household-1');
  });

  tearDown(() async {
    await database.close();
  });

  test('aggregates finance, chores, documents, and maintenance events', () async {
    final targetDate = DateTime(2026, 3, 10, 9);

    await database.into(database.expenses).insert(
          ExpensesCompanion.insert(
            id: 'expense-1',
            householdId: 'household-1',
            title: 'Internet Bill',
            amountCents: 8900,
            category: 'utilities',
            paidByUserId: 'user-1',
            expenseDate: DateTime(2026, 3, 1),
            splitRuleJson: '{}',
            isRecurringTemplate: const Value<bool>(true),
            nextDueAt: Value<DateTime?>(targetDate),
            createdBy: 'user-1',
            createdAt: DateTime(2026, 3, 1),
            updatedAt: DateTime(2026, 3, 1),
          ),
        );
    await database.into(database.chores).insert(
          ChoresCompanion.insert(
            id: 'chore-1',
            householdId: 'household-1',
            title: 'Take out recycling',
            areaTag: 'Kitchen',
            estimatedMinutes: 10,
            frequency: 'weekly',
            assignmentType: 'single',
            assignedToUserIds: '["user-1"]',
            nextDueAt: targetDate.add(const Duration(hours: 1)),
            createdAt: DateTime(2026, 3, 1),
            createdByUserId: 'user-1',
          ),
        );
    await database.into(database.documents).insert(
          DocumentsCompanion.insert(
            id: 'document-1',
            householdId: 'household-1',
            title: 'Passport',
            docType: 'passport',
            expiryDate: Value<DateTime?>(targetDate.add(const Duration(hours: 2))),
            localFilePath: '/tmp/passport.pdf',
            fileSizeBytes: 512,
            mimeType: 'application/pdf',
            uploadedByUserId: 'user-1',
            uploadedAt: DateTime(2026, 3, 1),
          ),
        );
    await database.into(database.maintenanceTasks).insert(
          MaintenanceTasksCompanion.insert(
            id: 'task-1',
            householdId: 'household-1',
            title: 'Replace air filter',
            dueDate: Value<DateTime?>(targetDate.add(const Duration(hours: 3))),
            createdAt: DateTime(2026, 3, 1),
            createdByUserId: 'user-1',
          ),
        );

    final monthEvents = await repository.watchEventsForMonth(2026, 3).first;
    final dayEvents = await repository.getEventsForDate(DateTime(2026, 3, 10));

    expect(monthEvents, hasLength(4));
    expect(dayEvents, hasLength(4));
    expect(
      monthEvents.map((event) => event.source).toSet(),
      <CalendarEventSource>{
        CalendarEventSource.finance,
        CalendarEventSource.chores,
        CalendarEventSource.documents,
        CalendarEventSource.maintenance,
      },
    );
    expect(
      monthEvents
          .firstWhere((event) => event.source == CalendarEventSource.finance)
          .deepLinkRoute,
      '/finance/expense/expense-1',
    );
    expect(
      monthEvents
          .firstWhere((event) => event.source == CalendarEventSource.chores)
          .deepLinkRoute,
      '/chores/chore-1',
    );
    expect(
      monthEvents
          .firstWhere((event) => event.source == CalendarEventSource.documents)
          .deepLinkRoute,
      '/documents/document-1',
    );
    expect(
      monthEvents
          .firstWhere((event) => event.source == CalendarEventSource.maintenance)
          .deepLinkRoute,
      '/maintenance/tasks/task-1',
    );
  });
}
