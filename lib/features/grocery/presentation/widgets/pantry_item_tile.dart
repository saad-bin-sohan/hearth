import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/widgets/grocery_visuals.dart';

class PantryItemTile extends StatelessWidget {
  const PantryItemTile({required this.item, super.key});

  final PantryItemEntity item;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final showExpiry = item.expiryUrgency != PantryExpiryUrgency.none;
    return HearthCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            pantryCategoryIcon(item.category),
            size: 24,
            color: AppColors.secondaryFor(brightness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    Text(
                      item.quantityDisplay,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                    _LocationPill(label: item.location.label),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (showExpiry)
                ExpiryBadge(
                  urgency: pantryBadgeUrgency(item.expiryUrgency),
                  daysUntil: item.daysUntilExpiry,
                  date: item.expiryDate,
                  size: ExpiryBadgeSize.compact,
                  pulse: item.expiryUrgency == PantryExpiryUrgency.critical,
                ),
              if (item.isLowStock) ...<Widget>[
                if (showExpiry) const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentContainerFor(brightness),
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                  ),
                  child: Text(
                    'Low Stock',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accentFor(brightness),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(brightness),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondaryFor(brightness),
        ),
      ),
    );
  }
}
