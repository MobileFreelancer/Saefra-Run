import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/photo_permission_scaffold.dart';
import 'package:saefra_run/generated/assets.dart';

import '../../../core/services/permission_service.dart';

class EnableLocationScreen extends StatefulWidget {
  const EnableLocationScreen({super.key});

  @override
  State<EnableLocationScreen> createState() => _EnableLocationScreenState();
}

class _EnableLocationScreenState extends State<EnableLocationScreen> {


  Future<void> _allowLocation() async {
    final granted = await PermissionService.requestLocationPermission();
    if (!mounted) return;
    context.read<OnboardingService>().setLocationEnabled(granted);
    context.go('/onboarding/notifications');
  }

  void _skipLocation() {
    context.read<OnboardingService>().setLocationEnabled(false);
    context.go('/onboarding/notifications');
  }
  // void _continue({required bool enabled})async{
  //   final granted = await PermissionService.requestLocationPermission();
  //   if (granted) {
  //     context.read<OnboardingService>().setLocationEnabled(enabled);
  //     context.go('/onboarding/notifications');
  //   } else {
  //     context.read<OnboardingService>().setLocationEnabled(enabled);
  //     context.go('/onboarding/notifications');
  //   }
  //
  // }

  @override
  Widget build(BuildContext context) {
    return PhotoPermissionScaffold(
      icon: Icons.location_on,
      iconAssetPath: Assets.onboardingLocationIcon,
      backgroundAssetPath: Assets.onboardingLocationBg,
      onBack: () => context.go('/onboarding/goal'),
      title: 'Location & Phone permissions required',
      description: 'Saefra Run needs your location to suggest safe routes '
          'and provide real-time safety alerts while you run.',
      primaryLabel: 'Allow Location',
      secondaryLabel: 'Maybe Later',
      onPrimary: _allowLocation,
      onSecondary: _skipLocation,
    );
  }
}
