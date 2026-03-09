import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';

class ChoreStreakBadge extends StatefulWidget {
  const ChoreStreakBadge({required this.streakCount, super.key});

  final int streakCount;

  @override
  State<ChoreStreakBadge> createState() => _ChoreStreakBadgeState();
}

class _ChoreStreakBadgeState extends State<ChoreStreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.verySlow,
    );
    if (widget.streakCount >= 14) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ChoreStreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakCount >= 14 && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.streakCount < 14 && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streakCount <= 0) {
      return const SizedBox.shrink();
    }
    final brightness = Theme.of(context).brightness;
    final scaleRange = switch (widget.streakCount) {
      >= 30 => 0.06,
      >= 14 => 0.04,
      >= 7 => 0.02,
      _ => 0.0,
    };
    final borderColor = switch (widget.streakCount) {
      >= 30 => AppColors.accentFor(brightness),
      >= 7 => AppColors.warningFor(brightness),
      _ => Colors.transparent,
    };
    final backgroundColor = widget.streakCount >= 30
        ? AppColors.accentFor(brightness).withValues(alpha: 0.22)
        : AppColors.accentContainerFor(brightness);
    final padding = switch (widget.streakCount) {
      >= 30 => const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      >= 14 => const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      _ => const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    };

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final glow = widget.streakCount >= 7
            ? math.max(0.02, _controller.value * 0.12)
            : 0.0;
        return Transform.scale(
          scale: 1 + (_controller.value * scaleRange),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
              border: Border.all(color: borderColor),
              boxShadow: glow == 0
                  ? const <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: borderColor.withValues(alpha: glow),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: child,
          ),
        );
      },
      child: Text(
        '🔥 ${widget.streakCount} days',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.accentFor(brightness),
        ),
      ),
    );
  }
}
