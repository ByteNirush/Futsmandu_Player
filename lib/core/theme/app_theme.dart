import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_theme.dart' as ds;

class AppTheme {
  static const double radiusM = 12.0;

  static ThemeData get light => ds.AppTheme.light();
  static ThemeData get dark => ds.AppTheme.dark();

  static BoxDecoration cardDecorationDark(ColorScheme scheme) {
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        width: 0.9,
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.45),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }
}

extension AppThemeContextX on BuildContext {
  ThemeData get appTheme => Theme.of(this);
}
