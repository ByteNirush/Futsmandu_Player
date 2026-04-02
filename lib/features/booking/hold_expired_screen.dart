import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/futs_button.dart';

class HoldExpiredScreen extends StatelessWidget {
  const HoldExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.amber.withValues(alpha: 0.10),
                  border: Border.all(color: AppColors.amber, width: 1.5),
                ),
                child: Center(
                  child: Icon(Icons.timer_off_outlined, size: 48, color: AppColors.amber),
                ),
              ),
              const SizedBox(height: 32),
              Text('Hold Expired', style: AppText.h1, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Your 7-minute slot hold has expired.\nThe slot is now available to others.',
                style: AppText.body.copyWith(color: AppColors.txtDisabled),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FutsButton(
                label: 'Choose Another Slot',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/venues', (_) => false);
                },
              ),
              const SizedBox(height: 12),
              FutsButton(
                label: 'Back to Home',
                outlined: true,
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
