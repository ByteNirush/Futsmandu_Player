import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

/// Admin-only pending join-request list with approve/reject actions.
class PendingRequestsSection extends StatelessWidget {
  final List<Map<String, dynamic>> pendingMembers;
  final bool isSubmitting;
  final void Function(String userId) onApprove;
  final void Function(String userId) onReject;

  const PendingRequestsSection({
    super.key,
    required this.pendingMembers,
    required this.isSubmitting,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingMembers.isEmpty) return const SizedBox.shrink();

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
                color: scheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.pending_actions_rounded,
                  size: 18, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.xxl),
            Text('Pending Requests',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: AppFontWeights.bold)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('${pendingMembers.length}',
                  style: tt.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: AppFontWeights.bold,
                  )),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...pendingMembers.map((member) {
          final name = member['name']?.toString() ?? '-';
          final avatarUrl = member['avatarUrl']?.toString() ?? '';
          final position = member['position']?.toString() ?? '';
          final userId = member['id']?.toString() ?? '';
          final initials =
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: scheme.surfaceContainerHighest,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? Text(initials, style: tt.titleSmall)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.xxl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: tt.bodyMedium?.copyWith(
                                fontWeight: AppFontWeights.semiBold)),
                        if (position.isNotEmpty)
                          Text(position, style: tt.bodySmall),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: isSubmitting
                        ? null
                        : () => onApprove(userId),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text('Approve',
                        style: tt.labelSmall?.copyWith(
                            fontWeight: AppFontWeights.bold)),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  OutlinedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => onReject(userId),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      side: BorderSide(color: AppColors.red.withOpacity(0.5)),
                    ),
                    child: Text('Reject',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.red,
                          fontWeight: AppFontWeights.bold,
                        )),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
