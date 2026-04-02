import 'package:flutter/material.dart';

import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';

class FutsButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final Color? customColor;

  const FutsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.customColor,
  });

  @override
  State<FutsButton> createState() => _FutsButtonState();
}

class _FutsButtonState extends State<FutsButton> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _pressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _pressed = false);
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null || widget.isLoading;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: disabled ? null : _handleTapDown,
        onTapUp: disabled ? null : _handleTapUp,
        onTapCancel: disabled ? null : _handleTapCancel,
        child: widget.outlined
            ? _buildOutlined(disabled)
            : _buildFilled(disabled),
      ),
    );
  }

  Widget _buildFilled(bool disabled) {
    return FilledButton(
      onPressed: disabled ? null : widget.onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: widget.customColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildOutlined(bool disabled) {
    final outlineColor =
        widget.customColor ?? Theme.of(context).colorScheme.primary;
    return OutlinedButton(
      onPressed: disabled ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: outlineColor,
        elevation: 0,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: BorderSide(
          color: disabled ? Theme.of(context).colorScheme.outlineVariant : outlineColor,
          width: 1.5,
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Text(widget.label);
  }
}
