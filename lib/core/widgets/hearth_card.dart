import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_card_press.dart';

class HearthCard extends StatelessWidget {
  const HearthCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceFor(brightness),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        boxShadow: AppElevation.elevationLow,
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return HearthCardPress(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      child: content,
    );
  }
}
