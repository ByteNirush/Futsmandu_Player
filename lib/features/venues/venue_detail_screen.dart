import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import 'data/services/player_venues_service.dart';

class _VenueDetailSpacing {
  // Keep these aligned with the screen's local `_space*` scale.
  static const EdgeInsets pillPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xs2,
    vertical: AppSpacing.xs,
  );
  static const double sectionHeaderGap = AppSpacing.xs2; // 12
  static const double sectionGap = AppSpacing.lg; // 16
  static const double smallGap = AppSpacing.xxs; // 4
  static const EdgeInsets reviewCardPadding = EdgeInsets.all(AppSpacing.xs2);
}

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({super.key});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  final PlayerVenuesService _venuesService = PlayerVenuesService.instance;
  final ScrollController _detailScrollController = ScrollController();

  static const double _spaceXs = 4;
  static const double _spaceSm = 8;
  static const double _spaceMd = 12;
  static const double _spaceLg = 16;
  static const double _spaceXl = 20;
  static const double _space2xl = 24;

  String? _venueId;
  Map<String, dynamic>? _venue;
  bool _isLoading = true;
  String? _errorMessage;

  int _courtIdx = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _selectedSlots = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _availabilitySlots =
      const <Map<String, dynamic>>[];
  bool _isLoadingAvailability = false;
  String? _availabilityError;
  bool _showCollapsedTitle = false;
  String _bookingMode = 'solo';

  final Map<String, IconData> _amenityIcons = {
    'Parking': Icons.local_parking,
    'Changing Room': Icons.checkroom_outlined,
    'Floodlights': Icons.highlight_outlined,
    'Cafeteria': Icons.restaurant_outlined,
  };

  @override
  void initState() {
    super.initState();
    _detailScrollController.addListener(_onDetailScroll);
  }

  @override
  void dispose() {
    _detailScrollController
      ..removeListener(_onDetailScroll)
      ..dispose();
    super.dispose();
  }

  void _onDetailScroll() {
    if (!_detailScrollController.hasClients) return;
    final showTitle = _detailScrollController.offset > 170;
    if (showTitle != _showCollapsedTitle && mounted) {
      setState(() => _showCollapsedTitle = showTitle);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_venueId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _venueId = args['id'] as String?;
      _venue = args;
      if (_venueId != null && _venueId!.isNotEmpty) {
        _loadVenueDetail();
        return;
      }
    }

    _isLoading = false;
    _errorMessage = 'Venue ID is missing.';
  }

  Future<void> _loadVenueDetail() async {
    final venueId = _venueId;
    if (venueId == null || venueId.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final venue = await _venuesService.getVenueDetail(venueId);
      if (!mounted) return;
      setState(() {
        _venue = venue;
        _isLoading = false;
        if (_courtIdx >= (_venue?['courts'] as List? ?? const []).length) {
          _courtIdx = 0;
          _selectedSlots = const <Map<String, dynamic>>[];
        }
      });
      await _loadAvailability();
    } on VenueApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load venue details right now.';
      });
    }
  }

  Future<void> _loadAvailability() async {
    final venueId = _venueId;
    final selectedDate = _selectedDate;
    final venue = _venue;

    if (venueId == null ||
        venueId.isEmpty ||
        selectedDate == null ||
        venue == null) {
      if (!mounted) return;
      setState(() {
        _availabilitySlots = const <Map<String, dynamic>>[];
        _availabilityError = null;
        _isLoadingAvailability = false;
      });
      return;
    }

    final courts = (venue['courts'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    if (courts.isEmpty || _courtIdx >= courts.length) {
      if (!mounted) return;
      setState(() {
        _availabilitySlots = const <Map<String, dynamic>>[];
        _availabilityError = 'No courts available for this venue.';
        _isLoadingAvailability = false;
      });
      return;
    }

    final selectedCourt = courts[_courtIdx];
    final courtId = (selectedCourt['id'] as String?) ?? '';
    if (courtId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _availabilitySlots = const <Map<String, dynamic>>[];
        _availabilityError = 'Court ID is missing for selected court.';
        _isLoadingAvailability = false;
      });
      return;
    }

    setState(() {
      _isLoadingAvailability = true;
      _availabilityError = null;
      _selectedSlots = const <Map<String, dynamic>>[];
    });

    try {
      final slots = await _venuesService.getVenueAvailability(
        venueId: venueId,
        courtId: courtId,
        date: _formatApiDate(selectedDate),
      );

      if (!mounted) return;
      setState(() {
        _availabilitySlots = slots;
        _isLoadingAvailability = false;
      });
    } on VenueApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _availabilitySlots = const <Map<String, dynamic>>[];
        _availabilityError = e.message;
        _isLoadingAvailability = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availabilitySlots = const <Map<String, dynamic>>[];
        _availabilityError = 'Could not load availability right now.';
        _isLoadingAvailability = false;
      });
    }
  }

  String _formatApiDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Helper methods for consecutive slot selection
  String _getSelectedTimeRange() {
    if (_selectedSlots.isEmpty) return '';
    final first = _selectedSlots.first;
    final last = _selectedSlots.last;
    return '${first['time']} - ${last['endTime']}';
  }

  String _getSelectedDuration() {
    if (_selectedSlots.isEmpty) return '';
    final minutes = _selectedSlots.length * 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      if (remaining == 0) return '$hours hour${hours > 1 ? 's' : ''}';
      return '$hours hour${hours > 1 ? 's' : ''} $remaining min';
    }
    return '$minutes minutes';
  }

  bool _isSlotSelected(Map<String, dynamic> slot) {
    return _selectedSlots.any((s) => s['time'] == slot['time']);
  }

  bool _isSlotInSelectedRange(int index) {
    if (_selectedSlots.isEmpty) return false;
    // Find indices of all selected slots in the availability list
    final selectedIndices = _selectedSlots
        .map((s) =>
            _availabilitySlots.indexWhere((slot) => slot['time'] == s['time']))
        .where((idx) => idx != -1)
        .toList();
    if (selectedIndices.isEmpty) return false;
    final minIndex = selectedIndices.reduce((a, b) => a < b ? a : b);
    final maxIndex = selectedIndices.reduce((a, b) => a > b ? a : b);
    return index > minIndex && index < maxIndex;
  }

  bool _isSlotSelectable(Map<String, dynamic> slot, int index,
      List<Map<String, dynamic>> allSlots) {
    // Must be available
    if (slot['status'] != 'AVAILABLE') return false;

    // If no slots selected, any available slot is selectable
    if (_selectedSlots.isEmpty) return true;

    // If already selected, it's selectable (to deselect)
    if (_isSlotSelected(slot)) return true;

    // Check if the slot is adjacent to the current selection
    final selectedIndices = _selectedSlots
        .map((s) => allSlots.indexWhere((slot) => slot['time'] == s['time']))
        .where((idx) => idx != -1)
        .toList();

    final minIndex = selectedIndices.reduce((a, b) => a < b ? a : b);
    final maxIndex = selectedIndices.reduce((a, b) => a > b ? a : b);

    // Can only select slots immediately adjacent to current selection
    // to maintain consecutiveness
    if (index == minIndex - 1 || index == maxIndex + 1) {
      // Check if all slots between would be consecutive and available
      return true;
    }

    return false;
  }

  void _toggleSlotSelection(Map<String, dynamic> slot, int index,
      List<Map<String, dynamic>> allSlots) {
    setState(() {
      if (_isSlotSelected(slot)) {
        // Deselect this slot - but only allow deselecting from the edges
        // to maintain consecutiveness
        final selectedIndices = _selectedSlots
            .map(
                (s) => allSlots.indexWhere((slot) => slot['time'] == s['time']))
            .where((idx) => idx != -1)
            .toList();

        final minIndex = selectedIndices.reduce((a, b) => a < b ? a : b);
        final maxIndex = selectedIndices.reduce((a, b) => a > b ? a : b);

        // Can only deselect edge slots to maintain consecutiveness
        if (index == minIndex || index == maxIndex) {
          _selectedSlots =
              _selectedSlots.where((s) => s['time'] != slot['time']).toList();
        }
      } else {
        // Select this slot - must be adjacent to current selection
        if (_selectedSlots.isEmpty) {
          _selectedSlots = [slot];
        } else {
          final selectedIndices = _selectedSlots
              .map((s) =>
                  allSlots.indexWhere((slot) => slot['time'] == s['time']))
              .where((idx) => idx != -1)
              .toList();

          final minIndex = selectedIndices.reduce((a, b) => a < b ? a : b);
          final maxIndex = selectedIndices.reduce((a, b) => a > b ? a : b);

          if (index == minIndex - 1) {
            // Add to the beginning
            _selectedSlots = [slot, ..._selectedSlots];
          } else if (index == maxIndex + 1) {
            // Add to the end
            _selectedSlots = [..._selectedSlots, slot];
          }
          // Otherwise don't select (non-consecutive)
        }
      }
    });
  }

  Future<void> _showWriteReviewSheet() async {
    final venueId = _venueId;
    if (venueId == null || venueId.isEmpty) return;

    final bookingIdController = TextEditingController();
    final commentController = TextEditingController();
    double rating = 5;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Write Review', style: AppText.h3),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: bookingIdController,
                    decoration: const InputDecoration(
                      labelText: 'Booking ID',
                      hintText: 'Enter completed booking ID',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Rating: ${rating.toStringAsFixed(1)}',
                      style: AppText.bodySm),
                  Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: rating,
                    label: rating.toStringAsFixed(1),
                    onChanged: (value) => setSheetState(() => rating = value),
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final bookingId = bookingIdController.text.trim();
                        if (bookingId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Booking ID is required')),
                          );
                          return;
                        }

                        try {
                          await _venuesService.createVenueReview(
                            venueId: venueId,
                            bookingId: bookingId,
                            rating: rating.round(),
                            comment: commentController.text,
                          );
                          if (!mounted) return;
                          Navigator.of(this.context).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text('Review submitted successfully')),
                          );
                          _loadVenueDetail();
                        } on VenueApiException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text('Could not submit review')),
                          );
                        }
                      },
                      child: const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading && _venue == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _venue == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('Venue'),
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.txtDisabled),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage ?? 'Could not load venue details.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.txtDisabled),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: _loadVenueDetail,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final venue = _venue;
    if (venue == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('Venue'),
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
        ),
        body: const Center(child: Text('Venue not found')),
      );
    }

    final courts = (venue['courts'] as List?) ?? const [];
    if (courts.isEmpty) {
      _courtIdx = 0;
      _selectedSlots = const <Map<String, dynamic>>[];
    }

    final selectedCourt = courts.isNotEmpty
        ? courts[_courtIdx] as Map<String, dynamic>
        : const <String, dynamic>{};
    final isVerified = venue['isVerified'] == true;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: _selectedSlots.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 380;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(
                        _spaceLg, _spaceMd, _spaceLg, _spaceMd),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getSelectedTimeRange(),
                                style: textTheme.titleSmall,
                              ),
                              const SizedBox(height: _spaceXs),
                              Text(
                                '${_getSelectedDuration()} • ${selectedCourt['name'] ?? 'Court'}',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: _spaceMd),
                              SizedBox(
                                width: double.infinity,
                                child: FutsButton(
                                  label: 'Continue',
                                  onPressed: () => _showSlotSheet(
                                      context,
                                      _selectedSlots.first,
                                      _selectedSlots.last,
                                      venue),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getSelectedTimeRange(),
                                      style: textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: _spaceXs),
                                    Text(
                                      '${_getSelectedDuration()} • ${selectedCourt['name'] ?? 'Court'}',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: _spaceMd),
                              SizedBox(
                                width: 170,
                                child: FutsButton(
                                  label: 'Continue',
                                  onPressed: () => _showSlotSheet(
                                      context,
                                      _selectedSlots.first,
                                      _selectedSlots.last,
                                      venue),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
      body: CustomScrollView(
        controller: _detailScrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _showCollapsedTitle ? 1 : 0,
              child: Text(
                venue['name'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: venue['coverUrl'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.scrim.withValues(alpha: 0.06),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.98),
                        ],
                        stops: const [0.32, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.62),
                ),
                icon: Icon(Icons.share, color: colorScheme.onSurface),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon')),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                _spaceLg,
                AppSpacing.pagePadding,
                _space2xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue['name'] ?? '',
                          style: textTheme.headlineSmall,
                        ),
                      ),
                      if (isVerified)
                        Icon(
                          Icons.verified_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: _spaceSm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: _spaceSm),
                      Expanded(
                        child: Text(
                          venue['address'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _spaceMd),
                  Wrap(
                    spacing: _spaceSm,
                    runSpacing: _spaceSm,
                    children: [
                      _MetaPill(
                        icon: isVerified
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                        label: isVerified ? 'Verified Venue' : 'Standard Venue',
                      ),
                      _MetaPill(
                        icon: Icons.star_rounded,
                        label: '${venue['rating']} (${venue['reviewCount']})',
                      ),
                      _MetaPill(
                        icon: Icons.sports_soccer_rounded,
                        label: '${courts.length} Courts',
                      ),
                      if (venue['distance'] != null)
                        _MetaPill(
                          icon: Icons.near_me_rounded,
                          label: venue['distance'],
                        ),
                    ],
                  ),
                  const SizedBox(height: _spaceXl),

                  _SectionCard(
                    title: 'Amenities',
                    child: Wrap(
                      spacing: _spaceSm,
                      runSpacing: _spaceSm,
                      children: (venue['amenities'] as List).map((a) {
                        return Container(
                          padding: _VenueDetailSpacing.pillPadding,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _amenityIcons[a] ?? Icons.circle,
                                size: 15,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                a.toString(),
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: _spaceXl),

                  _SectionCard(
                    title: 'Select Court',
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: courts.asMap().entries.map((e) {
                          final bool isSelected = _courtIdx == e.key;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _courtIdx = e.key;
                                _selectedSlots = const <Map<String, dynamic>>[];
                              });
                              _loadAvailability();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                right:
                                    e.key == courts.length - 1 ? 0 : _spaceMd,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHigh,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusM),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.value['name'],
                                    style: AppText.h3.copyWith(
                                      fontSize: 16,
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: _spaceXs),
                                  Text(
                                    '${e.value['type']} · ${e.value['surface']}',
                                    style: AppText.label.copyWith(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                              .withValues(alpha: 0.7)
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: _spaceXl),

                  _SectionCard(
                    title: 'Select Date',
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs3,
                        vertical: AppSpacing.xs3,
                      ),
                      child: TableCalendar<dynamic>(
                        firstDay: DateUtils.dateOnly(DateTime.now()),
                        lastDay: DateUtils.dateOnly(
                          DateTime.now().add(const Duration(days: 30)),
                        ),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDate, day),
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month'
                        },
                        daysOfWeekHeight: 22,
                        rowHeight: 44,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.txtPrimary,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.txtPrimary,
                          ),
                          titleTextStyle: AppText.h3.copyWith(fontSize: 18),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: AppText.label.copyWith(
                            color: AppColors.txtDisabled,
                          ),
                          weekendStyle: AppText.label.copyWith(
                            color: AppColors.txtDisabled,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: AppText.bodySm,
                          weekendTextStyle: AppText.bodySm,
                          outsideTextStyle: AppText.label.copyWith(
                            color:
                                AppColors.txtDisabled.withValues(alpha: 0.45),
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: AppText.body.copyWith(
                            color: AppColors.green,
                            fontWeight: AppFontWeights.semiBold,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: AppText.body.copyWith(
                            color: AppColors.bgPrimary,
                            fontWeight: AppFontWeights.semiBold,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDate = DateUtils.dateOnly(selectedDay);
                            _focusedDay = DateUtils.dateOnly(focusedDay);
                            _selectedSlots = const <Map<String, dynamic>>[];
                          });
                          _loadAvailability();
                        },
                        onPageChanged: (focusedDay) {
                          setState(() =>
                              _focusedDay = DateUtils.dateOnly(focusedDay));
                        },
                      ),
                    ),
                  ),

                  // Available Slots
                  const SizedBox(height: _spaceXl),
                  _SectionCard(
                    title: 'Available Slots',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedDate == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                            ),
                            child: Text(
                              'Pick a date from the date strip to view available slots.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (_selectedDate != null) ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool compactHeader =
                                  constraints.maxWidth < 390;
                              final title = Text(
                                DateFormat('EEE, MMM d').format(_selectedDate!),
                                style: textTheme.titleLarge,
                              );
                              final legend = Wrap(
                                spacing: _spaceMd,
                                runSpacing: _spaceSm,
                                children: [
                                  _LegendDot(colorScheme.primary, 'Available'),
                                  _LegendDot(colorScheme.error, 'Unavailable'),
                                  _LegendDot(colorScheme.primary, 'Selected',
                                      isFilled: true),
                                ],
                              );

                              if (compactHeader) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    title,
                                    const SizedBox(height: _spaceSm),
                                    legend,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: title),
                                  const SizedBox(width: _spaceMd),
                                  legend,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: _spaceMd),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const double spacing = _spaceMd;
                              final int columns =
                                  constraints.maxWidth < 360 ? 2 : 3;
                              final double chipWidth = (constraints.maxWidth -
                                      (spacing * (columns - 1))) /
                                  columns;

                              final slots = _availabilitySlots;

                              if (_isLoadingAvailability) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: _spaceXl),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (_availabilityError != null) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHigh,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusM),
                                  ),
                                  child: Text(
                                    _availabilityError!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }

                              if (slots.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHigh,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusM),
                                  ),
                                  child: Text(
                                    'No slots available for this date.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children:
                                        slots.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final slot = entry.value;
                                      final bool isSelected =
                                          _isSlotSelected(slot);
                                      final bool isSelectable =
                                          _isSlotSelectable(slot, index, slots);

                                      return SizedBox(
                                        width: chipWidth,
                                        child: _SlotChip(
                                          slot: slot,
                                          isSelected: isSelected,
                                          isInRange:
                                              _isSlotInSelectedRange(index),
                                          onTap: isSelectable
                                              ? () => _toggleSlotSelection(
                                                  slot, index, slots)
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (_selectedSlots.isNotEmpty) ...[
                                    const SizedBox(height: _spaceMd),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: _spaceMd,
                                        vertical: _spaceSm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusM),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: _spaceSm),
                                          Flexible(
                                            child: Text(
                                              'Only consecutive time slots can be selected',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Reviews
                  const SizedBox(height: _spaceXl),
                  _SectionCard(
                    title: 'Reviews',
                    trailing: TextButton(
                      onPressed: _showWriteReviewSheet,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: _VenueDetailSpacing.pillPadding,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        textStyle: textTheme.labelSmall,
                      ),
                      child: const Text('Write review'),
                    ),
                    child: _buildReviews(venue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSlotSheet(BuildContext ctx, Map<String, dynamic> firstSlot,
      Map<String, dynamic> lastSlot, Map<String, dynamic> venue) {
    final courts = (venue['courts'] as List?) ?? const [];
    final colorScheme = Theme.of(ctx).colorScheme;
    final textTheme = Theme.of(ctx).textTheme;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double horizontalPad =
                  (MediaQuery.of(ctx).size.width * 0.07)
                      .clamp(_spaceLg.toDouble(), _space2xl);
              String selectedBookingMode = _bookingMode;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      _spaceXl,
                      horizontalPad,
                      _spaceLg,
                    ),
                    margin: const EdgeInsets.only(top: _space2xl * 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusM),
                      ),
                    ),
                    child: StatefulBuilder(
                      builder: (context, setSheetState) {
                        final isSolo = selectedBookingMode == 'solo';
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: _spaceXl),
                            Text(
                              'Confirm Slot',
                              style: textTheme.headlineSmall,
                            ),
                            const SizedBox(height: _spaceLg),
                            FutsCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          courts[_courtIdx]['name'],
                                          style: AppText.h3,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${courts[_courtIdx]['type']} · ${courts[_courtIdx]['surface']}',
                                          style: AppText.bodySm,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: _spaceMd),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${firstSlot['time']} – ${lastSlot['endTime']}',
                                        style: AppText.h3,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                          '${_selectedSlots.length * 60} minutes',
                                          style: AppText.bodySm),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _spaceMd),
                            FutsCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking Type',
                                      style: textTheme.titleSmall),
                                  const SizedBox(height: _spaceSm),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text('Solo Booking'),
                                          selected: isSolo,
                                          onSelected: (_) {
                                            setSheetState(() =>
                                                selectedBookingMode = 'solo');
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: _spaceSm),
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text('Full Futsal'),
                                          selected: !isSolo,
                                          onSelected: (_) {
                                            setSheetState(() =>
                                                selectedBookingMode = 'full');
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: _spaceSm),
                                  Text(
                                    isSolo
                                        ? 'Solo creates an open match where others can join.'
                                        : 'Full futsal reserves the full court for your group.',
                                    style: AppText.bodySm,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _spaceXl),
                            Row(
                              children: [
                                Text('Total', style: textTheme.titleSmall),
                                const Spacer(),
                                Text(
                                  'Price shown at payment',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: _VenueDetailSpacing.smallGap),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Hold fee NPR 20 (non-refundable)',
                                style: AppText.label,
                              ),
                            ),
                            const SizedBox(height: _space2xl),
                            FutsButton(
                              label: 'Hold This Slot — 7 min',
                              onPressed: () {
                                final selectedDate = _selectedDate;
                                final selectedCourt =
                                    courts[_courtIdx] as Map<String, dynamic>;
                                _bookingMode = selectedBookingMode;
                                Navigator.pop(ctx);
                                Navigator.pushNamed(
                                  ctx,
                                  '/booking-hold',
                                  arguments: {
                                    'slot': firstSlot,
                                    'venue': venue,
                                    'courtIdx': _courtIdx,
                                    'courtId': selectedCourt['id'],
                                    'bookingDate': selectedDate == null
                                        ? null
                                        : _formatApiDate(selectedDate),
                                    'startTime': firstSlot['time'],
                                    'endTime': lastSlot['endTime'],
                                    'bookingMode': selectedBookingMode,
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: _spaceLg),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReviews(Map<String, dynamic> venue) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reviews = (venue['reviews'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];

    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Text(
          'No reviews yet. Be the first to review this venue.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: reviews.take(3).toList().asMap().entries.map(
        (entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == reviews.take(3).length - 1 ? 0 : _spaceMd,
            ),
            child: _ReviewCard(entry.value),
          );
        },
      ).toList(),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isFilled;

  const _LegendDot(this.color, this.label, {this.isFilled = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : null,
            border: Border.all(
              color: color,
              width: isFilled ? 0 : 2,
            ),
          ),
        ),
        const SizedBox(width: _VenueDetailSpacing.smallGap),
        Text(label, style: textTheme.labelMedium),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    return Container(
      padding: _VenueDetailSpacing.pillPadding,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: _VenueDetailSpacing.smallGap),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: _VenueDetailSpacing.sectionHeaderGap),
        child,
        const SizedBox(height: _VenueDetailSpacing.sectionGap),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  final Map<String, dynamic> slot;
  final bool isSelected;
  final bool isInRange;
  final VoidCallback? onTap;

  const _SlotChip({
    required this.slot,
    required this.isSelected,
    this.isInRange = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    final bool isUnavailable = slot['status'] == 'UNAVAILABLE';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          color: isSelected
              ? colorScheme.primary
              : isInRange
                  ? colorScheme.primary.withValues(alpha: 0.16)
                  : isUnavailable
                      ? colorScheme.error.withValues(alpha: 0.08)
                      : colorScheme.surfaceContainerHigh,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot['time'],
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: AppFontWeights.semiBold,
                color: isSelected
                    ? colorScheme.onPrimary
                    : isInRange
                        ? colorScheme.primary
                        : isUnavailable
                            ? colorScheme.error
                            : colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              slot['status'] == 'AVAILABLE' ? 'Available' : 'Unavailable',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary.withValues(alpha: 0.85)
                    : isInRange
                        ? colorScheme.primary.withValues(alpha: 0.85)
                        : isUnavailable
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> r;

  const _ReviewCard(this.r);

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    final rating = (r['rating'] as num?)?.toDouble() ?? 0;
    final String author = (r['author'] as String?) ?? '';
    final String authorInitial = author.isNotEmpty ? author[0] : '?';

    return Container(
      padding: _VenueDetailSpacing.reviewCardPadding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                alignment: Alignment.center,
                child: Text(
                  authorInitial,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (idx) => Padding(
                            padding: const EdgeInsets.only(
                                right: AppSpacing.xxs / 2),
                            child: Icon(
                              idx < rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Text(r['date'], style: theme.textTheme.labelMedium),
              ),
            ],
          ),
          const SizedBox(height: _VenueDetailSpacing.sectionHeaderGap),
          Text(
            r['text'],
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}
