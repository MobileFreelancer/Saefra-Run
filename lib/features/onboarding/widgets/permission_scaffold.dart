import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';

class PermissionScaffold extends StatelessWidget {
  const PermissionScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    this.child,
    this.customIcon,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final Widget? child;
  final Widget? customIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              customIcon ??
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, size: 44, color: AppColors.primary),
                  ),
              const SizedBox(height: 32),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (child != null) ...[
                const SizedBox(height: 32),
                child!,
              ],
              const Spacer(),
              PrimaryButton(
                label: primaryLabel,
                onPressed: onPrimary,
                isLoading: isLoading,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: secondaryLabel,
                onPressed: isLoading ? null : onSecondary,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
