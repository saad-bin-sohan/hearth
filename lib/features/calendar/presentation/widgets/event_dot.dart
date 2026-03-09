import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/features/calendar/domain/entities/calendar_event.dart';

class EventDot extends StatefulWidget {
  const EventDot({required this.source, this.size = 6, super.key});

  final CalendarEventSource source;
  final double size;

  @override
  State<EventDot> createState() => _EventDotState();
}

class _EventDotState extends State<EventDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CalendarEvent.colorForSource(widget.source),
        ),
      ),
    );
  }
}
