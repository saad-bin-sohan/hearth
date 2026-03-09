import 'dart:async';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';
import 'package:hearth/features/calendar/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._db, this._householdId);

  final AppDatabase _db;
  final String _householdId;

  @override
  Stream<List<CalendarEvent>> watchEventsForMonth(int year, int month) async* {
    yield await _fetchEventsForMonth(year, month);

    final merged = StreamGroup.merge(
      <Stream<void>>[
        _db.tableUpdates(TableUpdateQuery.onTable(_db.expenses)).map((_) {}),
        _db.tableUpdates(TableUpdateQuery.onTable(_db.chores)).map((_) {}),
        _db.tableUpdates(TableUpdateQuery.onTable(_db.documents)).map((_) {}),
        _db.tableUpdates(TableUpdateQuery.onTable(_db.maintenanceTasks)).map((_) {}),
      ],
    );

    await for (final _ in merged) {
      yield await _fetchEventsForMonth(year, month);
    }
  }

  @override
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    return _fetchEventsBetween(start, end);
  }

  Future<List<CalendarEvent>> _fetchEventsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
    return _fetchEventsBetween(start, end);
  }

  Future<List<CalendarEvent>> _fetchEventsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final events = <CalendarEvent>[];

    final expenseRows = await (_db.select(_db.expenses)
          ..where(
            (table) =>
                table.householdId.equals(_householdId) &
                table.isRecurringTemplate.equals(true) &
                table.nextDueAt.isNotNull() &
                table.nextDueAt.isBiggerOrEqualValue(start) &
                table.nextDueAt.isSmallerOrEqualValue(end),
          ))
        .get();
    for (final row in expenseRows) {
      events.add(
        CalendarEvent(
          id: 'finance_${row.id}',
          title: row.title,
          date: row.nextDueAt!,
          source: CalendarEventSource.finance,
          sourceEntityId: row.id,
          subtitle:
              '${row.category} · ${AppFormatters.currencyFromCents(amountCents: row.amountCents, currencyCode: 'USD')}',
          deepLinkRoute: '/finance/expense/${row.id}',
        ),
      );
    }

    final choreRows = await (_db.select(_db.chores)
          ..where(
            (table) =>
                table.householdId.equals(_householdId) &
                table.isActive.equals(true) &
                table.nextDueAt.isBiggerOrEqualValue(start) &
                table.nextDueAt.isSmallerOrEqualValue(end),
          ))
        .get();
    for (final row in choreRows) {
      events.add(
        CalendarEvent(
          id: 'chore_${row.id}',
          title: row.title,
          date: row.nextDueAt,
          source: CalendarEventSource.chores,
          sourceEntityId: row.id,
          subtitle: row.areaTag,
          deepLinkRoute: '/chores/${row.id}',
        ),
      );
    }

    final documentRows = await (_db.select(_db.documents)
          ..where(
            (table) =>
                table.householdId.equals(_householdId) &
                table.expiryDate.isNotNull() &
                table.expiryDate.isBiggerOrEqualValue(start) &
                table.expiryDate.isSmallerOrEqualValue(end),
          ))
        .get();
    for (final row in documentRows) {
      events.add(
        CalendarEvent(
          id: 'document_${row.id}',
          title: '${row.title} expires',
          date: row.expiryDate!,
          source: CalendarEventSource.documents,
          sourceEntityId: row.id,
          subtitle: row.docType,
          deepLinkRoute: '/documents/${row.id}',
        ),
      );
    }

    final taskRows = await (_db.select(_db.maintenanceTasks)
          ..where(
            (table) =>
                table.householdId.equals(_householdId) &
                table.dueDate.isNotNull() &
                table.dueDate.isBiggerOrEqualValue(start) &
                table.dueDate.isSmallerOrEqualValue(end) &
                table.statusEnum.isNotValue('completed'),
          ))
        .get();
    for (final row in taskRows) {
      events.add(
        CalendarEvent(
          id: 'maintenance_${row.id}',
          title: row.title,
          date: row.dueDate!,
          source: CalendarEventSource.maintenance,
          sourceEntityId: row.id,
          subtitle: row.statusEnum == 'overdue' ? 'Overdue' : null,
          deepLinkRoute: '/maintenance/tasks/${row.id}',
        ),
      );
    }

    events.sort((CalendarEvent left, CalendarEvent right) {
      return left.date.compareTo(right.date);
    });
    return events;
  }
}
