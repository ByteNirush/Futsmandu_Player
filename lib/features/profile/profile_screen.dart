import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';
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
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.red,
                    size: 36,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(
                        context, Theme.of(context).colorScheme),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
          'Profile',
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
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
              AppSpacing.pageHorizontal,
              AppSpacing.xxl,
            ),
            children: [
              // ── Profile Header Card ─────────────────────────────────────
              _PlayerProfileHeader(
                user: user,
                onAvatarTap: _pickAndUploadAvatar,
                isAvatarUploading: _isUploadingAvatar,
                localAvatarFile: _localAvatarFile,
              ),

              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Account',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: AppFontWeights.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AccountSection(
                onManageProfile: _openEditProfileSheet,
                onShowStats: () => _showStatsSheet(
                  context: context,
                  matchesPlayed: matchesPlayed,
                  won: won,
                  lost: lost,
                  draw: draw,
                  winRate: winRate,
                  user: user,
                  score: score,
                  scoreColor: scoreColor,
                  scoreLabel: scoreLabel,
                ),
                onLogout: () => _showLogoutConfirm(context),
              ),

              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: AppFontWeights.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PreferencesSection(
                notificationsEnabled: _notificationsEnabled,
                onNotificationsChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),

              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Support',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: AppFontWeights.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SupportSection(
                onSupportTap: () => _showSupportSheet(context),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showLogoutConfirm(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onErrorContainer,
                    minimumSize: const Size.fromHeight(
                      AppSpacing.buttonHeight,
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

  void _showStatsSheet({
    required BuildContext context,
    required int matchesPlayed,
    required int won,
    required int lost,
    required int draw,
    required double winRate,
    required Map<String, dynamic> user,
    required int score,
    required Color scoreColor,
    required String scoreLabel,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xxl + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Match Statistics',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: AppFontWeights.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _PerformanceSection(
                matchesPlayed: matchesPlayed,
                won: won,
                lost: lost,
                draw: draw,
                winRate: winRate,
              ),
              const SizedBox(height: AppSpacing.xl),
              _ReliabilitySection(
                user: user,
                score: score,
                scoreColor: scoreColor,
                scoreLabel: scoreLabel,
              ),
            ],
          ),
        );
      },
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
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
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
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
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
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Preferred Roles',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: AppFontWeights.medium,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
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
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Match History Publicly'),
                    value: showMatchHistory,
                    onChanged: (value) =>
                        setLocalState(() => showMatchHistory = value),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
      if (e.statusCode == 404) {
        await _loadCachedProfile(silent: silent);
        return;
      }
      if (!silent) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => _errorMessage = 'Failed to load profile');
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCachedProfile({bool silent = false}) async {
    final cachedUser = await PlayerAuthStorageService.instance.getUser();
    if (!mounted) return;

    if (cachedUser == null) {
      if (!silent) {
        setState(() {
          _errorMessage = 'User not found';
          _user = _fallbackUser;
        });
      }
      return;
    }

    final mapped = Map<String, dynamic>.from(_fallbackUser)
      ..addAll({
        'id': cachedUser['id']?.toString() ?? '',
        'name': _string(cachedUser['name']),
        'email': _string(cachedUser['email']),
        'phone': _string(cachedUser['phone']),
        'handle': _buildHandle(
              name: _string(cachedUser['name']),
              email: _string(cachedUser['email']),
            ) ??
            '',
        'avatarUrl': _string(
          cachedUser['profile_image_url'] ?? cachedUser['avatarUrl'],
        ),
      });

    if (!mounted) return;
    setState(() {
      _user = mapped;
      _errorMessage = null;
    });
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
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
  final VoidCallback onAvatarTap;
  final bool isAvatarUploading;
  final XFile? localAvatarFile;

  const _PlayerProfileHeader({
    required this.user,
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar with camera button ─────────────────────
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.2),
                      width: 2.5,
                    ),
                  ),
                  child: _buildAvatarContent(64, cs),
                ),
                // Camera badge
                Positioned(
                  bottom: -4,
                  right: -4,
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
          const SizedBox(width: AppSpacing.xl),
          // ── Player info ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                        style: tt.titleMedium?.copyWith(
                          fontWeight: AppFontWeights.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (user['isVerified'] == true) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                    ],
                  ],
                ),
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: AppFontWeights.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
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
            const SizedBox(width: AppSpacing.xs),
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
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
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
          const SizedBox(width: AppSpacing.xs),
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

class _AccountSection extends StatelessWidget {
  final VoidCallback onManageProfile;
  final VoidCallback onShowStats;
  final VoidCallback onLogout;

  const _AccountSection({
    required this.onManageProfile,
    required this.onShowStats,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Manage Profile',
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: onManageProfile,
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.bar_chart_rounded,
            title: 'Match Statistics',
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: onShowStats,
          ),
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  final VoidCallback onSupportTap;

  const _SupportSection({required this.onSupportTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: onSupportTap,
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About Us',
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _AvatarSourceSheet extends StatelessWidget {
  const _AvatarSourceSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.md),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.sm),
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
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: 22),
              const SizedBox(width: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
                  const SizedBox(width: AppSpacing.lg),
                  _PerformanceStat(
                    icon: Icons.emoji_events_outlined,
                    label: 'Win Rate',
                    value: '${(winRate * 100).round()}%',
                    color: AppColors.green,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _StatPill(
                    label: 'Won',
                    value: '$won',
                    color: AppColors.green,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatPill(
                    label: 'Lost',
                    value: '$lost',
                    color: AppColors.red,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatPill(
                    label: 'Draw',
                    value: '$draw',
                    color: AppColors.amber,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: winRate,
                  minHeight: 7,
                  backgroundColor: AppColors.green.withValues(alpha: 0.12),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.green),
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
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: scoreColor,
                                fontWeight: AppFontWeights.bold,
                              ),
                        ),
                        Text(
                          '/100',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
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
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          scoreLabel,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
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

  const _PreferencesSection({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                trailing: Switch.adaptive(
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                ),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.language_outlined,
                title: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('English',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.brightness_6_outlined,
                title: 'Theme',
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
            ],
          );
        },
      ),
    );
  }
}
