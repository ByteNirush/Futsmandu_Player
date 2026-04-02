import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> card(ColorScheme scheme) {
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

