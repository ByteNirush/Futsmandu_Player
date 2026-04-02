import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/mock/mock_data.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_badge.dart';
import 'home_shell.dart' show kNavBarHeight;

// --- Email Nudge Banner ---
class _EmailNudgeBanner extends StatefulWidget {
  const _EmailNudgeBanner();

  @override
  State<_EmailNudgeBanner> createState() => _EmailNudgeBannerState();
}

class _EmailNudgeBannerState extends State<_EmailNudgeBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.amber, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.mark_email_unread, size: 18, color: AppColors.amber),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Verify your email to enable bookings.',
              style: GoogleFonts.barlow(fontSize: 13, color: AppColors.amber),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            style: TextButton.styleFrom(foregroundColor: AppColors.amber),
            child: const Text('Verify'),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: AppColors.amber),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}

// --- Match Mini Card ---
class _MatchMiniCard extends StatelessWidget {
  final Map<String, dynamic> match;
  
  const _MatchMiniCard(this.match);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/match-detail', arguments: match),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppSpacing.xs2),
        // Used ClipRRect so children fit within bounds
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: match['venueImage'],
                fit: BoxFit.cover,
                width: 160,
                height: 200,
                placeholder: (context, url) => Container(
                  width: 160,
                  height: 200,
                  color: AppColors.bgElevated,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 160,
                  height: 200,
                  color: AppColors.bgElevated,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 28,
                    color: AppColors.txtDisabled,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: AppSpacing.xs3,
                left: AppSpacing.xs3,
                right: AppSpacing.xs3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      label: '${match['spotsLeft']} spots',
                      color: match['spotsLeft'] <= 2 
                          ? AppColors.red 
                          : match['spotsLeft'] <= 4 
                              ? AppColors.amber 
                              : AppColors.green,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      match['venueName'],
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 11, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${match['time']} · ${match['distance']}',
                          style: GoogleFonts.barlow(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (match['friendsIn'] > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        '+${match['friendsIn']}',
                        style: GoogleFonts.barlow(
                          fontSize: 10,
                          color: AppColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Meta Chip & Upcoming Booking Card ---
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.txtDisabled),
        const SizedBox(width: AppSpacing.xxs),
        Text(text, style: AppText.label),
      ],
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  final Map<String, dynamic> b;

  const _UpcomingBookingCard(this.b);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/match-detail', arguments: MockData.matches[0]),
      child: FutsCard(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  right: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(label: 'CONFIRMED', color: AppColors.green),
                        const Spacer(),
                        Text(
                          'NPR ${b['priceNPR']}', 
                          style: GoogleFonts.barlow(
                            color: AppColors.green, 
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      b['venueName'], 
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      b['courtName'], 
                      style: AppText.bodySm,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _MetaChip(Icons.calendar_today, b['date'].split(' ').take(3).join(' ')),
                        const SizedBox(width: AppSpacing.xs2),
                        _MetaChip(Icons.access_time, b['time']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopFutsalCard extends StatelessWidget {
  final Map<String, dynamic> venue;

  const _TopFutsalCard(this.venue);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/venues'),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: AppSpacing.xs2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: venue['coverUrl'] ?? '',
                fit: BoxFit.cover,
                width: 220,
                height: 140,
                placeholder: (context, url) => Container(
                  width: 220,
                  height: 140,
                  color: AppColors.bgElevated,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 220,
                  height: 140,
                  color: AppColors.bgElevated,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 24,
                    color: AppColors.txtDisabled,
                  ),
                ),
              ),
              Container(
                width: 220,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.80),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.xs3,
                right: AppSpacing.xs3,
                bottom: AppSpacing.xs3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue['name'] ?? '',
                      style: GoogleFonts.barlow(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.amber),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${venue['rating']}  ·  ${venue['distance']}',
                          style: GoogleFonts.barlow(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

// --- Home Screen ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Map<String, dynamic> currentUser = MockData.currentUser;
    final int score = currentUser['reliabilityScore'] ?? 100;
    final bool isVerified = currentUser['isVerified'] ?? true;

    Map<String, dynamic>? upcomingBooking;
    try {
      upcomingBooking = MockData.bookings.firstWhere((b) => b['status'] == 'CONFIRMED');
    } catch (_) {}
    final List<Map<String, dynamic>> topFutsals =
        List<Map<String, dynamic>>.from(MockData.venues)
          ..sort(
            (a, b) => ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num),
          );

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Sliver 1: Email nudge banner (outside any card to avoid double-padding)
            if (!isVerified)
              const SliverToBoxAdapter(
                child: _EmailNudgeBanner(),
              ),

            // Sliver 2: Greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.bgSurface,
                            AppColors.bgSurface.withValues(alpha: 0.88),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderClr, width: 1),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Good evening', style: AppText.bodySm),
                                Text(
                                  currentUser['name'],
                                  style: AppText.h1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(
                                  currentUser['avatarUrl'],
                                ),
                              ),
                              Positioned(
                                bottom: 1,
                                right: 1,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.green,
                                    border: Border.all(
                                      color: AppColors.bgPrimary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                color: AppColors.txtDisabled,
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/notifications'),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '3',
                                      style: GoogleFonts.barlow(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
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
            ),
            
            // Sliver 2: Reliability Warning
            if (score < 70)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    top: AppSpacing.xs2,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xs2),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: AppColors.amber, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.amber),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Reliability score is $score. Attend bookings to improve.',
                          style: GoogleFonts.barlow(
                            fontSize: 13,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Sliver 3: Top Futsal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: 'Top Futsal',
                      onAction: () => Navigator.pushNamed(context, '/venues'),
                    ),
                    const SizedBox(height: AppSpacing.xs2),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        itemCount: topFutsals.length >= 4 ? 4 : topFutsals.length,
                        itemBuilder: (ctx, i) => _TopFutsalCard(topFutsals[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sliver 4: Play Tonight
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: 'Play Tonight',
                      onAction: () => Navigator.pushNamed(context, '/discovery'),
                    ),
                    const SizedBox(height: AppSpacing.xs2),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        itemCount: 3,
                        itemBuilder: (ctx, i) => _MatchMiniCard(MockData.matches[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sliver 5: Upcoming Booking
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.md,
                  0,
                  MediaQuery.of(context).padding.bottom + kNavBarHeight + AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    SectionHeader(
                      title: 'Upcoming',
                      onAction: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Use Bookings tab below')),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs2),
                    if (upcomingBooking != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: _UpcomingBookingCard(upcomingBooking),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: EmptyState(
                          icon: Icons.sports_soccer_outlined,
                          title: 'No upcoming bookings',
                          subtitle: 'Find a court and book your next game',
                          buttonLabel: 'Browse Courts',
                          onButton: () => Navigator.pushNamed(context, '/venues'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
