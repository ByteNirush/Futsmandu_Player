import 'package:flutter/material.dart';

class FutsInput extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final String? prefixText;

  const FutsInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = true,
    this.validator,
    this.enabled = true,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      maxLength: maxLength,
      buildCounter: showCounter
          ? null
          : (
              BuildContext context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              return null;
            },
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixText: prefixText,
        counterText: showCounter ? null : '',
      ),
    );
  }
}
