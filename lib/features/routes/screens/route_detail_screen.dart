import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/live_runing_services.dart';
import 'package:saefra_run/core/services/route_detail_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/app_route_map.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/generated/assets.dart';

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
    final textTheme = Theme.of(context).textTheme;
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
                      style: textTheme.bodyMedium,
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
                              style: textTheme.titleLarge?.copyWith(fontSize: 18.sp),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              '${route.locationLabel ?? 'Your area'} | ${route.visibilityLabel ?? 'Safe route'}',
                              style: textTheme.bodySmall,
                            ),
                            SizedBox(height: 16.h),
                            _RouteMapCard(route: route),
                            SizedBox(height: 16.h),
                            PrimaryButton(
                              label: 'Start Run',
                              onPressed: () {
                                const start = LatLng(21.205194905801783, 72.77568113625402);
                                const end = LatLng(21.2035, 72.7997);
                                context.read<RunningProvider>().selectDestination(
                                  startPoint: start,
                                  endPoint: end,
                                );
                                context.pushNamed(
                                  'safetyCheckIn',
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
                              style: textTheme.titleMedium,
                            ),
                            SizedBox(height: 12.h),
                            _SaefraScoreCard(score: route.saefraScore ?? 0),
                            SizedBox(height: 16.h),
                            Text(
                              'Safety Information',
                              style: textTheme.bodyMedium,
                            ),
                            SizedBox(height: 10.h),
                            _SafetyInfoRow(
                              label: 'Lighting Level',
                              value: route.lightingLevel ?? 'High',
                              valueColor: AppColors.primary,
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'Live Highlights',
                              style: textTheme.bodyMedium,
                            ),
                            SizedBox(height: 10.h),
                            LiveHighlightsCard()
                            // SizedBox(
                            //   height: 120.h,
                            //   child: ListView.separated(
                            //     scrollDirection: Axis.horizontal,
                            //     itemCount: 3,
                            //     separatorBuilder: (_, __) =>
                            //         SizedBox(width: 12.w),
                            //     itemBuilder: (context, index) {
                            //       return _HighlightCard(index: index);
                            //     },
                            //   ),
                            // ),
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
    final textTheme = Theme.of(context).textTheme;
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
                style: textTheme.bodySmall,
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
                          style: textTheme.titleMedium?.copyWith(fontSize: 14.sp),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${route.distanceLabel} • ${route.safePoints ?? 0} Data Points',
                          style: textTheme.bodySmall,
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
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
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
    final textTheme = Theme.of(context).textTheme;
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
              Column(
                spacing: 8.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAEFRA SCORE',
                    style: textTheme.bodySmall?.copyWith(letterSpacing: 0.6, fontSize: 14.sp,fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${pct.round()}%',
                    style: textTheme.displayLarge?.copyWith(fontSize: 38.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),

              const Spacer(),
              Image.asset(Assets.seftiIcon, width: 24.w, height: 24.h),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8.h,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 10.w),
          Text(
            'Optimal conditions for your morning run.',
            style: textTheme.bodySmall?.copyWith(letterSpacing: 0.6, fontSize: 12.sp,fontWeight: FontWeight.w500,color: AppColors.white),
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
    final textTheme = Theme.of(context).textTheme;
    return Container(
     // margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border.all(width: 1.2,color: AppColors.textBorder),
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8.w,
            children: [
              Image.asset(Assets.saftyinfoIcon, width: 24.w, height: 24.h),
              Text(
                'Safety Information',
                style: textTheme.bodySmall?.copyWith(letterSpacing: 0.6, fontSize: 14.sp,fontWeight: FontWeight.w500,color: AppColors.white),
              ),
            ],
          ),
          SizedBox(height: 12.h,),
          Container(
            width: 300.w,
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w,),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              spacing: 5.w,
              children: [
                Icon(Icons.star_border, color: Colors.amberAccent),
                Text(
                  'Community Rating',
                  style: textTheme.bodySmall?.copyWith(letterSpacing: 0.6, fontSize: 14.sp,fontWeight: FontWeight.w500,color: AppColors.background),
                ),
                const Spacer(),
                Text(
                  "48",
                  style: textTheme.bodySmall?.copyWith(letterSpacing: 0.6, fontSize: 14.sp,fontWeight: FontWeight.w500,color: Colors.amberAccent),
                ),
                Text(
                  "/ 5",
                  style: textTheme.bodySmall?.copyWith(letterSpacing: 0.6, fontSize: 14.sp,fontWeight: FontWeight.w500,color: Colors.black),
                ),

              ],
            ),
          )
        ],
      ),
    );
  }
}



class LiveHighlightsCard extends StatelessWidget {
  const LiveHighlightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      //padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 5,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "Live Highlights",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff222222),
                    ),
                  ),

                  Text(
                    "View All",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),

                ],
              ),


              const SizedBox(height: 20),


              // Images
              Row(
                children: [

                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        "https://w7.pngwing.com/pngs/692/245/png-transparent-two-women-running-running-jogging-running-man-physical-fitness-sport-people-thumbnail.png",
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),


                  const SizedBox(width: 12),


                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        "https://w7.pngwing.com/pngs/692/245/png-transparent-two-women-running-running-jogging-running-man-physical-fitness-sport-people-thumbnail.png",
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                ],
              ),


              const SizedBox(height: 22),


              // Quote
              Text(
                '"Always well lit and plenty of other runners around. Feel very safe here!"',
                style: TextStyle(
                  fontSize: 20,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.brown.shade600,
                ),
              ),


              const SizedBox(height: 8),


              // Author
              Text(
                "— Sarah M.",
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.brown.shade600,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
