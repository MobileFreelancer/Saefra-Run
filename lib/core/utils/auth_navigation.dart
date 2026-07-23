import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/core/services/fcm_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';

Future<void> navigateAfterAuth(BuildContext context) async {
  final auth = context.read<AuthService>();
  final onboarding = context.read<OnboardingService>();
  final dashboard = context.read<DashboardServices>();

  if (!auth.isLoggedIn) return;

  await onboarding.syncFromServer();
  if (!context.mounted) return;

  if (onboarding.isComplete) {
    await FcmService.requestPermissionAndSync();
    if (!context.mounted) return;
    dashboard.resetHomeRoutes();
    context.go('/dashboard');
    return;
  }

  context.go(onboarding.resumeRoute);
}
