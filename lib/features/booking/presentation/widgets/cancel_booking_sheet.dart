import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_spacing.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../data/models/booking_models.dart';
import '../providers/booking_controllers.dart';

class CancelBookingSheet extends ConsumerStatefulWidget {
  const CancelBookingSheet({
    super.key,
    required this.booking,
  });

  final BookingHistoryItem booking;

  @override
  ConsumerState<CancelBookingSheet> createState() => _CancelBookingSheetState();
}

class _CancelBookingSheetState extends ConsumerState<CancelBookingSheet> {
  final _reasonController = TextEditingController();
  bool _isCancelling = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _onCancelPressed() async {
    final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirm Cancellation'),
            content: const Text(
              'Are you sure you want to cancel this booking? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep Booking'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Cancel Booking'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldCancel) return;

    if (!mounted) return;
    setState(() => _isCancelling = true);

    try {
      final response = await ref
          .read(bookingHistoryControllerProvider.notifier)
          .cancelBooking(
            bookingId: widget.booking.id,
            reason: _reasonController.text,
          );
      
      if (!mounted) return;
      Navigator.of(context).pop();
      
      final refundText = response.displayRefund.isNotEmpty
          ? response.displayRefund
          : 'NPR ${response.refundAmount}';
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking cancelled. Refund: $refundText'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Exception
                ? e.toString().replaceFirst('Exception: ', '')
                : 'Could not cancel booking right now.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
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
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cancel Booking?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: AppFontWeights.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.booking.venueName.isNotEmpty ? widget.booking.venueName : 'Selected Venue',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.txtPrimary,
                ),
            decoration: InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Let the venue know why you are cancelling...',
              alignLabelWithHint: true,
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: AppFontWeights.semiBold,
                  ),
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.txtDisabled,
                  ),
              filled: true,
              fillColor: AppColors.bgElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : () => Navigator.pop(context),
                  child: const Text('Keep Booking'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red.withValues(alpha: 0.1),
                    foregroundColor: AppColors.red,
                  ),
                  onPressed: _isCancelling ? null : _onCancelPressed,
                  child: _isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel & Refund'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
