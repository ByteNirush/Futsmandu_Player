import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/mock/mock_data.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/futs_card.dart';
import '../home/home_shell.dart' show kNavBarHeight;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const user = MockData.currentUser;
    final int score = user['reliabilityScore'] as int;
    final Color scoreColor = AppColors.reliabilityColor(score);
    final String scoreLabel = score >= 70
        ? 'Reliable'
        : score >= 40
            ? 'Fair'
            : 'Restricted';
    final int matchesPlayed = user['matchesPlayed'] as int;
    final int won = user['won'] as int;
    final int lost = user['lost'] as int;
    final int draw = user['draw'] as int;
    final double winRate = matchesPlayed == 0 ? 0 : won / matchesPlayed;
    final double bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                floating: false,
                snap: false,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: AppColors.bgPrimary,
                iconTheme: IconThemeData(color: AppColors.txtPrimary),
                titleSpacing: 16,
                title: Text(
                  'Profile',
                  style: AppText.h3.copyWith(fontSize: 18),
                ),
                actions: [
                  _AppBarAction(
                    icon: Icons.settings_outlined,
                    onTap: () => _showComingSoon(context, 'Settings'),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _ProfileHeader(
                    user: user,
                    score: score,
                    scoreColor: scoreColor,
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  bottomPad + kNavBarHeight + 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Performance Section
                    const _SectionLabel(label: 'Performance'),
                    const SizedBox(height: 12),
                    FutsCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top row: matches + win rate
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.sports_score_outlined,
                                  label: 'Matches',
                                  value: '$matchesPlayed',
                                  color: AppColors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.emoji_events_outlined,
                                  label: 'Win Rate',
                                  value: '${(winRate * 100).round()}%',
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Bottom row: won / lost / draw
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.check_circle_outline,
                                  label: 'Won',
                                  value: '$won',
                                  color: AppColors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.cancel_outlined,
                                  label: 'Lost',
                                  value: '$lost',
                                  color: AppColors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.remove_circle_outline,
                                  label: 'Draw',
                                  value: '$draw',
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Win Progress', style: AppText.label),
                              Text(
                                '${(winRate * 100).round()}%',
                                style: AppText.label.copyWith(
                                  color: AppColors.green,
                                  fontWeight: AppTextStyles.semiBold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: winRate,
                              minHeight: 7,
                              backgroundColor: AppColors.bgElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Reliability Section
                    const _SectionLabel(label: 'Reliability Score'),
                    const SizedBox(height: 12),
                    FutsCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size.square(88),
                                  painter:
                                      ReliabilityRingPainter(score, scoreColor),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$score',
                                      style: GoogleFonts.barlow(
                                        fontSize: 24,
                                        fontWeight: AppTextStyles.semiBold,
                                        color: scoreColor,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      '/100',
                                      style: AppText.label.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: scoreColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      scoreLabel,
                                      style: AppText.h3.copyWith(
                                        fontSize: 17,
                                        color: scoreColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  score >= 70
                                      ? 'Excellent attendance and booking behavior.'
                                      : score >= 40
                                          ? 'Improve attendance to avoid account limits.'
                                          : 'Current score may impact booking eligibility.',
                                  style: AppText.bodySm.copyWith(
                                    color: AppColors.txtDisabled,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _InfoChip(
                                      label: 'No-shows',
                                      value: '${user['noShows']}',
                                      color: AppColors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    _InfoChip(
                                      label: 'Late cancels',
                                      value: '${user['lateCancels']}',
                                      color: AppColors.amber,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions Section
                    const _SectionLabel(label: 'Quick Actions'),
                    const SizedBox(height: 12),
                    _QuickActionsGrid(context: context),

                    const SizedBox(height: 24),

                    // Preferences Section
                    const _SectionLabel(label: 'Preferences'),
                    const SizedBox(height: 12),
                    FutsCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: _notificationsEnabled ? 'On' : 'Off',
                            trailing: Switch.adaptive(
                              value: _notificationsEnabled,
                              activeThumbColor: AppColors.green,
                              onChanged: (value) {
                                setState(() => _notificationsEnabled = value);
                              },
                            ),
                            onTap: () {
                              setState(
                                () => _notificationsEnabled =
                                    !_notificationsEnabled,
                              );
                            },
                          ),
                          const _SettingsTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Theme',
                            subtitle: 'Appearance',
                            trailing: _ThemeModeMenu(),
                          ),
                          _SettingsTile(
                            icon: Icons.shield_outlined,
                            title: 'Account Security',
                            subtitle: 'Password & 2FA',
                            onTap: () =>
                                _showComingSoon(context, 'Account Security'),
                          ),
                          _SettingsTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle: 'FAQs & contact',
                            onTap: () =>
                                _showComingSoon(context, 'Help & Support'),
                          ),
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            title: 'Log Out',
                            iconColor: AppColors.red,
                            textColor: AppColors.red,
                            showDivider: false,
                            onTap: () {
                              _showLogoutConfirm(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: AppText.h3.copyWith(fontSize: 18)),
        content: Text(
          'Are you sure you want to log out?',
          style: AppText.bodySm.copyWith(color: AppColors.txtDisabled),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppText.bodySm.copyWith(color: AppColors.txtDisabled),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              'Log Out',
              style: AppText.bodySm.copyWith(
                color: AppColors.red,
                fontWeight: AppTextStyles.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final int score;
  final Color scoreColor;

  const _ProfileHeader({
    required this.user,
    required this.score,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.green.withValues(alpha: 0.18),
                AppColors.bgPrimary,
              ],
              stops: const [0.0, 0.85],
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          top: -60,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          left: -40,
          bottom: 20,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue.withValues(alpha: 0.06),
            ),
          ),
        ),
        // Content — padded to sit below the collapsed app bar height (~56 dp)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.green.withValues(alpha: 0.8),
                          AppColors.blue.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.bgElevated,
                      backgroundImage:
                          NetworkImage(user['avatarUrl'] as String),
                    ),
                  ),
                  // Camera button
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Avatar upload coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.bgPrimary, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 13,
                          color: AppColors.bgPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Name
              Text(
                user['name'] as String,
                style: AppText.h2.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '@aarav_sharma',
                    style: AppText.bodySm.copyWith(
                      color: AppColors.txtDisabled,
                      fontSize: 13,
                    ),
                  ),
                  if (user['isVerified'] == true) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppColors.blue,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Badges row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Badge(
                    text: user['skillLevel'] as String,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    text: 'ELO ${user['eloRating']}',
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 8),
                  _Badge(text: '$score pts', color: scoreColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppText.h3.copyWith(fontSize: 16)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar action icon button
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderClr),
        ),
        child: Icon(icon, size: 18, color: AppColors.txtPrimary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reliability ring painter
// ─────────────────────────────────────────────────────────────────────────────

class ReliabilityRingPainter extends CustomPainter {
  final int score;
  final Color color;

  ReliabilityRingPainter(this.score, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bg = Paint()
      ..color = AppColors.borderClr
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final Paint fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width - 7,
      height: size.height - 7,
    );

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bg);
    canvas.drawArc(rect, -math.pi / 2, (score / 100) * 2 * math.pi, false, fg);
  }

  @override
  bool shouldRepaint(covariant ReliabilityRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge chip
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs3,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: AppText.label.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric card (inside performance section)
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs2,
        vertical: AppSpacing.xs2,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.barlow(
              fontSize: 22,
              fontWeight: AppTextStyles.semiBold,
              color: AppColors.txtPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.label),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info chip (no-shows, late cancels)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs3,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppText.bodySm.copyWith(
              fontWeight: AppTextStyles.semiBold,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.label.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions — uses LayoutBuilder to avoid hardcoded width math
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final BuildContext context;
  const _QuickActionsGrid({required this.context});

  @override
  Widget build(BuildContext buildContext) {
    const actions = [
      (Icons.edit_outlined, 'Edit Profile', '/edit-profile'),
      (Icons.calendar_month_rounded, 'My Bookings', '/bookings'),
      (Icons.history_rounded, 'Match History', null),
      (Icons.group_outlined, 'Friends', null),
      (Icons.privacy_tip_outlined, 'Privacy', null),
      (Icons.star_border_rounded, 'Reviews', null),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // 2-column grid with a 10dp gap; each card fills exactly half the width.
        final double cardWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions.map((a) {
            return _QuickActionTile(
              icon: a.$1,
              label: a.$2,
              width: cardWidth,
              onTap: () {
                if (a.$3 != null) {
                  Navigator.pushNamed(context, a.$3!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${a.$2} coming soon'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.fromLTRB(
                          AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                    ),
                  );
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double width;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderClr),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings tile
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          minVerticalPadding: 10,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.xs3),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderClr),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? AppColors.txtDisabled,
            ),
          ),
          title: Text(
            title,
            style: AppText.body.copyWith(
              color: textColor ?? AppColors.txtPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: AppText.label.copyWith(fontSize: 12),
                )
              : null,
          trailing: trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.txtDisabled,
              ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderClr,
            indent: 48,
            endIndent: 10,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme mode selector
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeModeMenu extends StatelessWidget {
  const _ThemeModeMenu();

  @override
  Widget build(BuildContext context) {
    final provider = ThemeProvider.instance;
    return AnimatedBuilder(
      animation: provider,
      builder: (_, __) => PopupMenuButton<ThemeMode>(
        initialValue: provider.themeMode,
        onSelected: provider.setThemeMode,
        itemBuilder: (context) => const [
          PopupMenuItem(value: ThemeMode.system, child: Text('System')),
          PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
          PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
        ],
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              switch (provider.themeMode) {
                ThemeMode.system => 'System',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              },
              style: AppText.bodySm.copyWith(color: AppColors.txtDisabled),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded,
                color: AppColors.txtDisabled, size: 18),
          ],
        ),
      ),
    );
  }
}
