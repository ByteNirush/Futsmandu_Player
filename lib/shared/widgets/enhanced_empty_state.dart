import 'package:futsmandu_design_system/components/empty_state/empty_state.dart';

/// Re-export of the design system's EmptyStateWidget and EmptyStateType.
///
/// Use this for enhanced empty states with illustrations.
///
/// Example:
/// ```dart
/// EnhancedEmptyState(
///   type: EmptyStateType.noData,
///   action: TextButton(
///     onPressed: () {},
///     child: Text('Refresh'),
///   ),
/// )
/// ```
///
/// For backward compatibility, the original [EmptyState] widget is still
/// available in `shared/widgets/empty_state.dart`.
export 'package:futsmandu_design_system/components/empty_state/empty_state.dart';

/// Alias for [EmptyStateWidget] for apps that want to use the enhanced version.
typedef EnhancedEmptyState = EmptyStateWidget;
