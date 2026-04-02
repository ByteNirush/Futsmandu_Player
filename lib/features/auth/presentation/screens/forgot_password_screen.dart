import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_screen_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            title: 'Reset Password',
            subtitle: 'Enter your email to receive a password reset link',
          ),
          const SizedBox(height: AppSpacing.md),
          const AppInputField(
            label: 'Email',
            hint: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Send Reset Link',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('OTP sent to your email!')));
              Navigator.pushNamed(
                context,
                '/otp-verification',
                arguments: {'nextRoute': '/reset-password'},
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login'),
            ),
          ),
        ],
      ),
    );
  }
}
