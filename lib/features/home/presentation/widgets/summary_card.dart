import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/hearth_card.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.title,
    required this.metric,
    required this.caption,
    required this.accentColor,
    super.key,
  });

  final String title;
  final String metric;
  final String caption;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      width: 220,
      height: 128,
      child: HearthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
            HearthNumberTicker(
              value: metric,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: accentColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
