import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart'
    show ProfileSectionHeader, SettingsTile, AppCard;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/player_auth_storage_service.dart';
import 'data/models/player_profile_models.dart';
import 'data/services/player_profile_service.dart';
import '../auth/presentation/providers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Map<String, dynamic> _fallbackUser = <String, dynamic>{
    'name': '',
    'handle': '',
    'avatarUrl': '',
    'isVerified': false,
    'skillLevel': null,
    'skillLevelRaw': null,
    'eloRating': null,
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
  XFile? _localAvatarFile;
  String? _errorMessage;
  Map<String, dynamic> _user = _fallbackUser;
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

    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppText.bodySm,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Player Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppFontWeights.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh profile',
            onPressed: _loadProfile,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            children: [
              // ── Profile Header Card ─────────────────────────────────────
              _PlayerProfileHeader(
                user: user,
                onEditProfile: _openEditProfileSheet,
                onAvatarTap: _pickAndUploadAvatar,
                isAvatarUploading: _isUploadingAvatar,
                localAvatarFile: _localAvatarFile,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Performance Section ────────────────────────────────────
              _PerformanceSection(
                matchesPlayed: matchesPlayed,
                won: won,
                lost: lost,
                draw: draw,
                winRate: winRate,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Reliability Section ────────────────────────────────────
              _ReliabilitySection(
                user: user,
                score: score,
                scoreColor: scoreColor,
                scoreLabel: scoreLabel,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Quick Actions Section ─────────────────────────────────
              const ProfileSectionHeader(
                title: 'Quick Actions',
                subtitle: 'Access your bookings and account features.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuickActionsList(
                onEditProfile: _openEditProfileSheet,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Preferences Section ───────────────────────────────────
              _PreferencesSection(
                notificationsEnabled: _notificationsEnabled,
                onNotificationsChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                onSupportTap: () => _showSupportSheet(context),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Account Section ────────────────────────────────────────
              _AccountSection(
                onLogout: () => _showLogoutConfirm(context),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeights.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Preferred Roles',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: AppFontWeights.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
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
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Match History Publicly'),
                    value: showMatchHistory,
                    onChanged: (value) =>
                        setLocalState(() => showMatchHistory = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
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

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AvatarSourceSheet(),
    );
    if (source == null) return;

    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;

    setState(() {
      _localAvatarFile = file;
      _isUploadingAvatar = true;
    });

    try {
      final bytes = await file.readAsBytes();
      await _profileService.uploadAvatarBytes(bytes);
      await _loadProfile(silent: true);
      if (!mounted) return;
      setState(() => _localAvatarFile = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated')),
      );
    } on ProfileApiException catch (e) {
      if (!mounted) return;
      setState(() => _localAvatarFile = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _localAvatarFile = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload avatar')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _loadProfile({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final raw = await _profileService.getOwnProfile();
      final mapped = _mapProfile(raw);
      if (!mounted) return;
      setState(() => _user = mapped);
      await PlayerAuthStorageService.instance.saveUser({
        'id': mapped['id'],
        'name': mapped['name'],
        'email': mapped['email'],
        'phone': mapped['phone'],
        'profile_image_url': mapped['avatarUrl'],
      });
    } on ProfileApiException catch (e) {
      if (!mounted) return;
      if (!silent) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => _errorMessage = 'Failed to load profile');
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
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
      'handle': _buildHandle(name: name, email: email) ?? '',
      'avatarUrl': raw.profileImageUrl,
      'isVerified': raw.isVerified,
      'skillLevelRaw': raw.skillLevel.isEmpty ? null : raw.skillLevel,
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

  String? _displaySkill(String skill) {
    if (skill.isEmpty) return null;
    final normalized = skill.toLowerCase();
    if (normalized == 'intermediate') return 'Intermediate';
    if (normalized == 'advanced') return 'Advanced';
    return 'Beginner';
  }

  String? _buildHandle({required String name, required String email}) {
    if (email.isNotEmpty && email.contains('@')) {
      return '@${email.split('@').first.toLowerCase()}';
    }
    final normalized =
        name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (normalized.isEmpty) return null;
    return '@$normalized';
  }

  void _showLogoutConfirm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          'Log Out',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppFontWeights.bold,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
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
              style: tt.labelLarge?.copyWith(
                color: cs.error,
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player Profile Header (card-style like Owner app)
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;
  final bool isAvatarUploading;
  final XFile? localAvatarFile;

  const _PlayerProfileHeader({
    required this.user,
    required this.onEditProfile,
    required this.onAvatarTap,
    required this.isAvatarUploading,
    this.localAvatarFile,
  });

  String get _initials {
    final name = (user['name'] as String? ?? '').trim();
    final parts = name.split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildAvatarContent(double size, ColorScheme cs) {
    // 1. Instant local preview right after picking
    if (localAvatarFile != null) {
      return ClipOval(
        child: Image.file(
          File(localAvatarFile!.path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildInitials(size, cs),
        ),
      );
    }

    // 2. Network image with loading / error states
    final url = user['avatarUrl'] as String? ?? '';
    if (url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (ctx, url2) => _buildInitials(size, cs),
          errorWidget: (ctx, url2, err) => _buildInitials(size, cs),
        ),
      );
    }

    // 3. Initials fallback (no avatar yet)
    return ClipOval(child: _buildInitials(size, cs));
  }

  Widget _buildInitials(double size, ColorScheme cs) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: AppFontWeights.bold,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final handle = user['handle'] as String? ?? '';
    final preferredRoles = (user['preferredRoles'] is List)
        ? (user['preferredRoles'] as List).whereType<String>().toList()
        : <String>[];

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar with camera button ─────────────────────
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.2),
                                width: 2.5,
                              ),
                            ),
                            child: _buildAvatarContent(72, cs),
                          ),
                          // Camera badge
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isAvatarUploading
                                    ? cs.surfaceContainerHighest
                                    : cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.surface, width: 2),
                              ),
                              child: isAvatarUploading
                                  ? Center(
                                      child: SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt_rounded,
                                      color: cs.onPrimary,
                                      size: 12,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // ── Player info ────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  (user['name'] as String?)?.isNotEmpty == true
                                      ? user['name'] as String
                                      : 'Player',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.titleLarge?.copyWith(
                                    fontWeight: AppFontWeights.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              if (user['isVerified'] == true) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: cs.primary,
                                ),
                              ],
                            ],
                          ),
                          if (handle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              handle,
                              style: tt.bodySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: AppFontWeights.medium,
                              ),
                            ),
                          ],
                          if (user['email'] != null &&
                              (user['email'] as String).isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user['email'] as String,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // ── Status & role chips ──────────────────────────────────
                if (user['skillLevel'] != null ||
                    user['eloRating'] != null ||
                    preferredRoles.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (user['skillLevel'] != null)
                        _PlayerChip(
                          icon: Icons.sports_soccer_outlined,
                          label: user['skillLevel'] as String,
                          foreground: cs.onSurface,
                          background: cs.surfaceContainerHighest,
                        ),
                      if (user['eloRating'] != null)
                        _PlayerChip(
                          icon: Icons.emoji_events_outlined,
                          label: 'ELO ${user['eloRating']}',
                          foreground: cs.onSurface,
                          background: cs.surfaceContainerHighest,
                        ),
                      for (final role in preferredRoles)
                        _PlayerChip(
                          icon: Icons.person_outline_rounded,
                          label: role[0].toUpperCase() + role.substring(1),
                          foreground: cs.primary,
                          background: cs.primary.withValues(alpha: 0.08),
                        ),
                    ],
                  ),
                ],
                // ── Edit Profile Button ──────────────────────────────────
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: AppFontWeights.semiBold,
                ),
          ),
        ],
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
    const double strokeWidth = 8;
    final Paint bg = Paint()
      ..color = AppColors.borderClr.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width - strokeWidth,
      height: size.height - strokeWidth,
    );

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bg);
    canvas.drawArc(rect, -math.pi / 2, (score / 100) * 2 * math.pi, false, fg);
  }

  @override
  bool shouldRepaint(covariant ReliabilityRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: AppFontWeights.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: tt.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
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
              style: tt.labelLarge?.copyWith(
                fontWeight: AppFontWeights.semiBold,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
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
            style: tt.labelLarge?.copyWith(
              fontWeight: AppFontWeights.semiBold,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions — clean list layout with only functional items
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsList extends StatelessWidget {
  final VoidCallback onEditProfile;

  const _QuickActionsList({
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final actions = [
      (Icons.edit_outlined, 'Edit Profile', null, onEditProfile),
      (Icons.calendar_month_rounded, 'My Bookings', '/bookings', null as VoidCallback?),
      (Icons.group_outlined, 'Friends', '/friends', null as VoidCallback?),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(AppRadius.lg))
                    : i == actions.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg))
                        : BorderRadius.zero,
                onTap: () {
                  final action = actions[i];
                  if (action.$4 != null) {
                    action.$4!();
                  } else if (action.$3 != null) {
                    Navigator.pushNamed(context, action.$3!);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(actions[i].$1, size: 18, color: cs.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          actions[i].$2,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: AppFontWeights.medium,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Avatar source picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarSourceSheet extends StatelessWidget {
  const _AvatarSourceSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            'Update Profile Photo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeights.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs2),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a Photo',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs2,
          ),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: AppFontWeights.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted Sections
// ─────────────────────────────────────────────────────────────────────────────

class _PerformanceSection extends StatelessWidget {
  final int matchesPlayed;
  final int won;
  final int lost;
  final int draw;
  final double winRate;

  const _PerformanceSection({
    required this.matchesPlayed,
    required this.won,
    required this.lost,
    required this.draw,
    required this.winRate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeader(
          title: 'Performance',
          subtitle: 'Your match statistics and win rate.',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _PerformanceStat(
                    icon: Icons.sports_score_outlined,
                    label: 'Matches Played',
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
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Win Progress',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(winRate * 100).round()}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.green,
                      fontWeight: AppFontWeights.semiBold,
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
                  backgroundColor: AppColors.green.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReliabilitySection extends StatelessWidget {
  final Map<String, dynamic> user;
  final int score;
  final Color scoreColor;
  final String scoreLabel;

  const _ReliabilitySection({
    required this.user,
    required this.score,
    required this.scoreColor,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeader(
          title: 'Reliability Score',
          subtitle: 'Your attendance and booking behavior.',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(96),
                      painter: ReliabilityRingPainter(score, scoreColor),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: scoreColor,
                            fontWeight: AppFontWeights.bold,
                          ),
                        ),
                        Text(
                          '/100',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          scoreLabel,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scoreColor,
                            fontWeight: AppFontWeights.bold,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
        ),
      ],
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onSupportTap;

  const _PreferencesSection({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onSupportTap,
  });

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeader(
          title: 'Preferences',
          subtitle: 'Tune how the player workspace behaves.',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: AnimatedBuilder(
            animation: ThemeProvider.instance,
            builder: (context, _) {
              final themeMode = ThemeProvider.instance.themeMode;
              return Column(
                children: [
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Booking alerts and account updates',
                    trailing: Switch.adaptive(
                      value: notificationsEnabled,
                      onChanged: onNotificationsChanged,
                    ),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.brightness_6_outlined,
                    title: 'Theme',
                    subtitle: _themeModeLabel(themeMode),
                    trailing: ToggleButtons(
                      borderRadius: BorderRadius.circular(AppRadius.md),
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
                          index == 0 ? ThemeMode.light : ThemeMode.dark,
                        );
                      },
                      children: const [
                        Icon(Icons.light_mode_outlined, size: 18),
                        Icon(Icons.dark_mode_outlined, size: 18),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'See FAQs or contact the support team',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: onSupportTap,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  final VoidCallback onLogout;

  const _AccountSection({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeader(
          title: 'Account',
          subtitle: 'Manage access to this player workspace.',
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            icon: Icon(Icons.logout_rounded, size: 18, color: colorScheme.error),
            label: Text(
              'Logout',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
              minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
