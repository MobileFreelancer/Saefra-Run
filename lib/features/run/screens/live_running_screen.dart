import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/run_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';
import 'package:saefra_run/core/widgets/app_route_map.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RunService>().startRun(
            routeId: widget.routeId,
            routeName: widget.routeName,
          );
      context.read<RunningProvider>().initTracking();
    });
  }

  void _showPauseDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PauseRunDialog(
        onResume: () {
          Navigator.pop(ctx);
          context.read<RunService>().resume();
        },
        onEnd: () {
          Navigator.pop(ctx);
          context.read<RunService>().stop();
          context.pushReplacementNamed('runSummary');
        },
      ),
    );
  }

  void _showSosDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SosConfirmDialog(
        onCancel: () => Navigator.pop(ctx),
        onSend: () async {
          Navigator.pop(ctx);
          await context.read<RunService>().activateSos();
          if (mounted) context.pushNamed('sosActive');
        },
      ),
    );
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
                            onPressed: () => context.read<RunningProvider>().togglePauseResume(),
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
                            onPressed: () => context.read<RunningProvider>().finishRun(),
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
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled, color: AppColors.primary, size: 56),
            SizedBox(height: 12.h),
            Text('Run Paused', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8.h),
            Text(
              'Your progress is saved. Take a breath. When you\'re ready.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16.h),
            PrimaryButton(label: 'Resume Run', onPressed: onResume),
            SizedBox(height: 8.h),
            SecondaryButton(label: 'End Run', onPressed: onEnd),
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
    return Dialog(
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(Assets.sos, width: 48, errorBuilder: (_, __, ___) => const Icon(Icons.warning_amber, color: AppColors.primary, size: 48)),
            SizedBox(height: 12.h),
            Text('Emergency SOS', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8.h),
            Text(
              'Your location will be shared with your emergency contacts. Do you want to continue?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: SecondaryButton(label: 'Cancel', onPressed: onCancel)),
                SizedBox(width: 8.w),
                Expanded(child: PrimaryButton(label: 'Send SOS', onPressed: onSend)),
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final run = context.watch<RunService>();

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
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        Assets.sos,
                        width: 56,
                        errorBuilder: (_, __, ___) => const Text(
                          'SOS',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'SOS Activated. Your location is now being shared with your emergency contacts.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 20.h),
                  Text('Emergency Contacts Notified', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 10.h),
                  ...settings.contacts.map(
                    (c) => ListTile(
                      leading: CircleAvatar(child: Text(c.name[0])),
                      title: Text(c.name),
                      subtitle: Text(c.phone),
                      trailing: const Icon(Icons.check_circle, color: AppColors.success),
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
                    label: "I'm Safe",
                    onPressed: () {
                      run.markSafe();
                      context.pop();
                    },
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
