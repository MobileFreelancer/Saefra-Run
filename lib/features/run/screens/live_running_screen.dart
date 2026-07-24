import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/core/services/generate_route_service.dart';
import 'package:saefra_run/core/services/run_service.dart';
import 'package:saefra_run/core/services/route_detail_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/emergency_contact_avatar.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';
import 'package:saefra_run/generated/assets.dart';

import '../../../core/services/live_running_services.dart';

class LiveRunningScreen extends StatefulWidget {
  const LiveRunningScreen({super.key, this.routeId, this.routeName});

  final String? routeId;
  final String? routeName;

  @override
  State<LiveRunningScreen> createState() => _LiveRunningScreenState();
}

class _LiveRunningScreenState extends State<LiveRunningScreen> {
  bool _bootstrapped = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bindTrackingSync() {
    final tracking = context.read<RunningProvider>();
    final runService = context.read<RunService>();
    tracking.onTrackingUpdate =
        ({
          required latitude,
          required longitude,
          required distanceKm,
          required durationSeconds,
          required speedKmh,
          required steps,
          required pace,
        }) {
          runService.syncLiveUpdate(
            latitude: latitude,
            longitude: longitude,
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            speedKmh: speedKmh,
            pace: pace,
            steps: steps,
          );
        };
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped || !mounted) return;
    _bootstrapped = true;

    final tracking = context.read<RunningProvider>();
    final runService = context.read<RunService>();
    _bindTrackingSync();

    RouteModel? route = await _resolveRoute();
    if (!mounted) return;

    if (route != null) {
      final start = route.startPoint;
      final end = route.endPoint;
      if (start != null && end != null) {
        final points = route.polylinePoints;
        tracking.prepareForRun(
          startPoint: start,
          endPoint: end,
          routePolyline: points.length > 1 ? points : null,
        );
      }
    }

    await tracking.initTracking();
    if (!mounted) return;

    final lat =
        tracking.currentPosition?.latitude ??
        route?.startPoint?.latitude ??
        0.0;
    final lng =
        tracking.currentPosition?.longitude ??
        route?.startPoint?.longitude ??
        0.0;

    final started = await runService.startRun(
      routeId: widget.routeId,
      routeName: widget.routeName ?? route?.name,
      latitude: lat,
      longitude: lng,
    );

    if (!mounted) return;

    if (!started && runService.apiError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(runService.apiError!)));
    }

    if (!tracking.isTracking) {
      await tracking.startRunSession();
    }
  }

  Future<RouteModel?> _resolveRoute() async {
    final detail = context.read<RouteDetailService>();
    final generated = context.read<GenerateRouteService>().generatedRoute;
    final dashboard = context.read<DashboardServices>();

    if (widget.routeId != null && widget.routeId!.trim().isNotEmpty) {
      await detail.load(widget.routeId!);
      if (detail.route != null) return detail.route;
    }

    if (generated != null) return generated;

    final recommended = dashboard.recommendedRoute;
    if (recommended != null) {
      return RouteModel.fromJson(Map<String, dynamic>.from(recommended));
    }

    return null;
  }

  Future<void> _endRunAndGoToSummary() async {
    if (_isFinishing) return;
    _isFinishing = true;

    final tracking = context.read<RunningProvider>();
    final runService = context.read<RunService>();

    runService.completeFromTracking(
      distanceKm: tracking.totalDistanceKm,
      steps: tracking.totalSteps,
      secondsElapsed: tracking.secondsElapsed,
      routePath: List<LatLng>.from(tracking.runningPathCoordinates),
    );

    final lat = tracking.currentPosition?.latitude ?? 0.0;
    final lng = tracking.currentPosition?.longitude ?? 0.0;

    final finished = await runService.finishRunOnServer(
      latitude: lat,
      longitude: lng,
      routePath: List<LatLng>.from(tracking.runningPathCoordinates),
    );

    if (!mounted) return;

    if (!finished && runService.apiError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(runService.apiError!)));
    }

    await runService.loadRunSummary();
    tracking.onTrackingUpdate = null;
    tracking.finishRun();

    if (!mounted) return;
    context.pushReplacementNamed('runSummary');
  }

  void _showPauseDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _PauseRunDialog(
        onResume: () async {
          Navigator.pop(ctx);
          if (!context.read<RunningProvider>().isTracking) {
            context.read<RunningProvider>().togglePauseResume();
          }
          final ok = await context.read<RunService>().resume();
          if (!mounted) return;
          if (!ok && context.read<RunService>().apiError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.read<RunService>().apiError!)),
            );
          }
        },
        onEnd: () {
          Navigator.pop(ctx);
          _endRunAndGoToSummary();
        },
      ),
    );
  }

  void _showSosDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _SosConfirmDialog(
        onCancel: () => Navigator.pop(ctx),
        onSend: () async {
          Navigator.pop(ctx);

          final tracking = context.read<RunningProvider>();
          final dashboard = context.read<DashboardServices>();
          final settings = context.read<SettingsService>();
          final runService = context.read<RunService>();

          if (settings.contacts.isEmpty) {
            await settings.load();
          }

          final lat = tracking.currentPosition?.latitude ?? dashboard.latitude;
          final lng =
              tracking.currentPosition?.longitude ?? dashboard.longitude;
          final addressLink = lat != null && lng != null
              ? 'https://www.google.com/maps?q=$lat,$lng'
              : null;

          final ok = await runService.activateSos(
            latitude: lat,
            longitude: lng,
            addressLink: addressLink,
          );

          if (!mounted) return;

          if (ok) {
            context.pushNamed('sosActive');
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                runService.sosError ??
                    'Failed to activate SOS. Please try again.',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onPausePressed() async {
    final tracking = context.read<RunningProvider>();
    final runService = context.read<RunService>();

    if (tracking.isTracking) {
      tracking.togglePauseResume();
      final ok = await runService.pause();
      if (!mounted) return;
      if (!ok && runService.apiError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(runService.apiError!)));
      }
      _showPauseDialog();
    } else {
      tracking.togglePauseResume();
      final ok = await runService.resume();
      if (!mounted) return;
      if (!ok && runService.apiError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(runService.apiError!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingProvider = context.watch<RunningProvider>();
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  trackingProvider.currentPosition ??
                  const LatLng(37.7749, -122.4194),
              zoom: 18.5, // More zoom like the screenshot
              tilt: 0,
              bearing: 0,
            ),
            onMapCreated: (GoogleMapController controller) {
              trackingProvider.onMapReady(controller);
              context.read<DashboardServices>().applyMapStyle(controller);

              if (trackingProvider.currentPosition != null) {
                controller.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: trackingProvider.currentPosition!,
                      zoom: 18.5,
                      tilt: 0,
                      bearing: 0,
                    ),
                  ),
                );
              }
            },
            polylines: Set<Polyline>.of(trackingProvider.polylines.values),
            markers: trackingProvider.buildMarkerSet(),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // GoogleMap(
          //   initialCameraPosition: CameraPosition(
          //     target: trackingProvider.currentPosition ?? const LatLng(37.7749, -122.4194),
          //     zoom: 16,
          //   ),
          //   onMapCreated: (GoogleMapController controller) {
          //     trackingProvider.onMapReady(controller);
          //     context.read<DashboardServices>().applyMapStyle(controller);
          //   },
          //   polylines: Set<Polyline>.of(trackingProvider.polylines.values),
          //   markers: trackingProvider.buildMarkerSet(),
          //   onTap: (LatLng position) {
          //     // if (!trackingProvider.mapController.isCompleted) {
          //     //   trackingProvider.mapController.complete(trackingProvider.mapController);
          //     // }
          //     //trackingProvider.selectDestination(position);
          //   },
          //   myLocationEnabled: false,
          //   zoomControlsEnabled: false,
          //   mapToolbarEnabled: false,
          // ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D0D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sesi Judul Detail & Tombol SOS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Track Details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trackingProvider.destinationPosition == null
                                ? 'Loading route...'
                                : 'Route Remaining: ${trackingProvider.routeRemainingStr}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (trackingProvider.isUsingStepTracking) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Indoor mode: tracking steps along route',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      // SOS EMERGENCY BUTTON
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0x33E52344),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFE52344),
                          radius: 20,
                          child: InkWell(
                            onTap: () {
                              print("---------------------------sdsdsdsdsdsds");
                              _showSosDialog();
                            },
                            child: const Text(
                              'SOS',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // LIVE RUNNING TIME DISPLAY
                  Text(
                    'Running time',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  Text(
                    trackingProvider.formattedDuration,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // WHITE METRICS ROW CARD (KM, STEPS, KM/HR)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricItem(
                          "assets/images/runicon.png",
                          trackingProvider.totalDistanceKm < 0.1
                              ? trackingProvider.totalDistanceKm
                                    .toStringAsFixed(2)
                              : trackingProvider.totalDistanceKm
                                    .toStringAsFixed(1),
                          "km",
                        ),
                        _buildVerticalDivider(),
                        _buildMetricItem(
                          "assets/images/runicon.png",
                          "${trackingProvider.totalSteps}",
                          "Steps",
                        ),
                        _buildVerticalDivider(),
                        _buildMetricItem(
                          "assets/images/kmphicon.png",
                          trackingProvider.currentSpeedKmh.toStringAsFixed(1),
                          "km/hr",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    children: [
                      if (!trackingProvider.isTracking &&
                          trackingProvider.secondsElapsed == 0) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context
                                .read<RunningProvider>()
                                .startRunSession(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Start Run Session",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onPausePressed,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  trackingProvider.isTracking
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  trackingProvider.isTracking
                                      ? "Pause"
                                      : "Resume",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: _endRunAndGoToSummary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE52344),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  color: AppColors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Finish",
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }

  Widget _buildMetricItem(String icon, String value, String unit) {
    return Column(
      children: [
        Row(
          children: [
            Image.asset(icon, scale: 2.5),
            // Icon(icon, color: const Color(0xFFF07522), size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _PauseRunDialog extends StatelessWidget {
  const _PauseRunDialog({required this.onResume, required this.onEnd});

  final VoidCallback onResume;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Assets.pauseDialogImg,
              height: 88.h,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.pause_circle_filled,
                color: AppColors.primary,
                size: 72.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Run Paused',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Your progress is saved. Take a breath, check your surroundings.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontSize: 14.sp,
                height: 1.45,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.white,
                ),
                label: const Text('Resume Run'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEnd,
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: AppColors.white,
                ),
                label: const Text('End Run'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(
                    color: AppColors.buttonColor,
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosConfirmDialog extends StatelessWidget {
  const _SosConfirmDialog({required this.onCancel, required this.onSend});

  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Assets.emergencyDialogImg,
              height: 88.h,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
                size: 72,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Emergency SOS',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Your live location will be shared with your emergency contacts. Do you want to continue?',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontSize: 14.sp,
                height: 1.45,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(
                        color: AppColors.buttonColor,
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: const Text('Send SOS'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SosActiveScreen extends StatefulWidget {
  const SosActiveScreen({super.key});

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsService>().load();
    });
  }

  Future<void> _markSafe() async {
    final run = context.read<RunService>();
    final ok = await run.markSafe();
    if (!mounted) return;

    if (ok) {
      safePop(context, fallback: '/run/live');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          run.sosError ?? 'Failed to cancel SOS. Please try again.',
        ),
      ),
    );
  }

  void _showEmergencyContactSelectionDialog(
    BuildContext context,
    List<dynamic> contacts,
    RunService runService,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Contact to Call',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22.sp,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 300.h,
                child: ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (listCtx, idx) {
                    final contact = contacts[idx];
                    final name = contact.name ?? 'Unknown';
                    final phone = contact.phone ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaced1F,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        leading: EmergencyContactAvatar(
                          contact: contact,
                          radius: 18.r,
                        ),
                        title: Text(
                          name,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        subtitle: Text(
                          phone,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12.sp,
                              ),
                        ),
                        onTap: () async {
                          Navigator.pop(listCtx);
                          final ok = await runService.callEmergencyContact(
                            contact,
                          );
                          if (!mounted) return;

                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  runService.emergencyCallError ??
                                      'Failed to initiate call. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                        trailing: Icon(
                          Icons.phone,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(
                      color: AppColors.buttonColor,
                      width: 1.5,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final run = context.watch<RunService>();
    final contacts = run.sosNotifiedContacts.isNotEmpty
        ? run.sosNotifiedContacts
        : settings.contacts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Emergency SOS'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0x33E52344),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0x33E52344),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFE52344),
                          radius: 30,
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    run.sosMessage ??
                        'SOS Activated. Your location is now being shared with your emergency contacts.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Emergency Contacts Notified',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 10.h),
                  if (settings.isLoading && contacts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (contacts.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        'No emergency contacts found. Add contacts in Settings first.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  else
                    ...contacts.map(
                      (c) => Container(
                        margin: EdgeInsets.only(
                          bottom: 12.h,
                        ), // Spacing between list items
                        decoration: BoxDecoration(
                          color: AppColors.surfaced1F, // Card background color
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.white.withValues(
                              alpha: 0.1,
                            ), // Subtle border outline
                            width: 1.w,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          leading: EmergencyContactAvatar(
                            contact: c,
                            radius: 20.r,
                          ),
                          title: Text(
                            c.name,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Alert Sent',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors
                                          .success, // Assuming AppColors.success is green
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons
                                    .check_box, // Matches the square checkbox in the design
                                color: AppColors.success,
                                size: 20.w,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Share Live Notification',
                    isLoading: context
                        .watch<RunService>()
                        .isShareLocationLoading,
                    onPressed: () async {
                      final tracking = context.read<RunningProvider>();
                      final dashboard = context.read<DashboardServices>();
                      final run = context.read<RunService>();
                      final lat =
                          tracking.currentPosition?.latitude ??
                          dashboard.latitude ??
                          0.0;
                      final lng =
                          tracking.currentPosition?.longitude ??
                          dashboard.longitude ??
                          0.0;
                      if (lat == 0.0 && lng == 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Location not available. Please enable GPS.',
                            ),
                          ),
                        );
                        return;
                      }

                      final ok = await run
                          .shareUpdatedLocationWithEmergencyContact(
                            latitude: lat,
                            longitude: lng,
                          );

                      if (!mounted) return;

                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Location shared with emergency contacts.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              run.shareLocationError ??
                                  'Failed to share location. Please try again.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 8.h),
                  SecondaryButton(
                    label: context.watch<RunService>().emergencyCallLoading
                        ? 'Calling...'
                        : 'Call local emergency service',
                    onPressed: context.watch<RunService>().emergencyCallLoading
                        ? null
                        : () async {
                            final settings = context.read<SettingsService>();
                            final run = context.read<RunService>();
                            final contacts = run.sosNotifiedContacts.isNotEmpty
                                ? run.sosNotifiedContacts
                                : settings.contacts;

                            if (contacts.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No emergency contacts available. Please add an emergency contact in Settings.',
                                  ),
                                ),
                              );
                              return;
                            }

                            // If only one contact, call directly
                            if (contacts.length == 1) {
                              final ok = await run.callEmergencyContact(
                                contacts.first,
                              );
                              if (!mounted) return;

                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      run.emergencyCallError ??
                                          'Failed to initiate call. Please try again.',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            // Show contact selection dialog
                            _showEmergencyContactSelectionDialog(
                              context,
                              contacts,
                              run,
                            );
                          },
                  ),
                  SizedBox(height: 8.h),
                  SecondaryButton(
                    label: run.sosLoading ? 'Cancelling...' : "I'm Safe",
                    onPressed: run.sosLoading ? null : _markSafe,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .lock_outline_rounded, // Matches the square checkbox in the design
                    color: AppColors.whiteText,
                    size: 15.w,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Your live location will remain shared until SOS is turned off. Only select 'I'm Safe' when you're out of danger.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors
                            .whiteText, // Assuming AppColors.success is green
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
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
