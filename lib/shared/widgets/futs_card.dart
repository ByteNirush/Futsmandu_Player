import 'package:flutter/material.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_shadows.dart';
import '../../core/design_system/app_spacing.dart';

class FutsCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const FutsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
  });

  @override
  State<FutsCard> createState() => _FutsCardState();
}

class _FutsCardState extends State<FutsCard> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    if (widget.onTap != null) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final padding = widget.padding ?? EdgeInsets.all(AppSpacing.cardPadding);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        curve: Curves.easeOutBack,
        duration: const Duration(milliseconds: 250),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? colorScheme.surface,
            borderRadius: radius,
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(_isPressed ? 0.4 : 1.0),
            ),
            boxShadow: _isPressed
                ? [] // Flatten shadow on press
                : AppShadows.card(colorScheme),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: Padding(
              padding: padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
