import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/design_system/app_spacing.dart';
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
  Map<String, dynamic>? _selectedSlot;
  List<Map<String, dynamic>> _availabilitySlots =
      const <Map<String, dynamic>>[];
  bool _isLoadingAvailability = false;
  String? _availabilityError;

  final Map<String, IconData> _amenityIcons = {
    'Parking': Icons.local_parking,
    'Changing Room': Icons.checkroom_outlined,
    'Floodlights': Icons.highlight_outlined,
    'Cafeteria': Icons.restaurant_outlined,
  };

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
          _selectedSlot = null;
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
      _selectedSlot = null;
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
    if (_isLoading && _venue == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
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
      _selectedSlot = null;
    }

    final selectedCourt = courts.isNotEmpty
        ? courts[_courtIdx] as Map<String, dynamic>
        : const <String, dynamic>{};
    final isVerified = venue['isVerified'] == true;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      bottomNavigationBar: _selectedSlot == null
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
                      color: AppColors.bgSurface,
                      border:
                          Border(top: BorderSide(color: AppColors.borderClr)),
                    ),
                    child: isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_selectedSlot!['time']} - ${_selectedSlot!['endTime']}',
                                style: AppText.body.copyWith(
                                    fontWeight: AppTextStyles.semiBold),
                              ),
                              const SizedBox(height: _spaceXs),
                              Text(
                                '${_selectedSlot!['status'] == 'AVAILABLE' ? 'Price shown at payment' : 'Unavailable'} • ${selectedCourt['name'] ?? 'Court'}',
                                style: AppText.label
                                    .copyWith(color: AppColors.txtDisabled),
                              ),
                              const SizedBox(height: _spaceMd),
                              SizedBox(
                                width: double.infinity,
                                child: FutsButton(
                                  label: 'Continue',
                                  onPressed: () => _showSlotSheet(
                                      context, _selectedSlot!, venue),
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
                                      '${_selectedSlot!['time']} - ${_selectedSlot!['endTime']}',
                                      style: AppText.body.copyWith(
                                          fontWeight: AppTextStyles.semiBold),
                                    ),
                                    const SizedBox(height: _spaceXs),
                                    Text(
                                      '${_selectedSlot!['status'] == 'AVAILABLE' ? 'Price shown at payment' : 'Unavailable'} • ${selectedCourt['name'] ?? 'Court'}',
                                      style: AppText.label.copyWith(
                                          color: AppColors.txtDisabled),
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
                                      context, _selectedSlot!, venue),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.bgPrimary,
            iconTheme: IconThemeData(color: AppColors.txtPrimary),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                venue['name'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.h3.copyWith(fontSize: 17),
              ),
              titlePadding: const EdgeInsets.only(
                  left: 56, bottom: _spaceLg, right: _spaceLg),
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
                          Colors.transparent,
                          AppColors.bgPrimary.withValues(alpha: 0.95),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: _spaceLg,
                    right: _spaceLg,
                    bottom: 72,
                    child: Row(
                      children: [
                        Container(
                          padding: _VenueDetailSpacing.pillPadding,
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    AppColors.borderClr.withValues(alpha: 0.7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 16, color: AppColors.amber),
                              const SizedBox(width: _spaceXs),
                              Text(
                                '${venue['rating']} (${venue['reviewCount']})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.bodySm.copyWith(
                                  color: AppColors.txtPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: _spaceSm),
                        if (venue['distance'] != null)
                          Container(
                            padding: _VenueDetailSpacing.pillPadding,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.bgPrimary.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: AppColors.borderClr
                                      .withValues(alpha: 0.7)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me_rounded,
                                    size: 14, color: AppColors.green),
                                const SizedBox(width: _spaceXs),
                                Text(
                                  venue['distance'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.bodySm.copyWith(
                                    color: AppColors.txtPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.bgPrimary.withValues(alpha: 0.4),
                ),
                icon: Icon(Icons.share, color: AppColors.txtPrimary),
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
                  _spaceLg, _spaceLg, _spaceLg, _space2xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutsCard(
                    backgroundColor: AppColors.bgSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue['name'],
                            style: AppText.h2.copyWith(fontSize: 26)),
                        const SizedBox(height: _spaceSm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: AppColors.txtDisabled),
                            const SizedBox(width: _spaceSm),
                            Expanded(
                              child: Text(
                                venue['address'],
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body
                                    .copyWith(color: AppColors.txtDisabled),
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
                              label: isVerified
                                  ? 'Verified Venue'
                                  : 'Standard Venue',
                            ),
                            _MetaPill(
                              icon: Icons.sports_soccer_rounded,
                              label: '${courts.length} Courts',
                            ),
                          ],
                        ),
                      ],
                    ),
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
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.borderClr),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_amenityIcons[a] ?? Icons.circle,
                                  size: 15, color: AppColors.txtDisabled),
                              const SizedBox(width: 6),
                              Text(a.toString(), style: AppText.bodySm),
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
                                _selectedSlot = null;
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
                                    ? AppColors.green
                                    : AppColors.bgElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: !isSelected
                                    ? Border.all(color: AppColors.borderClr)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.green
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
                                          ? AppColors.bgPrimary
                                          : AppColors.txtPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: _spaceXs),
                                  Text(
                                    '${e.value['type']} · ${e.value['surface']}',
                                    style: AppText.label.copyWith(
                                      color: isSelected
                                          ? AppColors.bgPrimary
                                              .withValues(alpha: 0.7)
                                          : AppColors.txtDisabled,
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
                        border: Border.all(color: AppColors.borderClr),
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
                            fontWeight: AppTextStyles.semiBold,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: AppText.body.copyWith(
                            color: AppColors.bgPrimary,
                            fontWeight: AppTextStyles.semiBold,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDate = DateUtils.dateOnly(selectedDay);
                            _focusedDay = DateUtils.dateOnly(focusedDay);
                            _selectedSlot = null;
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
                              color: AppColors.bgElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderClr),
                            ),
                            child: Text(
                              'Pick a date from the calendar to view available slots.',
                              style: AppText.bodySm
                                  .copyWith(color: AppColors.txtDisabled),
                            ),
                          ),
                        if (_selectedDate != null) ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool compactHeader =
                                  constraints.maxWidth < 390;
                              final title = Text(
                                DateFormat('EEE, MMM d').format(_selectedDate!),
                                style: AppText.h3.copyWith(fontSize: 18),
                              );
                              final legend = Wrap(
                                spacing: _spaceMd,
                                runSpacing: _spaceSm,
                                children: [
                                  _LegendDot(AppColors.green, 'Available'),
                                  _LegendDot(AppColors.red, 'Unavailable'),
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
                                    color: AppColors.bgElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.borderClr),
                                  ),
                                  child: Text(
                                    _availabilityError!,
                                    style: AppText.bodySm
                                        .copyWith(color: AppColors.txtDisabled),
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
                                    color: AppColors.bgElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.borderClr),
                                  ),
                                  child: Text(
                                    'No slots available for this date.',
                                    style: AppText.bodySm
                                        .copyWith(color: AppColors.txtDisabled),
                                  ),
                                );
                              }

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: slots.map((slot) {
                                  final bool isSelected = _selectedSlot !=
                                          null &&
                                      _selectedSlot?['time'] == slot['time'];

                                  return SizedBox(
                                    width: chipWidth,
                                    child: _SlotChip(
                                      slot: slot,
                                      isSelected: isSelected,
                                      onTap: slot['status'] == 'AVAILABLE'
                                          ? () => setState(
                                              () => _selectedSlot = slot)
                                          : null,
                                    ),
                                  );
                                }).toList(),
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
                        foregroundColor: AppColors.green,
                        padding: _VenueDetailSpacing.pillPadding,
                        backgroundColor: AppColors.green.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

  void _showSlotSheet(
      BuildContext ctx, Map<String, dynamic> slot, Map<String, dynamic> venue) {
    final courts = (venue['courts'] as List?) ?? const [];
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
                      color: AppColors.bgSurface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderClr,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: _spaceXl),
                        Text('Confirm Slot', style: AppText.h2),
                        const SizedBox(height: _spaceLg),
                        FutsCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    '${slot['time']} – ${slot['endTime']}',
                                    style: AppText.h3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text('60 minutes', style: AppText.bodySm),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: _spaceXl),
                        Row(
                          children: [
                            Text('Total', style: AppText.body),
                            const Spacer(),
                            Text(
                              'Price shown at payment',
                              style: GoogleFonts.poppins(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _VenueDetailSpacing.smallGap),
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
                            Navigator.pop(ctx);
                            Navigator.pushNamed(
                              ctx,
                              '/booking-hold',
                              arguments: {
                                'slot': slot,
                                'venue': venue,
                                'courtIdx': _courtIdx,
                                'courtId': selectedCourt['id'],
                                'bookingDate': selectedDate == null
                                    ? null
                                    : _formatApiDate(selectedDate),
                                'startTime': slot['time'],
                                'endTime': slot['endTime'],
                              },
                            );
                          },
                        ),
                        const SizedBox(height: _spaceLg),
                      ],
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
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderClr),
        ),
        child: Text(
          'No reviews yet. Be the first to review this venue.',
          style: AppText.bodySm.copyWith(color: AppColors.txtDisabled),
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

  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: _VenueDetailSpacing.smallGap),
        Text(label, style: AppText.label),
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
    return Container(
      padding: _VenueDetailSpacing.pillPadding,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderClr),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.green),
          const SizedBox(width: _VenueDetailSpacing.smallGap),
          Text(label,
              style: AppText.label.copyWith(color: AppColors.txtPrimary)),
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
    return FutsCard(
      backgroundColor: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.h3.copyWith(
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: _VenueDetailSpacing.sectionHeaderGap),
          child,
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final Map<String, dynamic> slot;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SlotChip({
    required this.slot,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? AppColors.green.withValues(alpha: 0.15)
              : slot['status'] == 'UNAVAILABLE'
                  ? AppColors.red.withValues(alpha: 0.07)
                  : AppColors.bgElevated,
          border: Border.all(
            color: isSelected
                ? AppColors.green
                : slot['status'] == 'UNAVAILABLE'
                    ? AppColors.red.withValues(alpha: 0.5)
                    : AppColors.borderClr,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot['time'],
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: AppTextStyles.semiBold,
                color: isSelected
                    ? AppColors.green
                    : slot['status'] == 'UNAVAILABLE'
                        ? AppColors.red
                        : AppColors.txtPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              slot['status'] == 'AVAILABLE' ? 'Available' : 'Unavailable',
              style: AppText.label.copyWith(
                color: isSelected
                    ? AppColors.green.withValues(alpha: 0.8)
                    : slot['status'] == 'UNAVAILABLE'
                        ? AppColors.red
                        : AppColors.txtDisabled,
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
    final rating = (r['rating'] as num?)?.toDouble() ?? 0;
    final String author = (r['author'] as String?) ?? '';
    final String authorInitial = author.isNotEmpty ? author[0] : '?';

    return FutsCard(
      padding: _VenueDetailSpacing.reviewCardPadding,
      backgroundColor: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(16),
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
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderClr),
                ),
                alignment: Alignment.center,
                child: Text(
                  authorInitial,
                  style:
                      AppText.body.copyWith(fontWeight: AppTextStyles.semiBold),
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
                      style: AppText.body
                          .copyWith(fontWeight: AppTextStyles.semiBold),
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
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppText.label.copyWith(
                            color: AppColors.amber,
                            fontWeight: AppTextStyles.semiBold,
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
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderClr),
                ),
                child: Text(r['date'], style: AppText.label),
              ),
            ],
          ),
          const SizedBox(height: _VenueDetailSpacing.sectionHeaderGap),
          Text(
            r['text'],
            style: AppText.bodySm.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}
