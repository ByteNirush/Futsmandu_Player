import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../data/services/player_auth_service.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length > 128) return 'Password is too long';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authSessionProvider.notifier).login(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/shell');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Login failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          const Center(child: AppLogo(size: 76)),
                          const SizedBox(height: AppSpacing.lg),
                          AppContainer(
                            useShadow: true,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            backgroundColor: theme.colorScheme.surface,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomText(
                                  'Welcome Back',
                                  variant: CustomTextVariant.subHeading,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                CustomText(
                                  'Sign in to book and play futsal',
                                  variant: CustomTextVariant.body,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  ErrorMessageWidget(
                                    message: _errorMessage!,
                                    backgroundColor: theme.colorScheme.errorContainer,
                                    foregroundColor: theme.colorScheme.onErrorContainer,
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                AppTextField(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  keyboardType: TextInputType.emailAddress,
                                  maxLength: 254,
                                  showCounter: false,
                                  controller: _emailController,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppTextField(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  maxLength: 128,
                                  showCounter: false,
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/forgot-password',
                                    ),
                                    child: const Text('Forgot Password?'),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                PrimaryButton(
                                  label: 'Sign In',
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      child: CustomText(
                                        'OR',
                                        variant: CustomTextVariant.caption,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SecondaryButton(
                                  label: 'Create Account',
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/register',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
