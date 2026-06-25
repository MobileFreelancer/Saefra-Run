import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B3A2F),
                  Color(0xFF0D1F17),
                  AppColors.background,
                ],
              ),
            ),
            child: Image.asset(
              'assets/images/onboarding_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
          Container(color: AppColors.overlay),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    "Let's Create Your\nStyle with\nSaefra Run",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 36,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/onboarding/activity-level'),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
