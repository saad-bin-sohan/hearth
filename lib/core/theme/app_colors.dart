import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2EDE6);
  static const Color primary = Color(0xFFC8603A);
  static const Color primaryLight = Color(0xFFE8846A);
  static const Color primaryContainer = Color(0xFFF5D5C8);
  static const Color secondary = Color(0xFF6B7B3A);
  static const Color secondaryLight = Color(0xFF8A9E52);
  static const Color secondaryContainer = Color(0xFFD6E0B5);
  static const Color accent = Color(0xFFE8A83E);
  static const Color accentContainer = Color(0xFFF8E4B0);
  static const Color textPrimary = Color(0xFF1C1410);
  static const Color textSecondary = Color(0xFF6B5E54);
  static const Color textTertiary = Color(0xFF9E8E7E);
  static const Color divider = Color(0xFFE8E0D8);
  static const Color error = Color(0xFFD95F52);
  static const Color errorContainer = Color(0xFFFAD5D2);
  static const Color success = Color(0xFF5A8A5E);
  static const Color successContainer = Color(0xFFD0EAD2);
  static const Color warning = Color(0xFFE8A83E);
  static const Color warningContainer = Color(0xFFF8E4B0);
  static const Color shadow = Color(0x1A6B5E54);
  static const Color overlay = Color(0x801C1410);

  static const Color backgroundDark = Color(0xFF1C1410);
  static const Color surfaceDark = Color(0xFF2A1F18);
  static const Color surfaceVariantDark = Color(0xFF3A2D24);
  static const Color primaryDark = Color(0xFFE8846A);
  static const Color primaryLightDark = Color(0xFFC8603A);
  static const Color primaryContainerDark = Color(0xFF5C2A1A);
  static const Color secondaryDark = Color(0xFF8A9E52);
  static const Color secondaryContainerDark = Color(0xFF2E3A18);
  static const Color accentDark = Color(0xFFE8A83E);
  static const Color accentContainerDark = Color(0xFF4A3610);
  static const Color textPrimaryDark = Color(0xFFFAF7F2);
  static const Color textSecondaryDark = Color(0xFFBCAFA6);
  static const Color textTertiaryDark = Color(0xFF8A7A72);
  static const Color dividerDark = Color(0xFF3A2D24);
  static const Color errorDark = Color(0xFFFF8A80);
  static const Color successDark = Color(0xFF80C784);
  static const Color shadowDark = Color(0x33000000);

  static Color backgroundFor(Brightness brightness) {
    return brightness == Brightness.dark ? backgroundDark : background;
  }

  static Color surfaceFor(Brightness brightness) {
    return brightness == Brightness.dark ? surfaceDark : surface;
  }

  static Color surfaceVariantFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? surfaceVariantDark
        : surfaceVariant;
  }

  static Color primaryFor(Brightness brightness) {
    return brightness == Brightness.dark ? primaryDark : primary;
  }

  static Color primaryContainerFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? primaryContainerDark
        : primaryContainer;
  }

  static Color secondaryFor(Brightness brightness) {
    return brightness == Brightness.dark ? secondaryDark : secondary;
  }

  static Color secondaryContainerFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? secondaryContainerDark
        : secondaryContainer;
  }

  static Color accentFor(Brightness brightness) {
    return brightness == Brightness.dark ? accentDark : accent;
  }

  static Color accentContainerFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? accentContainerDark
        : accentContainer;
  }

  static Color textPrimaryFor(Brightness brightness) {
    return brightness == Brightness.dark ? textPrimaryDark : textPrimary;
  }

  static Color textSecondaryFor(Brightness brightness) {
    return brightness == Brightness.dark ? textSecondaryDark : textSecondary;
  }

  static Color textTertiaryFor(Brightness brightness) {
    return brightness == Brightness.dark ? textTertiaryDark : textTertiary;
  }

  static Color dividerFor(Brightness brightness) {
    return brightness == Brightness.dark ? dividerDark : divider;
  }

  static Color successFor(Brightness brightness) {
    return brightness == Brightness.dark ? successDark : success;
  }

  static Color errorFor(Brightness brightness) {
    return brightness == Brightness.dark ? errorDark : error;
  }

  static Color shadowFor(Brightness brightness) {
    return brightness == Brightness.dark ? shadowDark : shadow;
  }
}
