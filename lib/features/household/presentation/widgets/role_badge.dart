import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/features/household/domain/household_models.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({required this.role, super.key});

  final HouseholdRole role;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = switch (role) {
      HouseholdRole.admin => AppColors.primaryFor(brightness),
      HouseholdRole.member => AppColors.secondaryFor(brightness),
      HouseholdRole.observer => AppColors.accentFor(brightness),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Text(
        role.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
