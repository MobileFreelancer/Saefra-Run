import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_progress_widgets.dart';
import 'package:saefra_run/core/widgets/option_tile.dart';

import '../../../generated/assets.dart'; // Ensure correct path to Assets class

class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  static const _selfIdentify = 'Prefer to self-identify as ...';

  late final TextEditingController _selfIdentifyController;

  @override
  void initState() {
    super.initState();
    final saved = context.read<OnboardingService>().data.gender;
    _selfIdentifyController = TextEditingController(
      text: saved != null &&
          saved != 'Man' &&
          saved != 'Woman' &&
          saved != 'Prefer not to say'
          ? saved
          : '',
    );
  }

  @override
  void dispose() {
    _selfIdentifyController.dispose();
    super.dispose();
  }

  void _select(String value) {
    context.read<OnboardingService>().setGender(value);
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingService>();
    final selected = onboarding.data.gender;
    final isSelfIdentify = selected != null &&
        selected != 'Man' &&
        selected != 'Woman' &&
        selected != 'Prefer not to say';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingStepHeader(
              step: 1,
              totalSteps: 4,
              onBack: () => context.go('/auth/login'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Centered content hierarchy
                  children: [
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        children: const [
                          TextSpan(text: 'What '),
                          TextSpan(
                            text: 'Gender',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          TextSpan(text: ' do you Identify With?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This information helps us improve and personalize the\nSaefra experience',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),
                    OptionTile(
                      title: 'Man',
                      isSelected: selected == 'Man',
                      imagePath: Assets.onboardingManIcon,
                      onTap: () => _select('Man'),
                    ),
                    const SizedBox(height: 14),
                    OptionTile(
                      title: 'Woman',
                      dividerHeight: 30,
                      isSelected: selected == 'Woman' ,
                      imagePath: Assets.onboardingWomenIcon,
                      onTap: () => _select('Woman'),
                    ),
                    const SizedBox(height: 14),
                    OptionTile(
                      title: _selfIdentify,
                      isSelected: isSelfIdentify,
                      showTextField: true,
                      imagePath: Assets.onboardingPreferenceIcon,
                      textFieldController: _selfIdentifyController,
                      textFieldHint: _selfIdentify,
                      onTap: () {
                        final text = _selfIdentifyController.text.trim();
                        _select(text.isEmpty ? _selfIdentify : text);
                      },
                    ),
                    const SizedBox(height: 14),
                    OptionTile(
                      title: 'Prefer not to say',
                      isSelected: selected == 'Prefer not to say',
                      imagePath: Assets.onboardingNotToSayIcon,
                      onTap: () => _select('Prefer not to say'),
                    ),
                  ],
                ),
              ),
            ),
            OnboardingContinueBar(
              isEnabled: selected != null && selected.isNotEmpty,
              onContinue: () => context.go('/onboarding/activity-level'),
              onSkip: () => context.go('/onboarding/activity-level'),
            ),
          ],
        ),
      ),
    );
  }
}