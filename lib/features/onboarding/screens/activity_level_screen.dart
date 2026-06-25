import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_nav_bar.dart';
import 'package:saefra_run/core/widgets/selection_card.dart';
import 'package:saefra_run/features/onboarding/widgets/onboarding_step_scaffold.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  static const _options = ['Beginner', 'Intermediate', 'Advance'];

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingService>();
    final selected = onboarding.data.activityLevel;

    return OnboardingStepScaffold(
      title: 'Your regular physical\nactivity level?',
      bottomNavigationBar: OnboardingNavBar(
        onBack: () => context.go('/onboarding/intro'),
        onNext: selected != null
            ? () => context.go('/onboarding/goal')
            : null,
        isNextEnabled: selected != null,
      ),
      child: Column(
        children: _options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SelectionCard(
              label: option,
              isSelected: selected == option,
              onTap: () => context.read<OnboardingService>().setActivityLevel(option),
            ),
          );
        }).toList(),
      ),
    );
  }
}
