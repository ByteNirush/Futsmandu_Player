import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/app_logo.dart';

import '../widgets/auth_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: bottomInset + AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Logo ──────────────────────────────────────────────
                    const SizedBox(height: AppSpacing.xl),
                    const Center(child: AppLogo(size: 80.0)),

                    // ── Section header ────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    const AuthHeader(
                      title: 'Welcome Back',
                      subtitle: 'Sign in to manage your futsal venue',
                    ),

                    // ── Input fields ──────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    const AppInputField(
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppInputField(
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    // ── Primary CTA ───────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Login',
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/shell'),
                    ),

                    // ── OR divider ────────────────────────────────────────
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Secondary CTA ─────────────────────────────────────
                    AppButton(
                      label: 'Create Account',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


