import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/chores/presentation/chore_notifier.dart';
import 'package:hearth/features/chores/presentation/chores_dashboard_screen.dart';
import 'package:hugeicons/hugeicons.dart';

class ChoresSummaryCard extends ConsumerWidget {
  const ChoresSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final summaryAsync = ref.watch(choresHomeSummaryProvider);
    return SizedBox(
      width: 220,
      height: 128,
      child: HearthCard(
        onTap: () => context.go(ChoresDashboardScreen.routePath),
        child: summaryAsync.when(
          data: (summary) {
            final dueToday = summary?.dueTodayCount ?? 0;
            final overdue = summary?.overdueCount ?? 0;
            final footerColor = overdue > 0
                ? AppColors.warningFor(brightness)
                : AppColors.successFor(brightness);
            final footerText = overdue > 0 ? '$overdue overdue' : 'All clear';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      HugeIcons.strokeRoundedCheckList,
                      color: AppColors.secondaryFor(brightness),
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Chores',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
                HearthNumberTicker(
                  value: '$dueToday',
                  style: AppTextStyles.numericMedium.copyWith(
                    color: AppColors.secondaryFor(brightness),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'due today',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      footerText,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: footerColor,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    HugeIcons.strokeRoundedCheckList,
                    color: AppColors.secondaryFor(brightness),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Chores',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
              HearthNumberTicker(
                value: '...',
                style: AppTextStyles.numericMedium.copyWith(
                  color: AppColors.secondaryFor(brightness),
                ),
              ),
              Text(
                'Checking today',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
            ],
          ),
          error: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    HugeIcons.strokeRoundedCheckList,
                    color: AppColors.secondaryFor(brightness),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Chores',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
              HearthNumberTicker(
                value: '0',
                style: AppTextStyles.numericMedium.copyWith(
                  color: AppColors.secondaryFor(brightness),
                ),
              ),
              Text(
                'Ready to start',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
