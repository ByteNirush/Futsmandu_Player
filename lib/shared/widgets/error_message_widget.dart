import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_radius.dart';

import '../../core/design_system/app_spacing.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onDismiss;
  final bool isDismissible;

  const ErrorMessageWidget({
    super.key,
    required this.message,
    this.backgroundColor,
    this.foregroundColor,
    this.onDismiss,
    this.isDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.errorContainer;
    final fgColor = foregroundColor ?? theme.colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: fgColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: fgColor),
            ),
          ),
          if (isDismissible)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: fgColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
