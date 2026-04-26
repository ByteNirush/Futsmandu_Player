import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 64.0});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoPath = isDarkMode ? 'assets/White_logo.png' : 'assets/black_logo.png';
    final borderRadius = size * 0.25;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Image.asset(
              logoPath,
              key: ValueKey<String>(logoPath),
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
