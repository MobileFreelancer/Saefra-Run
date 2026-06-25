import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/onboarding_progress_widgets.dart';
import 'package:saefra_run/core/widgets/option_tile.dart';

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
              onBack: () => context.pop(),
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
                          TextSpan(text: 'What '),
                          TextSpan(
                            text: 'Gender',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                          TextSpan(text: ' do you\nIdentify With?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This information helps us improve and personalize the '
                      'Saefra experience',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 28),
                    OptionTile(
                      title: 'Man',
                      isSelected: selected == 'Man',
                      onTap: () => _select('Man'),
                    ),
                    const SizedBox(height: 12),
                    OptionTile(
                      title: 'Woman',
                      isSelected: selected == 'Woman',
                      onTap: () => _select('Woman'),
                    ),
                    const SizedBox(height: 12),
                    OptionTile(
                      title: _selfIdentify,
                      isSelected: isSelfIdentify,
                      showTextField: true,
                      textFieldController: _selfIdentifyController,
                      textFieldHint: _selfIdentify,
                      onTap: () {
                        final text = _selfIdentifyController.text.trim();
                        _select(text.isEmpty ? _selfIdentify : text);
                      },
                    ),
                    const SizedBox(height: 12),
                    OptionTile(
                      title: 'Prefer not to say',
                      isSelected: selected == 'Prefer not to say',
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
