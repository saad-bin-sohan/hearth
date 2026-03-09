import 'package:flutter/animation.dart';

class AppAnimations {
  const AppAnimations._();

  static const SpringDescription springStandard = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 28,
  );

  static const SpringDescription springSnappy = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 35,
  );

  static const SpringDescription springGentle = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 22,
  );

  static const SpringDescription springBouncy = SpringDescription(
    mass: 1,
    stiffness: 400,
    damping: 18,
  );

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration verySlow = Duration(milliseconds: 650);

  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeInOutQuart;
}
