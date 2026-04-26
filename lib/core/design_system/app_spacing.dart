import 'package:futsmandu_design_system/futsmandu_design_system.dart' as ds;

/// Compatibility shim — maps the legacy naming convention used across this app
/// onto the canonical design system values. All new code should import directly
/// from [ds.AppSpacing] (package:futsmandu_design_system).
///
/// Legend: old app name → design system name → value
///   xxs  → ds.AppSpacing.xs          → 4
///   xs   → ds.AppSpacing.sm          → 8
///   xs2  → ds.AppSpacing.md          → 12
///   sm   → ds.AppSpacing.lg          → 16
///   sm2  → ds.AppSpacing.pageHoriz   → 20
///   md   → ds.AppSpacing.xl          → 24
///   lg   → ds.AppSpacing.xxl         → 32
///   xl   → ds.AppSpacing.xxxl        → 40
class AppSpacing {
  AppSpacing._();

  static const double xxs = ds.AppSpacing.xs;          // 4
  static const double xs  = ds.AppSpacing.sm;          // 8
  static const double xs2 = ds.AppSpacing.md;          // 12
  static const double sm  = ds.AppSpacing.lg;          // 16
  static const double sm2 = ds.AppSpacing.pageHorizontal; // 20
  static const double md  = ds.AppSpacing.xl;          // 24
  static const double lg  = ds.AppSpacing.xxl;         // 32
  static const double xl  = ds.AppSpacing.xxxl;        // 40

  static const double cardPadding   = ds.AppSpacing.cardPadding;      // 16
  static const double screenPadding = ds.AppSpacing.pageHorizontal;   // 20
  static const double pagePadding   = ds.AppSpacing.pageHorizontal;   // 20
  static const double buttonHeight  = ds.AppSpacing.buttonHeight;     // 48
  static const double radius        = ds.AppRadius.md;                // 10
}
