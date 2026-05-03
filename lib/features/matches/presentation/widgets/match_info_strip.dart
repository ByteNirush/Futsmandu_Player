import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../../../../shared/widgets/status_badge.dart';

/// Compact info strip below the hero: address, status badge, and skill level.
///
/// Replaces the old stats-row card and scattered address / badge / count rows.
class MatchInfoStrip extends StatelessWidget {
  final String venueAddress;
  final String skillLevel;
  final bool isPartialTeamBooking;
  final bool isOpen;
  final int confirmedCount;
  final int maxPlayers;
  final int slotsAvailable;

  const MatchInfoStrip({
    super.key,
    required this.venueAddress,
    required this.skillLevel,
    required this.isPartialTeamBooking,
    required this.isOpen,
    required this.confirmedCount,
    required this.maxPlayers,
    required this.slotsAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);

    final statusLabel = isPartialTeamBooking
        ? 'Partial Team'
        : isOpen
            ? 'Open Match'
            : 'Private';
    final statusColor =
        (isOpen || isPartialTeamBooking) ? AppColors.green : AppColors.textSecondary();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxs, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address row with enhanced styling
          if (venueAddress.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.location_on_outlined,
                      size: 16, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      venueAddress,
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.textSecondary(),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

          if (venueAddress.isNotEmpty) const SizedBox(height: AppSpacing.lg),

          // Status + skill + slots row with divider
          Container(
            padding: EdgeInsets.only(top: venueAddress.isNotEmpty ? AppSpacing.md : 0),
            decoration: BoxDecoration(
              border: venueAddress.isNotEmpty
                  ? Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(label: statusLabel, color: statusColor),
                if (skillLevel.isNotEmpty && skillLevel != '—' && skillLevel.toLowerCase() != 'all')
                  StatusBadge(
                    label: skillLevel,
                    color: _skillColor(skillLevel),
                  ),
                _SlotsChip(
                  confirmedCount: confirmedCount,
                  maxPlayers: maxPlayers,
                  slotsAvailable: slotsAvailable,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _skillColor(String? level) => switch (level?.toLowerCase().trim()) {
        'advanced' => AppColors.red,
        'intermediate' => AppColors.amber,
        'beginner' => AppColors.green,
        _ => AppColors.blue,
      };
}

class _SlotsChip extends StatelessWidget {
  final int confirmedCount;
  final int maxPlayers;
  final int slotsAvailable;

  const _SlotsChip({
    required this.confirmedCount,
    required this.maxPlayers,
    required this.slotsAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = AppTypography.textTheme(scheme);
    final isFull = slotsAvailable <= 0;
    final color = isFull ? AppColors.green : AppColors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFull ? Icons.check_circle_rounded : Icons.person_outline_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isFull ? '$confirmedCount/$maxPlayers Full' : '$confirmedCount/$maxPlayers · $slotsAvailable open',
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: AppFontWeights.bold,
            ),
          ),
        ],
      ),
    );
  }
}
