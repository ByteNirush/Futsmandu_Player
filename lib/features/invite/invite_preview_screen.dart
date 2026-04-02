import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/mock/mock_data.dart';
import '../../core/painters/field_painter.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/status_badge.dart';

class InvitePreviewScreen extends StatefulWidget {
  const InvitePreviewScreen({super.key});

  @override
  State<InvitePreviewScreen> createState() => _InvitePreviewScreenState();
}

class _InvitePreviewScreenState extends State<InvitePreviewScreen> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    // Gracefully handle dynamic MockData.invite if not explicitly defined
    final Map<String, dynamic> invite = (() {
      try {
        return (MockData as dynamic).invite as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{
          'id': 'inv001',
          'venueName': 'Futsmandu Arena',
          'venueAddress': 'Thamel, Kathmandu',
          'venueImage': 'https://picsum.photos/seed/arena1/200',
          'date': 'Sat, 14 Oct',
          'time': '17:00 – 18:00',
          'format': '5v5 Turf',
          'skillLevel': 'Intermediate',
          'expiresIn': '48 hrs',
          'maxPlayers': 10,
          'spotsLeft': 3,
          'members': MockData.friends.take(7).toList(),
        };
      }
    })();

    final List members = (invite['members'] as List?) ?? [];
    final int maxPlayers = invite['maxPlayers'] as int? ?? 10;
    final int spotsLeft = invite['spotsLeft'] as int? ?? (maxPlayers - members.length);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HERO
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.bgPrimary,
                  ),
                  CustomPaint(
                    painter: FootballFieldPainter(),
                    child: const SizedBox(width: double.infinity, height: double.infinity),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: StatusBadge(
                      label: 'Expires in ${invite['expiresIn']}',
                      color: AppColors.amber,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("You're Invited!", style: AppText.bodySm),
                        const SizedBox(height: 6),
                        Text('Join the Match', style: AppText.h1, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // MATCH DETAILS
                  FutsCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(invite['venueName'] ?? '', style: AppText.h2),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on, size: 13, color: AppColors.txtDisabled),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          invite['venueAddress'] ?? '',
                                          style: AppText.bodySm,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: invite['venueImage'] ?? '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.8,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _GridItem('Date', invite['date']),
                            _GridItem('Time', invite['time']),
                            _GridItem('Format', invite['format']),
                            _GridItem('Skill', invite['skillLevel']),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text("Who's Playing (${members.length}/$maxPlayers)", style: AppText.h3),
                      const Spacer(),
                      Text('$spotsLeft spots left', style: AppText.bodySm.copyWith(color: AppColors.amber)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Avatar Stack
                  SizedBox(
                    height: 40,
                    child: Stack(
                      children: [
                        ...members.take(7).toList().asMap().entries.map((e) {
                          return Positioned(
                            left: e.key * 28.0, 
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.bgElevated,
                              backgroundImage: NetworkImage(e.value['avatarUrl'] ?? ''),
                            ),
                          );
                        }),
                        if (members.length > 7)
                          Positioned(
                            left: 7 * 28.0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.bgElevated,
                              child: Text(
                                '+${members.length - 7}',
                                style: AppText.label.copyWith(color: AppColors.txtPrimary),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Skill Progress Indicators
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: 0.43,
                                valueColor: AlwaysStoppedAnimation(AppColors.green),
                                backgroundColor: AppColors.bgElevated,
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: 0.43,
                                valueColor: AlwaysStoppedAnimation(AppColors.amber),
                                backgroundColor: AppColors.bgElevated,
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: 0.14,
                                valueColor: AlwaysStoppedAnimation(AppColors.red),
                                backgroundColor: AppColors.bgElevated,
                                minHeight: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _LegendItem(AppColors.green, 'Beginner'),
                          const Spacer(),
                          _LegendItem(AppColors.amber, 'Intermediate'),
                          const Spacer(),
                          _LegendItem(AppColors.red, 'Advanced'),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs2,
                            ),
                          ),
                          icon: Icon(Icons.share_outlined, size: 16, color: AppColors.txtDisabled),
                          label: Text('Share', style: AppText.bodySm.copyWith(color: AppColors.txtPrimary)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share coming soon')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _isLoggedIn = !_isLoggedIn),
                          child: Text(
                            _isLoggedIn ? 'Logged In\n(tap to toggle)' : 'Logged Out\n(tap to toggle)',
                            style: AppText.label.copyWith(color: AppColors.txtDisabled),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoggedIn)
                    FutsButton(
                      label: 'Join This Match',
                      onPressed: () => Navigator.pushNamed(context, '/match-detail', arguments: MockData.matches[0]),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FutsButton(
                          label: 'Sign In to Join',
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                        ),
                        const SizedBox(height: 12),
                        FutsButton(
                          label: 'Create Account',
                          outlined: true,
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text('Preview only — sign in to join', style: AppText.label),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final String label;
  final String value;

  const _GridItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 2),
        Text(value, style: AppText.h3.copyWith(fontSize: 16)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppText.label),
      ],
    );
  }
}
