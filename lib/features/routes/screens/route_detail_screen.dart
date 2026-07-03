import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/route_detail_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/app_route_map.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/generated/assets.dart';

import '../../../core/widgets/asset_or_fallback.dart';

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteDetailService>().load(widget.routeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final detail = context.watch<RouteDetailService>();
    final route = detail.route;
    final userName = auth.currentUser?.fullName?.split(' ').first ??
        auth.currentUser?.email?.split('@').first ??
        'Runner';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: detail.isLoading && route == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : route == null
                ? Center(
                    child: Text(
                      detail.error ?? 'Route not found',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : Column(
                    children: [
                      const AppPageHeader(title: 'Route Detail'),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                          children: [
                            Text(
                              'Ready, $userName?',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              '${route.locationLabel ?? 'Your area'} | ${route.visibilityLabel ?? 'Safe route'}',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _RouteMapCard(route: route),
                            SizedBox(height: 16.h),
                            PrimaryButton(
                              label: 'Start Run',
                              onPressed: () {
                                context.pushNamed(
                                  'liveRunning',
                                  queryParameters: {
                                    'routeId': widget.routeId,
                                    'routeName': route.name,
                                  },
                                );
                              },
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              'More Information',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _SaefraScoreCard(score: route.saefraScore ?? 0),
                            SizedBox(height: 16.h),
                            Text(
                              'Safety Information',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _SafetyInfoRow(
                              label: 'Lighting Level',
                              value: route.lightingLevel ?? 'High',
                              valueColor: AppColors.primary,
                            ),
                            _SafetyInfoRow(
                              label: 'Traffic Level',
                              value: route.trafficLevel ?? 'Low',
                              valueColor: AppColors.success,
                            ),
                            _SafetyInfoRow(
                              label: 'Community Rating',
                              value:
                                  '${route.communityRating?.toStringAsFixed(1) ?? '4.8'} / 5',
                              valueColor: AppColors.white,
                              trailing: const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'Live Highlights',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            SizedBox(
                              height: 120.h,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: 12.w),
                                itemBuilder: (context, index) {
                                  return _HighlightCard(index: index);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _RouteMapCard extends StatelessWidget {
  const _RouteMapCard({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Stack(
        children: [
          AppRouteMap(height: 220.h, borderRadius: 20),
          Positioned(
            top: 12.h,
            right: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Route Scope',
                style: TextStyle(color: AppColors.white, fontSize: 11.sp),
              ),
            ),
          ),
          Positioned(
            left: 12.w,
            right: 12.w,
            bottom: 12.h,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${route.distanceLabel} • ${route.safePoints ?? 0} Data Points',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${route.runnerCount} active',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaefraScoreCard extends StatelessWidget {
  const _SaefraScoreCard({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final pct = score.clamp(0, 100);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SAEFRA SCORE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.sp,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Icon(Icons.check_circle, color: AppColors.primary, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6.h,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyInfoRow extends StatelessWidget {
  const _SafetyInfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 4.w), trailing!],
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final titles = ['Sunset trail', 'Community run', 'Safe loop'];
    return Container(
      width: 160.w,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AssetOrFallback(
              assetPath: Assets.routeHighlightImg,
              fallback: Container(
                color: AppColors.surfaceLight,
                child: Icon(Icons.image_outlined, color: AppColors.textMuted),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Text(
              titles[index % titles.length],
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
