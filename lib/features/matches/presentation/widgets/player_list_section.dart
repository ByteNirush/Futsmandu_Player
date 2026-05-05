import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

/// Unified "Players" section — compact boxed rows with add/remove actions.
class PlayerListSection extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final int maxPlayers;
  final int slotsAvailable;
  final int offlinePlayersCount;
  final bool isAdmin;
  final bool isSubmitting;
  final VoidCallback? onAddFriend;
  final Function(String userId)? onRemovePlayer;
  final Function(String userId)? onViewProfile;

  const PlayerListSection({
    super.key,
    required this.members,
    required this.maxPlayers,
    required this.slotsAvailable,
    required this.offlinePlayersCount,
    required this.isAdmin,
    required this.isSubmitting,
    this.onAddFriend,
    this.onRemovePlayer,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    final confirmed = members.where((m) => m['status'] == 'confirmed').toList();
    final confirmedCount = confirmed.length;
    final progress = maxPlayers > 0 ? confirmedCount / maxPlayers : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
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
                child: Icon(Icons.people_alt_rounded, size: 18, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Players',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                    if (offlinePlayersCount > 0)
                      Text(
                        'Includes $offlinePlayersCount offline players',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.textSecondary(),
                          fontWeight: AppFontWeights.medium,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (progress >= 1.0 ? AppColors.green : scheme.primary)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$confirmedCount/$maxPlayers',
                  style: tt.labelSmall?.copyWith(
                    color: progress >= 1.0 ? AppColors.green : scheme.primary,
                    fontWeight: AppFontWeights.bold,
                  ),
                ),
              ),
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
          const SizedBox(height: AppSpacing.md),
          if (confirmed.isEmpty && offlinePlayersCount == 0)
            _EmptyPlayersHint(slotsAvailable: slotsAvailable)
          else
            Column(
              children: [
                ...confirmed.asMap().entries.map((entry) {
                  final member = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PlayerRow(
                      member: member,
                      canRemove: isAdmin && member['isAdmin'] != true,
                      onRemove: onRemovePlayer,
                      onTap: onViewProfile,
                    ),
                  );
                }),
                ...List.generate(offlinePlayersCount, (index) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReservedRow(),
                  );
                }),
              ],
            ),
          if (slotsAvailable > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: scheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$slotsAvailable spot${slotsAvailable == 1 ? '' : 's'} open — waiting for players',
                      style: tt.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: AppFontWeights.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool canRemove;
  final Function(String userId)? onRemove;
  final Function(String userId)? onTap;

  const _PlayerRow({
    required this.member,
    required this.canRemove,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    final id = member['id']?.toString() ?? '';
    final name = member['name']?.toString() ?? 'Unknown';
    final avatarUrl = member['avatarUrl']?.toString() ?? '';
    final skillLevel = member['skillLevel']?.toString() ?? '';
    final position = member['position']?.toString() ?? '';
    final isAdminMember = member['isAdmin'] == true;
    final joinedAt = member['joinedAt']?.toString() ?? '';
    final bookingTime = _formatBookingTime(joinedAt);
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: id.isNotEmpty ? () => onTap?.call(id) : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.28),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: isAdminMember
                        ? scheme.primary.withOpacity(0.15)
                        : scheme.surfaceContainerHighest,
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            initials,
                            style: tt.titleSmall?.copyWith(
                              color: isAdminMember
                                  ? scheme.primary
                                  : scheme.onSurface,
                              fontWeight: AppFontWeights.bold,
                            ),
                          )
                        : null,
                  ),
                  if (isAdminMember)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        child: Icon(Icons.star_rounded,
                            size: 10, color: scheme.onPrimary),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                        if (isAdminMember) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.xxs),
                            ),
                            child: Text(
                              'ADMIN',
                              style: tt.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: AppFontWeights.bold,
                                fontSize: 10,
                              ),
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
                          Text(
                            ' · ',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.textSecondary(),
                            ),
                          ),
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
              if (canRemove)
                IconButton(
                  onPressed: () => onRemove?.call(id),
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: scheme.error.withOpacity(0.7),
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove Player',
                )
              else if (position.isNotEmpty && position != '—')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      ),
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

class _EmptyPlayersHint extends StatelessWidget {
  final int slotsAvailable;
  const _EmptyPlayersHint({required this.slotsAvailable});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.group_add_rounded,
                size: 32, color: AppColors.textDisabled()),
            const SizedBox(height: AppSpacing.md),
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

class _ReservedRow extends StatelessWidget {
  const _ReservedRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outlineVariant.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: AppColors.textDisabled(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserved Spot',
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.textSecondary(),
                    fontWeight: AppFontWeights.medium,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Offline player',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.textDisabled(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'SECURED',
              style: tt.labelSmall?.copyWith(
                color: AppColors.textDisabled(),
                fontWeight: AppFontWeights.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
