import 'package:flutter/material.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(title, variant: CustomTextVariant.heading),
        const SizedBox(height: AppSpacing.sm),
        CustomText(subtitle, variant: CustomTextVariant.body),
      ],
    );
  }
}
