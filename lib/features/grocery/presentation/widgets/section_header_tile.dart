import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_badge.dart';
import 'package:hugeicons/hugeicons.dart';

class SectionHeaderTile extends StatelessWidget {
  const SectionHeaderTile({
    required this.label,
    required this.count,
    required this.collapsed,
    required this.onTap,
    required this.icon,
    super.key,
  });

  final String label;
  final int count;
  final bool collapsed;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: AppColors.surfaceVariantFor(brightness),
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: AppColors.secondaryFor(brightness)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ),
                HearthBadge(
                  count: count,
                  backgroundColor: AppColors.primaryContainerFor(brightness),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedRotation(
                  turns: collapsed ? 0 : 0.25,
                  duration: AppAnimations.fast,
                  curve: AppAnimations.easeInOut,
                  child: Icon(
                    HugeIcons.strokeRoundedArrowRight01,
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
