import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/futs_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/services/player_payments_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PlayerPaymentsService _paymentsService = PlayerPaymentsService.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _payments = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final payments = await _paymentsService.getPaymentHistory();
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } on PaymentsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load payment history.';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return AppColors.green;
      case 'INITIATED':
      case 'PENDING':
        return AppColors.amber;
      case 'FAILED':
        return AppColors.red;
      default:
        return AppColors.txtDisabled;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return 'Completed';
      case 'INITIATED':
        return 'Processing';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      default:
        return status;
    }
  }

  String _gatewayLabel(String gateway) {
    final normalized = gateway.toUpperCase();
    return normalized == 'KHALTI'
        ? 'Khalti'
        : normalized == 'ESEWA'
            ? 'eSewa'
            : gateway;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr is! String || dateStr.isEmpty) return '-';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return '${parsed.day} ${_monthAbbr(parsed.month)} ${parsed.year}';
  }

  String _monthAbbr(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Payment History', style: AppText.h2),
        elevation: 0,
        backgroundColor: AppColors.bgPrimary,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchPaymentHistory(refresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: AppColors.red),
                      const SizedBox(height: AppSpacing.sm),
                      Text(_errorMessage!,
                          style: AppText.body, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => _fetchPaymentHistory(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _payments.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Icons.wallet_outlined,
                        title: 'No Payments Yet',
                        subtitle:
                            'Book a court to make your first payment here will appear',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _payments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _PaymentHistoryCard(
                        payment: _payments[i],
                        statusColor: _statusColor(_payments[i]['status']?.toString() ?? ''),
                        statusLabel: _statusLabel(_payments[i]['status']?.toString() ?? ''),
                        gatewayLabel: _gatewayLabel(_payments[i]['gateway']?.toString() ?? ''),
                        formatDate: _formatDate,
                      ),
                    ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Color statusColor;
  final String statusLabel;
  final String gatewayLabel;
  final String Function(dynamic) formatDate;

  const _PaymentHistoryCard({
    required this.payment,
    required this.statusColor,
    required this.statusLabel,
    required this.gatewayLabel,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final booking = payment['booking'] is Map
        ? (payment['booking'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final court = booking['court'] is Map
        ? (booking['court'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final venue = court['venue'] is Map
        ? (court['venue'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final venueName = venue['name']?.toString() ?? 'Court';
    final courtName = court['name']?.toString() ?? '-';
    final bookingDate = booking['booking_date']?.toString() ?? '-';
    final startTime = booking['start_time']?.toString() ?? '-';
    final amount = payment['displayAmount']?.toString() ??
        payment['amount']?.toString() ??
        '-';

    return FutsCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venueName,
                        style: AppText.bodySm.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$courtName • $startTime',
                        style: AppText.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('NPR $amount',
                      style: AppText.bodySm
                          .copyWith(fontWeight: FontWeight.w600, color: AppColors.green)),
                  const SizedBox(height: 2),
                  StatusBadge(
                    label: statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.txtDisabled),
              const SizedBox(width: 6),
              Text(formatDate(bookingDate), style: AppText.label),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(gatewayLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.txtDisabled,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
