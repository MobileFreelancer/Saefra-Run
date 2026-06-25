import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';

/// Permission screen layout matching the "Enable Location Services" /
/// "Notification" designs:
///
/// - A back arrow top-left.
/// - A full-bleed photo/illustration area behind everything (pass
///   [backgroundAssetPath] once you have the real image; until then a dark
///   gradient is shown so the layout still looks intentional).
/// - A glowing circular badge centered over that area, holding either the
///   real icon asset ([iconAssetPath]) or a Material [icon] fallback.
/// - A frosted "glass" card anchored to the bottom, overlapping the photo,
///   containing the title, description, and the two action buttons.
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

  /// Material icon fallback shown inside the glowing badge until
  /// [iconAssetPath] resolves to a real image.
  final IconData icon;

  /// e.g. Assets.onboardingLocationIcon — optional, falls back to [icon].
  final String? iconAssetPath;

  /// e.g. Assets.onboardingLocationBg — optional, falls back to a dark
  /// gradient so the screen still reads as a deliberate photo area.
  final String? backgroundAssetPath;

  final Color glowColor;
  final bool isLoading;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Full-bleed background photo area (top ~58% of the screen),
          // fading to black so the glass card below reads cleanly.
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  flex: 58,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AssetOrFallback(
                        assetPath: backgroundAssetPath,
                        fallback: const _BackgroundGradient(),
                      ),
                      // Subtle fade so the glass card sits on a clean edge.
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              AppColors.background,
                            ],
                            stops: [0.0, 0.65, 1.0],
                          ),
                        ),
                      ),
                      Center(
                        child: _GlowBadge(
                          icon: icon,
                          iconAssetPath: iconAssetPath,
                          glowColor: glowColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(flex: 42, child: SizedBox()),
              ],
            ),
          ),

          // Back button.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Glass card pinned to the bottom, overlapping the photo.
          Align(
            alignment: Alignment.bottomCenter,
            child: _GlassCard(
              title: title,
              description: description,
              primaryLabel: primaryLabel,
              secondaryLabel: secondaryLabel,
              onPrimary: onPrimary,
              onSecondary: onSecondary,
              isLoading: isLoading,
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
            Color(0xFF161616),
            AppColors.background,
          ],
        ),
      ),
    );
  }
}

class _GlowBadge extends StatelessWidget {
  const _GlowBadge({
    required this.icon,
    required this.iconAssetPath,
    required this.glowColor,
  });

  final IconData icon;
  final String? iconAssetPath;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            glowColor.withValues(alpha: 0.35),
            glowColor.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceLight.withValues(alpha: 0.6),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: AssetOrFallback(
            assetPath: iconAssetPath,
            width: 72,
            height: 72,
            fallback: Icon(icon, size: 32, color: glowColor),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.isLoading,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: primaryLabel,
              onPressed: onPrimary,
              isLoading: isLoading,
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: secondaryLabel,
              onPressed: isLoading ? null : onSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
