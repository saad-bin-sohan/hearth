import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}

extension StringX on String {
  String get initials {
    final parts = trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) {
      return '?';
    }

    return parts
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
  }

  String get titleCase {
    final tokens = trim().split(RegExp(r'[_\-\s]+'));
    return tokens
        .where((token) => token.isNotEmpty)
        .map(
          (token) =>
              '${token[0].toUpperCase()}${token.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

extension BrightnessX on Brightness {
  Color get textPrimary =>
      this == Brightness.dark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimary;

  Color get textSecondary =>
      this == Brightness.dark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondary;
}

extension EdgeInsetsX on num {
  EdgeInsets get all => EdgeInsets.all(toDouble());
  EdgeInsets get horizontal =>
      EdgeInsets.symmetric(horizontal: toDouble());
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: toDouble());
}

EdgeInsets get screenPadding => const EdgeInsets.symmetric(
  horizontal: AppSpacing.md,
  vertical: AppSpacing.md,
);
