import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

class OnboardingNavBar extends StatelessWidget {
  const OnboardingNavBar({
    super.key,
    required this.onBack,
    required this.onNext,
    this.nextLabel = 'Next',
    this.showBack = true,
    this.isNextEnabled = true,
    this.isLoading = false,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool showBack;
  final bool isNextEnabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
              ),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          SizedBox(
            width: 100,
            height: 44,
            child: ElevatedButton(
              onPressed: (isNextEnabled && !isLoading) ? onNext : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}
