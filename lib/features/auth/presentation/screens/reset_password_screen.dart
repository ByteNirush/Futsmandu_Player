import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../data/services/player_auth_service.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../providers/auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    final token = value?.trim() ?? '';
    if (token.isEmpty) return 'Reset token is required';
    if (token.length < 32) return 'Reset token is invalid';
    if (token.length > 256) return 'Reset token is too long';
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
      final message =
          await ref.read(authSessionProvider.notifier).resetPassword(
                token: _tokenController.text,
                newPassword: _newPasswordController.text,
              );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Password reset failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _routeArgs(context);
    final email = args?['email'] as String?;

    return AuthScaffold(
      role: AppRole.player,
      showAppBar: true,
      child: AuthCard(
        role: AppRole.player,
        title: 'Set New Password',
        subtitle: email == null || email.isEmpty
            ? 'Enter the reset token from your email'
            : 'We sent a reset token to $email',
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
                label: 'Reset Token',
                showLabelAboveField: true,
                hint: 'Paste the token from your email',
                prefixIcon: Icons.confirmation_number_outlined,
                maxLength: 256,
                showCounter: false,
                controller: _tokenController,
                validator: _validateToken,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInputField(
                label: 'New Password',
                showLabelAboveField: true,
                hint: 'Create new password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                maxLength: 64,
                showCounter: false,
                controller: _newPasswordController,
                validator: _validatePassword,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInputField(
                label: 'Confirm Password',
                showLabelAboveField: true,
                hint: 'Confirm new password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                maxLength: 64,
                showCounter: false,
                controller: _confirmPasswordController,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save Password',
                isLoading: _isLoading,
                onPressed: _handleResetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
