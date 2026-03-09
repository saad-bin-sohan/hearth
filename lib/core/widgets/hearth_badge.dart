import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';

class HearthBadge extends StatefulWidget {
  const HearthBadge({required this.count, this.backgroundColor, super.key});

  final int count;
  final Color? backgroundColor;

  @override
  State<HearthBadge> createState() => _HearthBadgeState();
}

class _HearthBadgeState extends State<HearthBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.accentFor(brightness),
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        ),
        child: Text(
          '${widget.count}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
