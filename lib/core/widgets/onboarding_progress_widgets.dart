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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
              color: AppColors.redDark.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$step of $totalSteps',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54, // Perfectly sized rounded capsule button match
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
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
                  : Text(
                continueLabel,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (showSkip) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading ? null : onSkip,
              style: TextButton.styleFrom(
                minimumSize: const Size(80, 36),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}