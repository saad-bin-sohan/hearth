import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';

class HearthTransitionsBuilder extends PageTransitionsBuilder {
  const HearthTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return HearthTransitionChild(animation: animation, child: child);
  }
}

class HearthTransitionChild extends StatelessWidget {
  const HearthTransitionChild({
    required this.animation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppAnimations.emphasized,
      reverseCurve: AppAnimations.easeInOut,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (BuildContext context, Widget? _) {
        final opacity = curved.value.clamp(0.0, 1.0);
        final y = (1 - curved.value) * 40;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(0, y), child: child),
        );
      },
    );
  }
}
