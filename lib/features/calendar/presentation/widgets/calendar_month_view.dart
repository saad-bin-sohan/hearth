import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';
import 'package:hearth/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:hugeicons/hugeicons.dart';

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.eventsByDay,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.slideFromRight,
    super.key,
  });

  final int year;
  final int month;
  final int? selectedDay;
  final Map<int, List<CalendarEvent>> eventsByDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool slideFromRight;

  @override
  Widget build(BuildContext context) {
    final current = DateTime(year, month, 1);
    final brightness = Theme.of(context).brightness;
    final gridDates = _gridDates(current);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
            ),
            Expanded(
              child: Text(
                _monthLabel(current),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimaryFor(brightness),
                ),
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(HugeIcons.strokeRoundedArrowRight01),
            ),
          ],
        ),
        Row(
          children: const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map(
                (String label) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppAnimations.standard,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final offsetTween = Tween<Offset>(
                begin: slideFromRight ? const Offset(0.2, 0) : const Offset(-0.2, 0),
                end: Offset.zero,
              );
              return SlideTransition(
                position: offsetTween.animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: GridView.builder(
              key: ValueKey<String>('calendar-$year-$month'),
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: gridDates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemBuilder: (BuildContext context, int index) {
                final date = gridDates[index];
                return CalendarDayCell(
                  date: date,
                  isCurrentMonth: date.month == month,
                  isSelected: selectedDay == date.day && date.month == month,
                  isToday: _isSameDay(date, DateTime.now()),
                  events: date.month == month
                      ? (eventsByDay[date.day] ?? const <CalendarEvent>[])
                      : const <CalendarEvent>[],
                  onTap: () => onDaySelected(date),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<DateTime> _gridDates(DateTime monthStart) {
    final firstDisplayDay = monthStart.subtract(Duration(days: monthStart.weekday - 1));
    return List<DateTime>.generate(
      42,
      (int index) => firstDisplayDay.add(Duration(days: index)),
    );
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  String _monthLabel(DateTime value) {
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
    return '${labels[value.month - 1]} ${value.year}';
  }
}
