import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_radius.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/painters/field_painter.dart';
import '../../core/services/player_auth_storage_service.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../matches/data/services/player_match_service.dart';

class InvitePreviewScreen extends StatefulWidget {
  const InvitePreviewScreen({super.key});

  @override
  State<InvitePreviewScreen> createState() => _InvitePreviewScreenState();
}

class _InvitePreviewScreenState extends State<InvitePreviewScreen> {
  final PlayerMatchService _matchService = PlayerMatchService.instance;
  final PlayerAuthStorageService _authStorage =
      PlayerAuthStorageService.instance;

  bool _isLoading = true;
  bool _isJoining = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  bool _initialized = false;
  String? _selectedPosition = 'midfielder';
  Map<String, dynamic>? _invite;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadInvite();
  }

  Future<void> _loadInvite() async {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs.cast<String, dynamic>() : null;
    final token = (args?['token'] ?? args?['inviteToken'])?.toString();

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _isLoggedIn = (await _authStorage.getAccessToken())?.isNotEmpty == true;

      if (token != null && token.isNotEmpty) {
        try {
          final preview = await _matchService.getInvitePreview(token);
          if (!mounted) return;
          setState(() {
            _invite = preview;
            _isLoading = false;
          });
          return;
        } on MatchApiException {
          if (args != null) {
            if (!mounted) return;
            setState(() {
              _invite = _normalizeLocalInvite(args);
              _isLoading = false;
            });
            return;
          }
          rethrow;
        }
      }

      if (args != null) {
        if (!mounted) return;
        setState(() {
          _invite = _normalizeLocalInvite(args);
          _isLoading = false;
        });
        return;
      }

      throw const MatchApiException(
        message: 'Invite link not found',
        statusCode: 404,
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load invite preview right now.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeLocalInvite(Map<String, dynamic> raw) {
    return {
      'matchGroupId':
          raw['matchGroupId']?.toString() ?? raw['id']?.toString() ?? '',
      'venueName': raw['venueName']?.toString() ?? '',
      'venueAddress': raw['venueAddress']?.toString() ?? '',
      'venueImage': raw['venueImage']?.toString() ?? '',
      'date': raw['date']?.toString() ?? '',
      'startTime': raw['startTime']?.toString() ?? '',
      'spotsLeft': raw['spotsLeft'] is num ? raw['spotsLeft'] as num : 0,
      'skillFilter': raw['skillFilter']?.toString() ??
          raw['skillLevel']?.toString() ??
          'All',
    };
  }

  String _skillText(String? skillFilter) {
    final text = skillFilter?.toString() ?? '';
    if (text.isEmpty || text == 'All') return 'Open to all skill levels';
    return '$text players preferred';
  }

  Future<void> _joinMatch() async {
    final invite = _invite;
    final matchGroupId = invite?['matchGroupId']?.toString() ?? '';

    if (!_isLoggedIn) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (matchGroupId.isEmpty) return;

    setState(() => _isJoining = true);
    try {
      await _matchService.requestToJoinMatch(
        matchId: matchGroupId,
        position: _selectedPosition,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/match-detail',
        arguments: {'id': matchGroupId},
      );
    } on MatchApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not join match right now')),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _invite == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('Invite Preview'),
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_off_rounded,
                    size: 48, color: AppColors.txtDisabled),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage ?? 'Could not load invite preview.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.txtDisabled),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: _loadInvite,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final invite = _invite ?? const <String, dynamic>{};
    final spotsLeft =
        (invite['spotsLeft'] is num ? invite['spotsLeft'] as num : 0).toInt();
    final skillText = _skillText(invite['skillFilter']?.toString());

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                children: [
                  if ((invite['venueImage']?.toString() ?? '').isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: invite['venueImage'].toString(),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.bgPrimary,
                    ),
                  CustomPaint(
                    painter: FootballFieldPainter(),
                    child: const SizedBox.expand(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.bgPrimary.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: StatusBadge(
                      label: 'Preview',
                      color: AppColors.amber,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("You're Invited!", style: AppText.bodySm),
                        const SizedBox(height: 6),
                        Text('Join the Match',
                            style: AppText.h1, textAlign: TextAlign.center),
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
                  FutsCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(invite['venueName']?.toString() ?? '',
                                      style: AppText.h2),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 13,
                                          color: AppColors.txtDisabled),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          invite['venueAddress']?.toString() ??
                                              '',
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
                              borderRadius: AppRadius.small,
                              child: (invite['venueImage']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true)
                                  ? CachedNetworkImage(
                                      imageUrl: invite['venueImage'].toString(),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.bgElevated,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.image_not_supported,
                                          color: AppColors.txtDisabled),
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
                            _GridItem(
                                'Date', invite['date']?.toString() ?? '-'),
                            _GridItem(
                                'Time', invite['startTime']?.toString() ?? '-'),
                            _GridItem('Spots', '$spotsLeft left'),
                            _GridItem('Skill', skillText),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text("Who's Playing", style: AppText.h3),
                      const Spacer(),
                      Text('$spotsLeft spots left',
                          style:
                              AppText.bodySm.copyWith(color: AppColors.amber)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: AppRadius.medium,
                      border: Border.all(color: AppColors.borderClr),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.group_outlined, color: AppColors.green),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Confirm your spot and join the lineup.',
                            style: AppText.bodySm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoggedIn)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PositionChip(
                                label: 'GK',
                                value: 'goalkeeper',
                                selectedValue: _selectedPosition,
                                onTap: (value) =>
                                    setState(() => _selectedPosition = value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PositionChip(
                                label: 'DEF',
                                value: 'defender',
                                selectedValue: _selectedPosition,
                                onTap: (value) =>
                                    setState(() => _selectedPosition = value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PositionChip(
                                label: 'MID',
                                value: 'midfielder',
                                selectedValue: _selectedPosition,
                                onTap: (value) =>
                                    setState(() => _selectedPosition = value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PositionChip(
                                label: 'FWD',
                                value: 'striker',
                                selectedValue: _selectedPosition,
                                onTap: (value) =>
                                    setState(() => _selectedPosition = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FutsButton(
                          label: _isJoining ? 'Joining...' : 'Join This Match',
                          isLoading: _isJoining,
                          onPressed: _joinMatch,
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FutsButton(
                          label: 'Sign In to Join',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                        ),
                        const SizedBox(height: 12),
                        FutsButton(
                          label: 'Create Account',
                          outlined: true,
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Preview only - sign in to join',
                            style: AppText.label,
                          ),
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

class _PositionChip extends StatelessWidget {
  final String label;
  final String value;
  final String? selectedValue;
  final ValueChanged<String> onTap;

  const _PositionChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.borderClr,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(
            color: isSelected ? AppColors.bgPrimary : AppColors.txtDisabled,
          ),
        ),
      ),
    );
  }
}
