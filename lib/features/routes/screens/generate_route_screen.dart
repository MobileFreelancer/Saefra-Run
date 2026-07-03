import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/generate_route_filters.dart';
import 'package:saefra_run/core/services/generate_route_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/segment_selector.dart';
import 'package:saefra_run/generated/assets.dart';

class GenerateRouteScreen extends StatefulWidget {
  const GenerateRouteScreen({super.key});

  @override
  State<GenerateRouteScreen> createState() => _GenerateRouteScreenState();
}

class _GenerateRouteScreenState extends State<GenerateRouteScreen> {
  Future<void> _generate() async {
    final service = context.read<GenerateRouteService>();
    final route = await service.generate();
    if (!mounted || route == null) {
      if (mounted && service.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(service.error!)),
        );
      }
      return;
    }
    context.pushNamed('routeDetail', pathParameters: {'id': route.id});
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GenerateRouteService>();
    final filters = service.filters;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Generate Route'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  _MapPreviewCard(onReset: () {
                    service.setDistance(5);
                    service.setDifficulty(RouteDifficulty.medium);
                    service.setShape(RouteShape.loop);
                    service.setLighting(RouteLighting.wellLit);
                  }),
                  SizedBox(height: 24.h),
                  Text(
                    'Route Setup',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distance',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                      Text(
                        '${filters.distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: filters.distanceKm,
                    min: 1,
                    max: 10,
                    divisions: 18,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceLight,
                    onChanged: service.setDistance,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 km', style: _hintStyle),
                      Text('10+ km', style: _hintStyle),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text('Difficulty', style: _sectionLabel),
                  SizedBox(height: 10.h),
                  SegmentSelector<RouteDifficulty>(
                    options: RouteDifficulty.values,
                    selected: filters.difficulty,
                    onChanged: service.setDifficulty,
                    labelBuilder: (v) => switch (v) {
                      RouteDifficulty.easy => 'Easy',
                      RouteDifficulty.medium => 'Medium',
                      RouteDifficulty.hard => 'Hard',
                    },
                  ),
                  SizedBox(height: 20.h),
                  Text('Route Type', style: _sectionLabel),
                  SizedBox(height: 10.h),
                  SegmentSelector<RouteShape>(
                    options: RouteShape.values,
                    selected: filters.shape,
                    onChanged: service.setShape,
                    labelBuilder: (v) =>
                        v == RouteShape.loop ? 'Loop' : 'One way',
                  ),
                  SizedBox(height: 20.h),
                  Text('Lighting & Visibility', style: _sectionLabel),
                  SizedBox(height: 10.h),
                  SegmentSelector<RouteLighting>(
                    options: RouteLighting.values,
                    selected: filters.lighting,
                    onChanged: service.setLighting,
                    labelBuilder: (v) => v == RouteLighting.wellLit
                        ? 'Well-lit'
                        : 'Dim/Dark',
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: PrimaryButton(
                label: 'Generate Route',
                isLoading: service.isLoading,
                onPressed: _generate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _sectionLabel => TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
      );

  TextStyle get _hintStyle => TextStyle(
        color: AppColors.textMuted,
        fontSize: 11.sp,
      );
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
        image: DecorationImage(
          image: AssetImage(Assets.generateRouteMapPreview),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12.h,
            right: 12.w,
            child: TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.9),
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              ),
              child: const Text('Reset Route'),
            ),
          ),
        ],
      ),
    );
  }
}
