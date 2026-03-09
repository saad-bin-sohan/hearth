import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';

class HearthListItemEntry extends StatefulWidget {
  const HearthListItemEntry({
    required this.child,
    this.index = 0,
    super.key,
  });

  final Widget child;
  final int index;

  @override
  State<HearthListItemEntry> createState() => _HearthListItemEntryState();
}

class _HearthListItemEntryState extends State<HearthListItemEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.standard,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.easeOut,
    );
    _offset = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.emphasized),
    );

    final cappedDelay = widget.index >= 8 ? 0 : widget.index * 40;
    _timer = Timer(Duration(milliseconds: cappedDelay), _controller.forward);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _offset.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
