// Re-export the canonical design-system input so every screen in this app
// that does `import '…/shared/widgets/app_input_field.dart'` resolves to the
// single shared implementation without any changes to existing call-sites.
export 'package:futsmandu_design_system/futsmandu_design_system.dart'
    show AppInputField;
