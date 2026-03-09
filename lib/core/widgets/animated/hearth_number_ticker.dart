import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';

class HearthNumberTicker extends StatelessWidget {
  const HearthNumberTicker({
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    super.key,
  });

  final String value;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppAnimations.medium,
      reverseDuration: AppAnimations.medium,
      switchInCurve: AppAnimations.easeInOut,
      switchOutCurve: AppAnimations.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final incoming = Tween<Offset>(
          begin: const Offset(0, 0.45),
          end: Offset.zero,
        ).animate(animation);
        final outgoing = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.45),
        ).animate(animation);

        return ClipRect(
          child: SlideTransition(
            position: child.key == ValueKey<String>('ticker-$value')
                ? incoming
                : outgoing,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Text(
        '$prefix$value$suffix',
        key: ValueKey<String>('ticker-$value'),
        style: style ?? Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
