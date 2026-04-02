import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_screen_scaffold.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            title: 'Create Owner Account',
            subtitle: 'Register your futsal business',
          ),
          const SizedBox(height: AppSpacing.md),
          const AppInputField(
            label: 'Full Name',
            hint: 'Enter your full name',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.xs),
          const AppInputField(
            label: 'Email',
            hint: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.xs),
          const AppInputField(
            label: 'Phone',
            hint: 'Enter phone number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.xs),
          const AppInputField(
            label: 'Password',
            hint: 'Create password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          const AppInputField(
            label: 'Confirm Password',
            hint: 'Confirm password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Signup',
            onPressed: () => Navigator.pushNamed(
              context,
              '/otp-verification',
              arguments: {'nextRoute': '/shell'},
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Login'),
            ),
          ),
        ],
      ),
    );
  }
}
