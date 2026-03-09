import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class AppRadius {
  const AppRadius._();

  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusFull = 999;
}

class AppElevation {
  const AppElevation._();

  static const List<BoxShadow> elevationLow = <BoxShadow>[
    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevationMedium = <BoxShadow>[
    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> elevationHigh = <BoxShadow>[
    BoxShadow(color: AppColors.shadow, blurRadius: 32, offset: Offset(0, 8)),
    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
  ];
}
