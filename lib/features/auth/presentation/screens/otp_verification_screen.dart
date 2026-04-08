import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../../data/services/player_auth_service.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_screen_scaffold.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _routeArgs(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) return rawArgs.cast<String, dynamic>();
    return null;
  }

  String? _validateToken(String? value) {
    final token = value?.trim() ?? '';
    if (token.isEmpty) return 'Verification token is required';
    if (token.length < 6) return 'Verification token is invalid';
    if (token.length > 256) return 'Verification token is too long';
    return null;
  }

  Future<void> _handleVerifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final message = await ref.read(authSessionProvider.notifier).verifyEmail(
            token: _tokenController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Email verification failed: $e');
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
              title: 'Verify Email',
              subtitle: email == null || email.isEmpty
                  ? 'Paste the verification token from your email'
                  : 'We sent a verification token to $email',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ErrorMessageWidget(
                message: _errorMessage!,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppInputField(
              label: 'Verification Token',
              hint: 'Paste the token from your email',
              prefixIcon: Icons.verified_user_outlined,
              maxLength: 256,
              showCounter: false,
              controller: _tokenController,
              validator: _validateToken,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Verify',
              isLoading: _isLoading,
              onPressed: _handleVerifyEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
