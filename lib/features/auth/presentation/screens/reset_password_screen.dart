import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../data/services/player_auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_screen_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = PlayerAuthService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _routeArgs(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) return rawArgs.cast<String, dynamic>();
    return null;
  }

  String? _validateToken(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Reset token is required';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
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
    if (value != _newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final message = await _authService.resetPassword(
        token: _tokenController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Password reset failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _routeArgs(context);
    final email = args?['email'] as String?;

    return AuthScreenScaffold(
      showAppBar: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeader(
              title: 'Set New Password',
              subtitle: email == null || email.isEmpty
                  ? 'Enter the reset token from your email'
                  : 'We sent a reset token to $email',
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
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppInputField(
              label: 'Reset Token',
              hint: 'Paste the token from your email',
              prefixIcon: Icons.confirmation_number_outlined,
              controller: _tokenController,
              validator: _validateToken,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppInputField(
              label: 'New Password',
              hint: 'Create new password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _newPasswordController,
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppInputField(
              label: 'Confirm Password',
              hint: 'Confirm new password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              controller: _confirmPasswordController,
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Save Password',
              isLoading: _isLoading,
              onPressed: _handleResetPassword,
            ),
          ],
        ),
      ),
    );
  }
}
