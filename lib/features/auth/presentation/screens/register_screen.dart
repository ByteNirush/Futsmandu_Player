import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../data/services/player_auth_service.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_screen_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Name is required';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (trimmed.length > 100) return 'Name must be 100 characters or less';
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (trimmed.length > 254) return 'Email must be 254 characters or less';
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Phone number is required';
    final validPhone = RegExp(r'^\+?977\d{9,10}$|^\d{9,10}$');
    if (!validPhone.hasMatch(trimmed)) {
      return 'Enter a valid Nepal phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (password.length > 64) return 'Password must be 64 characters or less';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain a number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authSessionProvider.notifier).register(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            password: _passwordController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Account created successfully. Please verify your email.')),
      );
      Navigator.pushReplacementNamed(
        context,
        '/verify-email',
        arguments: {'email': _emailController.text.trim()},
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Registration failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthHeader(
              title: 'Create Account',
              subtitle: 'Register your futsal profile',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppInputField(
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              maxLength: 100,
              showCounter: false,
              controller: _nameController,
              validator: _validateName,
            ),
            const SizedBox(height: AppSpacing.xs),
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
            const SizedBox(height: AppSpacing.xs),
            AppInputField(
              label: 'Phone',
              hint: 'Enter phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 14,
              showCounter: false,
              controller: _phoneController,
              validator: _validatePhone,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppInputField(
              label: 'Password',
              hint: 'Create password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              maxLength: 64,
              showCounter: false,
              controller: _passwordController,
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppInputField(
              label: 'Confirm Password',
              hint: 'Confirm password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              maxLength: 64,
              showCounter: false,
              controller: _confirmPasswordController,
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Sign Up',
              isLoading: _isLoading,
              onPressed: _handleRegister,
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
      ),
    );
  }
}
