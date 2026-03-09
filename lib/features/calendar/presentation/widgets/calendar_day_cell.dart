import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';
import 'package:hearth/features/calendar/presentation/widgets/event_dot.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.events,
    required this.onTap,
    super.key,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final List<CalendarEvent> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = isSelected
        ? AppColors.primaryFor(brightness)
        : isToday
        ? AppColors.primaryContainerFor(brightness)
        : Colors.transparent;
    final fgColor = isSelected
        ? AppColors.surface
        : isToday
        ? AppColors.primaryFor(brightness)
        : isCurrentMonth
        ? AppColors.textPrimaryFor(brightness)
        : AppColors.textTertiaryFor(brightness);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          children: <Widget>[
            AnimatedContainer(
              duration: AppAnimations.fast,
              curve: AppAnimations.easeInOut,
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${date.day}',
                style: AppTextStyles.labelLarge.copyWith(color: fgColor),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  events.length > 3 ? 3 : events.length,
                  (int index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: EventDot(source: events[index].source),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
