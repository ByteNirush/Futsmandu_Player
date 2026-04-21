import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

export 'package:futsmandu_design_system/core/theme/app_typography.dart'
    show AppFontWeights, AppTypography, AppTypographyScale;

/// Re-export of design system typography with app-specific naming.
///
/// This file serves as a thin wrapper around the design system's typography
/// to maintain backward compatibility while using the centralized design system.
///
/// Prefer using AppTypography directly from the design system for new code.
class AppTextStyles {
  AppTextStyles._();

  // Re-export font weights from design system
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = AppFontWeights.regular;
  static const FontWeight normal = regular;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = AppFontWeights.semiBold;
  static const FontWeight bold = AppFontWeights.bold;
  static const FontWeight extraBold = AppFontWeights.extraBold;

  // Headings - delegate to design system
  static TextStyle h1(BuildContext context, ColorScheme scheme) =>
      AppTypography.heading(context, scheme);

  static TextStyle h2(BuildContext context, ColorScheme scheme) =>
      AppTypography.subHeading(context, scheme);

  static TextStyle h3(BuildContext context, ColorScheme scheme) =>
      AppTypography.subHeading(context, scheme)
          .copyWith(fontSize: 20 * AppTypographyScale.fromContext(context));

  // Titles - use Material 3 text theme from design system
  static TextStyle titleMd(BuildContext context, ColorScheme scheme) =>
      AppTypography.textTheme(scheme).titleMedium!;

  static TextStyle titleSm(BuildContext context, ColorScheme scheme) =>
      AppTypography.textTheme(scheme).titleSmall!;

  // Body - delegate to design system
  static TextStyle body(BuildContext context, ColorScheme scheme) =>
      AppTypography.body(context, scheme);

  static TextStyle bodySm(BuildContext context, ColorScheme scheme) =>
      AppTypography.body(context, scheme)
          .copyWith(fontSize: 14 * AppTypographyScale.fromContext(context));

  static TextStyle bodyXs(BuildContext context, ColorScheme scheme) =>
      AppTypography.caption(context, scheme);

  // Labels / utility
  static TextStyle label(BuildContext context, ColorScheme scheme) =>
      AppTypography.textTheme(scheme).labelMedium!;

  static TextStyle labelSm(BuildContext context, ColorScheme scheme) =>
      AppTypography.caption(context, scheme);

  static TextStyle labelXs(BuildContext context, ColorScheme scheme) =>
      AppTypography.textTheme(scheme).labelSmall!;

  static TextStyle button(BuildContext context, ColorScheme scheme) =>
      AppTypography.button(context, scheme);

  static TextStyle buttonSm(BuildContext context, ColorScheme scheme) =>
      AppTypography.button(context, scheme)
          .copyWith(fontSize: 13 * AppTypographyScale.fromContext(context));

  static TextStyle caption(BuildContext context, ColorScheme scheme) =>
      AppTypography.caption(context, scheme);

  static TextTheme textTheme(ColorScheme scheme) {
    return AppTypography.textTheme(scheme);
  }
}

class AppText {
  AppText._();

  // These getters are deprecated and will be removed.
  // Use AppTypography methods with BuildContext instead.

  static TextStyle get h1 => _deprecatedStyle(34, FontWeight.w800);

  static TextStyle get h2 => _deprecatedStyle(22, FontWeight.w700);

  static TextStyle get h3 => _deprecatedStyle(20, FontWeight.w700);

  static TextStyle get body => _deprecatedStyle(15, FontWeight.w400);

  static TextStyle get bodySm => _deprecatedStyle(14, FontWeight.w400);

  static TextStyle get label => _deprecatedStyle(13, FontWeight.w600);

  static TextStyle get button => _deprecatedStyle(15, FontWeight.w600);

  static TextStyle get caption => _deprecatedStyle(12, FontWeight.w400);

  static TextStyle get mono => _deprecatedStyle(15, FontWeight.w500);

  static TextStyle _deprecatedStyle(double fontSize, FontWeight weight) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      fontWeight: weight,
    );
  }
}
