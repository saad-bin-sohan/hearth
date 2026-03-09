import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';

class FairnessBar extends StatefulWidget {
  const FairnessBar({
    required this.score,
    this.compact = false,
    this.delay = Duration.zero,
    this.showLabel = true,
    super.key,
  });

  final double score;
  final bool compact;
  final Duration delay;
  final bool showLabel;

  @override
  State<FairnessBar> createState() => _FairnessBarState();
}

class _FairnessBarState extends State<FairnessBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.standard,
    );
    _timer = Timer(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final clampedScore = widget.score.clamp(0, 100).toDouble();
    final fillColor = clampedScore >= 80
        ? AppColors.successFor(brightness)
        : clampedScore >= 50
        ? AppColors.warningFor(brightness)
        : AppColors.errorFor(brightness);
    final label = clampedScore.toStringAsFixed(clampedScore % 1 == 0 ? 0 : 1);
    final height = widget.compact ? AppSpacing.sm : 12.0;

    return Row(
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  final width =
                      constraints.maxWidth *
                      (clampedScore / 100) *
                      _controller.value;
                  return Stack(
                    children: <Widget>[
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariantFor(brightness),
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusFull,
                          ),
                        ),
                      ),
                      Container(
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusFull,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: fillColor.withValues(alpha: 0.24),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        if (widget.showLabel) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          HearthNumberTicker(
            value: label,
            suffix: '%',
            style: widget.compact
                ? AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  )
                : AppTextStyles.numericSmall.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
          ),
        ],
      ],
    );
  }
}
