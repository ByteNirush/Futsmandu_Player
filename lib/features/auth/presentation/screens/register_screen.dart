import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../data/services/player_auth_service.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../providers/auth_controller.dart';

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
      final player = await ref.read(authSessionProvider.notifier).register(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            password: _passwordController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Enter the OTP sent to your email.'),
        ),
      );
      Navigator.pushReplacementNamed(
        context,
        '/otp-verification',
        arguments: {
          'userId': player.id,
          'email': _emailController.text.trim(),
        },
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Registration failed: $e');
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
        title: 'Create Account',
        subtitle: 'Register your futsal profile',
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
                label: 'Full Name',
                showLabelAboveField: true,
                hint: 'Enter your full name',
                prefixIcon: Icons.person_outline,
                maxLength: 100,
                showCounter: false,
                controller: _nameController,
                validator: _validateName,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInputField(
                label: 'Email',
                showLabelAboveField: true,
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
                label: 'Phone',
                showLabelAboveField: true,
                hint: 'Enter phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 14,
                showCounter: false,
                controller: _phoneController,
                validator: _validatePhone,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInputField(
                label: 'Password',
                showLabelAboveField: true,
                hint: 'Create password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                maxLength: 64,
                showCounter: false,
                controller: _passwordController,
                validator: _validatePassword,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInputField(
                label: 'Confirm Password',
                showLabelAboveField: true,
                hint: 'Confirm password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                maxLength: 64,
                showCounter: false,
                controller: _confirmPasswordController,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Sign Up',
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
