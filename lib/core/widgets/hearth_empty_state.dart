import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/hearth_button.dart';

class HearthEmptyState extends StatefulWidget {
  const HearthEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCtaPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  @override
  State<HearthEmptyState> createState() => _HearthEmptyStateState();
}

class _HearthEmptyStateState extends State<HearthEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.verySlow,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.05).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: AppAnimations.easeInOut,
                ),
              ),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainerFor(brightness),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: AppColors.primaryFor(brightness),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
            if (widget.ctaLabel != null &&
                widget.onCtaPressed != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              HearthButton(
                label: widget.ctaLabel!,
                onPressed: widget.onCtaPressed,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
