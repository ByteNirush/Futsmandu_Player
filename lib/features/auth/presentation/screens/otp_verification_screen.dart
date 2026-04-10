import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../data/services/player_auth_service.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_header.dart';

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
    if (rawArgs is Map) {
      return rawArgs.cast<String, dynamic>();
    }
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

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(authSessionProvider.notifier).verifyOtp(
            userId: userId,
            otp: otp,
          );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OTP verification failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      final result = await ref.read(authSessionProvider.notifier).resendOtp(
            userId: userId,
          );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to resend OTP: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final args = _routeArgs(context);
    final userId = args?['userId']?.toString() ?? '';
    final email = args?['email']?.toString() ?? '';
    final subtitle = email.isEmpty
        ? 'Enter the 6-digit code sent to your email'
        : 'Enter the 6-digit code sent to $email';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const Center(child: AppLogo(size: 72.0)),
                    const SizedBox(height: AppSpacing.sm),
                    AuthHeader(title: 'Verify OTP', subtitle: subtitle),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Pinput(
                        controller: _otpController,
                        length: 6,
                        keyboardType: TextInputType.number,
                        defaultPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        submittedPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Verify',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : () => _verify(userId),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => _resend(userId),
                        child: const Text('Resend Code'),
                      ),
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
