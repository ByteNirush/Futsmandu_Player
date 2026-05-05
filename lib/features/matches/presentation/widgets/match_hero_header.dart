import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

/// Clean hero image header for match details (like venue details style).
/// 
/// Shows a clean image with gradient overlays, no text on image.
/// Title appears in collapsed app bar when scrolled.
class MatchHeroHeader extends StatelessWidget {
  final String venueImage;
  final String venueName;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onShare;
  final bool showCollapsedTitle;

  const MatchHeroHeader({
    super.key,
    required this.venueImage,
    required this.venueName,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onShare,
    this.showCollapsedTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Venue image with loading/error states
          if (venueImage.isNotEmpty)
            Image.network(
              venueImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: scheme.surfaceContainerHighest,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: scheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            // Placeholder when no image
            Container(
              color: scheme.primaryContainer,
              child: Center(
                child: Icon(
                  Icons.sports_soccer_rounded,
                  size: 80,
                  color: scheme.primary.withOpacity(0.5),
                ),
              ),
            ),

          // Custom Header Overlay (replacing AppBar for better stability in Stack)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surface.withOpacity(0.62),
                        ),
                        icon: Icon(Icons.arrow_back, color: scheme.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      // Collapsed Title
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: showCollapsedTitle ? 1 : 0,
                          child: Text(
                            venueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: AppFontWeights.bold,
                            ),
                          ),
                        ),
                      ),
                      // Refresh button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surface.withOpacity(0.62),
                        ),
                        icon: Icon(Icons.refresh_rounded, color: scheme.onSurface),
                        onPressed: isRefreshing ? null : onRefresh,
                      ),
                      const SizedBox(width: 8),
                      // Share button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surface.withOpacity(0.62),
                        ),
                        icon: Icon(Icons.share_outlined, color: scheme.onSurface),
                        onPressed: onShare,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Venue name and date/time header shown below the hero image.
/// Use this in the SliverList content area after the hero header.
/// Matches the venue details content styling exactly.
class MatchHeaderContent extends StatelessWidget {
  final String venueName;
  final String dateLabel;
  final String timeLabel;
  final String venueAddress;
  final List<String> amenities;

  const MatchHeaderContent({
    super.key,
    required this.venueName,
    required this.dateLabel,
    required this.timeLabel,
    this.venueAddress = '',
    this.amenities = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue name
          Text(
            venueName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: AppFontWeights.semiBold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date and time row
          if (dateLabel.isNotEmpty || timeLabel.isNotEmpty)
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: timeLabel.isEmpty ? dateLabel : '$dateLabel · $timeLabel',
              textTheme: textTheme,
              scheme: scheme,
            ),

          // Location row
          if (venueAddress.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: venueAddress,
              textTheme: textTheme,
              scheme: scheme,
            ),
          ],

          // Amenities row
          if (amenities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: amenities.map((a) => _AmenityTag(label: a)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextTheme textTheme;
  final ColorScheme scheme;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.textTheme,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmenityTag extends StatelessWidget {
  final String label;

  const _AmenityTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: AppFontWeights.medium,
        ),
      ),
    );
  }
}

