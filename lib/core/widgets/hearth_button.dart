import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_card_press.dart';

enum HearthButtonVariant { primary, secondary, destructive, ghost }

class HearthButton extends StatelessWidget {
  const HearthButton({
    required this.label,
    required this.onPressed,
    this.variant = HearthButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final HearthButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isEnabled = onPressed != null && !isLoading;
    final colors = switch (variant) {
      HearthButtonVariant.primary => (
        background: AppColors.primaryFor(brightness),
        foreground: AppColors.surface,
        border: AppColors.primaryFor(brightness),
      ),
      HearthButtonVariant.secondary => (
        background: AppColors.secondaryFor(brightness),
        foreground: AppColors.surface,
        border: AppColors.secondaryFor(brightness),
      ),
      HearthButtonVariant.destructive => (
        background: AppColors.errorFor(brightness),
        foreground: AppColors.surface,
        border: AppColors.errorFor(brightness),
      ),
      HearthButtonVariant.ghost => (
        background: AppColors.surfaceVariantFor(brightness),
        foreground: AppColors.textPrimaryFor(brightness),
        border: AppColors.dividerFor(brightness),
      ),
    };

    final child = AnimatedContainer(
      duration: AppAnimations.fast,
      width: expanded ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isEnabled
            ? colors.background
            : colors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        border: Border.all(color: colors.border),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
          color: colors.foreground,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            if (isLoading)
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colors.foreground,
                ),
              )
            else ...<Widget>[
              if (icon != null) ...<Widget>[
                IconTheme(
                  data: IconThemeData(color: colors.foreground, size: 20),
                  child: icon!,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          ],
        ),
      ),
    );

    return HearthCardPress(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      child: child,
    );
  }
}
