import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_nav_bar.dart';
import 'package:saefra_run/core/widgets/selection_card.dart';
import 'package:saefra_run/features/onboarding/widgets/onboarding_step_scaffold.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  static const _options = [
    'Building consistency',
    'Training for a goal',
    'Exploring new routes',
  ];

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingService>();
    final selected = onboarding.data.goal;

    return OnboardingStepScaffold(
      title: 'What brings you to\nSaefra (optional)',
      bottomNavigationBar: OnboardingNavBar(
        onBack: () => context.go('/onboarding/activity-level'),
        onNext: () => context.go('/onboarding/age'),
      ),
      child: Column(
        children: _options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SelectionCard(
              label: option,
              isSelected: selected == option,
              onTap: () => context.read<OnboardingService>().setGoal(option),
            ),
          );
        }).toList(),
      ),
    );
  }
}
