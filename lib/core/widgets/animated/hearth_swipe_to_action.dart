import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';

class HearthSwipeAction {
  const HearthSwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTriggered,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTriggered;
}

class HearthSwipeToAction extends StatefulWidget {
  const HearthSwipeToAction({
    required this.child,
    this.leadingAction,
    this.trailingAction,
    this.leftAction,
    this.rightAction,
    this.onLeftTriggered,
    this.onRightTriggered,
    super.key,
  });

  final Widget child;
  final HearthSwipeAction? leadingAction;
  final HearthSwipeAction? trailingAction;
  final Widget? leftAction;
  final Widget? rightAction;
  final VoidCallback? onLeftTriggered;
  final VoidCallback? onRightTriggered;

  @override
  State<HearthSwipeToAction> createState() => _HearthSwipeToActionState();
}

class _HearthSwipeToActionState extends State<HearthSwipeToAction>
    with TickerProviderStateMixin {
  static const double _maxReveal = 96;
  double _drag = 0;
  late final AnimationController _settleController;
  late final AnimationController _bounceController;

  HearthSwipeAction? get _leadingAction => widget.leadingAction;
  HearthSwipeAction? get _trailingAction => widget.trailingAction;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _drag = _settleController.value;
        });
      });
    _bounceController = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _settleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleEnd(double width) {
    final revealThreshold = width * 0.8;
    if (_drag >= revealThreshold &&
        (_leadingAction != null || widget.onLeftTriggered != null)) {
      HapticFeedback.heavyImpact();
      (_leadingAction?.onTriggered ?? widget.onLeftTriggered)?.call();
      _animateTo(0);
      return;
    } else if (_drag <= -revealThreshold &&
        (_trailingAction != null || widget.onRightTriggered != null)) {
      HapticFeedback.heavyImpact();
      (_trailingAction?.onTriggered ?? widget.onRightTriggered)?.call();
      _animateTo(0);
      return;
    }

    if (_drag > 0 && (_leadingAction != null || widget.leftAction != null)) {
      _animateTo(_drag.abs() > _maxReveal / 2 ? _maxReveal : 0);
      return;
    }
    if (_drag < 0 && (_trailingAction != null || widget.rightAction != null)) {
      _animateTo(_drag.abs() > _maxReveal / 2 ? -_maxReveal : 0);
      return;
    }
    _animateTo(0);
  }

  void _animateTo(double target) {
    _settleController.animateWith(
      SpringSimulation(AppAnimations.springStandard, _drag, target, 0),
    );
    if (target.abs() >= _maxReveal) {
      _bounceController.animateWith(
        SpringSimulation(
          AppAnimations.springBouncy,
          _bounceController.value,
          1,
          0,
        ),
      );
    } else {
      _bounceController.animateBack(
        0,
        duration: AppAnimations.fast,
        curve: AppAnimations.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            setState(() {
              _drag += details.delta.dx;
              if (_drag > 0 &&
                  _leadingAction == null &&
                  widget.leftAction == null) {
                _drag = 0;
              }
              if (_drag < 0 &&
                  _trailingAction == null &&
                  widget.rightAction == null) {
                _drag = 0;
              }
              _drag = _drag.clamp(-constraints.maxWidth, constraints.maxWidth);
              if (_drag.abs() >= _maxReveal) {
                _bounceController.forward();
              } else {
                _bounceController.reverse();
              }
            });
          },
          onHorizontalDragEnd: (_) => _handleEnd(constraints.maxWidth),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Row(
                  children: <Widget>[
                    if (_leadingAction != null || widget.leftAction != null)
                      _ActionPane(
                        alignment: Alignment.centerLeft,
                        action: _leadingAction,
                        customChild: widget.leftAction,
                        visible: _drag > 0,
                        bounce: _drag >= _maxReveal,
                        bounceAnimation: _bounceController,
                      )
                    else
                      const Spacer(),
                    if (_trailingAction != null || widget.rightAction != null)
                      _ActionPane(
                        alignment: Alignment.centerRight,
                        action: _trailingAction,
                        customChild: widget.rightAction,
                        visible: _drag < 0,
                        bounce: _drag <= -_maxReveal,
                        bounceAnimation: _bounceController,
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: AppAnimations.standard,
                curve: AppAnimations.easeInOut,
                transform: Matrix4.translationValues(_drag, 0, 0),
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionPane extends StatelessWidget {
  const _ActionPane({
    required this.alignment,
    required this.action,
    required this.customChild,
    required this.visible,
    required this.bounce,
    required this.bounceAnimation,
  });

  final Alignment alignment;
  final HearthSwipeAction? action;
  final Widget? customChild;
  final bool visible;
  final bool bounce;
  final Animation<double> bounceAnimation;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = action?.color ?? AppColors.surfaceVariantFor(brightness);
    return Expanded(
      child: AnimatedOpacity(
        duration: AppAnimations.fast,
        opacity: visible ? 1 : 0,
        child: Container(
          alignment: alignment,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AnimatedBuilder(
            animation: bounceAnimation,
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(
                scale: bounce ? 1 + (bounceAnimation.value * 0.08) : 1,
                child: child,
              );
            },
            child:
                customChild ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(action?.icon, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      action?.label ?? '',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
