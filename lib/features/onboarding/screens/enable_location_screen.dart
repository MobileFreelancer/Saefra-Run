import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/features/onboarding/widgets/permission_scaffold.dart';

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
    return PermissionScaffold(
      icon: Icons.location_on_outlined,
      title: 'Enable Location Services',
      description:
          'Allow Saefra Run to access your location to track runs, '
          'suggest routes, and show nearby trails.',
      primaryLabel: 'Allow Location',
      secondaryLabel: 'Not Now',
      onPrimary: () => _continue(enabled: true),
      onSecondary: () => _continue(enabled: false),
      customIcon: _LocationIcon(),
    );
  }
}

class _LocationIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
