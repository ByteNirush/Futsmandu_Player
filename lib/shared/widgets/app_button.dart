import 'package:flutter/material.dart';
import 'futs_button.dart';

enum AppButtonVariant { primary, outlined }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final Color? customColor;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.customColor,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = FutsButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      outlined: variant == AppButtonVariant.outlined,
      customColor: customColor,
    );
    
    if (expand) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    return button;
  }
}
