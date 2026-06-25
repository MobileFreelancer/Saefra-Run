import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_progress_widgets.dart';
import 'package:saefra_run/core/widgets/option_tile.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityOption {
  const _ActivityOption(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  static const _options = [
    _ActivityOption(
      'Easy Pace',
      'Shorter distances • Flatter routes • Great for jogging at relaxed rate',
      Icons.directions_run,
    ),
    _ActivityOption(
      'Moderate Challenge',
      'Moderate distance • Some hills and elevation • Balanced effort and pace',
      Icons.directions_run,
    ),
    _ActivityOption(
      'Push My Limits',
      'Longer distances • More hills and elevation • Designed for runners seeking a challenge',
      Icons.directions_run,
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
              step: 1,
              totalSteps: 3,
              onBack: () => context.go('/onboarding/gender'),
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
                          TextSpan(text: 'What kind of runs do you '),
                          TextSpan(
                            text: 'Enjoy?',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This helps us personalize your training plan and '
                      'recommended routes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 28),
                    ..._options.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OptionTile(
                          title: option.title,
                          subtitle: option.subtitle,
                          icon: option.icon,
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
