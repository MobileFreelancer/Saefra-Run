import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthService>();
    final onboarding = context.read<OnboardingService>();

  /*  await Future.wait([
      auth.initialize(),
      onboarding.initialize(),
    ]);
*/
    if (!mounted) return;

    if (!onboarding.isComplete) {
      context.go('/onboarding/intro');
    } else if (auth.isLoggedIn) {
      context.go('/dashboard');
    } else {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: AppLogo(size: 100)),
    );
  }
}
