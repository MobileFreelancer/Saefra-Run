import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/community_service.dart';
import 'package:saefra_run/core/services/live_running_services.dart';
import 'package:saefra_run/core/services/route_detail_service.dart';
import 'package:saefra_run/core/widgets/app_route_map.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

class CommunityRouteDetailScreen extends StatefulWidget {
  const CommunityRouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  @override
  State<CommunityRouteDetailScreen> createState() =>
      _CommunityRouteDetailScreenState();
}

class _CommunityRouteDetailScreenState extends State<CommunityRouteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityService>().loadRouteDetail(widget.routeId);
      context.read<RouteDetailService>().load(widget.routeId);
    });
  }

  void _startRoute() {
    final routeModel = context.read<RouteDetailService>().route;
    final start = routeModel?.startPoint;
    final end = routeModel?.endPoint;

    if (start != null && end != null) {
      final points = routeModel!.polylinePoints;
      context.read<RunningProvider>().prepareForRun(
            startPoint: start,
            endPoint: end,
            routePolyline: points.length > 1 ? points : null,
          );
    }

    final community = context.read<CommunityService>().selectedRoute;
    context.pushNamed(
      'liveRunning',
      queryParameters: {
        'routeId': widget.routeId,
        'routeName': community?.name ?? routeModel?.name ?? 'Route',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityService>();
    final routeDetail = context.watch<RouteDetailService>();
    final route = community.selectedRoute;
    final polylinePoints = routeDetail.route?.polylinePoints ?? const [];

    if (community.isLoading && route == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (route == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text(community.error ?? 'Route not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Route Detail'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(route.name, style: Theme.of(context).textTheme.titleLarge),
                            Text(route.location, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(route.rating.toStringAsFixed(1)),
                        ],
                      ),
                      SizedBox(width: 8.w),
                      if (route.difficultyTag != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            route.difficultyTag!,
                            style: TextStyle(color: AppColors.success, fontSize: 11.sp),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: SizedBox(
                      height: 200.h,
                      width: double.infinity,
                      child: AppRouteMap(
                        height: 200,
                        borderRadius: 16,
                        polylinePoints:
                            polylinePoints.length > 1 ? polylinePoints : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => community.toggleLike(route.id),
                        icon: const Icon(Icons.favorite_border, color: AppColors.primary),
                      ),
                      const Icon(Icons.share_outlined, color: AppColors.textMuted),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.pushNamed(
                          'routeReviews',
                          pathParameters: {'id': route.id},
                        ),
                        child: const Text('Reviews'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8.w,
                    children: route.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: AppColors.surface,
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      _MiniStat(label: 'Distance', value: '${route.distanceKm} km'),
                      _MiniStat(label: 'Est. Time', value: '${route.durationMinutes} min'),
                      _MiniStat(label: 'Elev. Gain', value: '${route.elevationGainM.toInt()} m'),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text('About this route', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 6.h),
                  Text(
                    route.description ??
                        'Community-rated route with safety insights and runner activity.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: PrimaryButton(
                label: 'Start This Route',
                onPressed: _startRoute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13.sp)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
