import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Poppins supports 100-900 and is loaded via google_fonts across platforms.
  // Font Weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = AppFontWeights.regular;
  static const FontWeight normal = regular;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = AppFontWeights.semiBold;
  static const FontWeight bold = AppFontWeights.bold;
  static const FontWeight extraBold = AppFontWeights.extraBold;

  static TextStyle poppinsTextTheme({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Headings
  static TextStyle h1(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 28,
        fontWeight: bold,
        color: scheme.onSurface,
      ).copyWith(height: 1.2, letterSpacing: -0.2);

  static TextStyle h2(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 24,
        fontWeight: semiBold,
        color: scheme.onSurface,
      ).copyWith(height: 1.25, letterSpacing: -0.1);

  static TextStyle h3(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 20,
        fontWeight: semiBold,
        color: scheme.onSurface,
      ).copyWith(height: 1.3);

  // Titles
  static TextStyle titleMd(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 16,
        fontWeight: semiBold,
        color: scheme.onSurface,
    ).copyWith(height: 1.35);

  static TextStyle titleSm(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 14,
        fontWeight: medium,
        color: scheme.onSurface,
    ).copyWith(height: 1.35);

  // Body
  static TextStyle body(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 16,
        fontWeight: regular,
        color: scheme.onSurface,
      ).copyWith(height: 1.5);

  static TextStyle bodySm(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 14,
        fontWeight: regular,
        color: scheme.onSurface,
      ).copyWith(height: 1.45);

  static TextStyle bodyXs(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 12,
        fontWeight: regular,
        color: scheme.onSurfaceVariant,
      ).copyWith(height: 1.35);

  // Labels / utility
  static TextStyle label(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 13,
        fontWeight: medium,
        color: scheme.onSurface,
      ).copyWith(height: 1.3, letterSpacing: 0.15);

  static TextStyle labelSm(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 12,
        fontWeight: medium,
        color: scheme.onSurfaceVariant,
    ).copyWith(height: 1.3, letterSpacing: 0.2);

  static TextStyle labelXs(ColorScheme scheme) => poppinsTextTheme(
        fontSize: 11,
        fontWeight: medium,
        color: scheme.onSurfaceVariant,
    ).copyWith(height: 1.25, letterSpacing: 0.2);

    static TextStyle button(ColorScheme scheme) => poppinsTextTheme(
      fontSize: 15,
      fontWeight: semiBold,
      color: scheme.onPrimary,
    ).copyWith(height: 1.2, letterSpacing: 0.25);

    static TextStyle buttonSm(ColorScheme scheme) => poppinsTextTheme(
      fontSize: 13,
      fontWeight: semiBold,
      color: scheme.onPrimary,
    ).copyWith(height: 1.2, letterSpacing: 0.2);

    static TextStyle caption(ColorScheme scheme) => poppinsTextTheme(
      fontSize: 11,
      fontWeight: regular,
      color: scheme.onSurfaceVariant,
    ).copyWith(height: 1.3);

  static TextTheme textTheme(ColorScheme scheme) {
    return AppTypography.textTheme(scheme);
  }
}

/// Centralized text styles used across the UI.
///
/// This is intentionally context-free (no `BuildContext`), so callers can use
/// `AppText.h1`, `AppText.bodySm`, etc. The colors are derived from
/// `AppColors`, which already tracks the current theme mode.
class AppText {
  // Headings
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: AppTextStyles.extraBold,
        color: AppColors.txtPrimary,
      ).copyWith(height: 1.18, letterSpacing: -0.2);

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: AppTextStyles.bold,
        color: AppColors.txtPrimary,
      ).copyWith(height: 1.24, letterSpacing: -0.1);

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: AppTextStyles.bold,
        color: AppColors.txtPrimary,
      ).copyWith(height: 1.28);

  // Body
  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: AppTextStyles.regular,
        color: AppColors.txtPrimary,
      ).copyWith(height: 1.45);

  static TextStyle get bodySm => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: AppTextStyles.regular,
        color: AppColors.txtPrimary,
      ).copyWith(height: 1.42);

  // Labels / metadata
  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: AppTextStyles.semiBold,
        color: AppColors.txtDisabled,
      ).copyWith(height: 1.26, letterSpacing: 0.15);

  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: AppTextStyles.semiBold,
        color: AppColors.txtPrimary,
      ).copyWith(height: 1.2, letterSpacing: 0.25);

  static TextStyle get caption => GoogleFonts.poppins(
      fontSize: 12,
        fontWeight: AppTextStyles.regular,
        color: AppColors.txtDisabled,
      ).copyWith(height: 1.3);

  static TextStyle get mono => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: AppTextStyles.medium,
        color: AppColors.txtPrimary,
      );
}
