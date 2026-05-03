import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_radius.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme(
          Theme.of(context).colorScheme,
        ).labelSmall?.copyWith(
          color: color,
          fontWeight: AppFontWeights.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
