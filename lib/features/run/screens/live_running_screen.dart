import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/core/services/run_service.dart';
import 'package:saefra_run/core/services/route_detail_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/emergency_contact_avatar.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';
import 'package:saefra_run/generated/assets.dart';

import '../../../core/services/live_runing_services.dart';

class LiveRunningScreen extends StatefulWidget {
  const LiveRunningScreen({super.key, this.routeId, this.routeName});

  final String? routeId;
  final String? routeName;

  @override
  State<LiveRunningScreen> createState() => _LiveRunningScreenState();
}

class _LiveRunningScreenState extends State<LiveRunningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<RunService>().startRun(
            routeId: widget.routeId,
            routeName: widget.routeName,
          );

      final tracking = context.read<RunningProvider>();
      if (widget.routeId != null && tracking.destinationPosition == null) {
        final detail = context.read<RouteDetailService>();
        await detail.load(widget.routeId!);
        final route = detail.route;
        final start = route?.startPoint;
        final end = route?.endPoint;
        if (start != null && end != null) {
          final points = route!.polylinePoints;
          tracking.selectDestination(
            startPoint: start,
            endPoint: end,
            routePolyline: points.length > 1 ? points : null,
          );
        }
      }

      if (mounted) {
        tracking.initTracking();
      }
    });
  }

  void _endRunAndGoToSummary() {
    final tracking = context.read<RunningProvider>();
    context.read<RunService>().completeFromTracking(
      distanceKm: tracking.totalDistanceKm,
      steps: tracking.totalSteps,
      secondsElapsed: tracking.secondsElapsed,
      routePath: List<LatLng>.from(tracking.runningPathCoordinates),
    );
    tracking.finishRun();
    context.pushReplacementNamed('runSummary');
  }

  void _showPauseDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _PauseRunDialog(
        onResume: () {
          Navigator.pop(ctx);
          if (!context.read<RunningProvider>().isTracking) {
            context.read<RunningProvider>().togglePauseResume();
          }
          context.read<RunService>().resume();
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

          final lat =
              tracking.currentPosition?.latitude ?? dashboard.latitude;
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
                runService.sosError ?? 'Failed to activate SOS. Please try again.',
              ),
            ),
          );
        },
      ),
    );
  }

  void _onPausePressed() {
    final tracking = context.read<RunningProvider>();
    if (tracking.isTracking) {
      tracking.togglePauseResume();
      context.read<RunService>().pause();
      _showPauseDialog();
    } else {
      tracking.togglePauseResume();
      context.read<RunService>().resume();
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
              target: trackingProvider.currentPosition ?? const LatLng(37.7749, -122.4194),
              zoom: 16,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (!trackingProvider.mapController.isCompleted) {
                trackingProvider.mapController.complete(controller);
              }
              context.read<DashboardServices>().applyMapStyle(controller);
            },
            polylines: Set<Polyline>.of(trackingProvider.polylines.values),
            markers: Set<Marker>.of(trackingProvider.markers.values),
            onTap: (LatLng position) {
              // if (!trackingProvider.mapController.isCompleted) {
              //   trackingProvider.mapController.complete(trackingProvider.mapController);
              // }
              //trackingProvider.selectDestination(position);
            },
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

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
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trackingProvider.destinationPosition == null
                                ? '👉 Tap map to select destination'
                                : 'Route Remaining: ${trackingProvider.routeRemainingStr}',
                            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                          ),
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
                              _showSosDialog();
                            },
                            child: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),

                  // LIVE RUNNING TIME DISPLAY
                  Text('Running time', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                  Text(
                    trackingProvider.formattedDuration,
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // WHITE METRICS ROW CARD (KM, STEPS, KM/HR)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricItem(Icons.directions_run, trackingProvider.totalDistanceKm.toStringAsFixed(1), "km"),
                        _buildVerticalDivider(),
                        _buildMetricItem(Icons.directions_walk, "${trackingProvider.totalSteps}", "Steps"),
                        _buildVerticalDivider(),
                        _buildMetricItem(Icons.flash_on, trackingProvider.currentSpeedKmh.toStringAsFixed(1), "km/hr"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),


                  Row(
                    children: [
                      if (!trackingProvider.isTracking && trackingProvider.secondsElapsed == 0) ...[

                        Expanded(
                          child: ElevatedButton(
                            onPressed: trackingProvider.destinationPosition == null
                                ? null
                                : () => context.read<RunningProvider>().startRunSession(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE52344),
                              disabledBackgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text("Start Run Session", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ] else ...[

                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onPausePressed,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE52344), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(trackingProvider.isTracking ? Icons.pause : Icons.play_arrow, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(trackingProvider.isTracking ? "Pause" : "Resume", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flag, color: Colors.white),
                                const SizedBox(width: 8),
                                Text("Finish", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
          )
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }

  Widget _buildMetricItem(IconData icon, String value, String unit) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFF07522), size: 18), // Warna jingga ikon sesuai Screenshot
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
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
                icon: const Icon(Icons.play_arrow_rounded, color: AppColors.white),
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
                icon: const Icon(Icons.stop_circle_outlined, color: AppColors.white),
                label: const Text('End Run'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.buttonColor, width: 1.5),
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
                      side: const BorderSide(color: AppColors.buttonColor, width: 1.5),
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
      context.pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(run.sosError ?? 'Failed to cancel SOS. Please try again.'),
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
                    child:  Container(
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
                          child: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    )
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
                      (c) => ListTile(
                        leading: EmergencyContactAvatar(
                          contact: c,
                          radius: 20,
                        ),
                        title: Text(c.name),
                        subtitle: Text(c.phone),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
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
                    onPressed: () {},
                  ),
                  SizedBox(height: 8.h),
                  SecondaryButton(
                    label: 'Call local emergency service',
                    onPressed: () {},
                  ),
                  SizedBox(height: 8.h),
                  SecondaryButton(
                    label: run.sosLoading ? 'Cancelling...' : "I'm Safe",
                    onPressed: run.sosLoading ? null : _markSafe,
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
