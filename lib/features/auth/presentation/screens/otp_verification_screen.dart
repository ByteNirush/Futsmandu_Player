import 'package:flutter/material.dart';

import 'package:pinput/pinput.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../shared/widgets/app_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_screen_scaffold.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs.cast<String, dynamic>() : null;
    final nextRoute = args?['nextRoute'] as String?;

    return AuthScreenScaffold(
      showAppBar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            title: 'Verify OTP',
            subtitle: 'Enter the 6-digit code sent to your email',
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Pinput(
              length: 6,
              defaultPinTheme: PinTheme(
                width: 50,
                height: 60,
                textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 50,
                height: 60,
                textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              submittedPinTheme: PinTheme(
                width: 50,
                height: 60,
                textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Verify',
            onPressed: () {
              if (nextRoute != null) {
                Navigator.pushReplacementNamed(context, nextRoute);
                return;
              }
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                    const SnackBar(content: Text('OTP sent again!')));
              },
              child: const Text('Resend Code'),
            ),
          ),
        ],
      ),
    );
  }
}
