import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../data/services/player_auth_service.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../providers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final message =
          await ref.read(authSessionProvider.notifier).forgotPassword(
                email: _emailController.text,
              );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.pushNamed(
        context,
        '/reset-password',
        arguments: {'email': _emailController.text.trim()},
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Reset request failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      role: AppRole.player,
      showAppBar: true,
      showAccentStrip: false,
      allowScroll: false,
      child: AuthCard(
        role: AppRole.player,
        title: 'Reset Password',
        subtitle: 'We will email a reset token to you',
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
                showLabelAboveField: true,
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                maxLength: 254,
                showCounter: false,
                controller: _emailController,
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Send Reset Link',
                isLoading: _isLoading,
                onPressed: _handleSendResetLink,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
