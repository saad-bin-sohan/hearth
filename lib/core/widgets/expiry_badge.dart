import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hugeicons/hugeicons.dart';

enum ExpiryBadgeUrgency { none, safe, warning, critical, expired }

enum ExpiryBadgeSize { compact, standard, large }

class ExpiryBadge extends StatefulWidget {
  const ExpiryBadge({
    required this.urgency,
    this.daysUntil,
    this.date,
    this.size = ExpiryBadgeSize.standard,
    this.pulse = false,
    super.key,
  });

  final ExpiryBadgeUrgency urgency;
  final int? daysUntil;
  final DateTime? date;
  final ExpiryBadgeSize size;
  final bool pulse;

  @override
  State<ExpiryBadge> createState() => _ExpiryBadgeState();
}

class _ExpiryBadgeState extends State<ExpiryBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _shouldPulse =>
      widget.pulse && widget.urgency == ExpiryBadgeUrgency.critical;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.verySlow,
    );
    if (_shouldPulse) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ExpiryBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
      return;
    }
    if (!_shouldPulse && _controller.isAnimating) {
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
    if (widget.urgency == ExpiryBadgeUrgency.none) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final showIcon = widget.size != ExpiryBadgeSize.compact;
    final height = switch (widget.size) {
      ExpiryBadgeSize.compact => AppSpacing.lg - AppSpacing.xs,
      ExpiryBadgeSize.standard => AppSpacing.lg,
      ExpiryBadgeSize.large => AppSpacing.xl - AppSpacing.xs,
    };
    final theme = switch (widget.urgency) {
      ExpiryBadgeUrgency.safe => (
        background: AppColors.successContainer,
        foreground: AppColors.successFor(brightness),
        icon: HugeIcons.strokeRoundedCalendar01,
      ),
      ExpiryBadgeUrgency.warning => (
        background: AppColors.warningContainerFor(brightness),
        foreground: AppColors.warningFor(brightness),
        icon: HugeIcons.strokeRoundedCalendar01,
      ),
      ExpiryBadgeUrgency.critical => (
        background: AppColors.errorContainer,
        foreground: AppColors.errorFor(brightness),
        icon: HugeIcons.strokeRoundedCalendar01,
      ),
      ExpiryBadgeUrgency.expired => (
        background: AppColors.errorContainer,
        foreground: AppColors.errorFor(brightness),
        icon: HugeIcons.strokeRoundedCalendarBlock01,
      ),
      ExpiryBadgeUrgency.none => (
        background: AppColors.surfaceVariantFor(brightness),
        foreground: AppColors.textTertiaryFor(brightness),
        icon: HugeIcons.strokeRoundedCalendar01,
      ),
    };
    final label = _buildLabel();

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final scale = _shouldPulse ? 1 + (_controller.value * 0.05) : 1.0;
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

  String _buildLabel() {
    if (widget.urgency == ExpiryBadgeUrgency.expired) {
      if (widget.size == ExpiryBadgeSize.large && widget.date != null) {
        return 'Expired • ${AppFormatters.shortDate(widget.date!)}';
      }
      return 'Expired';
    }
    final daysText =
        '${widget.daysUntil ?? 0} day${widget.daysUntil == 1 ? '' : 's'}';
    if (widget.size == ExpiryBadgeSize.large && widget.date != null) {
      return '$daysText • ${AppFormatters.shortDate(widget.date!)}';
    }
    return daysText;
  }
}
