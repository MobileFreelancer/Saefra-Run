import 'package:flutter/material.dart';
import 'package:saefra_run/core/widgets/app_logo.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.bottomWidget,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottomWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Center(child: AppLogo(size: 64)),
              const SizedBox(height: 32),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              child,
              if (bottomWidget != null) ...[
                const SizedBox(height: 24),
                bottomWidget!,
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
