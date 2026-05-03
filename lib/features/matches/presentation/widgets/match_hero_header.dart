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
                  color: scheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),

          // Gradient overlay at bottom to ensure image blends nicely or text is readable
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),

          // App Bar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: scheme.onSurface),
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showCollapsedTitle ? 1 : 0,
                child: Text(
                  venueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
              ),
              actions: [
                // Refresh button with semi-transparent background
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.surface.withValues(alpha: 0.62),
                  ),
                  icon: Icon(Icons.refresh_rounded, color: scheme.onSurface),
                  onPressed: isRefreshing ? null : onRefresh,
                ),
                const SizedBox(width: 8),
                // Share button with semi-transparent background
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.surface.withValues(alpha: 0.62),
                  ),
                  icon: Icon(Icons.share_outlined, color: scheme.onSurface),
                  onPressed: onShare,
                ),
                const SizedBox(width: 16),
              ],
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

  const MatchHeaderContent({
    super.key,
    required this.venueName,
    required this.dateLabel,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
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
          const SizedBox(height: AppSpacing.sm),
          // Date and time row
          if (dateLabel.isNotEmpty || timeLabel.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  timeLabel.isEmpty
                      ? dateLabel
                      : '$dateLabel · $timeLabel',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
