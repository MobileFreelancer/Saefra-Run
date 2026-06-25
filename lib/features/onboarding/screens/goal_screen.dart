import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_progress_widgets.dart';
import 'package:saefra_run/core/widgets/option_tile.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalOption {
  const _GoalOption(this.title, this.icon);
  final String title;
  final IconData icon;
}

class _GoalScreenState extends State<GoalScreen> {
  static const _other = 'Other';

  static const _options = [
    _GoalOption('Just getting started', Icons.flag_outlined),
    _GoalOption('Building consistency', Icons.repeat),
    _GoalOption('Training for a goal', Icons.emoji_events_outlined),
    _GoalOption('Exploring new routes', Icons.map_outlined),
    _GoalOption('Just for fun', Icons.directions_run),
    _GoalOption(_other, Icons.edit_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingService>();
    final selected = onboarding.data.goal;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingStepHeader(
              step: 2,
              totalSteps: 3,
              onBack: () => context.go('/onboarding/activity-level'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium,
                        children: const [
                          TextSpan(text: 'What brings you to '),
                          TextSpan(
                            text: 'Saefra?',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This helps us personalize your experience and '
                      'recommended routes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 28),
                    ..._options.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OptionTile(
                          title: option.title,
                          icon: option.icon,
                          isSelected: selected == option.title,
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
              isEnabled: true,
              onContinue: () => context.go('/onboarding/dob'),
              onSkip: () => context.go('/onboarding/dob'),
            ),
          ],
        ),
      ),
    );
  }
}
