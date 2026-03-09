import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';
import 'package:hearth/features/calendar/presentation/widgets/event_dot.dart';
import 'package:hugeicons/hugeicons.dart';

class EventListTile extends StatelessWidget {
  const EventListTile({required this.event, required this.onTap, super.key});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return HearthCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              EventDot(source: event.source, size: 8),
              Container(
                width: 2,
                height: 36,
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                color: CalendarEvent.colorForSource(event.source),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${event.source.name} · ${AppFormatters.shortDate(event.date)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: CalendarEvent.colorForSource(event.source),
                  ),
                ),
                if (event.subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    event.subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            HugeIcons.strokeRoundedArrowRight01,
            color: AppColors.textTertiaryFor(brightness),
          ),
        ],
      ),
    );
  }
}
