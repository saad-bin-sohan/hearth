import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';

class HearthCelebration extends StatefulWidget {
  const HearthCelebration({this.onCompleted, super.key});

  final VoidCallback? onCompleted;

  @override
  State<HearthCelebration> createState() => _HearthCelebrationState();
}

class _HearthCelebrationState extends State<HearthCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    final random = Random();
    final colors = <Color>[
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
    ];
    _particles = List<_Particle>.generate(24, (int index) {
      return _Particle(
        dx: (random.nextDouble() - 0.5) * 180,
        dy: -40 - random.nextDouble() * 180,
        radius: 4 + random.nextDouble() * 4,
        color: colors[index % colors.length],
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.verySlow,
    )..forward().whenComplete(() => widget.onCompleted?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _CelebrationPainter(
              particles: _particles,
              progress: _controller.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.color,
  });

  final double dx;
  final double dy;
  final double radius;
  final Color color;
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final particle in particles) {
      final dx = center.dx + particle.dx * progress;
      final dy =
          center.dy + particle.dy * progress + (progress * progress * 80);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1 - progress);
      canvas.drawCircle(Offset(dx, dy), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
