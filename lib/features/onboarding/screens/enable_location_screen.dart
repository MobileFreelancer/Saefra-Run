import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/photo_permission_scaffold.dart';
import 'package:saefra_run/generated/assets.dart';

class EnableLocationScreen extends StatefulWidget {
  const EnableLocationScreen({super.key});

  @override
  State<EnableLocationScreen> createState() => _EnableLocationScreenState();
}

class _EnableLocationScreenState extends State<EnableLocationScreen> {
  void _continue({required bool enabled}) {
    context.read<OnboardingService>().setLocationEnabled(enabled);
    context.go('/onboarding/notifications');
  }

  @override
  Widget build(BuildContext context) {
    return PhotoPermissionScaffold(
      icon: Icons.location_on,
      iconAssetPath: Assets.onboardingLocationIcon,
      backgroundAssetPath: Assets.onboardingLocationBg,
      title: 'Location & Phone permissions required',
      description: 'Saefra Run needs your location to suggest safe routes '
          'and provide real-time safety alerts while you run.',
      primaryLabel: 'Allow Location',
      secondaryLabel: 'Maybe Later',
      onPrimary: () => _continue(enabled: true),
      onSecondary: () => _continue(enabled: false),
    );
  }
}
