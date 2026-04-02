import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

class SlotHoldScreen extends StatefulWidget {
  const SlotHoldScreen({super.key});

  @override
  State<SlotHoldScreen> createState() => _SlotHoldScreenState();
}

class _SlotHoldScreenState extends State<SlotHoldScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        final args = ModalRoute.of(context)?.settings.arguments;
        Navigator.pushReplacementNamed(context, '/payment', arguments: args);
      }
    });
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
        child: Column(
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
                  Center(
                    child: Icon(Icons.lock_clock_outlined, size: 48, color: AppColors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Securing your slot…', style: AppText.h1, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Acquiring booking lock.\nThis takes under 3 seconds.',
              style: AppText.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const _PulsingDots(),
          ],
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

class _PulsingDotsState extends State<_PulsingDots> with TickerProviderStateMixin {
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
            CurvedAnimation(parent: _controllers[index], curve: Curves.easeInOutSine),
          ),
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            decoration: BoxDecoration(
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
