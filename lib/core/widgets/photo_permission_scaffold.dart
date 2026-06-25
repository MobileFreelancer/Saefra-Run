import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';

class PhotoPermissionScaffold extends StatelessWidget {
  const PhotoPermissionScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.icon,
    this.iconAssetPath,
    this.backgroundAssetPath,
    this.glowColor = AppColors.primary,
    this.isLoading = false,
    this.onBack,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final IconData icon;
  final String? iconAssetPath;
  final String? backgroundAssetPath;
  final Color glowColor;
  final bool isLoading;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // The top overlap offset of the badge icon relative to the sheet card
    const double badgeSize = 300;
    const double badgeOverlap = badgeSize / 2.2;

    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      body: Stack(
        children: [

          // 2. Back button layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: Colors.white,
              ),
            ),
          ),

          // 3. Glass Card & Overlapping Icon Badge Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Bottom UI Glass Card Container
                _GlassCard(
                  topPadding: badgeOverlap + 24, // Gives text space from the overlapping badge
                  title: title,
                  description: description,
                  primaryLabel: primaryLabel,
                  secondaryLabel: secondaryLabel,
                  onPrimary: onPrimary,
                  onSecondary: onSecondary,
                  isLoading: isLoading,
                ),

                // Positioned right on the top edge splitter to match image_310169.png
                Positioned(
                  top: - badgeOverlap,
                  child: _GlowBadge(
                    size: badgeSize,
                    icon: icon,
                    iconAssetPath: iconAssetPath,
                    glowColor: glowColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF070707),
          ],
        ),
      ),
    );
  }
}

class _GlowBadge extends StatelessWidget {
  const _GlowBadge({
    required this.size,
    required this.icon,
    required this.iconAssetPath,
    required this.glowColor,
  });

  final double size;
  final IconData icon;
  final String? iconAssetPath;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,

      child: Container(
        width: size * 0.65,
        height: size * 0.65,
        alignment: Alignment.center,
        child: AssetOrFallback(
          assetPath: iconAssetPath,
          width: size * 0.65,
          height: size * 0.65,
          fallback: Icon(icon, size: size * 0.35, color: glowColor),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.topPadding,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.isLoading,
  });

  final double topPadding;
  final String title;
  final String description;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 36),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            // Replicating the dark gradient & subtle right glow seen on image_310169.png
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E2124).withOpacity(0.85),
                const Color(0xFF0F1012).withOpacity(0.95),
                const Color(0xFF231418).withOpacity(0.9), // Dark red ambient glow corner
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),

                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}