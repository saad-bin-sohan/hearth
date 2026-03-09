import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';

class HearthChip extends StatelessWidget {
  const HearthChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.easeInOut,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryContainerFor(brightness)
            : AppColors.surfaceVariantFor(brightness),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? AppColors.primaryFor(brightness)
                      : AppColors.textSecondaryFor(brightness),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppColors.primaryFor(brightness)
                      : AppColors.textSecondaryFor(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
