import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';
import 'data/services/player_booking_service.dart';
import 'presentation/providers/booking_repository_provider.dart';

class BookingStatusScreen extends ConsumerStatefulWidget {
  const BookingStatusScreen({super.key});

  @override
  ConsumerState<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends ConsumerState<BookingStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createBookingAndContinue();
    });
  }

  Future<void> _createBookingAndContinue() async {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs.cast<String, dynamic>() : null;

    final courtId = (args?['courtId'] as String?) ?? '';
    final bookingDate = (args?['bookingDate'] as String?) ?? '';
    final startTime = (args?['startTime'] as String?) ?? '';
    final bookingType = (args?['bookingType'] as String?) ?? 'FULL_TEAM';
    final rawMaxPlayers = args?['maxPlayers'];
    final maxPlayers = rawMaxPlayers is int
      ? rawMaxPlayers
      : int.tryParse(rawMaxPlayers?.toString() ?? '');
    final rawMyPlayers = args?['myPlayers'];
    final myPlayers = rawMyPlayers is int
      ? rawMyPlayers
      : int.tryParse(rawMyPlayers?.toString() ?? '');
    final friendIds = (args?['friendIds'] as List?)?.whereType<String>().toList();

    if (courtId.isEmpty || bookingDate.isEmpty || startTime.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Missing booking details. Please reselect your slot.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Backend has a strict check: currentPlayerCount MUST equal 1 (admin) + friendIds.length.
      // To support "offline" players (myPlayers > 1), we map the excess offline players
      // by reducing the app-managed maxPlayers and playersNeeded counts.
      final offlineCount = (myPlayers ?? 1) - 1;
      final apiMaxPlayers = (maxPlayers != null) ? maxPlayers - offlineCount : null;
      final apiCurrentPlayerCount = 1 + (friendIds?.length ?? 0);
      final apiPlayersNeeded = (apiMaxPlayers != null)
          ? apiMaxPlayers - apiCurrentPlayerCount
          : null;

      final bookingRecord = await ref.read(bookingRepositoryProvider).createBooking(
            courtId: courtId,
            date: bookingDate,
            startTime: startTime,
            bookingType: bookingType,
            maxPlayers: apiMaxPlayers,
            currentPlayerCount: apiCurrentPlayerCount,
            playersNeeded: apiPlayersNeeded,
            friendIds: friendIds,
          );

      if (!mounted) return;
      // Bypass payment: treat held booking as optimistically confirmed in UI.
      // Pass a `verification` object with `bypassed: true` so the
      // BookingConfirmScreen displays appropriate messaging.
      Navigator.pushReplacementNamed(
        context,
        '/booking-confirm',
        arguments: {
          ...?args,
          'bookingRecord': bookingRecord.toMap(),
          'verification': {
            'bypassed': true,
            'payment': {'status': 'BYPASSED'},
            'confirmed': {},
            'matchGroup': bookingRecord.matchGroupId.isNotEmpty
                ? {'id': bookingRecord.matchGroupId}
                : {},
          },
        },
      );
    } on BookingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Unable to create booking right now. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bgElevated,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(120, 120),
                              painter: _ArcPainter(_ctrl.value),
                            );
                          },
                        ),
                        const Center(
                          child: Icon(Icons.check_circle_outline,
                              size: 48, color: AppColors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Finalizing your booking...',
                      style: AppTypography.heading(context, Theme.of(context).colorScheme), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Just a moment while we process your request.',
                    style: AppTypography.caption(context, Theme.of(context).colorScheme),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  const _PulsingDots(),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _errorMessage ?? 'Unable to create booking.',
                      style: AppTypography.body(context, Theme.of(context).colorScheme),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: _createBookingAndContinue,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(
                parent: _controllers[index], curve: Curves.easeInOutSine),
          ),
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green,
            ),
          ),
        );
      }),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;

  _ArcPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    canvas.drawArc(rect, -math.pi / 2, value * 2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
