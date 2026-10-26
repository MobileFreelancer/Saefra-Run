import 'package:flutter/material.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/generated/assets.dart';

/// A single row in the "Recent Routes" list: thumbnail, name, stats line,
/// a small tag, and a trailing chevron.
class RecentRouteTile extends StatelessWidget {
  const RecentRouteTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.thumbnailAssetPath,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final String? thumbnailAssetPath;
  final VoidCallback? onTap;

  factory RecentRouteTile.fromRouteModel(
    RouteModel route, {
    VoidCallback? onTap,
  }) {
    return RecentRouteTile(
      title: route.name,
      subtitle: dashboardSubtitle(
        dateIso: route.dateIso,
        distanceKm: route.distanceKm,
        duration: route.durationMinutes,
      ),
      tag: dashboardTag(route.tag),
      thumbnailAssetPath: route.imageAsset?.isNotEmpty == true
          ? route.imageAsset
          : Assets.background,
      onTap: onTap,
    );
  }

  factory RecentRouteTile.fromRawMap(
    Map<String, dynamic> route, {
    VoidCallback? onTap,
  }) {
    final distance = route['distance_km'] ?? route['distance'] ?? 0.0;
    final duration = route['estimated_time'] ??
        route['estimated_time_minutes'] ??
        route['duration'] ??
        0;
    final tag = route['tag']?.toString();
    final title = route['route_name']?.toString() ?? 'Route';
    final dateStr = route['date']?.toString();
    final image = route['route_image']?.toString();

    return RecentRouteTile(
      title: title,
      subtitle: dashboardSubtitle(
        dateIso: dateStr,
        distanceKm: _toDouble(distance),
        duration: _toInt(duration),
      ),
      tag: dashboardTag(tag),
      thumbnailAssetPath: image?.isNotEmpty == true ? image : Assets.background,
      onTap: onTap,
    );
  }

  static String dashboardSubtitle({
    String? dateIso,
    double distanceKm = 0,
    int duration = 0,
  }) {
    var dateLabel = 'Recent';
    if (dateIso != null) {
      try {
        final parsed = DateTime.parse(dateIso);
        dateLabel = '${parsed.day}/${parsed.month}/${parsed.year}';
      } catch (_) {}
    }

    return '$dateLabel • $distanceKm km • $duration';
  }

  static String dashboardTag(String? tag) {
    if (tag == null || tag == 'Na' || tag == 'NA') return 'Route';
    return tag;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: AssetOrFallback(
                  assetPath: thumbnailAssetPath,
                  fallback: Container(
                    color: const Color(0xFF1E2A20),
                    child: const Icon(
                      Icons.route_outlined,
                      color: Color(0xFF4ADE80),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textMuted,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title matching the dashboard "Recent Routes" header.
class RecentRoutesSectionHeader extends StatelessWidget {
  const RecentRoutesSectionHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Routes',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
