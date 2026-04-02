import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/mock/mock_data.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../home/home_shell.dart' show kNavBarHeight;
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/status_badge.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _filter = 'All';

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return MockData.bookings;
    return MockData.bookings.where((b) {
      return b['status'] == _filter.toUpperCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('My Bookings', style: AppText.h2),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs3),
            child: FilterChipRow(
              options: const ['All', 'Confirmed', 'Completed', 'Cancelled'],
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'No bookings',
                    subtitle: 'Your booking history will appear here',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs2),
                    itemBuilder: (ctx, i) => _BookingCard(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> b;

  const _BookingCard(this.b);

  @override
  Widget build(BuildContext context) {
    return FutsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['venueName'], style: AppText.h3.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(b['courtName'], style: AppText.bodySm),
                ],
              ),
              const Spacer(),
              StatusBadge(
                label: b['status'],
                color: AppColors.statusColor(b['status']),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Meta(Icons.calendar_today, b['date']),
              _Meta(Icons.access_time, b['time']),
              _Meta(Icons.timelapse_outlined, b['duration']),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'NPR ${b['priceNPR']}',
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.txtPrimary,
                ),
              ),
              const Spacer(),
              if (b['status'] == 'CONFIRMED')
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.red),
                      foregroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      textStyle: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => _showCancelSheet(context, b),
                    child: const Text('Cancel'),
                  ),
                ),
              if (b['status'] == 'COMPLETED')
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.green),
                      foregroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      textStyle: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review feature coming soon')),
                      );
                    },
                    child: const Text('Review'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelSheet(BuildContext ctx, Map<String, dynamic> b) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary.withValues(alpha: 0),
      builder: (_) {
        return Container(
          margin: const EdgeInsets.only(top: kNavBarHeight),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderClr,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Cancel Booking?', style: AppText.h2),
              const SizedBox(height: 4),
              Text(b['venueName'], style: AppText.bodySm),
              const SizedBox(height: 20),
              FutsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Refund Policy', style: AppText.h3),
                    const SizedBox(height: 12),
                    _RefundRow(
                      timeLabel: '>24 hrs before',
                      pctLabel: '100% refund',
                      amount: 'NPR 1,800',
                      color: AppColors.green,
                      isActive: true,
                    ),
                    const SizedBox(height: 6),
                    _RefundRow(
                      timeLabel: '6–24 hrs before',
                      pctLabel: '50% refund',
                      amount: 'NPR 900',
                      color: AppColors.amber,
                      isActive: false,
                    ),
                    const SizedBox(height: 6),
                    _RefundRow(
                      timeLabel: '<6 hrs before',
                      pctLabel: 'No refund',
                      amount: 'NPR 0',
                      color: AppColors.red,
                      isActive: false,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Text('Your refund:', style: AppText.body),
                        const Spacer(),
                        Text(
                          'NPR 1,800',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 3,
                style: AppText.body.copyWith(color: AppColors.txtPrimary),
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Let the venue know why you\'re cancelling…',
                  alignLabelWithHint: true,
                  labelStyle: AppText.label,
                  hintStyle: AppText.bodySm.copyWith(color: AppColors.txtDisabled),
                  filled: true,
                  fillColor: AppColors.bgElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.txtDisabled.withValues(alpha: 0.5)),
                        foregroundColor: AppColors.txtPrimary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: GoogleFonts.barlow(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Keep Booking'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red.withValues(alpha: 0.10),
                        foregroundColor: AppColors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.red),
                        ),
                        textStyle: GoogleFonts.barlow(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Booking cancelled. NPR 1,800 refund initiated.')),
                        );
                      },
                      child: const Text('Cancel & Refund'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.txtDisabled),
        const SizedBox(width: 4),
        Text(text, style: AppText.label.copyWith(color: AppColors.txtPrimary)),
      ],
    );
  }
}

class _RefundRow extends StatelessWidget {
  final String timeLabel;
  final String pctLabel;
  final String amount;
  final Color color;
  final bool isActive;

  const _RefundRow({
    required this.timeLabel,
    required this.pctLabel,
    required this.amount,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs2,
        vertical: AppSpacing.xs3,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.08)
            : AppColors.bgPrimary.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: color.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$timeLabel • $pctLabel',
              style: AppText.bodySm.copyWith(
                color: isActive ? AppColors.txtPrimary : AppColors.txtDisabled,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? color : AppColors.txtDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
