import 'package:flutter/material.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';

class AuthScreenScaffold extends StatelessWidget {
  const AuthScreenScaffold({
    super.key,
    required this.child,
    this.showAppBar = false,
    this.logoTopSpacing = AppSpacing.xxl,
    this.logoSize = 100,
  });

  final Widget child;
  final bool showAppBar;
  final double logoTopSpacing;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final topGap = keyboardVisible ? AppSpacing.lg : logoTopSpacing;
    final currentLogoSize = keyboardVisible ? logoSize * 0.72 : logoSize;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar() : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: topGap,
              ),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: AppLogo(size: currentLogoSize),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
