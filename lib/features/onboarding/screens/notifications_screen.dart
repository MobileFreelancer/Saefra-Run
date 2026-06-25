import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/features/onboarding/widgets/permission_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;

  Future<void> _complete({required bool enable}) async {
    final service = context.read<OnboardingService>();
    service.setPushNotifications(enable && _pushEnabled);
    service.setEmailNotifications(enable && _emailEnabled);

    final success = await service.completeOnboarding();
    if (!mounted) return;

    if (success) {
      context.go('/auth/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(service.error ?? 'Something went wrong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<OnboardingService>().isLoading;

    return PermissionScaffold(
      icon: Icons.notifications_outlined,
      title: 'Stay Updated & Secure',
      description: 'Choose how you want to receive updates about your runs, '
          'achievements, and account security.',
      primaryLabel: 'Enable Notifications',
      secondaryLabel: 'Maybe Later',
      isLoading: isLoading,
      onPrimary: () => _complete(enable: true),
      onSecondary: () => _complete(enable: false),
      child: Column(
        children: [
          _NotificationToggle(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: 'Get alerts for runs and milestones',
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          const SizedBox(height: 16),
          _NotificationToggle(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Weekly summaries and account updates',
            value: _emailEnabled,
            onChanged: (v) => setState(() => _emailEnabled = v),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
