import 'package:flutter/material.dart';

class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.title,
    required this.child,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      height: 1.2,
                    ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: child,
              ),
            ),
            if (bottomNavigationBar != null) bottomNavigationBar!,
          ],
        ),
      ),
    );
  }
}
