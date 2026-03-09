import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hugeicons/hugeicons.dart';

enum ExpiryBadgeSize { compact, standard, large }

class ExpiryBadge extends StatefulWidget {
  const ExpiryBadge({
    required this.document,
    this.size = ExpiryBadgeSize.standard,
    this.pulse = false,
    super.key,
  });

  final DocumentEntity document;
  final ExpiryBadgeSize size;
  final bool pulse;

  @override
  State<ExpiryBadge> createState() => _ExpiryBadgeState();
}

class _ExpiryBadgeState extends State<ExpiryBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.verySlow,
    );
    if (widget.pulse &&
        widget.document.expiryUrgency == DocumentExpiryUrgency.critical) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ExpiryBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPulse =
        widget.pulse &&
        widget.document.expiryUrgency == DocumentExpiryUrgency.critical;
    if (shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldPulse && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgency = widget.document.expiryUrgency;
    if (urgency == DocumentExpiryUrgency.none) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final daysUntil = widget.document.daysUntilExpiry;
    final showIcon = widget.size != ExpiryBadgeSize.compact;
    final height = switch (widget.size) {
      ExpiryBadgeSize.compact => AppSpacing.lg - AppSpacing.xs,
      ExpiryBadgeSize.standard => AppSpacing.lg,
      ExpiryBadgeSize.large => AppSpacing.xl - AppSpacing.xs,
    };
    final theme = switch (urgency) {
      DocumentExpiryUrgency.safe => (
          background: AppColors.successContainer,
          foreground: AppColors.successFor(brightness),
          icon: HugeIcons.strokeRoundedCalendar01,
        ),
      DocumentExpiryUrgency.warning => (
          background: AppColors.warningContainerFor(brightness),
          foreground: AppColors.warningFor(brightness),
          icon: HugeIcons.strokeRoundedCalendar01,
        ),
      DocumentExpiryUrgency.critical => (
          background: AppColors.errorContainer,
          foreground: AppColors.errorFor(brightness),
          icon: HugeIcons.strokeRoundedCalendar01,
        ),
      DocumentExpiryUrgency.expired => (
          background: AppColors.errorContainer,
          foreground: AppColors.errorFor(brightness),
          icon: HugeIcons.strokeRoundedCalendarBlock01,
        ),
      DocumentExpiryUrgency.none => (
          background: AppColors.surfaceVariantFor(brightness),
          foreground: AppColors.textTertiaryFor(brightness),
          icon: HugeIcons.strokeRoundedCalendar01,
        ),
    };
    final label = switch (urgency) {
      DocumentExpiryUrgency.expired => widget.size == ExpiryBadgeSize.large &&
              widget.document.expiryDate != null
          ? 'Expired • ${AppFormatters.shortDate(widget.document.expiryDate!)}'
          : 'Expired',
      _ => widget.size == ExpiryBadgeSize.large &&
              widget.document.expiryDate != null
          ? '${daysUntil ?? 0} days • ${AppFormatters.shortDate(widget.document.expiryDate!)}'
          : '${daysUntil ?? 0} days',
    };

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final scale = widget.pulse &&
                urgency == DocumentExpiryUrgency.critical
            ? 1 + (_controller.value * 0.04)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showIcon) ...<Widget>[
              Icon(theme.icon, size: 14, color: theme.foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: theme.foreground),
            ),
          ],
        ),
      ),
    );
  }
}
