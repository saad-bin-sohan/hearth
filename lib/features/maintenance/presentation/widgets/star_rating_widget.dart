import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hugeicons/hugeicons.dart';

class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({
    required this.rating,
    this.size = 24,
    this.interactive = false,
    this.onRatingChanged,
    super.key,
  });

  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final filledStars = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (int index) {
        final filled = index < filledStars;
        final icon = Icon(
          HugeIcons.strokeRoundedStar,
          size: size,
          color: filled
              ? AppColors.accentFor(brightness)
              : AppColors.textTertiaryFor(brightness),
        );
        if (!interactive) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: icon,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: _InteractiveStar(
            index: index,
            size: size,
            filled: filled,
            onTap: () {
              HapticFeedback.lightImpact();
              onRatingChanged?.call((index + 1).toDouble());
            },
          ),
        );
      }),
    );
  }
}

class _InteractiveStar extends StatefulWidget {
  const _InteractiveStar({
    required this.index,
    required this.size,
    required this.filled,
    required this.onTap,
  });

  final int index;
  final double size;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<_InteractiveStar> createState() => _InteractiveStarState();
}

class _InteractiveStarState extends State<_InteractiveStar> {
  double _scale = 1;

  Future<void> _handleTap() async {
    widget.onTap();
    setState(() {
      _scale = 1.2;
    });
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    setState(() {
      _scale = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        duration: AppAnimations.fast,
        curve: AppAnimations.easeInOut,
        scale: _scale,
        child: Icon(
          HugeIcons.strokeRoundedStar,
          size: widget.size,
          color: widget.filled
              ? AppColors.accentFor(brightness)
              : AppColors.textTertiaryFor(brightness),
        ),
      ),
    );
  }
}
