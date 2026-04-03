import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/painters/field_painter.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/status_badge.dart';

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  String? _selectedPos;
  bool _isMember = false;

  @override
  Widget build(BuildContext context) {
    final match =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: AppColors.bgPrimary,
            iconTheme: IconThemeData(color: AppColors.txtPrimary),
            actions: [
              IconButton(
                icon: Icon(Icons.share_outlined, color: AppColors.txtPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon')),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: AppColors.txtPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Options coming soon')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 72,
                bottom: 14,
                end: 16,
              ),
              title: Text(match['venueName'] ?? '',
                  style: AppText.h3.copyWith(fontSize: 18)),
              background: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.bgPrimary,
                  ),
                  CustomPaint(
                    painter: FootballFieldPainter(),
                    child: const SizedBox(
                        width: double.infinity, height: double.infinity),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Match Group', style: AppText.bodySm),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          child: Text(
                            match['venueName'] ?? '',
                            style: AppText.h1,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${match['date']} · ${match['time']}–${match['endTime']}',
                          style: AppText.bodySm,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MATCH META
                  FutsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              _StatCol(
                                value:
                                    '${match['spotsLeft']}/${match['maxPlayers']}',
                                label: 'Spots Left',
                                color: AppColors.green,
                              ),
                              const VerticalDivider(),
                              _StatCol(
                                value: match['skillLevel'] ?? '',
                                label: 'Skill Level',
                                color: match['skillLevel'] == 'Advanced'
                                    ? AppColors.red
                                    : match['skillLevel'] == 'Intermediate'
                                        ? AppColors.amber
                                        : AppColors.green,
                              ),
                              const VerticalDivider(),
                              _StatCol(
                                value: match['distance'] ?? '',
                                label: 'Distance',
                                color: AppColors.blue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.txtDisabled),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (match['venueName'] ?? '') + ' · Thamel',
                                style: AppText.bodySm,
                              ),
                            ),
                            StatusBadge(
                              label: match['isOpen'] == true
                                  ? 'Open Match'
                                  : 'Private',
                              color: match['isOpen'] == true
                                  ? AppColors.green
                                  : AppColors.txtDisabled,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TEAMS HEADER
                  Row(
                    children: [
                      Text('Teams', style: AppText.h3),
                      const Spacer(),
                      Text(
                          '${((match['members'] ?? []) as List).length}/${match['maxPlayers']} players',
                          style: AppText.bodySm),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // TEAMS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TeamColumn(
                          team: 'A',
                          color: AppColors.green,
                          members: ((match['members'] ?? []) as List)
                              .where((m) => m['team'] == 'A')
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TeamColumn(
                          team: 'B',
                          color: AppColors.blue,
                          members: ((match['members'] ?? []) as List)
                              .where((m) => m['team'] == 'B')
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // INVITE FRIENDS
                  Text('Invite Friends', style: AppText.h3),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderClr),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Share invite link',
                                  style: AppText.body
                                      .copyWith(fontWeight: FontWeight.w600)),
                              Text('Valid for 48 hours · max 10 uses',
                                  style: AppText.bodySm),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                            backgroundColor: AppColors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text('Copy Link',
                              style: TextStyle(
                                  color: AppColors.bgPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs3,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(top: BorderSide(color: AppColors.borderClr)),
        ),
        child: _isMember
            ? FutsButton(
                label: 'Leave Match',
                outlined: true,
                customColor: AppColors.red,
                onPressed: () => setState(() => _isMember = false),
              )
            : (match['spotsLeft'] ?? 0) > 0
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['GK', 'DEF', 'MID', 'FWD'].map((pos) {
                            final bool isSelected = _selectedPos == pos;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedPos = pos),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin:
                                    const EdgeInsets.only(right: AppSpacing.xs),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.green
                                      : AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.green
                                        : AppColors.borderClr,
                                  ),
                                ),
                                child: Text(
                                  pos,
                                  style: GoogleFonts.barlow(
                                    fontSize: 15,
                                    fontWeight: AppTextStyles.semiBold,
                                    color: isSelected
                                        ? AppColors.bgPrimary
                                        : AppColors.txtDisabled,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FutsButton(
                        label: 'Join as ${_selectedPos ?? 'Player'}',
                        onPressed: _selectedPos == null
                            ? null
                            : () => setState(() => _isMember = true),
                      ),
                    ],
                  )
                : const FutsButton(
                    label: 'Match Full',
                    onPressed: null,
                  ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCol({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppText.h2.copyWith(color: color)),
          const SizedBox(height: 3),
          Text(label, style: AppText.label),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final String team;
  final Color color;
  final List members;

  const _TeamColumn({
    required this.team,
    required this.color,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final int emptySlots = math.max(0, 5 - members.length);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs2),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    team,
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: AppTextStyles.semiBold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Team $team', style: AppText.h3.copyWith(fontSize: 16)),
              const Spacer(),
              Text('${members.length}/5', style: AppText.label),
            ],
          ),
          const SizedBox(height: 8),
          ...members.map((m) => _MemberRow(m: m)),
          ...List.generate(emptySlots, (_) {
            return Container(
              height: 34,
              margin: const EdgeInsets.only(top: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('Empty slot',
                    style:
                        AppText.label.copyWith(color: AppColors.txtDisabled)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final dynamic m;

  const _MemberRow({required this.m});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.bgElevated,
            backgroundImage: NetworkImage(m['avatarUrl'] ?? ''),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m['name'].toString().split(' ')[0],
              style: AppText.bodySm.copyWith(color: AppColors.txtPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(m['position'] ?? '—', style: AppText.label),
        ],
      ),
    );
  }
}
