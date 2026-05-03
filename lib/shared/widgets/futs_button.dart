import 'package:flutter/material.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';

class FutsButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    if (customColor == null) {
      return outlined
          ? SecondaryButton(
              label: label,
              onPressed: disabled ? null : onPressed,
              fullWidth: true,
            )
          : PrimaryButton(
              label: label,
              onPressed: disabled ? null : onPressed,
              isLoading: isLoading,
              fullWidth: true,
            );
    }

    return outlined ? _buildOutlined(context, disabled) : _buildFilled(context, disabled);
  }

  Widget _buildFilled(BuildContext context, bool disabled) {
    return FilledButton(
      onPressed: disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: customColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        minimumSize: const Size(0, AppSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildOutlined(BuildContext context, bool disabled) {
    final outlineColor =
        customColor ?? Theme.of(context).colorScheme.primary;
    return OutlinedButton(
      onPressed: disabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: outlineColor,
        elevation: 0,
        minimumSize: const Size(0, AppSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: BorderSide(
          color: disabled ? Theme.of(context).colorScheme.outlineVariant : outlineColor,
          width: 1.5,
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      final onPrimary = Theme.of(context).colorScheme.onPrimary;
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(onPrimary),
        ),
      );
    }
    return Text(label);
  }
}
