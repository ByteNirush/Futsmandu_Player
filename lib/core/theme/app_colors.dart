import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart' as ds;

import 'theme_provider.dart';

/// Centralized brand + semantic colors.
abstract class AppColors {
  static const Color seed = ds.AppColors.primary;

  // Shared brand tones
  static const Color primary = ds.AppColors.primary;
  static const Color success = ds.AppColors.success;
  static const Color warning = ds.AppColors.warning;
  static const Color error = ds.AppColors.error;

  // Semantic/brand extras used across the app.
  static const Color info = ds.AppColors.info;
  static const Color ratingStar = ds.AppColors.warning;
  static const Color khalti = Color(0xFF5C2D91);
  static const Color esewa = Color(0xFF60BB46);

  static bool get _isDark {
    final mode = ThemeProvider.instance.themeMode;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  static ColorScheme get _scheme => _isDark
      ? ds.AppColors.darkScheme
      : ds.AppColors.lightScheme;

  // Keep these getters because a lot of UI still uses `AppColors.*` directly.
  static Color get background => _scheme.surface;
  static Color get surface => _scheme.surface;
  static Color get card => _scheme.surface;
  static Color get primaryVariant => _scheme.onPrimaryContainer;
  static Color get textPrimary => _scheme.onSurface;
  static Color get textSecondary => _scheme.onSurfaceVariant;
  static Color get border => _scheme.outline;

  // Legacy aliases for existing widgets
  static Color get green => primary;
  static Color get amber => warning;
  static Color get red => error;
  static Color get blue => info;

  static Color get bgPrimary => background;
  static Color get bgSurface => surface;
  static Color get bgElevated => card;

  static Color get borderClr => _scheme.outlineVariant;

  static Color get txtPrimary => textPrimary;
  static Color get txtDisabled => textSecondary;

  static Color statusColor(String status) => switch (status) {
        'AVAILABLE' => green,
        'HELD' => amber,
        'CONFIRMED' => green,
        'CANCELLED' => red,
        'EXPIRED' => txtDisabled,
        'COMPLETED' => blue,
        'NO_SHOW' => red,
        _ => txtDisabled,
      };

  static Color reliabilityColor(int score) =>
      score >= 70 ? green : score >= 40 ? amber : red;
}

class AppColorSchemes {
  static ColorScheme get light => ds.AppColors.lightScheme;

  static ColorScheme get dark => ds.AppColors.darkScheme;
}
