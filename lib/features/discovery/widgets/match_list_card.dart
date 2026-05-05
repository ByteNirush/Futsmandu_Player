import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../../matches/data/models/player_match_models.dart';
import '../../../shared/widgets/futs_card.dart';
import '../../../shared/widgets/status_badge.dart';

class MatchListCard extends StatelessWidget {
  final MatchSummary match;
  final int index;

  const MatchListCard({
    super.key,
    required this.match,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine skill color
    final skillColor = match.skillLevel == 'Advanced'
        ? AppColors.error
        : match.skillLevel == 'Intermediate'
            ? AppColors.warning
            : AppColors.success;

    // Spot color
    final int spotsLeft = match.spotsLeft;
    final int slotsAvailable = match.slotsAvailable;
    // Always compute playersNeeded from actual member count for accuracy
    final int playersNeeded = (match.maxPlayers - match.memberCount).clamp(0, match.maxPlayers);
    final spotColor = spotsLeft == 1
        ? AppColors.error
        : spotsLeft <= 3
            ? AppColors.warning
            : AppColors.success;

    final friendsCount = match.friendsIn;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: FutsCard(
        onTap: () => Navigator.pushNamed(context, '/match-detail',
            arguments: match.toMap()),
        // Use default FutsCard padding instead of incorrectly overriding it
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Image
            Hero(
              tag:
                  'match_image_${match.id.isNotEmpty ? match.id : index}', // Ideal to have unique match ID
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: match.venueImage,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 90,
                    height: 90,
                    color: AppColors.bgElevated,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 90,
                    height: 90,
                    color: AppColors.bgElevated,
                    child: Icon(Icons.image_not_supported,
                        color: AppColors.txtDisabled),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Venue Name + Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.venueName.isEmpty
                              ? 'Unknown Venue'
                              : match.venueName,
                          style: AppTypography.textTheme(
                            Theme.of(context).colorScheme,
                          ).titleMedium?.copyWith(
                            fontWeight: AppFontWeights.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge(
                        label: '$slotsAvailable slots',
                        color: spotColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match.courtName,
                    style: AppTypography.textTheme(
                      Theme.of(context).colorScheme,
                    ).bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Need $playersNeeded players  |  $slotsAvailable slots available',
                    style: AppTypography.textTheme(
                      Theme.of(context).colorScheme,
                    ).labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Footer Row: Friends Profile + Price
                  if (friendsCount > 0)
                    Row(
                      children: [
                        ...List.generate(
                          math.min(2, friendsCount),
                          (i) => Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.65,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.person,
                                size: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '+$friendsCount friends',
                          style: AppTypography.textTheme(
                            Theme.of(context).colorScheme,
                          ).labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: AppFontWeights.semiBold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoChip(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.txtDisabled),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.textTheme(
            Theme.of(context).colorScheme,
          ).labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
