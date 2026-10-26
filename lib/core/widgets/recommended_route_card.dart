import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import '../../generated/assets.dart';


class RecommendedRouteCard extends StatelessWidget {
  const RecommendedRouteCard({
    super.key,
    required this.routeName,
    required this.distanceLabel,
    required this.runnersNearbyLabel,
    required this.onQuickStart,
    this.imageAssetPath,
    this.isSecure = true,
  });

  final String routeName;
  final String distanceLabel;
  final String runnersNearbyLabel;
  final VoidCallback onQuickStart;
  final String? imageAssetPath;
  final bool isSecure;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview area with badges + floating info panel.
          SizedBox(
            height: 168,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: AssetOrFallback(
                      assetPath: imageAssetPath,
                      fallback: const _RouteImageFallback(),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _Badge(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF60A5FA),
                    label: isSecure ? 'Route Secure' : 'Route Caution',
                  ),
                ),
                Padding(
                  padding:   EdgeInsets.only(top: 8.h),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: SizedBox(
                      width: 45.w,
                        height: 45.h,
                        child: Image.asset(Assets.sos)
                    ),
                  ),
                ),
                Positioned(
                  bottom: -28,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.background.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          routeName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          distanceLabel,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.people_alt,
                                size: 9,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              runnersNearbyLabel,
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: PrimaryButton(
              label: 'Quick Start Run',
              onPressed: onQuickStart,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteImageFallback extends StatelessWidget {
  const _RouteImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2E1F), Color(0xFF14241B)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.terrain_rounded, color: Colors.white12, size: 48),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.24), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
