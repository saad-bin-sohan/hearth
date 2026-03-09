import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/extensions.dart';

class HearthAvatar extends StatelessWidget {
  const HearthAvatar({required this.displayName, this.size = 40, super.key});

  final String displayName;
  final double size;

  Color _colorForName(Brightness brightness) {
    final colors = <Color>[
      AppColors.primaryFor(brightness),
      AppColors.secondaryFor(brightness),
      AppColors.accentFor(brightness),
      AppColors.primaryLight,
    ];
    return colors[displayName.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = _colorForName(brightness);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        displayName.initials,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.surface),
      ),
    );
  }
}
