import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/mock/mock_data.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';

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
  static const double _spaceXs = 4;
  static const double _spaceSm = 8;
  static const double _spaceMd = 12;
  static const double _spaceLg = 16;
  static const double _spaceXl = 20;
  static const double _space2xl = 24;

  int _courtIdx = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedSlot;

  final Map<String, IconData> _amenityIcons = {
    'Parking': Icons.local_parking,
    'Changing Room': Icons.checkroom_outlined,
    'Floodlights': Icons.highlight_outlined,
    'Cafeteria': Icons.restaurant_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final venue =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final selectedCourt =
        (venue['courts'] as List)[_courtIdx] as Map<String, dynamic>;
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
                                'NPR ${_selectedSlot!['price']} • ${selectedCourt['name']}',
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
                                      'NPR ${_selectedSlot!['price']} • ${selectedCourt['name']}',
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
                              label:
                                  '${(venue['courts'] as List).length} Courts',
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
                        children:
                            (venue['courts'] as List).asMap().entries.map((e) {
                          final bool isSelected = _courtIdx == e.key;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _courtIdx = e.key;
                              _selectedSlot = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                right: e.key ==
                                        (venue['courts'] as List).length - 1
                                    ? 0
                                    : _spaceMd,
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
                                  _LegendDot(AppColors.amber, 'Held'),
                                  _LegendDot(AppColors.red, 'Booked'),
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

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: (venue['courts'][_courtIdx]['slots']
                                        as List)
                                    .map((slot) {
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
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.green,
                        padding: _VenueDetailSpacing.pillPadding,
                        backgroundColor: AppColors.green.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: GoogleFonts.barlow(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('See all'),
                    ),
                    child: Column(
                      children: MockData.reviews
                          .take(3)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key == 2 ? 0 : _spaceMd,
                              ),
                              child: _ReviewCard(entry.value),
                            ),
                          )
                          .toList(),
                    ),
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
                    margin: const EdgeInsets.only(top: 48),
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
                                      venue['courts'][_courtIdx]['name'],
                                      style: AppText.h3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${venue['courts'][_courtIdx]['type']} · ${venue['courts'][_courtIdx]['surface']}',
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
                              'NPR ${slot['price']}',
                              style: GoogleFonts.barlow(
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
                            Navigator.pop(ctx);
                            Navigator.pushNamed(
                              ctx,
                              '/booking-hold',
                              arguments: {
                                'slot': slot,
                                'venue': venue,
                                'courtIdx': _courtIdx,
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
              : slot['status'] == 'HELD'
                  ? AppColors.amber.withValues(alpha: 0.07)
                  : slot['status'] == 'CONFIRMED'
                      ? AppColors.red.withValues(alpha: 0.07)
                      : AppColors.bgElevated,
          border: Border.all(
            color: isSelected
                ? AppColors.green
                : slot['status'] == 'HELD'
                    ? AppColors.amber.withValues(alpha: 0.5)
                    : slot['status'] == 'CONFIRMED'
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
              style: GoogleFonts.barlow(
                fontSize: 17,
                fontWeight: AppTextStyles.semiBold,
                color: isSelected
                    ? AppColors.green
                    : slot['status'] == 'HELD'
                        ? AppColors.amber
                        : slot['status'] == 'CONFIRMED'
                            ? AppColors.red
                            : AppColors.txtPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              slot['status'] == 'AVAILABLE'
                  ? 'NPR ${slot['price']}'
                  : slot['status'] == 'HELD'
                      ? 'Held'
                      : 'Booked',
              style: AppText.label.copyWith(
                color: isSelected
                    ? AppColors.green.withValues(alpha: 0.8)
                    : slot['status'] == 'HELD'
                        ? AppColors.amber
                        : AppColors.red,
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
