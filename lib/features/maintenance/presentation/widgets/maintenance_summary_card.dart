import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:hearth/features/maintenance/presentation/screens/maintenance_dashboard_screen.dart';
import 'package:hugeicons/hugeicons.dart';

class MaintenanceSummaryCard extends ConsumerWidget {
  const MaintenanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    if (householdId == null) {
      return const SizedBox.shrink();
    }
    final overdueAsync = ref.watch(overdueTasksProvider(householdId));
    final upcomingAsync = ref.watch(upcomingTasksProvider(householdId));
    final expiringAsync = ref.watch(expiringWarrantyAssetsProvider);

    return SizedBox(
      width: 220,
      height: 136,
      child: HearthCard(
        onTap: () => context.go(MaintenanceDashboardScreen.routePath),
        child: Builder(
          builder: (BuildContext context) {
            final overdueCount = overdueAsync.valueOrNull?.length ?? 0;
            final upcomingCount = upcomingAsync.valueOrNull?.length ?? 0;
            final expiringCount = expiringAsync.valueOrNull?.length ?? 0;
            final metric = overdueCount > 0 ? overdueCount : upcomingCount;
            final footerLabel = expiringCount > 0
                ? '$expiringCount warranty expiring'
                : 'All up to date';
            final footerColor = expiringCount > 0
                ? AppColors.warningFor(brightness)
                : AppColors.successFor(brightness);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      HugeIcons.strokeRoundedWrench01,
                      size: 20,
                      color: AppColors.accentFor(brightness),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Maintenance',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
                HearthNumberTicker(
                  value: '$metric',
                  style: AppTextStyles.numericMedium.copyWith(
                    color: overdueCount > 0
                        ? AppColors.errorFor(brightness)
                        : AppColors.textPrimaryFor(brightness),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      overdueCount > 0 ? 'overdue task(s)' : 'upcoming task(s)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: overdueCount > 0
                            ? AppColors.errorFor(brightness)
                            : AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      footerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: footerColor,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
