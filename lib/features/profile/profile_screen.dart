import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart'
    show ProfileSectionHeader;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/player_auth_storage_service.dart';
import 'data/models/player_profile_models.dart';
import 'data/services/player_profile_service.dart';
import '../auth/presentation/providers/auth_controller.dart';
import '../home/home_shell.dart' show kNavBarHeight;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Map<String, dynamic> _fallbackUser = <String, dynamic>{
    'name': 'Player',
    'handle': '@player',
    'avatarUrl': 'https://i.pravatar.cc/240?img=11',
    'isVerified': false,
    'skillLevel': 'Beginner',
    'skillLevelRaw': 'beginner',
    'eloRating': 0,
    'reliabilityScore': 0,
    'matchesPlayed': 0,
    'won': 0,
    'lost': 0,
    'draw': 0,
    'noShows': 0,
    'lateCancels': 0,
    'showMatchHistory': true,
    'preferredRoles': <String>[],
  };

  final PlayerProfileService _profileService = PlayerProfileService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  bool _isSavingProfile = false;
  String? _errorMessage;
  Map<String, dynamic> _user = _fallbackUser;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

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
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
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
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.red,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppText.bodySm,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                  style: AppTypography.subHeading(
                    context,
                    colorScheme,
                  ).copyWith(fontSize: 18),
                ),
                actions: [
                  _AppBarAction(
                    icon: Icons.refresh_rounded,
                    onTap: _loadProfile,
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _ProfileHeader(
                    user: user,
                    score: score,
                    scoreColor: scoreColor,
                    onEditProfile: _openEditProfileSheet,
                    onAvatarTap: _pickAndUploadAvatar,
                    isAvatarUploading: _isUploadingAvatar,
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.sm2,
                  AppSpacing.md,
                  AppSpacing.sm2,
                  bottomPad + kNavBarHeight + AppSpacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Performance Section
                    const _SectionLabel(label: 'Performance'),
                    const SizedBox(height: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _PerformanceStat(
                              icon: Icons.sports_score_outlined,
                              label: 'Matches',
                              value: '$matchesPlayed',
                              color: AppColors.blue,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _PerformanceStat(
                              icon: Icons.emoji_events_outlined,
                              label: 'Win Rate',
                              value: '${(winRate * 100).round()}%',
                              color: AppColors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            _StatPill(
                              label: 'Won',
                              value: '$won',
                              color: AppColors.green,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _StatPill(
                              label: 'Lost',
                              value: '$lost',
                              color: AppColors.red,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _StatPill(
                              label: 'Draw',
                              value: '$draw',
                              color: AppColors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Win Progress',
                              style: AppText.label.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${(winRate * 100).round()}%',
                              style: AppText.label.copyWith(
                                color: AppColors.green,
                                fontWeight: AppTextStyles.semiBold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: winRate,
                            minHeight: 7,
                            backgroundColor:
                                AppColors.green.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Reliability Section
                    const _SectionLabel(label: 'Reliability Score'),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
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
                                    style: AppTypography.textTheme(colorScheme)
                                        .headlineSmall
                                        ?.copyWith(
                                          color: scoreColor,
                                          fontWeight: AppFontWeights.semiBold,
                                        ),
                                  ),
                                  Text(
                                    '/100',
                                    style: AppTypography.caption(
                                      context,
                                      colorScheme,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
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
                              const SizedBox(height: 6),
                              Text(
                                score >= 70
                                    ? 'Excellent attendance and booking behavior.'
                                    : score >= 40
                                        ? 'Improve attendance to avoid account limits.'
                                        : 'Current score may impact booking eligibility.',
                                style: AppText.bodySm.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs2),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  _InfoChip(
                                    label: 'No-shows',
                                    value: '${user['noShows']}',
                                    color: AppColors.red,
                                  ),
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

                    const SizedBox(height: AppSpacing.md),

                    // Quick Actions Section
                    const _SectionLabel(label: 'Quick Actions'),
                    const SizedBox(height: AppSpacing.sm),
                    _QuickActionsGrid(
                      context: context,
                      onEditProfile: _openEditProfileSheet,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Preferences Section
                    const ProfileSectionHeader(
                      title: 'Preferences',
                      subtitle: 'Tune how the player workspace behaves.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedBuilder(
                      animation: ThemeProvider.instance,
                      builder: (context, _) {
                        final themeMode = ThemeProvider.instance.themeMode;
                        return Column(
                          children: [
                            _PreferenceTile(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              subtitle: 'Booking alerts and account updates',
                              trailing: Switch.adaptive(
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(
                                    () => _notificationsEnabled = value,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs2),
                            _PreferenceTile(
                              icon: Icons.brightness_6_outlined,
                              title: 'Theme',
                              subtitle: _themeModeLabel(themeMode),
                              trailing: ToggleButtons(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 36,
                                  minWidth: 44,
                                ),
                                isSelected: [
                                  themeMode == ThemeMode.light,
                                  themeMode == ThemeMode.dark,
                                ],
                                onPressed: (index) {
                                  ThemeProvider.instance.setThemeMode(
                                    index == 0
                                        ? ThemeMode.light
                                        : ThemeMode.dark,
                                  );
                                },
                                children: const [
                                  Icon(Icons.light_mode_outlined, size: 18),
                                  Icon(Icons.dark_mode_outlined, size: 18),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs2),
                            _PreferenceTile(
                              icon: Icons.help_outline_rounded,
                              title: 'Help & Support',
                              subtitle: 'See FAQs or contact the support team',
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => _showSupportSheet(context),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Account Section
                    const ProfileSectionHeader(
                      title: 'Account',
                      subtitle: 'Manage access to this player workspace.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showLogoutConfirm(context),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Logout'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.onErrorContainer,
                          minimumSize: const Size.fromHeight(
                            AppSpacing.buttonHeight,
                          ),
                        ),
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

  void _showSupportSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.email_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Email support'),
                  subtitle: const Text('support@futsmandu.com'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support email copied')),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.phone_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Call support'),
                  subtitle: const Text('+977 98XXXXXXXX'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support call requested')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditProfileSheet() async {
    final nameController = TextEditingController(text: _string(_user['name']));
    var selectedSkill = _string(_user['skillLevelRaw']);
    if (!const ['beginner', 'intermediate', 'advanced']
        .contains(selectedSkill)) {
      selectedSkill = 'beginner';
    }
    var showMatchHistory = _user['showMatchHistory'] == true;
    final selectedRoles =
        Set<String>.from(_asStringList(_user['preferredRoles']));

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;

        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Profile',
                    style: AppText.h3.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSkill,
                    items: const [
                      DropdownMenuItem(
                          value: 'beginner', child: Text('Beginner')),
                      DropdownMenuItem(
                          value: 'intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(
                          value: 'advanced', child: Text('Advanced')),
                    ],
                    decoration: const InputDecoration(labelText: 'Skill Level'),
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => selectedSkill = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preferred Roles',
                    style: AppText.bodySm.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final role in const [
                        'goalkeeper',
                        'defender',
                        'midfielder',
                        'striker'
                      ])
                        FilterChip(
                          label: Text(role),
                          selected: selectedRoles.contains(role),
                          onSelected: (selected) {
                            setLocalState(() {
                              if (selected) {
                                selectedRoles.add(role);
                              } else {
                                selectedRoles.remove(role);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Match History Publicly'),
                    value: showMatchHistory,
                    onChanged: (value) =>
                        setLocalState(() => showMatchHistory = value),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSavingProfile
                          ? null
                          : () {
                              Navigator.pop(ctx, true);
                            },
                      child: Text(_isSavingProfile ? 'Saving...' : 'Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      nameController.dispose();
      return;
    }

    final trimmedName = nameController.text.trim();
    nameController.dispose();
    if (trimmedName.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      await _profileService.updateOwnProfile(
        UpdateProfileRequest(
          name: trimmedName,
          skillLevel: selectedSkill,
          preferredRoles: selectedRoles.toList(growable: false),
          showMatchHistory: showMatchHistory,
        ),
      );
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } on ProfileApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      await _profileService.uploadAvatarBytes(bytes);
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated successfully')),
      );
    } on ProfileApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload avatar')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await _profileService.getOwnProfile();
      final mapped = _mapProfile(raw);
      if (!mounted) return;
      setState(() {
        _user = mapped;
      });
      await PlayerAuthStorageService.instance.saveUser({
        'id': mapped['id'],
        'name': mapped['name'],
        'email': mapped['email'],
        'phone': mapped['phone'],
        'profile_image_url': mapped['avatarUrl'],
      });
    } on ProfileApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load profile';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _mapProfile(PlayerProfile raw) {
    final mapped = Map<String, dynamic>.from(_fallbackUser);
    final email = raw.email;
    final name = raw.name.isEmpty ? mapped['name'] as String : raw.name;

    mapped.addAll({
      'id': raw.id,
      'name': name,
      'email': email,
      'phone': raw.phone,
      'handle': _buildHandle(name: name, email: email),
      'avatarUrl': raw.profileImageUrl.isEmpty
          ? mapped['avatarUrl']
          : raw.profileImageUrl,
      'isVerified': raw.isVerified,
      'skillLevelRaw': raw.skillLevel.isEmpty ? 'beginner' : raw.skillLevel,
      'skillLevel': _displaySkill(raw.skillLevel),
      'eloRating': raw.eloRating,
      'reliabilityScore': raw.reliabilityScore,
      'matchesPlayed': raw.matchesPlayed,
      'won': raw.matchesWon,
      'lost': raw.matchesLost,
      'draw': raw.matchesDraw,
      'noShows': raw.totalNoShows,
      'lateCancels': raw.totalLateCancels,
      'showMatchHistory': raw.showMatchHistory,
      'preferredRoles': raw.preferredRoles,
    });

    return mapped;
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().toList(growable: false);
  }

  String _string(dynamic value) {
    if (value is String) return value;
    return '';
  }

  String _displaySkill(String skill) {
    final normalized = skill.toLowerCase();
    if (normalized == 'intermediate') return 'Intermediate';
    if (normalized == 'advanced') return 'Advanced';
    return 'Beginner';
  }

  String _buildHandle({required String name, required String email}) {
    if (email.contains('@')) {
      return '@${email.split('@').first.toLowerCase()}';
    }
    final normalized =
        name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (normalized.isEmpty) return '@player';
    return '@$normalized';
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: AppText.h3.copyWith(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: AppText.bodySm.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppText.bodySm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authSessionProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;
  final bool isAvatarUploading;

  const _ProfileHeader({
    required this.user,
    required this.score,
    required this.scoreColor,
    required this.onEditProfile,
    required this.onAvatarTap,
    required this.isAvatarUploading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          child: SingleChildScrollView(
            reverse: true,
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
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
                      onTap: onAvatarTap,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAvatarUploading
                              ? Icons.hourglass_top_rounded
                              : Icons.camera_alt_outlined,
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
                style: AppText.h2.copyWith(
                  fontSize: 22,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user['handle'] as String,
                    style: AppText.bodySm.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
                  GestureDetector(
                    onTap: onEditProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs3,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Edit',
                        style: AppText.label.copyWith(
                          color: AppColors.green,
                          fontWeight: AppFontWeights.semiBold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: AppTypography.subHeading(
        context,
        colorScheme,
      ).copyWith(fontSize: 17),
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bgElevated.withValues(alpha: 0.7),
          shape: BoxShape.circle,
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
      ),
      child: Text(
        text,
        style: AppText.label.copyWith(
          color: color,
          fontWeight: AppFontWeights.semiBold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PerformanceStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PerformanceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.textTheme(
              Theme.of(context).colorScheme,
            ).headlineSmall?.copyWith(
              color: AppColors.txtPrimary,
              fontWeight: AppFontWeights.semiBold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppText.label.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs3,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(AppRadius.md),
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
            style: AppText.label.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
  final VoidCallback onEditProfile;

  const _QuickActionsGrid({
    required this.context,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext buildContext) {
    const actions = [
      (Icons.edit_outlined, 'Edit Profile', null),
      (Icons.calendar_month_rounded, 'My Bookings', '/bookings'),
      (Icons.receipt_long_rounded, 'Payment History', '/payment-history'),
      (Icons.group_outlined, 'Friends', '/friends'),
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
                if (a.$2 == 'Edit Profile') {
                  onEditProfile();
                  return;
                }
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
        color: Colors.transparent,
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
              color: AppColors.bgElevated.withValues(alpha: 0.55),
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
                      fontWeight: AppFontWeights.semiBold,
                      color: Theme.of(context).colorScheme.onSurface,
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

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs2,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgElevated.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 18, color: AppColors.green),
              ),
              const SizedBox(width: AppSpacing.xs2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.bodySm.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: AppTextStyles.semiBold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppText.label.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs2),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
