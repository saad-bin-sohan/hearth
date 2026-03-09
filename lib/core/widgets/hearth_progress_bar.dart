import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';

class HearthProgressBar extends StatelessWidget {
  const HearthProgressBar({
    required this.progress,
    super.key,
  });

  final double progress;

  Color _colorForProgress(Brightness brightness) {
    if (progress >= 0.9) {
      return AppColors.errorFor(brightness);
    }
    if (progress >= 0.7) {
      return AppColors.accentFor(brightness);
    }
    return AppColors.successFor(brightness);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final width = constraints.maxWidth * progress.clamp(0, 1);
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantFor(brightness),
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          ),
          child: Stack(
            children: <Widget>[
              AnimatedContainer(
                duration: AppAnimations.standard,
                curve: AppAnimations.easeInOut,
                width: width,
                decoration: BoxDecoration(
                  color: _colorForProgress(brightness),
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
