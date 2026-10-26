import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';

void goOnboarding(BuildContext context, String route) {
  context.read<OnboardingService>().saveProgress(route);
  context.go(route);
}
