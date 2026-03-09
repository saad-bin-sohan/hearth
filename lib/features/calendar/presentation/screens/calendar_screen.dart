import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:hearth/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:hearth/features/calendar/presentation/widgets/event_list_tile.dart';
import 'package:hugeicons/hugeicons.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  static const String routePath = '/calendar';

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _slideFromRight = true;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(calendarMonthProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    final selectedEvents = ref.watch(selectedDayEventsProvider);
    final eventsByDay = ref.watch(eventsByDayProvider);
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _monthLabel(month.year, month.month),
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 360,
            child: CalendarMonthView(
              year: month.year,
              month: month.month,
              selectedDay: ref.watch(selectedCalendarDayProvider),
              eventsByDay: eventsByDay,
              slideFromRight: _slideFromRight,
              onDaySelected: (DateTime value) {
                ref.read(selectedCalendarDayProvider.notifier).state = value.day;
              },
              onPreviousMonth: () {
                setState(() {
                  _slideFromRight = false;
                });
                ref.read(calendarMonthProvider.notifier).prevMonth();
                ref.read(selectedCalendarDayProvider.notifier).state = 1;
              },
              onNextMonth: () {
                setState(() {
                  _slideFromRight = true;
                });
                ref.read(calendarMonthProvider.notifier).nextMonth();
                ref.read(selectedCalendarDayProvider.notifier).state = 1;
              },
            ),
          ),
          Divider(color: AppColors.dividerFor(brightness), height: 1),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                final displayEvents = selectedEvents.isNotEmpty
                    ? selectedEvents
                    : events.where((event) {
                        final now = DateTime.now();
                        return event.date.year == now.year &&
                            event.date.month == now.month &&
                            event.date.day == now.day;
                      }).toList();
                if (displayEvents.isEmpty) {
                  final upcoming = events.take(5).toList();
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: <Widget>[
                      const HearthSectionHeader(title: 'Nothing scheduled for this day'),
                      if (upcoming.isEmpty)
                        const HearthEmptyState(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          title: 'Nothing scheduled for this day.',
                          body: 'This month has no synced events yet.',
                        )
                      else ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        const HearthSectionHeader(title: 'Coming up this month'),
                        ...upcoming.map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: EventListTile(
                              event: event,
                              onTap: () => context.push(
                                '/calendar/events/${event.id}',
                                extra: event,
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: <Widget>[
                    HearthSectionHeader(
                      title: '${displayEvents.length} event${displayEvents.length == 1 ? '' : 's'}',
                    ),
                    ...displayEvents.map((event) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: EventListTile(
                          event: event,
                          onTap: () => context.push(
                            '/calendar/events/${event.id}',
                            extra: event,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, _) => Center(child: Text('$error')),
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(int year, int month) {
    const labels = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${labels[month - 1]} $year';
  }
}
