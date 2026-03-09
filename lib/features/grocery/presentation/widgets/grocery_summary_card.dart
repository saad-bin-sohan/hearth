import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hearth/features/grocery/presentation/screens/grocery_dashboard_screen.dart';
import 'package:hugeicons/hugeicons.dart';

class GrocerySummaryCard extends ConsumerWidget {
  const GrocerySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final summaryAsync = ref.watch(groceryHomeSummaryProvider);
    return SizedBox(
      width: 220,
      height: 128,
      child: HearthCard(
        onTap: () => context.go(GroceryDashboardScreen.routePath),
        child: summaryAsync.when(
          data: (summary) {
            final uncheckedCount = summary?.uncheckedItemCount ?? 0;
            final lowStockCount = summary?.lowStockCount ?? 0;
            final expiringSoonCount = summary?.expiringSoonCount ?? 0;
            final footer = lowStockCount > 0
                ? (
                    label: '$lowStockCount low stock',
                    color: AppColors.warningFor(brightness),
                  )
                : expiringSoonCount > 0
                ? (
                    label: '$expiringSoonCount expiring soon',
                    color: AppColors.errorFor(brightness),
                  )
                : (
                    label: 'Pantry stocked',
                    color: AppColors.successFor(brightness),
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      HugeIcons.strokeRoundedShoppingCart01,
                      size: 20,
                      color: AppColors.primaryFor(brightness),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Grocery',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
                HearthNumberTicker(
                  value: '$uncheckedCount',
                  style: AppTextStyles.numericMedium.copyWith(
                    color: AppColors.primaryFor(brightness),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'items to get',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      footer.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: footer.color,
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
                    HugeIcons.strokeRoundedShoppingCart01,
                    size: 20,
                    color: AppColors.primaryFor(brightness),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Grocery',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
              HearthNumberTicker(
                value: '...',
                style: AppTextStyles.numericMedium.copyWith(
                  color: AppColors.primaryFor(brightness),
                ),
              ),
              Text(
                'Syncing pantry',
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
                    HugeIcons.strokeRoundedShoppingCart01,
                    size: 20,
                    color: AppColors.primaryFor(brightness),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Grocery',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
              HearthNumberTicker(
                value: '0',
                style: AppTextStyles.numericMedium.copyWith(
                  color: AppColors.primaryFor(brightness),
                ),
              ),
              Text(
                'Ready to shop',
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
