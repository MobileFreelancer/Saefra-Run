import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/goal_training_target_row.dart';
import 'package:saefra_run/core/widgets/onboarding_progress_widgets.dart';
import 'package:saefra_run/core/widgets/option_tile.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/assets.dart'; // Ensure this points correctly to your assets file

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalOption {
  const _GoalOption(this.title, this.imagePath);
  final String title;
  final String imagePath;
}

class _GoalScreenState extends State<GoalScreen> {
  static const _other = 'Other';
  static const _trainingForAGoal = OnboardingService.trainingForAGoal;

  // Array mapping matching the exact text options and corresponding image paths from image_2ed992.png
  static const _options = [
    _GoalOption('Just getting started', Assets.onboardingEasyPaceIcon),
    _GoalOption('Building consistency', Assets.onboardingConsistencyIcon),
    _GoalOption(_trainingForAGoal, Assets.onboardingTrainingGoalIcon),
    _GoalOption('Exploring new routes', Assets.onboardingExploreIcon),
    _GoalOption('Just for fun', Assets.onboardingFunIcon),
    _GoalOption(_other, Assets.onboardingPreferenceIcon),
  ];

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingService>();
    final selected = onboarding.data.goal;
    final selectedTarget = onboarding.data.goalTrainingTarget;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Matches dark layout theme of image_2ed992.png
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingStepHeader(
              step: 3,
              totalSteps: 4,
              onBack: () => context.go('/onboarding/activity-level'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Centered alignments
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
                          TextSpan(text: 'What brings you to '),
                          TextSpan(
                            text: 'Saefra?',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This helps us personalize your experience and\nrecommended routes',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ..._options.map((option) {
                      final isTrainingTile = option.title == _trainingForAGoal;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: OptionTile(
                          title: option.title,
                          height: 25,
                          width: 25,
                          imagePath: option.imagePath, // Uses image assets configured on previous screen
                          isSelected: selected == option.title,
                          expandedChild: isTrainingTile
                              ? GoalTrainingTargetRow(
                                  selected: selectedTarget,
                                  onSelect: (target) => context
                                      .read<OnboardingService>()
                                      .setGoalTrainingTarget(target),
                                )
                              : null,
                          onTap: () => context
                              .read<OnboardingService>()
                              .setGoal(option.title),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            OnboardingContinueBar(
              isEnabled: selected != null &&
                  (selected != _trainingForAGoal || selectedTarget != null),
              onContinue: () => context.go('/onboarding/dob'),
              onSkip: () => context.go('/onboarding/dob'),
            ),
          ],
        ),
      ),
    );
  }
}