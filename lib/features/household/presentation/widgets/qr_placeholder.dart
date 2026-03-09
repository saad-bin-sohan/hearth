import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';

class QrPlaceholder extends StatelessWidget {
  const QrPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(brightness),
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 64,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (BuildContext context, int index) {
          final filled = <int>{0, 1, 8, 9, 6, 7, 14, 15, 48, 49, 56, 57, 54, 55, 62, 63}
              .contains(index) ||
              index.isEven;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: filled
                  ? AppColors.primaryFor(brightness)
                  : AppColors.surfaceFor(brightness),
              borderRadius: BorderRadius.circular(AppRadius.radiusXs),
            ),
          );
        },
      ),
    );
  }
}
