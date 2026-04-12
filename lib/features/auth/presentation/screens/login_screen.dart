import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../data/services/player_auth_service.dart';
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      role: AppRole.player,
      child: AuthCard(
        role: AppRole.player,
        title: 'Welcome Back',
        subtitle: 'Sign in to book and play futsal',
        errorWidget: _errorMessage != null
            ? ErrorMessageWidget(
                message: _errorMessage!,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              )
            : null,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInputField(
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                maxLength: 254,
                showCounter: false,
                controller: _emailController,
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInputField(
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                maxLength: 128,
                showCounter: false,
                controller: _passwordController,
                validator: _validatePassword,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Create Account',
                onPressed: () => Navigator.pushNamed(context, '/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
