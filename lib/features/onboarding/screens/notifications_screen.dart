import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/photo_permission_scaffold.dart';
import 'package:saefra_run/generated/assets.dart';

import '../../../core/services/permission_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {


  Future<void> _complete({required bool enable}) async {
    final onboardingService = context.read<OnboardingService>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await PermissionService.requestNotificationPermission();

    onboardingService.setPushNotifications(enable);
    onboardingService.setEmailNotifications(enable);

    final success = await onboardingService.completeOnboarding();

    if (!mounted) return;

    if (success) {
      router.go('/dashboard');
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            onboardingService.error ?? 'Something went wrong',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<OnboardingService>().isLoading;

    return PhotoPermissionScaffold(
      icon: Icons.notifications_active,
      iconAssetPath: Assets.onboardingNotificationIcon,
      backgroundAssetPath: Assets.onboardingNotificationBg,
      onBack: () => context.go('/onboarding/location'),
      title: 'Stay Updated & Secure',
      description: 'Get instant alerts about hazards, community reports, '
          'and route updates in your area.',
      primaryLabel: 'Enable Notifications',
      secondaryLabel: 'Maybe Later',
      isLoading: isLoading,
      onPrimary: () => _complete(enable: true),
      onSecondary: () => _complete(enable: false),
    );
  }
}
