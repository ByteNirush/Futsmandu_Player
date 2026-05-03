import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import '../../core/utils/time_formatters.dart';
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
  bool _didStartPolling = false;
  bool _isPolling = false;
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
      _startPolling(bookingId);
    }
  }

  @override
  void dispose() {
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
  }

  Future<void> _pollBookingDetail(String bookingId) async {
    if (_isPolling || !mounted) return;

    setState(() => _isPolling = true);

    try {
      final detail =
          await ref.read(bookingRepositoryProvider).getBookingDetail(bookingId);
      final booking = detail.raw;
      final mg = booking['match_group'];
      final newMatchGroupId = (mg is Map) ? (mg['id']?.toString() ?? '') : '';

      if (newMatchGroupId.isNotEmpty && (_matchGroupId?.isEmpty ?? true)) {
        _matchGroupId = newMatchGroupId;
      }

      if (!mounted) return;
      setState(() => _isPolling = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingRecord = args?['bookingRecord'] is Map
        ? (args?['bookingRecord'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final selectedCourtName = args?['courtName']?.toString() ?? '';
    final bookingDate = args?['bookingDate']?.toString() ?? '';
    final startTime = args?['startTime']?.toString() ?? '';
    final endTime = args?['endTime']?.toString() ?? '';
    final totalAmount = bookingRecord['total_amount']?.toString() ?? '';
    final matchGroup = args?['matchGroup'] is Map
        ? (args?['matchGroup'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final gateway = args?['paymentGateway']?.toString() ?? '';
    final bookingId = _bookingIdFromArgs(args);
    final amountLabel = _formattedAmountLabel(totalAmount);

    // Extract booking type and player info
    final bookingType = args?['bookingType']?.toString() ?? '';
    final isPartialTeam = bookingType == 'PARTIAL_TEAM';
    final myPlayers =
        args?['myPlayers'] is int ? (args!['myPlayers'] as int) : 0;
    final maxPlayersArg = args?['maxPlayers'];
    final maxPlayers = maxPlayersArg is int
        ? maxPlayersArg
        : int.tryParse(maxPlayersArg?.toString() ?? '') ?? 0;
    final playersNeeded = (maxPlayers > myPlayers) ? maxPlayers - myPlayers : 0;

    // Effective matchGroupId: prefer the one from polling, fall back to initial
    final effectiveMatchGroupId = (_matchGroupId?.isNotEmpty == true)
        ? _matchGroupId!
        : (matchGroup['id']?.toString() ?? '');

    const serverTitle = 'Booking Confirmed!';
    const serverSubtitle = 'Your slot is locked in. See you on the pitch!';
    final paymentLabel = gateway.isNotEmpty
        ? '${gateway.toUpperCase()} paid $amountLabel'
        : 'Paid $amountLabel';
    final showMatchGroupButton =
        effectiveMatchGroupId.isNotEmpty && isPartialTeam;

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
              AppSpacing.xl,
              kNavBarHeight,
              AppSpacing.xl,
              AppSpacing.xxl,
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
                      child: const Center(
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
                      if (isPartialTeam && maxPlayers > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
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
                                  const Icon(Icons.group_add_rounded,
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
                      const SizedBox(height: 28),
                      FutsCard(
                        child: Column(
                          children: [
                            _ConfirmRow(
                                'Venue', args?['venueName']?.toString() ?? ''),
                            _ConfirmRow('Court', selectedCourtName),
                            _ConfirmRow('Date', bookingDate),
                            _ConfirmRow(
                              'Time',
                              formatClockTimeRange12Hour(startTime, endTime),
                            ),
                            const Divider(),
                            _ConfirmRow('Type',
                                isPartialTeam ? 'Partial Team' : 'Full Team'),
                            if (isPartialTeam && maxPlayers > 0) ...[
                              const Divider(),
                              _ConfirmRow('Spots open',
                                  '$playersNeeded of $maxPlayers'),
                            ],
                            const Divider(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
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
                                          fontWeight: AppFontWeights.semiBold,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
                        label: 'Done',
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (_) => false,
                          );
                        },
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
