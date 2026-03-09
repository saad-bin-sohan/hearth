import 'package:flutter/material.dart';
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
    super.key,
  });

  final Widget child;
  final HearthSwipeAction? leadingAction;
  final HearthSwipeAction? trailingAction;

  @override
  State<HearthSwipeToAction> createState() => _HearthSwipeToActionState();
}

class _HearthSwipeToActionState extends State<HearthSwipeToAction> {
  static const double _maxReveal = 96;
  double _drag = 0;

  void _handleEnd(double width) {
    final revealThreshold = width * 0.8;
    if (_drag >= revealThreshold && widget.leadingAction != null) {
      HapticFeedback.heavyImpact();
      widget.leadingAction!.onTriggered();
    } else if (_drag <= -revealThreshold && widget.trailingAction != null) {
      HapticFeedback.heavyImpact();
      widget.trailingAction!.onTriggered();
    }

    setState(() {
      if (_drag > 0 && widget.leadingAction != null) {
        _drag = _drag.abs() > _maxReveal / 2 ? _maxReveal : 0;
      } else if (_drag < 0 && widget.trailingAction != null) {
        _drag = _drag.abs() > _maxReveal / 2 ? -_maxReveal : 0;
      } else {
        _drag = 0;
      }
    });
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
              if (_drag > 0 && widget.leadingAction == null) {
                _drag = 0;
              }
              if (_drag < 0 && widget.trailingAction == null) {
                _drag = 0;
              }
              _drag = _drag.clamp(-constraints.maxWidth, constraints.maxWidth);
            });
          },
          onHorizontalDragEnd: (_) => _handleEnd(constraints.maxWidth),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Row(
                  children: <Widget>[
                    if (widget.leadingAction != null)
                      _ActionPane(
                        alignment: Alignment.centerLeft,
                        action: widget.leadingAction!,
                        visible: _drag > 0,
                        bounce: _drag >= _maxReveal,
                      )
                    else
                      const Spacer(),
                    if (widget.trailingAction != null)
                      _ActionPane(
                        alignment: Alignment.centerRight,
                        action: widget.trailingAction!,
                        visible: _drag < 0,
                        bounce: _drag <= -_maxReveal,
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
    required this.visible,
    required this.bounce,
  });

  final Alignment alignment;
  final HearthSwipeAction action;
  final bool visible;
  final bool bounce;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedOpacity(
        duration: AppAnimations.fast,
        opacity: visible ? 1 : 0,
        child: Container(
          alignment: alignment,
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AnimatedScale(
            duration: AppAnimations.fast,
            scale: bounce ? 1.08 : 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(action.icon, color: action.color),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimaryFor(Theme.of(context).brightness),
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
