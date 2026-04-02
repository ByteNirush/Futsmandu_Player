import 'package:flutter/material.dart';
import 'futs_input.dart';

class AppInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final dynamic prefixIcon;
  final dynamic suffixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  const AppInputField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.maxLines = 1,
    this.validator,
    this.enabled = true,
  });

  Widget? _buildIcon(dynamic icon) {
    if (icon == null) return null;
    if (icon is IconData) return Icon(icon);
    if (icon is Widget) return icon;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutsInput(
      label: label,
      controller: controller,
      hint: hint,
      prefixIcon: _buildIcon(prefixIcon),
      suffixIcon: _buildIcon(suffixIcon),
      obscureText: isPassword,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      validator: validator,
      enabled: enabled,
    );
  }
}
