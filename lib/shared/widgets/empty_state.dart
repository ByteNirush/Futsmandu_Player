import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/design_system/app_spacing.dart';
import 'futs_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.txtDisabled),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppText.h3.copyWith(color: AppColors.txtDisabled),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppText.bodySm,
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 180,
                child: FutsButton(
                  label: buttonLabel!,
                  onPressed: onButton,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
