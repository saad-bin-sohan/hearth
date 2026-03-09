import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hearth/core/theme/app_colors.dart';

part 'calendar_event.freezed.dart';

enum CalendarEventSource { finance, chores, documents, maintenance }

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required String id,
    required String title,
    required DateTime date,
    required CalendarEventSource source,
    required String sourceEntityId,
    String? subtitle,
    required String deepLinkRoute,
  }) = _CalendarEvent;

  const CalendarEvent._();

  static Color colorForSource(CalendarEventSource source) {
    switch (source) {
      case CalendarEventSource.finance:
        return AppColors.primary;
      case CalendarEventSource.chores:
        return AppColors.secondary;
      case CalendarEventSource.documents:
        return AppColors.secondaryLight;
      case CalendarEventSource.maintenance:
        return AppColors.accent;
    }
  }
}
