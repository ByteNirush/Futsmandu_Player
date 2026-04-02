import 'package:flutter/material.dart';

import 'theme_provider.dart';

/// Centralized brand + semantic colors.
abstract class AppColors {
  static const Color seed = Color(0xFF0B8F3A);

  // Shared brand tones
  static const Color primary = seed;
  static const Color success = Color(0xFF118347);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE5484D);

  // Semantic/brand extras used across the app.
  static const Color info = Color(0xFF0F766E);
  static const Color ratingStar = Color(0xFFFFB300);
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
      ? AppColorSchemes.dark
      : AppColorSchemes.light;

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
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0B8F3A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD4F6DF),
    onPrimaryContainer: Color(0xFF00210D),
    secondary: Color(0xFF1E6A3B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFA8F2BF),
    onSecondaryContainer: Color(0xFF00210E),
    tertiary: Color(0xFF0F766E),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB6F2EC),
    onTertiaryContainer: Color(0xFF001F1C),
    error: Color(0xFFE5484D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD7),
    onErrorContainer: Color(0xFF410006),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF111827),
    surfaceContainerHighest: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFE5E7EB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFF5FDC8C),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5FDC8C),
    onPrimary: Color(0xFF00391A),
    primaryContainer: Color(0xFF005127),
    onPrimaryContainer: Color(0xFF7BFAA6),
    secondary: Color(0xFF8FD6A8),
    onSecondary: Color(0xFF00391B),
    secondaryContainer: Color(0xFF17522F),
    onSecondaryContainer: Color(0xFFA8F2BF),
    tertiary: Color(0xFF83D5CD),
    onTertiary: Color(0xFF003733),
    tertiaryContainer: Color(0xFF00504B),
    onTertiaryContainer: Color(0xFF9EEFE8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690009),
    errorContainer: Color(0xFF93000F),
    onErrorContainer: Color(0xFFFFDAD7),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFF4F4F5),
    surfaceContainerHighest: Color(0xFF262626),
    onSurfaceVariant: Color(0xFFA1A1AA),
    outline: Color(0xFF3F3F46),
    outlineVariant: Color(0xFF27272A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE5E7EB),
    onInverseSurface: Color(0xFF18181B),
    inversePrimary: Color(0xFF0B8F3A),
  );
}
