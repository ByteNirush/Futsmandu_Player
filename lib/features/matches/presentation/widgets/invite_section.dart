import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

class InviteSection extends StatelessWidget {
  final bool isAdmin;
  final bool isSubmitting;
  final bool hasExistingInvite;
  final VoidCallback? onCopyInviteLink;

  const InviteSection({
    super.key,
    required this.isAdmin,
    required this.isSubmitting,
    required this.hasExistingInvite,
    this.onCopyInviteLink,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.link_rounded, size: 18, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Invite Friends',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppFontWeights.bold,
                )),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.15),
                        scheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.share_rounded, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share invite link',
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: AppFontWeights.semiBold)),
                      const SizedBox(height: 2),
                      Text(
                        hasExistingInvite
                            ? 'Invite link is active'
                            : 'Create a link to share',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.textSecondary(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilledButton.tonal(
                  onPressed:
                      isAdmin && !isSubmitting ? onCopyInviteLink : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(hasExistingInvite ? 'Copy' : 'Generate',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppFontWeights.bold,
                        letterSpacing: 0.3,
                      )),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
