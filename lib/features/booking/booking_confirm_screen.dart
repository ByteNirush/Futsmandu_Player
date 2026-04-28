import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_spacing.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';
import '../../shared/widgets/futs_card.dart';
import 'presentation/providers/booking_repository_provider.dart';
import '../home/home_shell.dart' show kNavBarHeight;

class BookingConfirmScreen extends ConsumerStatefulWidget {
  const BookingConfirmScreen({super.key});

  @override
  ConsumerState<BookingConfirmScreen> createState() =>
      _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen>
    with SingleTickerProviderStateMixin {
  bool _show = false;
  late AnimationController _confettiController;
  Timer? _pollTimer;
  bool _didStartPolling = false;
  bool _isPolling = false;
  String? _serverStatus;
  String? _serverNotice;
  bool _terminalStatusReached = false;
  String? _matchGroupId;

  String _formattedAmountLabel(String amount) {
    final normalized = amount.trim();
    if (normalized.isEmpty) return 'NPR 0';

    final upper = normalized.toUpperCase();
    if (upper.startsWith('NPR ')) return normalized;
    if (upper.startsWith('RS ')) {
      return 'NPR ${normalized.substring(3).trim()}';
    }

    return 'NPR $normalized';
  }

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartPolling) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final verification = args?['verification'] is Map
        ? (args?['verification'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final bypassed = verification['bypassed'] == true;
    final bookingId = _bookingIdFromArgs(args);

    if (bypassed && bookingId.isNotEmpty) {
      _didStartPolling = true;
      _serverStatus = 'HELD';
      _serverNotice = 'Waiting for the backend to finalize this booking.';
      _startPolling(bookingId);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  String _bookingIdFromArgs(Map<String, dynamic>? args) {
    final bookingRecord = args?['bookingRecord'] is Map
        ? (args?['bookingRecord'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final verification = args?['verification'] is Map
        ? (args?['verification'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final confirmed = verification['confirmed'] is Map
        ? (verification['confirmed'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return bookingRecord['id']?.toString().trim().isNotEmpty == true
        ? bookingRecord['id'].toString()
        : confirmed['id']?.toString().trim().isNotEmpty == true
            ? confirmed['id'].toString()
            : '';
  }

  void _startPolling(String bookingId) {
    _pollBookingDetail(bookingId);
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _pollBookingDetail(bookingId);
    });
  }

  Future<void> _pollBookingDetail(String bookingId) async {
    if (_isPolling || _terminalStatusReached || !mounted) return;

    setState(() => _isPolling = true);

    try {
      final detail =
          await ref.read(bookingRepositoryProvider).getBookingDetail(bookingId);
      final booking = detail.raw;
      final status = booking['status']?.toString().toUpperCase() ?? '';

      // Extract matchGroupId from the detail response if available
      final mg = booking['match_group'];
      final newMatchGroupId = (mg is Map) ? (mg['id']?.toString() ?? '') : '';
      if (newMatchGroupId.isNotEmpty && (_matchGroupId?.isEmpty ?? true)) {
        _matchGroupId = newMatchGroupId;
      }

      if (!mounted) return;

      if (status == 'CONFIRMED') {
        _terminalStatusReached = true;
        _pollTimer?.cancel();
        setState(() {
          _serverStatus = 'CONFIRMED';
          _serverNotice = 'The backend has confirmed your booking.';
          _isPolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed by the backend.')),
        );
        return;
      }

      if (status == 'EXPIRED') {
        _terminalStatusReached = true;
        _pollTimer?.cancel();
        setState(() {
          _serverStatus = 'EXPIRED';
          _serverNotice = 'The hold expired on the backend. Please book again.';
          _isPolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking hold expired on the backend.')),
        );
        return;
      }

      setState(() {
        _serverStatus = status.isNotEmpty ? status : 'HELD';
        _serverNotice = 'Waiting for backend finalization.';
        _isPolling = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serverNotice =
            'Unable to refresh booking status right now. Retrying...';
        _isPolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingRecord = args?['bookingRecord'] is Map
        ? (args?['bookingRecord'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final selectedCourtName = args?['venue']?['courts'] is List &&
            args?['courtIdx'] is int &&
            (args?['venue']?['courts'] as List).length >
                (args?['courtIdx'] as int)
        ? ((args?['venue']?['courts'] as List)[args?['courtIdx'] as int]['name']
                ?.toString() ??
            'Court')
        : 'Court';
    final bookingDate = args?['bookingDate']?.toString() ?? '-';
    final startTime = args?['startTime']?.toString() ?? '-';
    final endTime = args?['endTime']?.toString() ?? '-';
    final totalAmount =
        bookingRecord['displayAmount']?.toString().isNotEmpty == true
            ? bookingRecord['displayAmount'].toString()
            : bookingRecord['total_amount']?.toString() ??
                args?['slot']?['price']?.toString() ??
                '1800';
    final verification = args?['verification'] is Map
        ? (args?['verification'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final matchGroup = verification['matchGroup'] is Map
        ? (verification['matchGroup'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final gateway = args?['paymentGateway']?.toString() ?? '';
    final bypassed = verification['bypassed'] == true;
    final bookingId = _bookingIdFromArgs(args);
    final amountLabel = _formattedAmountLabel(totalAmount);

    // Extract booking type and player info
    final bookingType = args?['bookingType']?.toString() ?? '';
    final isPartialTeam = bookingType == 'PARTIAL_TEAM';
    final myPlayers = args?['myPlayers'] is int ? (args!['myPlayers'] as int) : 0;
    final maxPlayersArg = args?['maxPlayers'];
    final maxPlayers = maxPlayersArg is int
        ? maxPlayersArg
        : int.tryParse(maxPlayersArg?.toString() ?? '') ?? 0;
    final playersNeeded =
        (maxPlayers > myPlayers) ? maxPlayers - myPlayers : 0;

    // Effective matchGroupId: prefer the one from polling, fall back to initial
    final effectiveMatchGroupId = (_matchGroupId?.isNotEmpty == true)
        ? _matchGroupId!
        : (matchGroup['id']?.toString() ?? '');

    final effectiveServerStatus =
        _serverStatus ?? (bypassed ? 'HELD' : 'CONFIRMED');
    final serverTitle = effectiveServerStatus == 'EXPIRED'
        ? 'Booking Hold Expired'
        : effectiveServerStatus == 'CONFIRMED'
            ? 'Booking Confirmed by Server'
            : bypassed
                ? 'Booking Saved'
                : 'Booking Confirmed!';
    final serverSubtitle = effectiveServerStatus == 'EXPIRED'
        ? 'The backend released this slot. Please select another one.'
        : effectiveServerStatus == 'CONFIRMED'
            ? 'The backend has finalized your booking.'
            : bypassed
                ? 'Your booking is visible now while the backend finishes syncing.'
                : 'Your slot is locked in. See you on the pitch!';
    final paymentLabel = bypassed
        ? effectiveServerStatus == 'CONFIRMED'
            ? 'Confirmed • $amountLabel'
            : effectiveServerStatus == 'EXPIRED'
                ? 'Hold expired • $amountLabel'
                : 'Booked • $amountLabel'
        : gateway.isNotEmpty
            ? '${gateway.toUpperCase()} paid $amountLabel'
            : 'Paid $amountLabel';
    final showMatchGroupButton =
        effectiveMatchGroupId.isNotEmpty && effectiveServerStatus != 'EXPIRED';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // CONFETTI
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return Stack(
                children: List.generate(
                    22, (index) => _ConfettiItem(index, _confettiController)),
              );
            },
          ),
          // CONTENT
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kNavBarHeight,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Center(
                  child: AnimatedScale(
                    scale: _show ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green.withValues(alpha: 0.10),
                        border: Border.all(color: AppColors.green, width: 2),
                      ),
                      child: Center(
                        child: Icon(Icons.check_rounded,
                            size: 60, color: AppColors.green),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedOpacity(
                  opacity: _show ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      Text(serverTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(fontWeight: AppFontWeights.extraBold),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        serverSubtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.txtDisabled),
                        textAlign: TextAlign.center,
                      ),
                      if (bypassed) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: effectiveServerStatus == 'EXPIRED'
                                ? AppColors.red.withValues(alpha: 0.10)
                                : effectiveServerStatus == 'CONFIRMED'
                                    ? AppColors.green.withValues(alpha: 0.10)
                                    : AppColors.info.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: effectiveServerStatus == 'EXPIRED'
                                  ? AppColors.red.withValues(alpha: 0.28)
                                  : effectiveServerStatus == 'CONFIRMED'
                                      ? AppColors.green.withValues(alpha: 0.28)
                                      : AppColors.info.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                effectiveServerStatus == 'EXPIRED'
                                    ? Icons.error_outline_rounded
                                    : effectiveServerStatus == 'CONFIRMED'
                                        ? Icons.verified_rounded
                                        : Icons.info_outline_rounded,
                                size: 18,
                                color: effectiveServerStatus == 'EXPIRED'
                                    ? AppColors.red
                                    : effectiveServerStatus == 'CONFIRMED'
                                        ? AppColors.green
                                        : AppColors.info,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _serverNotice ??
                                      'This booking is confirmed in the app without payment. The backend may finalize it separately.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.txtPrimary,
                                        height: 1.35,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isPolling) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Syncing booking status for #$bookingId...',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.txtDisabled),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      if (isPartialTeam && maxPlayers > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.group_add_rounded,
                                      size: 16, color: AppColors.blue),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Partial Team Booking',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: AppFontWeights.semiBold,
                                          color: AppColors.blue,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'You have $myPlayers player${myPlayers != 1 ? "s" : ""}. '
                                '$playersNeeded more needed to complete a team of $maxPlayers.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This match is now visible in "Join a Match" for other players to find.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.txtDisabled),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ],
                      const SizedBox(height: 28),
                      FutsCard(
                        child: Column(
                          children: [
                            _ConfirmRow('Venue',
                                args?['venue']?['name'] ?? 'Futsmandu Arena'),
                            _ConfirmRow('Court', selectedCourtName),
                            _ConfirmRow('Date', bookingDate),
                            _ConfirmRow('Time', '$startTime - $endTime'),
                            const Divider(),
                            _ConfirmRow('Type',
                                isPartialTeam ? 'Partial Team' : 'Full Team'),
                            if (isPartialTeam && maxPlayers > 0) ...[
                              const Divider(),
                              _ConfirmRow('Spots open',
                                  '$playersNeeded of $maxPlayers'),
                            ],
                            if (bypassed) ...[
                              const Divider(),
                              _ConfirmRow(
                                  'Server Status', effectiveServerStatus),
                            ],
                            const Divider(),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 380;

                                final matchGroupInfo = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Match Group',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.group_outlined,
                                            size: 15, color: AppColors.blue),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            effectiveMatchGroupId.isNotEmpty
                                                ? 'Created and ready to join'
                                                : 'Preparing match group',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color: AppColors.info),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );

                                final paymentInfo = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 15, color: AppColors.green),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        paymentLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.green,
                                              fontWeight:
                                                  AppFontWeights.semiBold,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: compact
                                            ? TextAlign.left
                                            : TextAlign.right,
                                      ),
                                    ),
                                  ],
                                );

                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      matchGroupInfo,
                                      const SizedBox(height: 8),
                                      paymentInfo,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: matchGroupInfo),
                                    const SizedBox(width: 12),
                                    Flexible(child: paymentInfo),
                                  ],
                                );
                              },
                            ),
                            if (bookingId.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _ConfirmRow(
                                'Booking ID',
                                bookingId,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FutsButton(
                        label: 'View Match Group',
                        onPressed: !showMatchGroupButton
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/match-detail',
                                  arguments: {'id': effectiveMatchGroupId},
                                );
                              },
                      ),
                      const SizedBox(height: 12),
                      FutsButton(
                        label: effectiveServerStatus == 'EXPIRED'
                            ? 'Book Another Slot'
                            : 'Back to Home',
                        outlined: true,
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (_) => false,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          icon: Icon(Icons.calendar_today_outlined,
                              size: 16, color: AppColors.txtDisabled),
                          label: Text('Add to Calendar',
                              style: Theme.of(context).textTheme.bodyMedium),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Calendar feature coming soon')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.txtPrimary),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiItem extends StatelessWidget {
  final int index;
  final Animation<double> animation;

  const _ConfettiItem(this.index, this.animation);

  @override
  Widget build(BuildContext context) {
    final rand = math.Random(index);
    final double startX = rand.nextDouble();
    final List<Color> colors = [
      AppColors.green,
      AppColors.amber,
      AppColors.blue,
      AppColors.red,
      Colors.white.withValues(alpha: 0.6),
    ];
    final Color color = colors[index % 5];
    final double rotSpeed = index * 0.7;
    final double fallSpeedFactor = 0.8 + (rand.nextDouble() * 0.4);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final top = -20 + (animation.value * screenHeight * 0.6 * fallSpeedFactor);
    final left = startX * screenWidth;

    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: animation.value * rotSpeed * 6.28,
        child: Container(
          width: 7,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
