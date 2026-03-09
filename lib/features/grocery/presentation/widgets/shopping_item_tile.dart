import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hugeicons/hugeicons.dart';

enum ShoppingItemTileVariant { full, compact }

class ShoppingItemTile extends StatelessWidget {
  const ShoppingItemTile({
    required this.item,
    required this.onToggleChecked,
    this.variant = ShoppingItemTileVariant.full,
    this.assignedDisplayName,
    this.highlightPulse = false,
    super.key,
  });

  final ShoppingItemEntity item;
  final VoidCallback onToggleChecked;
  final ShoppingItemTileVariant variant;
  final String? assignedDisplayName;
  final bool highlightPulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: AppAnimations.medium,
      curve: Curves.elasticOut,
      scale: highlightPulse ? 1.04 : 1,
      child: switch (variant) {
        ShoppingItemTileVariant.full => _FullShoppingItemTile(
          item: item,
          onToggleChecked: onToggleChecked,
          assignedDisplayName: assignedDisplayName,
        ),
        ShoppingItemTileVariant.compact => _CompactShoppingItemTile(
          item: item,
          onToggleChecked: onToggleChecked,
          assignedDisplayName: assignedDisplayName,
        ),
      },
    );
  }
}

class _FullShoppingItemTile extends StatelessWidget {
  const _FullShoppingItemTile({
    required this.item,
    required this.onToggleChecked,
    required this.assignedDisplayName,
  });

  final ShoppingItemEntity item;
  final VoidCallback onToggleChecked;
  final String? assignedDisplayName;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return HearthCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: item.isChecked
          ? AppColors.surfaceVariantFor(brightness).withValues(alpha: 0.7)
          : null,
      child: Opacity(
        opacity: item.isChecked ? 0.68 : 1,
        child: Row(
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              onTap: () {
                HapticFeedback.lightImpact();
                onToggleChecked();
              },
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                curve: AppAnimations.easeInOut,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? AppColors.primaryFor(brightness)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  border: Border.all(
                    color: AppColors.primaryFor(brightness),
                    width: 2,
                  ),
                ),
                child: AnimatedOpacity(
                  duration: AppAnimations.fast,
                  opacity: item.isChecked ? 1 : 0,
                  child: const Icon(
                    HugeIcons.strokeRoundedTick02,
                    size: 18,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AnimatedDefaultTextStyle(
                    duration: AppAnimations.standard,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: item.isChecked
                          ? AppColors.textTertiaryFor(brightness)
                          : AppColors.textPrimaryFor(brightness),
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        item.quantityDisplay,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                      ),
                      _MiniPill(
                        label: item.section.label,
                        backgroundColor: AppColors.surfaceVariantFor(
                          brightness,
                        ),
                        foregroundColor: AppColors.textSecondaryFor(brightness),
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Icon(
                          HugeIcons.strokeRoundedNote01,
                          size: 16,
                          color: AppColors.textTertiaryFor(brightness),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (assignedDisplayName != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              HearthAvatar(displayName: assignedDisplayName!, size: 32),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactShoppingItemTile extends StatelessWidget {
  const _CompactShoppingItemTile({
    required this.item,
    required this.onToggleChecked,
    required this.assignedDisplayName,
  });

  final ShoppingItemEntity item;
  final VoidCallback onToggleChecked;
  final String? assignedDisplayName;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          onTap: () {
            HapticFeedback.lightImpact();
            onToggleChecked();
          },
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            curve: AppAnimations.easeInOut,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: item.isChecked
                  ? AppColors.primaryFor(brightness)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              border: Border.all(
                color: AppColors.primaryFor(brightness),
                width: 2,
              ),
            ),
            child: AnimatedOpacity(
              duration: AppAnimations.fast,
              opacity: item.isChecked ? 1 : 0,
              child: const Icon(
                HugeIcons.strokeRoundedTick02,
                size: 16,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: item.isChecked
                      ? AppColors.textTertiaryFor(brightness)
                      : AppColors.textPrimaryFor(brightness),
                  decoration: item.isChecked
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              Text(
                item.quantityDisplay,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
            ],
          ),
        ),
        if (assignedDisplayName != null)
          HearthAvatar(displayName: assignedDisplayName!, size: 24),
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: foregroundColor),
      ),
    );
  }
}
