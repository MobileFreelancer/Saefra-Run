import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/generate_route_filters.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/core/services/generate_route_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/app_route_map.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

import '../../../generated/assets.dart';

class GenerateRouteScreen extends StatefulWidget {
  const GenerateRouteScreen({super.key});

  @override
  State<GenerateRouteScreen> createState() => _GenerateRouteScreenState();
}

class _GenerateRouteScreenState extends State<GenerateRouteScreen> {
  // Local state variable to manage dynamic unit toggling
  bool _isKm = true;

  Future<void> _generate() async {
    final service = context.read<GenerateRouteService>();
    final dashboard = context.read<DashboardServices>();
    final route = await service.generate(
      latitude: dashboard.latitude,
      longitude: dashboard.longitude,
    );
    log("=========================");
    log("lat--${dashboard.latitude}---long--${dashboard.longitude}");
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
  void initState() {
    final dashboard = context.read<DashboardServices>();
    final service = context.read<GenerateRouteService>();

    service.markers.add(
        Marker(markerId: const MarkerId('origin'),
            position: LatLng(dashboard.latitude!, dashboard.longitude!),
            icon: BitmapDescriptor.defaultMarker
        )
    );

    service.markers.add(
        Marker(markerId: const MarkerId('destination'),
            position: LatLng(dashboard.destinationPositionLatitude!, dashboard.destinationPositionLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(90)
        )
    );
    service.getPolyline(originPosition: LatLng(dashboard.latitude!, dashboard.longitude!), destinationPosition: LatLng(dashboard.destinationPositionLatitude!, dashboard.destinationPositionLongitude!));
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final service = context.watch<GenerateRouteService>();
    final filters = service.filters;
    final textTheme = Theme.of(context).textTheme;

    // Derived theme elements using AppColors parameters
    final cardBg = AppColors.surfaced;
    final cardBorderColor = AppColors.border.withValues(alpha: 0.5);
    final unselectedItemBorder = AppColors.border.withValues(alpha: 0.5);
    final selectedBg =  AppColors.primary.withValues(alpha: 0.2); // Dark crimson matching mockup active state
    final selectedBorder = AppColors.primary;
    final textMuted = AppColors.white.withValues(alpha: 0.8);
    // Dynamic math conversion calculation: 1 mile = 1.60934 km
    final double displayedDistance = _isKm ? filters.distanceKm : (filters.distanceKm / 1.60934);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Generate Route'),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  SizedBox(height: 8.h),
                  Text('Create My Route', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text("Define your path. We'll ensure it's safe and optimized for your performance goals.", style: TextStyle(color:  textMuted, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: SizedBox(
                      width: 300.w,
                      height: 180.h,
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(21.205194905801783, 72.77568113625402),
                          zoom: 15,
                        ),
                        myLocationEnabled: true,
                        tiltGesturesEnabled: true,
                        compassEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        onMapCreated: (GoogleMapController controller) {
                          service.googleMapController.complete(controller);
                        },
                        markers: service.markers,
                        polylines: service.polyline,
                      ),
                    ),
                  ),
                  // _MapPreviewCard(
                  //   polylinePoints: service.previewPolylinePoints,
                  //   onReset: () {
                  //     setState(() => _isKm = true);
                  //     service.setDistance(5);
                  //     service.setDifficulty(RouteDifficulty.moderate);
                  //     service.setShape(RouteShape.loop);
                  //     service.setLighting(RouteLighting.wellLit);
                  //   },
                  // ),
                  Text('Route Setup', style: textTheme.titleMedium),
                  SizedBox(height: 12.h),

                  // 1. DISTANCE CARD
                  Container(
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: cardBorderColor, width: 1.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Distance', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,color: AppColors.white)),
                            // DYNAMIC KM/MILES TOGGLE PILL
                            Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(color: unselectedItemBorder),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _isKm = true),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: _isKm ? selectedBg : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4.r),
                                        border: Border.all(color: _isKm ? selectedBorder.withValues(alpha: 0.5) : Colors.transparent),
                                      ),
                                      child: Text('KM', style: TextStyle(color: _isKm ? selectedBorder : textMuted, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _isKm = false),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: !_isKm ? selectedBg : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4.r),
                                        border: Border.all(color: !_isKm ? selectedBorder.withValues(alpha: 0.5) : Colors.transparent),
                                      ),
                                      child: Text('Miles', style: TextStyle(color: !_isKm ? selectedBorder : textMuted, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Text(
                              displayedDistance.toStringAsFixed(1),
                              style: TextStyle(color: AppColors.primary, fontSize: 18.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 3.w),
                            Text(_isKm ? 'km' : 'mi', style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold)),

                          ],
                        ),
                        SizedBox(height: 2.h),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 10.h,
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surfaceLight.withValues(alpha: 0.4),
                            overlayColor: AppColors.primary.withValues(alpha: 0.15),
                            // Using our custom pixel-perfect square block shape builder
                            thumbShape: _CustomSquareSliderThumbShape(
                              thumbRadius: 14.r,
                              thumbColor: AppColors.primary,
                              borderColor: Colors.white,
                              borderWidth: 2.w,
                              borderRadius: 6.r,
                            ),
                            // Strips away default padding limits for seamless edges
                            trackShape: const _NoPaddingSliderTrackShape(),
                          ),
                          child: Slider(
                            value: filters.distanceKm.clamp(1.0, 42.2),
                            min: 1,
                            max: 42.2,
                            onChanged: service.setDistance,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_isKm ? '1 km' : '0.6 mi', style: TextStyle(color: textMuted, fontSize: 12.sp)),
                            Text(_isKm ? 'Marathon\n(42.2)' : 'Marathon\n(26.2)', textAlign: TextAlign.right, style: TextStyle(color: textMuted, fontSize: 12.sp)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. DIFFICULTY CARD
                  Container(
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: cardBorderColor, width: 1.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Difficulty', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,color: AppColors.white)),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionBlock(
                                label: 'Easy',
                                icon: Icons.run_circle_outlined,
                                imageAssetPath: Assets.onboardingEasyPaceIcon, // Dynamic asset image
                                isSelected: filters.difficulty == RouteDifficulty.easy,
                                selectedBg: selectedBg,
                                selectedBorder: selectedBorder,
                                unselectedBorder: unselectedItemBorder,
                                accentIconColor: AppColors.primary,
                                onTap: () => service.setDifficulty(RouteDifficulty.easy),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildOptionBlock(
                                label: 'Medium',
                                icon: Icons.directions_run,
                                imageAssetPath: Assets.onboardingModerateChallengeIcon, // Dynamic asset image
                                isSelected: filters.difficulty == RouteDifficulty.moderate,
                                selectedBg: selectedBg,
                                selectedBorder: selectedBorder,
                                unselectedBorder: unselectedItemBorder,
                                onTap: () => service.setDifficulty(RouteDifficulty.moderate),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildOptionBlock(
                                label: 'Hard',
                                icon: Icons.terrain,
                                isSelected: filters.difficulty == RouteDifficulty.hard,
                                imageAssetPath: Assets.onboardingPushMyLimitIcon, // Dynamic asset image
                                selectedBg: selectedBg,
                                selectedBorder: selectedBorder,
                                unselectedBorder: unselectedItemBorder,
                                accentIconColor: AppColors.primary,
                                onTap: () => service.setDifficulty(RouteDifficulty.hard),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. ROUTE TYPE CARD
                  Container(
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: cardBorderColor, width: 1.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Route Type', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,color: AppColors.white)),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionBlock(
                                label: 'Loop',
                                icon: Icons.all_inclusive,
                                isSelected: filters.shape == RouteShape.loop,
                                selectedBg: selectedBg,
                                selectedBorder: selectedBorder,
                                unselectedBorder: unselectedItemBorder,
                                isRowStyle: true,
                                onTap: () => service.setShape(RouteShape.loop),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildOptionBlock(
                                label: 'One-way',
                                icon: Icons.trending_flat,
                                isSelected: filters.shape == RouteShape.oneWay,
                                selectedBg: selectedBg,
                                selectedBorder: selectedBorder,
                                unselectedBorder: unselectedItemBorder,
                                isRowStyle: true,
                                onTap: () => service.setShape(RouteShape.oneWay),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. LIGHTING & VISIBILITY CARD
                  Container(
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: cardBorderColor, width: 1.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lighting & Visibility', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,color: AppColors.white)),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionBlock(
                                label: 'Well-lit',
                                icon: Icons.wb_sunny_outlined,
                                isSelected: filters.lighting == RouteLighting.wellLit,
                                selectedBg: selectedBg,
                                selectedBorder: selectedBorder,
                                unselectedBorder: unselectedItemBorder,
                                isRowStyle: true,
                                onTap: () => service.setLighting(RouteLighting.wellLit),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildOptionBlock(
                                label: 'Dim/Dark',
                                icon: Icons.nightlight_round,
                                isSelected: filters.lighting == RouteLighting.dimDark,
                                selectedBg: selectedBg,
                                selectedBorder: selectedBorder,
                                unselectedBorder: unselectedItemBorder,
                                isRowStyle: true,
                                onTap: () => service.setLighting(RouteLighting.dimDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

  Widget _buildOptionBlock({
    required String label,
    IconData? icon,
    String? imageAssetPath, // Accepts asset path strings seamlessly
    required bool isSelected,
    required Color selectedBg,
    required Color selectedBorder,
    required Color unselectedBorder,
    Color? accentIconColor,
    bool isRowStyle = false,
    required VoidCallback onTap,
  }) {
    final contentColor = isSelected ? AppColors.white : (accentIconColor ?? AppColors.white.withValues(alpha: 0.4));
    final textColor = isSelected ? AppColors.white : AppColors.white.withValues(alpha: 0.5);

    // Render Image Asset if provided; otherwise fall back to regular Icon layout
    final Widget visualElement = imageAssetPath != null
        ? Image.asset(
      imageAssetPath,
      width: 24.r,
      height: 24.r,
      color: isSelected ? null : AppColors.white.withValues(alpha: 0.8), // Keeps unselected assets subtle
    )
        : Icon(icon, color: contentColor, size: 22.r);

    final innerContent = [
      visualElement,
      SizedBox(width: isRowStyle ? 8.w : 0, height: isRowStyle ? 0 : 8.h),
      Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: 1.5,
          ),
        ),
        child: isRowStyle
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: innerContent)
            : Column(mainAxisSize: MainAxisSize.min, children: innerContent),
      ),
    );
  }
}

class _CustomSquareSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final Color thumbColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  const _CustomSquareSliderThumbShape({
    required this.thumbRadius,
    required this.thumbColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbRadius * 2, thumbRadius * 2);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final Canvas canvas = context.canvas;

    final rect = Rect.fromCenter(
      center: center,
      width: thumbRadius * 2,
      height: thumbRadius * 2,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // 1. Paint the solid background color
    final fillPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // 2. Paint the crisp outer border accent layer
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, borderPaint);
  }
}
class _NoPaddingSliderTrackShape extends RectangularSliderTrackShape {
  const _NoPaddingSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;

    // Returns full parent container width with zero margin offsets
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}
class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.onReset,
    this.polylinePoints = const [],
  });

  final VoidCallback onReset;
  final List<LatLng> polylinePoints;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 180.h,
        child: Stack(
          children: [
            AppRouteMap(
              height: 200,
              borderRadius: 16,
              polylinePoints: polylinePoints.isNotEmpty ? polylinePoints : null,
            ),
            Positioned(
              top: 12.h,
              right: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.white, size: 14.r),
                    SizedBox(width: 4.w),
                    Text(
                      'Route Secure',
                      style: TextStyle(color: AppColors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}