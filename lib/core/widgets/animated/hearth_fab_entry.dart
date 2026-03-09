import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';

class HearthFABEntry extends StatefulWidget {
  const HearthFABEntry({required this.child, super.key});

  final Widget child;

  @override
  State<HearthFABEntry> createState() => _HearthFABEntryState();
}

class _HearthFABEntryState extends State<HearthFABEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    );
    _timer = Timer(const Duration(milliseconds: 200), _controller.forward);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
      child: FadeTransition(opacity: _controller, child: widget.child),
    );
  }
}
