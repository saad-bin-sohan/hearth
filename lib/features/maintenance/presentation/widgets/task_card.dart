import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hugeicons/hugeicons.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.onTap,
    this.assetName,
    this.assigneeName,
    super.key,
  });

  final MaintenanceTask task;
  final VoidCallback onTap;
  final String? assetName;
  final String? assigneeName;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final stripeColor = switch (task.status) {
      MaintenanceTaskStatus.pending => AppColors.accentFor(brightness),
      MaintenanceTaskStatus.overdue => AppColors.errorFor(brightness),
      MaintenanceTaskStatus.completed => AppColors.successFor(brightness),
    };
    final dueLabel = _dueLabel(brightness);

    return HearthCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: <Widget>[
          Container(
            width: AppSpacing.xs,
            height: 96,
            decoration: BoxDecoration(
              color: stripeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.radiusMd),
                bottomLeft: Radius.circular(AppRadius.radiusMd),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                    ),
                  ),
                  if (assetName != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: <Widget>[
                        Icon(
                          HugeIcons.strokeRoundedWrench01,
                          size: 16,
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            assetName!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryFor(brightness),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    dueLabel.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: dueLabel.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (assigneeName != null)
                  HearthAvatar(displayName: assigneeName!, size: 32)
                else
                  const SizedBox(height: 32),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: switch (task.status) {
                      MaintenanceTaskStatus.pending =>
                        AppColors.primaryContainerFor(brightness),
                      MaintenanceTaskStatus.overdue => AppColors.errorContainer,
                      MaintenanceTaskStatus.completed =>
                        AppColors.successContainer,
                    },
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                  ),
                  child: Text(
                    switch (task.status) {
                      MaintenanceTaskStatus.pending => 'Pending',
                      MaintenanceTaskStatus.overdue => 'Overdue',
                      MaintenanceTaskStatus.completed => 'Done',
                    },
                    style: AppTextStyles.labelSmall.copyWith(
                      color: switch (task.status) {
                        MaintenanceTaskStatus.pending =>
                          AppColors.primaryFor(brightness),
                        MaintenanceTaskStatus.overdue =>
                          AppColors.errorFor(brightness),
                        MaintenanceTaskStatus.completed =>
                          AppColors.successFor(brightness),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _dueLabel(Brightness brightness) {
    final dueDate = task.dueDate;
    if (dueDate == null) {
      return (
        label: 'No due date',
        color: AppColors.textTertiaryFor(brightness),
      );
    }
    final now = DateTime.now();
    final days = DateTime(dueDate.year, dueDate.month, dueDate.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (task.status == MaintenanceTaskStatus.overdue || days < 0) {
      return (
        label: 'Overdue · ${AppFormatters.shortDate(dueDate)}',
        color: AppColors.errorFor(brightness),
      );
    }
    if (days == 0) {
      return (
        label: 'Due today',
        color: AppColors.primaryFor(brightness),
      );
    }
    if (days <= 3) {
      return (
        label: 'Due in $days day${days == 1 ? '' : 's'}',
        color: AppColors.accentFor(brightness),
      );
    }
    return (
      label: AppFormatters.shortDate(dueDate),
      color: AppColors.textTertiaryFor(brightness),
    );
  }
}
