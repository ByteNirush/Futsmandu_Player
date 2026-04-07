import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/components/text/custom_text.dart';

import '../../../../core/design_system/app_spacing.dart';

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
        const SizedBox(height: AppSpacing.xs),
        CustomText(subtitle, variant: CustomTextVariant.body),
      ],
    );
  }
}
