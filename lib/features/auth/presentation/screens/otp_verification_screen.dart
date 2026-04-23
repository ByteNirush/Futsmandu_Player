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
    final primaryColor = colorScheme.primary;
    
    final emailDisplay = email.trim();
    final hasEmail = emailDisplay.isNotEmpty;
    
    final destination = hasEmail ? emailDisplay : 'your email';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0, // No horizontal dividing line when scrolled
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Branding: Logo at the top
              const AppLogo(size: 56),
              const SizedBox(height: 32),
              
              // Typography: Heading
              Text(
                'Verify your account',
                style: AppTypography.subHeading(
                  context,
                  colorScheme,
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Typography: Instruction Text
              Text(
                'Enter the 6-digit code sent to',
                style: AppTypography.body(
                  context,
                  colorScheme,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Read-only confirmed data for email
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Text(
                  destination,
                  style: AppTypography.body(
                    context,
                    colorScheme,
                  ).copyWith(fontWeight: AppFontWeights.semiBold),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),
              
              // OTP Inputs Area
              Center(
                child: OtpPinInput(
                  controller: _otpController,
                  enabled: !_isLoading,
                ),
              ),
              
              const SizedBox(height: 56),
              
              // Call to Action: Large, pill-shaped primary button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Pill-shaped
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : () => _verify(userId),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Verify',
                          style: AppTypography.button(
                            context,
                            colorScheme,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Secondary Action: Clean text-only link
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  textStyle: AppTypography.textTheme(colorScheme).bodySmall?.copyWith(
                    fontWeight: AppFontWeights.semiBold,
                  ),
                ),
                onPressed: _isLoading ? null : () => _resend(userId),
                child: const Text('Resend Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
