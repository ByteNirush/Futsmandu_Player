import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/futs_button.dart';
import '../venues/data/services/player_venues_service.dart';

class BookCourtScreen extends StatefulWidget {
  const BookCourtScreen({super.key});

  @override
  State<BookCourtScreen> createState() => _BookCourtScreenState();
}

class _BookCourtScreenState extends State<BookCourtScreen> {
  // Use AppSpacing constants from design system directly in code
  static const double _spaceMd = AppSpacing.md;    // 24 - used for step indicator width

  final PlayerVenuesService _venuesService = PlayerVenuesService.instance;

  int _currentStep = 0;

  // Step 0: Select Court
  int? _selectedCourtIdx;

  // Step 1: Select Date & Time
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _availabilitySlots = const [];
  bool _isLoadingSlots = false;
  String? _slotsError;
  List<Map<String, dynamic>> _selectedSlots = const [];

  // Step 2: Booking Details
  String _bookingType = 'full';
  final _maxPlayersController = TextEditingController(text: '10');

  Map<String, dynamic>? _venue;
  List<Map<String, dynamic>> _courts = const [];
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _venue = args;
      _courts = ((args['courts'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      // Initialize from venue details if provided
      final initialCourtIdx = args['initialCourtIdx'] as int?;
      final initialDate = args['initialDate'] as DateTime?;
      if (initialCourtIdx != null &&
          initialCourtIdx >= 0 &&
          initialCourtIdx < _courts.length) {
        _selectedCourtIdx = initialCourtIdx;
      }
      if (initialDate != null) {
        _selectedDate = initialDate;
        _focusedDay = initialDate;
        // Load slots for the initial date if court is also selected
        if (_selectedCourtIdx != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadSlots();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _maxPlayersController.dispose();
    super.dispose();
  }

  String _formatApiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSlots() async {
    final venue = _venue;
    final date = _selectedDate;
    final courtIdx = _selectedCourtIdx;
    if (venue == null || date == null || courtIdx == null) return;

    final court = _courts[courtIdx];
    final courtId = (court['id'] as String?) ?? '';
    final venueId = (venue['id'] as String?) ?? '';
    if (courtId.isEmpty || venueId.isEmpty) return;

    setState(() {
      _isLoadingSlots = true;
      _slotsError = null;
      _selectedSlots = const [];
    });

    try {
      final slots = await _venuesService.getVenueAvailability(
        venueId: venueId,
        courtId: courtId,
        date: _formatApiDate(date),
      );
      if (!mounted) return;
      setState(() {
        _availabilitySlots = slots;
        _isLoadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availabilitySlots = const [];
        _slotsError = 'Could not load slots. Please try again.';
        _isLoadingSlots = false;
      });
    }
  }

  bool _isSlotSelected(Map<String, dynamic> slot) =>
      _selectedSlots.any((s) => s['time'] == slot['time']);

  bool _isSlotInRange(int index) {
    if (_selectedSlots.isEmpty) return false;
    final indices = _selectedSlots
        .map((s) =>
            _availabilitySlots.indexWhere((sl) => sl['time'] == s['time']))
        .where((i) => i != -1)
        .toList();
    if (indices.isEmpty) return false;
    final min = indices.reduce((a, b) => a < b ? a : b);
    final max = indices.reduce((a, b) => a > b ? a : b);
    return index > min && index < max;
  }

  bool _canSelectSlot(Map<String, dynamic> slot, int index) {
    if (slot['status'] != 'AVAILABLE') return false;
    if (_selectedSlots.isEmpty) return true;
    if (_isSlotSelected(slot)) return true;
    final indices = _selectedSlots
        .map((s) =>
            _availabilitySlots.indexWhere((sl) => sl['time'] == s['time']))
        .where((i) => i != -1)
        .toList();
    final min = indices.reduce((a, b) => a < b ? a : b);
    final max = indices.reduce((a, b) => a > b ? a : b);
    return index == min - 1 || index == max + 1;
  }

  void _toggleSlot(Map<String, dynamic> slot, int index) {
    setState(() {
      if (_isSlotSelected(slot)) {
        final indices = _selectedSlots
            .map((s) =>
                _availabilitySlots.indexWhere((sl) => sl['time'] == s['time']))
            .where((i) => i != -1)
            .toList();
        final min = indices.reduce((a, b) => a < b ? a : b);
        final max = indices.reduce((a, b) => a > b ? a : b);
        if (index == min || index == max) {
          _selectedSlots =
              _selectedSlots.where((s) => s['time'] != slot['time']).toList();
        }
      } else {
        if (_selectedSlots.isEmpty) {
          _selectedSlots = [slot];
        } else {
          final indices = _selectedSlots
              .map((s) =>
                  _availabilitySlots.indexWhere((sl) => sl['time'] == s['time']))
              .where((i) => i != -1)
              .toList();
          final min = indices.reduce((a, b) => a < b ? a : b);
          final max = indices.reduce((a, b) => a > b ? a : b);
          if (index == min - 1) {
            _selectedSlots = [slot, ..._selectedSlots];
          } else if (index == max + 1) {
            _selectedSlots = [..._selectedSlots, slot];
          }
        }
      }
    });
  }

  String _getTimeRange() {
    if (_selectedSlots.isEmpty) return '';
    return '${_selectedSlots.first['time']} – ${_selectedSlots.last['endTime']}';
  }

  bool _canAdvance() {
    switch (_currentStep) {
      case 0:
        return _selectedCourtIdx != null;
      case 1:
        return _selectedDate != null && _selectedSlots.isNotEmpty;
      case 2:
        if (_bookingType == 'partial') {
          final val = int.tryParse(_maxPlayersController.text.trim()) ?? 0;
          return val >= 2;
        }
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _advance() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _confirmBooking();
    }
  }

  void _confirmBooking() {
    final venue = _venue;
    final courtIdx = _selectedCourtIdx;
    final date = _selectedDate;
    if (venue == null ||
        courtIdx == null ||
        date == null ||
        _selectedSlots.isEmpty) {
      return;
    }

    final court = _courts[courtIdx];
    final bookingMode = _bookingType == 'full' ? 'full' : 'solo';

    Navigator.pushNamed(
      context,
      '/booking-hold',
      arguments: {
        'slot': _selectedSlots.first,
        'venue': venue,
        'courtIdx': courtIdx,
        'courtId': court['id'],
        'bookingDate': _formatApiDate(date),
        'startTime': _selectedSlots.first['time'],
        'endTime': _selectedSlots.last['endTime'],
        'bookingMode': bookingMode,
        if (_bookingType == 'partial')
          'maxPlayers':
              int.tryParse(_maxPlayersController.text.trim()) ?? 10,
      },
    );
  }

  static const _stepTitles = [
    'Select Court',
    'Date & Time',
    'Booking Details',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Book Court', style: textTheme.titleLarge),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.sm,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        child: Column(
          children: List.generate(_stepTitles.length, (i) {
            debugPrint('Building step $i: ${_stepTitles[i]}, currentStep=$_currentStep');
            final isActive = i == _currentStep;
            final isCompleted = i < _currentStep;
            final isLast = i == _stepTitles.length - 1;

            return Row(
              key: ValueKey('step_$i'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      _StepCircle(
                        number: i + 1,
                        isActive: isActive,
                        isCompleted: isCompleted,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: isActive
                              ? (isCompleted ? 60 : 200)
                              : (isCompleted ? 60 : 40),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: isCompleted
                              ? colorScheme.primary
                              : colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: _spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          _stepTitles[i],
                          style: textTheme.titleMedium?.copyWith(
                            color: isActive || isCompleted
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontWeight: isActive
                                ? AppFontWeights.semiBold
                                : AppFontWeights.medium,
                          ),
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _buildStepSummary(i, colorScheme, textTheme),
                        const SizedBox(height: AppSpacing.md),
                      ] else if (isActive) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildStepContent(i, colorScheme, textTheme),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: FutsButton(
                            label: i == 3 ? 'Confirm Booking' : 'Continue',
                            onPressed: _canAdvance() ? _advance : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ] else ...[
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepSummary(
      int step, ColorScheme colorScheme, TextTheme textTheme) {
    switch (step) {
      case 0:
        if (_selectedCourtIdx == null) return const SizedBox.shrink();
        final court = _courts[_selectedCourtIdx!];
        return Text(
          '${court['name']}  •  ${court['type']}',
          style:
              textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
        );
      case 1:
        if (_selectedDate == null) return const SizedBox.shrink();
        return Text(
          '${DateFormat('EEE, MMM d').format(_selectedDate!)}  •  ${_getTimeRange()}',
          style:
              textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
        );
      case 2:
        final label = _bookingType == 'full' ? 'Full Team' : 'Partial Team';
        final extra = _bookingType == 'partial'
            ? '  •  Max ${_maxPlayersController.text} players'
            : '';
        return Text(
          '$label$extra',
          style:
              textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepContent(
      int step, ColorScheme colorScheme, TextTheme textTheme) {
    switch (step) {
      case 0:
        return _buildSelectCourt(colorScheme, textTheme);
      case 1:
        return _buildSelectDateTime(colorScheme, textTheme);
      case 2:
        return _buildBookingDetails(colorScheme, textTheme);
      case 3:
        return _buildReview(colorScheme, textTheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectCourt(ColorScheme colorScheme, TextTheme textTheme) {
    if (_courts.isEmpty) {
      return Text(
        'No courts available for this venue.',
        style: textTheme.bodySmall
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }
    return Column(
      children: _courts.asMap().entries.map((e) {
        final idx = e.key;
        final court = e.value;
        final isSelected = _selectedCourtIdx == idx;
        final name = (court['name'] ?? 'Court').toString();
        final type = (court['type'] ?? '').toString();
        final surface = (court['surface'] ?? '').toString();
        final price =
            court['pricePerHour'] ?? court['price_per_hour'];
        final subtitle =
            [type, surface].where((s) => s.isNotEmpty).join(' · ');

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCourtIdx = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.35),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.sports_soccer_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: AppFontWeights.semiBold),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle,
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. $price',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: AppFontWeights.bold,
                          ),
                        ),
                        Text(
                          'per hour',
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectDateTime(
      ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: TableCalendar<dynamic>(
            firstDay: DateUtils.dateOnly(DateTime.now()),
            lastDay: DateUtils.dateOnly(
                DateTime.now().add(const Duration(days: 30))),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month'
            },
            daysOfWeekHeight: 22,
            rowHeight: 44,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left_rounded,
                  color: AppColors.txtPrimary),
              rightChevronIcon: Icon(Icons.chevron_right_rounded,
                  color: AppColors.txtPrimary),
              titleTextStyle: AppTypography.textTheme(Theme.of(context).colorScheme)
                  .titleLarge!
                  .copyWith(fontSize: 18),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTypography.textTheme(Theme.of(context).colorScheme)
                  .labelMedium!
                  .copyWith(color: AppColors.txtDisabled),
              weekendStyle: AppTypography.textTheme(Theme.of(context).colorScheme)
                  .labelMedium!
                  .copyWith(color: AppColors.txtDisabled),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: AppTypography.textTheme(Theme.of(context).colorScheme)
                  .bodyMedium!,
              weekendTextStyle: AppTypography.textTheme(Theme.of(context).colorScheme)
                  .bodyMedium!,
              outsideTextStyle: AppTypography.textTheme(Theme.of(context).colorScheme)
                  .bodySmall!
                  .copyWith(
                    color: AppColors.txtDisabled.withValues(alpha: 0.45),
                  ),
              todayDecoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              todayTextStyle: AppTypography.textTheme(Theme.of(context).colorScheme)
                  .bodyMedium!
                  .copyWith(
                    color: AppColors.green,
                    fontWeight: AppFontWeights.semiBold,
                  ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: AppTypography.textTheme(Theme.of(context).colorScheme)
                  .bodyMedium!
                  .copyWith(
                    color: AppColors.bgPrimary,
                    fontWeight: AppFontWeights.semiBold,
                  ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = DateUtils.dateOnly(selectedDay);
                _focusedDay = DateUtils.dateOnly(focusedDay);
                _selectedSlots = const [];
                _availabilitySlots = const [];
              });
              _loadSlots();
            },
            onPageChanged: (focusedDay) {
              setState(
                  () => _focusedDay = DateUtils.dateOnly(focusedDay));
            },
          ),
        ),
        if (_selectedDate != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Text(
              DateFormat('EEE, MMM d, y').format(_selectedDate!),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: AppFontWeights.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSlotGrid(colorScheme, textTheme),
        ],
      ],
    );
  }

  Widget _buildSlotGrid(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_slotsError != null) {
      return Text(_slotsError!,
          style:
              textTheme.bodySmall?.copyWith(color: colorScheme.error));
    }
    if (_availabilitySlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy_outlined,
                size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'No slots available for this date.',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth < 360 ? 2 : 3;
        final chipWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: _availabilitySlots.asMap().entries.map((e) {
                final index = e.key;
                final slot = e.value;
                final isSelected = _isSlotSelected(slot);
                final isInRange = _isSlotInRange(index);
                final canSelect = _canSelectSlot(slot, index);
                final isUnavailable = slot['status'] != 'AVAILABLE';

                return SizedBox(
                  width: chipWidth,
                  child: GestureDetector(
                    onTap: canSelect
                        ? () => _toggleSlot(slot, index)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 62,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusM),
                        color: isSelected
                            ? colorScheme.primary
                            : isInRange
                                ? colorScheme.primary
                                    .withValues(alpha: 0.16)
                                : isUnavailable
                                    ? colorScheme.error
                                        .withValues(alpha: 0.08)
                                    : colorScheme.surfaceContainerHigh,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.22),
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
                            style: AppTypography.textTheme(colorScheme)
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: AppFontWeights.semiBold,
                                  height: 1.2,
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : isInRange
                                          ? colorScheme.primary
                                          : isUnavailable
                                              ? colorScheme.error
                                              : colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            isUnavailable ? 'Unavailable' : 'Available',
                            style: textTheme.labelSmall?.copyWith(
                              height: 1.2,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                      .withValues(alpha: 0.85)
                                  : isInRange
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.85)
                                      : isUnavailable
                                          ? colorScheme.error
                                          : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedSlots.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Only consecutive time slots can be selected',
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBookingDetails(
      ColorScheme colorScheme, TextTheme textTheme) {
    final isFull = _bookingType == 'full';
    return Column(
      children: [
        _BookingTypeCard(
          title: 'Full Team',
          description: 'Book the full court for your group.',
          icon: Icons.group_rounded,
          isSelected: isFull,
          onTap: () => setState(() => _bookingType = 'full'),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppSpacing.xs),
        _BookingTypeCard(
          title: 'Partial Team',
          description: 'Create an open match where others can join.',
          icon: Icons.group_add_rounded,
          isSelected: !isFull,
          onTap: () => setState(() => _bookingType = 'partial'),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        if (!isFull) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Maximum players',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: AppFontWeights.semiBold,
                          )),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'How many players can join this match?',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _maxPlayersController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeights.semiBold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReview(ColorScheme colorScheme, TextTheme textTheme) {
    final venue = _venue;
    final courtIdx = _selectedCourtIdx;
    if (venue == null ||
        courtIdx == null ||
        _selectedDate == null ||
        _selectedSlots.isEmpty) {
      return Text(
        'Incomplete booking details.',
        style: textTheme.bodySmall
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    final court = _courts[courtIdx];
    final bookingTypeLabel =
        _bookingType == 'full' ? 'Full Team' : 'Partial Team';
    final courtLabel = '${court['name']}  •  ${court['type']}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewRow(
            icon: Icons.location_on_outlined,
            label: 'Venue',
            value: (venue['name'] ?? '').toString(),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const Divider(height: AppSpacing.lg),
          _ReviewRow(
            icon: Icons.sports_soccer_outlined,
            label: 'Court',
            value: courtLabel,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const Divider(height: AppSpacing.lg),
          _ReviewRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormat('EEE, MMM d, y').format(_selectedDate!),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const Divider(height: AppSpacing.lg),
          _ReviewRow(
            icon: Icons.access_time_outlined,
            label: 'Time',
            value: _getTimeRange(),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const Divider(height: AppSpacing.lg),
          _ReviewRow(
            icon: Icons.groups_outlined,
            label: 'Type',
            value: bookingTypeLabel +
                (_bookingType == 'partial'
                    ? ' (max ${_maxPlayersController.text})'
                    : ''),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const Divider(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Hold fee NPR 20 (non-refundable). Final price shown at payment.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
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

class _StepCircle extends StatelessWidget {
  final int number;
  final bool isActive;
  final bool isCompleted;

  const _StepCircle({
    required this.number,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFilled = isActive || isCompleted;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: isFilled ? colorScheme.primary : colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? Icon(Icons.check_rounded,
              size: 14, color: colorScheme.onPrimary)
          : Text(
              '$number',
              style: AppTypography.textTheme(colorScheme)
                  .labelSmall
                  ?.copyWith(
                    fontWeight: AppFontWeights.semiBold,
                    color: isActive
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
            ),
    );
  }
}

class _BookingTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _BookingTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              alignment: Alignment.center,
              child:
                  Icon(icon, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: AppFontWeights.semiBold),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.check_circle_rounded,
                  color: colorScheme.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: AppFontWeights.medium,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: AppFontWeights.semiBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
