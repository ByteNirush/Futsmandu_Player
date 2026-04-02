import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_screen_scaffold.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      showAppBar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            title: 'Set New Password',
            subtitle: 'Enter your new password below',
          ),
          const SizedBox(height: AppSpacing.md),
          const AppInputField(
            label: 'New Password',
            hint: 'Create new password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          const AppInputField(
            label: 'Confirm Password',
            hint: 'Confirm new password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Save Password',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset successfully!')),
              );
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
