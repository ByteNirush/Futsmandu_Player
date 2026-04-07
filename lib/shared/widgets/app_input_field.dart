import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/components/inputs/app_text_field.dart';

class AppInputField extends StatefulWidget {
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
  final int? maxLength;
  final bool showCounter;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final String? errorText;

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
    this.maxLength,
    this.showCounter = true,
    this.validator,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  bool _obscureText = true;

  Widget? _buildIcon(dynamic icon) {
    if (icon == null) return null;
    if (icon is IconData) return Icon(icon);
    if (icon is Widget) return icon;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      labelText: widget.label,
      controller: widget.controller,
      hintText: widget.hint,
      prefixIcon: _buildIcon(widget.prefixIcon),
      suffixIcon: widget.isPassword
          ? IconButton(
              onPressed: () => setState(() => _obscureText = !_obscureText),
              icon: Icon(
                _obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            )
          : _buildIcon(widget.suffixIcon),
      obscureText: widget.isPassword && _obscureText,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      showCounter: widget.showCounter,
      validator: widget.validator,
      enabled: widget.enabled,
    );
  }
}
