import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    required this.eventId,
    this.initialEvent,
    super.key,
  });

  final String eventId;
  final CalendarEvent? initialEvent;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final event = initialEvent;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          event?.source.name.toUpperCase() ?? 'Calendar Event',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: HearthCard(
          child: event == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'This event is unavailable outside the current calendar session.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HearthButton(
                      label: 'Back to Calendar',
                      onPressed: () => context.go('/calendar'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      event.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppFormatters.shortDate(event.date),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      event.source.name,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: CalendarEvent.colorForSource(event.source),
                      ),
                    ),
                    if (event.subtitle != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        event.subtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiaryFor(brightness),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    HearthButton(
                      label: 'View Original',
                      onPressed: () => context.go(event.deepLinkRoute),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
