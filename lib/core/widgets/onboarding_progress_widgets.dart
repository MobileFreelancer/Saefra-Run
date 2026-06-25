import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

/// Top bar used on onboarding question screens: a back arrow on the left
/// and a "X of Y" step pill on the right.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    this.onBack,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: AppColors.textPrimary,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$step of $totalSteps',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom area used on onboarding question screens: a full-width Continue
/// button with a centered "Skip" text link beneath it.
class OnboardingContinueBar extends StatelessWidget {
  const OnboardingContinueBar({
    super.key,
    required this.onContinue,
    this.onSkip,
    this.isEnabled = true,
    this.isLoading = false,
    this.continueLabel = 'Continue',
    this.showSkip = true,
  });

  final VoidCallback? onContinue;
  final VoidCallback? onSkip;
  final bool isEnabled;
  final bool isLoading;
  final String continueLabel;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: (isEnabled && !isLoading) ? onContinue : null,
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(continueLabel),
          ),
          if (showSkip) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: isLoading ? null : onSkip,
              child: Text(
                'Skip',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
