import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

import '../../../generated/assets.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with a smooth bottom dark gradient overlay
          ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,       // Keeps the top clear
                  Colors.transparent, // Fades to solid black at the bottom
                ],
                stops: [0.3, 0.85],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              Assets.onboardingRunnerImg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),

          // Content Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // Typography matching the style hierarchy
                  Text(
                    "Let's Create\nYour Style with",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.2,
                      fontWeight: FontWeight.w300, // Thinner weight for the intro phrase
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Saefra Run",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.2,
                      fontWeight: FontWeight.bold, // Bold weight for the brand name
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Perfect Circle Button Match
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/onboarding/gender'),
                      child: Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset(
                              Assets.onboardingRightArrow,
                              color: const Color(0xFFD31A38), // Red tint for the arrow icon
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.play_arrow,
                                color: Color(0xFFD31A38),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}