import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_page_transition.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primaryFor(brightness),
      onPrimary: AppColors.surface,
      secondary: AppColors.secondaryFor(brightness),
      onSecondary: AppColors.surface,
      error: AppColors.errorFor(brightness),
      onError: AppColors.surface,
      surface: AppColors.surfaceFor(brightness),
      onSurface: AppColors.textPrimaryFor(brightness),
      surfaceContainerHighest: AppColors.surfaceVariantFor(brightness),
      onSurfaceVariant: AppColors.textSecondaryFor(brightness),
      outline: AppColors.dividerFor(brightness),
      primaryContainer: AppColors.primaryContainerFor(brightness),
      onPrimaryContainer: AppColors.primaryFor(brightness),
      secondaryContainer: AppColors.secondaryContainerFor(brightness),
      onSecondaryContainer: AppColors.secondaryFor(brightness),
      tertiary: AppColors.accentFor(brightness),
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.accentContainerFor(brightness),
      onTertiaryContainer: AppColors.accentFor(brightness),
      shadow: AppColors.shadowFor(brightness),
      scrim: AppColors.overlay,
      inverseSurface: isDark ? AppColors.background : AppColors.surfaceDark,
      onInverseSurface: isDark ? AppColors.textPrimary : AppColors.textPrimaryDark,
      inversePrimary: isDark ? AppColors.primary : AppColors.primaryDark,
    );

    final baseTextTheme = TextTheme(
      displayLarge: AppTextStyles.display.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      titleLarge: AppTextStyles.titleLarge.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      titleMedium: AppTextStyles.titleMedium.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondaryFor(brightness),
      ),
      labelLarge: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textPrimaryFor(brightness),
      ),
      labelMedium: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondaryFor(brightness),
      ),
      labelSmall: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textTertiaryFor(brightness),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundFor(brightness),
      textTheme: baseTextTheme,
      fontFamily: AppTextStyles.bodyMedium.fontFamily,
      dividerColor: AppColors.dividerFor(brightness),
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        color: AppColors.surfaceFor(brightness),
        elevation: 0,
        shadowColor: AppColors.shadowFor(brightness),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundFor(brightness),
        foregroundColor: AppColors.textPrimaryFor(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimaryFor(brightness),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceFor(brightness),
        selectedItemColor: AppColors.primaryFor(brightness),
        unselectedItemColor: AppColors.textTertiaryFor(brightness),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryFor(brightness),
        foregroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantFor(brightness),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiaryFor(brightness),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondaryFor(brightness),
        ),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primaryFor(brightness),
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.errorFor(brightness),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          borderSide: BorderSide(color: AppColors.dividerFor(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          borderSide: const BorderSide(color: AppColors.primaryLight),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          borderSide: BorderSide(color: AppColors.errorFor(brightness)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          borderSide: BorderSide(color: AppColors.errorFor(brightness)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(
            AppColors.primaryFor(brightness),
          ),
          foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.surface),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            AppTextStyles.labelLarge.copyWith(color: AppColors.surface),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            ),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(
            AppColors.textPrimaryFor(brightness),
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: AppColors.dividerFor(brightness)),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(
            AppColors.primaryFor(brightness),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            AppTextStyles.labelLarge.copyWith(
              color: AppColors.primaryFor(brightness),
            ),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: HearthTransitionsBuilder(),
          TargetPlatform.iOS: HearthTransitionsBuilder(),
        },
      ),
    );
  }
}
