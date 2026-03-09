import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';
import 'package:hearth/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';

final calendarRepositoryProvider = Provider<CalendarRepository?>((Ref ref) {
  final householdId = ref.watch(maintenanceHouseholdIdProvider);
  if (householdId == null) {
    return null;
  }
  return CalendarRepositoryImpl(ref.watch(appDatabaseProvider), householdId);
});

class CalendarMonthNotifier extends Notifier<({int year, int month})> {
  @override
  ({int year, int month}) build() {
    final now = DateTime.now();
    return (year: now.year, month: now.month);
  }

  void nextMonth() {
    final current = DateTime(state.year, state.month + 1);
    state = (year: current.year, month: current.month);
  }

  void prevMonth() {
    final current = DateTime(state.year, state.month - 1);
    state = (year: current.year, month: current.month);
  }
}

final calendarMonthProvider =
    NotifierProvider<CalendarMonthNotifier, ({int year, int month})>(
      CalendarMonthNotifier.new,
    );

final calendarEventsProvider = StreamProvider<List<CalendarEvent>>((Ref ref) {
  final repository = ref.watch(calendarRepositoryProvider);
  if (repository == null) {
    return Stream<List<CalendarEvent>>.value(const <CalendarEvent>[]);
  }
  final month = ref.watch(calendarMonthProvider);
  return repository.watchEventsForMonth(month.year, month.month);
});

final eventsByDayProvider = Provider<Map<int, List<CalendarEvent>>>((Ref ref) {
  return ref.watch(calendarEventsProvider).maybeWhen(
    data: (List<CalendarEvent> events) {
      final grouped = <int, List<CalendarEvent>>{};
      for (final event in events) {
        grouped.putIfAbsent(event.date.day, () => <CalendarEvent>[]).add(event);
      }
      return grouped;
    },
    orElse: () => <int, List<CalendarEvent>>{},
  );
});

final selectedCalendarDayProvider = StateProvider<int?>((Ref ref) {
  return DateTime.now().day;
});

final selectedDayEventsProvider = Provider<List<CalendarEvent>>((Ref ref) {
  final selectedDay = ref.watch(selectedCalendarDayProvider);
  if (selectedDay == null) {
    return const <CalendarEvent>[];
  }
  final grouped = ref.watch(eventsByDayProvider);
  return grouped[selectedDay] ?? const <CalendarEvent>[];
});
