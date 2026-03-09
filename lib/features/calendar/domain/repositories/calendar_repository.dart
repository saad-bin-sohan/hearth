import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Stream<List<CalendarEvent>> watchEventsForMonth(int year, int month);
  Future<List<CalendarEvent>> getEventsForDate(DateTime date);
}
