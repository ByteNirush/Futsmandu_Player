import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart';

import '../../data/services/player_auth_service.dart';
import '../providers/auth_controller.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _routeArgs(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map) return rawArgs.cast<String, dynamic>();
    return null;
  }

  Future<void> _verify(String userId) async {
    if (userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user id for OTP verification.')),
      );
      return;
    }

    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ref
          .read(authSessionProvider.notifier)
          .verifyOtp(userId: userId, otp: otp);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('OTP verification failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend(String userId) async {
    if (userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user id for OTP resend.')),
      );
      return;
    }

    try {
      final result = await ref
          .read(authSessionProvider.notifier)
          .resendOtp(userId: userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to resend OTP: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _routeArgs(context);
    final userId = args?['userId']?.toString() ?? '';
    final email = args?['email']?.toString() ?? '';
    
    final colorScheme = Theme.of(context).colorScheme;
    
    final destination = email.trim().isNotEmpty ? email.trim() : 'your email';

    return AuthScaffold(
      role: AppRole.player,
      showAppBar: true,
      allowScroll: false,
      showAccentStrip: false,
      child: AuthCard(
        role: AppRole.player,
        title: 'Verify Account',
        subtitle: 'Enter the 6-digit code sent to\n$destination',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: OtpPinInput(
                controller: _otpController,
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            PrimaryButton(
              label: 'Verify',
              isLoading: _isLoading,
              onPressed: () => _verify(userId),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                onPressed: _isLoading ? null : () => _resend(userId),
                child: const Text('Resend Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
