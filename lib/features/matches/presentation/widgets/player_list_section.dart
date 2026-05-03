import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

/// Unified "Players" section — one player per row, with an Add button for admins.
///
/// Replaces:
/// - `_buildSlotVisualization` (avatar grid)
/// - `_buildConfirmedPlayersList` (duplicate player list)
/// - Scattered player count displays
class PlayerListSection extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final int maxPlayers;
  final int slotsAvailable;
  final bool isAdmin;
  final bool isSubmitting;
  final VoidCallback? onAddFriend;

  const PlayerListSection({
    super.key,
    required this.members,
    required this.maxPlayers,
    required this.slotsAvailable,
    required this.isAdmin,
    required this.isSubmitting,
    this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    final confirmed = members.where((m) => m['status'] == 'confirmed').toList();
    final confirmedCount = confirmed.length;
    final progress = maxPlayers > 0 ? confirmedCount / maxPlayers : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with Add button
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.people_alt_rounded,
                  size: 18, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              child: Text(
                'Players',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppFontWeights.bold,
                ),
              ),
            ),
            // Player count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (progress >= 1.0 ? AppColors.green : AppColors.amber)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$confirmedCount/$maxPlayers',
                style: tt.labelSmall?.copyWith(
                  color: progress >= 1.0 ? AppColors.green : AppColors.amber,
                  fontWeight: AppFontWeights.bold,
                ),
              ),
            ),
            // Add button (admin only, when slots available)
            if (isAdmin && slotsAvailable > 0) ...[
              const SizedBox(width: AppSpacing.lg),
              _AddPlayerButton(
                isSubmitting: isSubmitting,
                onTap: onAddFriend,
              ),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Progress bar with enhanced styling
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: scheme.surfaceContainerHighest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.green : scheme.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Player list — one per row
        if (confirmed.isEmpty)
          _EmptyPlayersHint(slotsAvailable: slotsAvailable)
        else
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: confirmed.asMap().entries.map((entry) {
                final index = entry.key;
                final member = entry.value;
                final isLast = index == confirmed.length - 1;
                return _PlayerRow(
                  member: member,
                  showDivider: !isLast,
                );
              }).toList(),
            ),
          ),

        // Spots open indicator with enhanced styling
        if (slotsAvailable > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty_rounded,
                    size: 16, color: AppColors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$slotsAvailable spot${slotsAvailable == 1 ? '' : 's'} open — waiting for players',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.amber,
                      fontWeight: AppFontWeights.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Player Row ───────────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool showDivider;

  const _PlayerRow({required this.member, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    final name = member['name']?.toString() ?? 'Unknown';
    final avatarUrl = member['avatarUrl']?.toString() ?? '';
    final skillLevel = member['skillLevel']?.toString() ?? '';
    final position = member['position']?.toString() ?? '';
    final isAdmin = member['isAdmin'] == true;
    final joinedAt = member['joinedAt']?.toString() ?? '';
    final bookingTime = _formatBookingTime(joinedAt);

    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isAdmin
                        ? AppColors.amber.withValues(alpha: 0.15)
                        : scheme.surfaceContainerHighest,
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            initials,
                            style: tt.titleSmall?.copyWith(
                              color:
                                  isAdmin ? AppColors.amber : scheme.onSurface,
                              fontWeight: AppFontWeights.bold,
                            ),
                          )
                        : null,
                  ),
                  if (isAdmin)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        child: Icon(Icons.star_rounded,
                            size: 10, color: scheme.surface),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: AppSpacing.lg),

              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: AppFontWeights.semiBold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· Admin',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.amber,
                              fontWeight: AppFontWeights.semiBold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (skillLevel.isNotEmpty && skillLevel != 'All') ...[
                          _SkillDot(skillLevel: skillLevel),
                          const SizedBox(width: 4),
                          Text(
                            skillLevel,
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.textSecondary(),
                            ),
                          ),
                        ],
                        if (skillLevel.isNotEmpty &&
                            skillLevel != 'All' &&
                            bookingTime.isNotEmpty)
                          Text(' · ',
                              style: tt.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary())),
                        if (bookingTime.isNotEmpty)
                          Text(
                            'Joined $bookingTime',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.textSecondary(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Position tag
              if (position.isNotEmpty && position != '—')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    position.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.textSecondary(),
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpacing.xxl + 44 + AppSpacing.xxl, // avatar width + gaps
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }

  static String _formatBookingTime(String? joinedAt) {
    if (joinedAt == null || joinedAt.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(joinedAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${dateTime.day}/${dateTime.month}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Skill Dot ────────────────────────────────────────────────────────────────

class _SkillDot extends StatelessWidget {
  final String skillLevel;
  const _SkillDot({required this.skillLevel});

  @override
  Widget build(BuildContext context) {
    final color = switch (skillLevel.toLowerCase().trim()) {
      'advanced' => AppColors.red,
      'intermediate' => AppColors.amber,
      'beginner' => AppColors.green,
      _ => AppColors.blue,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Add Player Button ────────────────────────────────────────────────────────

class _AddPlayerButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback? onTap;

  const _AddPlayerButton({required this.isSubmitting, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: isSubmitting ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_rounded, size: 16, color: scheme.onPrimary),
              const SizedBox(width: 6),
              Text(
                'Add',
                style: tt.labelSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: AppFontWeights.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyPlayersHint extends StatelessWidget {
  final int slotsAvailable;
  const _EmptyPlayersHint({required this.slotsAvailable});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.group_add_rounded,
                size: 32, color: AppColors.textDisabled()),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No players yet',
              style: tt.bodyMedium?.copyWith(
                color: AppColors.textSecondary(),
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$slotsAvailable spot${slotsAvailable == 1 ? '' : 's'} waiting to be filled',
              style: tt.bodySmall?.copyWith(
                color: AppColors.textDisabled(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
