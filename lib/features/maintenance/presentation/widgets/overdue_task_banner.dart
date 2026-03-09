import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hugeicons/hugeicons.dart';

class OverdueTaskBanner extends StatefulWidget {
  const OverdueTaskBanner({
    required this.overdueCount,
    required this.onViewPressed,
    super.key,
  });

  final int overdueCount;
  final VoidCallback onViewPressed;

  @override
  State<OverdueTaskBanner> createState() => _OverdueTaskBannerState();
}

class _OverdueTaskBannerState extends State<OverdueTaskBanner>
    with TickerProviderStateMixin {
  @override
  void didUpdateWidget(covariant OverdueTaskBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overdueCount == 0 && widget.overdueCount > 0) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AnimatedSize(
      duration: AppAnimations.standard,
      curve: AppAnimations.easeInOut,
      child: widget.overdueCount == 0
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                border: Border(
                  left: BorderSide(
                    color: AppColors.errorFor(brightness),
                    width: AppSpacing.xs,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    HugeIcons.strokeRoundedAlert01,
                    size: 20,
                    color: AppColors.errorFor(brightness),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${widget.overdueCount} task${widget.overdueCount == 1 ? '' : 's'} overdue',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.errorFor(brightness),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onViewPressed,
                    child: Text(
                      'View',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.errorFor(brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
