import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/photo_permission_scaffold.dart';
import 'package:saefra_run/generated/assets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _complete({required bool enable}) async {
    final auth = context.read<AuthService>();
    final service = context.read<OnboardingService>();
    service.setPushNotifications(enable);
    service.setEmailNotifications(enable);

    final success = await service.completeOnboarding(auth);
    if (!mounted) return;

    if (success) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(service.error ?? 'Something went wrong')),
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
