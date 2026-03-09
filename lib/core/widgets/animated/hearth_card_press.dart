import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hearth/core/theme/app_animations.dart';

class HearthCardPress extends StatefulWidget {
  const HearthCardPress({
    required this.child,
    this.onTap,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  State<HearthCardPress> createState() => _HearthCardPressState();
}

class _HearthCardPressState extends State<HearthCardPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
      lowerBound: 0.97,
      upperBound: 1,
      value: 1,
    );
  }

  Future<void> _pressTo(double target) async {
    await _controller.animateTo(
      target,
      duration: AppAnimations.fast,
      curve: AppAnimations.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _pressTo(0.97);
      },
      onTapUp: (_) => _pressTo(1),
      onTapCancel: () => _pressTo(1),
      child: ScaleTransition(
        scale: _controller,
        child: ClipRRect(borderRadius: borderRadius, child: widget.child),
      ),
    );
  }
}
