import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/widgets/app_logo.dart';
import 'package:saefra_run/generated/assets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    final auth = context.read<AuthService>();
    final onboarding = context.read<OnboardingService>();

    await Future.wait([
      auth.initialize(),
      onboarding.initialize(),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    if (auth.isLoggedIn) {
      context.go(
        onboarding.isComplete ? '/dashboard' : '/onboarding/gender',
      );
      return;
    }

    context.go('/onboarding/intro');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Image.asset(
          Assets.imagesAppLogo,
          width: 180,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const AppLogo(size: 100),
        ),
      ),
    );
  }
}
