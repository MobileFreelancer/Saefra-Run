import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_progress_widgets.dart';
import 'package:saefra_run/core/widgets/option_tile.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/assets.dart'; // Ensure correct path to Assets file

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityOption {
  const _ActivityOption(this.title, this.subtitle, this.imagePath);
  final String title;
  final String subtitle;
  final String imagePath;
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  // Using \n and bullet markers to perfectly replicate the vertical list info structure in image_2edd4f.png
  static const _options = [
    _ActivityOption(
      'Easy Pace',
      '• Shorter distances\n• Flatter routes\n• Great for jogging or relaxed runs',
      Assets.onboardingEasyPaceIcon,
    ),
    _ActivityOption(
      'Moderate Challenge',
      '• Moderate distance\n• Some hills and elevations\n• Balanced effort and variety',
      Assets.onboardingModerateChallengeIcon,
    ),
    _ActivityOption(
      'Push My Limits',
      '• Longer distances\n• More hills and elevation\n• Designed for runners seeking a challenge',
      Assets.onboardingPushMyLimitIcon,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingService>();
    final selected = onboarding.data.activityLevel;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingStepHeader(
              step: 2,
              totalSteps: 4, // Matches '1 of 2' from the target layout asset image_2edd4f.png
              onBack: () => context.go('/onboarding/gender'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Centered alignment
                  children: [
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        children: const [
                          TextSpan(text: 'What kind of runs do you '),
                          TextSpan(
                            text: 'Enjoy?',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This helps us personalize your experience and\nrecommended routes.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ..._options.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: OptionTile(
                          title: option.title,
                          subtitle: option.subtitle,
                          height: 55,
                          dividerHeight: 70,
                          width: 55,
                          imagePath: option.imagePath, // Custom asset image path property configuration
                          isSelected: selected == option.title,
                          onTap: () => context
                              .read<OnboardingService>()
                              .setActivityLevel(option.title),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            OnboardingContinueBar(
              isEnabled: selected != null,
              onContinue: () => context.go('/onboarding/goal'),
              onSkip: () => context.go('/onboarding/goal'),
            ),
          ],
        ),
      ),
    );
  }
}