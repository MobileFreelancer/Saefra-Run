import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/live_runing_services.dart';
import 'package:saefra_run/core/services/run_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';
import 'package:saefra_run/generated/assets.dart';

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

  void _onPause(RunService run) {
    if (run.isRunning) {
      run.pause();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PauseRunDialog(
          onResume: () {
            Navigator.pop(ctx);
            run.resume();
            context.read<RunningProvider>().resumeSession();
          },
          onEnd: () {
            Navigator.pop(ctx);
            _finishRun(run);
          },
        ),
      );
    } else if (run.isPaused) {
      run.resume();
      context.read<RunningProvider>().resumeSession();
    }
  }

  void _finishRun(RunService run) {
    run.stop();
    context.read<RunningProvider>().finishRun();
    if (mounted) context.pushReplacementNamed('runSummary');
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
    final tracking = context.watch<RunningProvider>();
    final run = context.watch<RunService>();
    final session = run.session;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: tracking.currentPosition ??
                  const LatLng(21.205194905801783, 72.77568113625402),
              zoom: 16,
            ),
            onMapCreated: (controller) {
              if (!tracking.mapController.isCompleted) {
                tracking.mapController.complete(controller);
              }
            },
            polylines: Set<Polyline>.of(tracking.polylines.values),
            markers: Set<Marker>.of(tracking.markers.values),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withValues(alpha: 0.85),
                      AppColors.background.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const AppPageHeader(title: 'Live Run'),
              ),
            ),
          ),

          // Track details bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 72.h,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 12.w),
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Track Details',
                    style: textTheme.titleLarge?.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    tracking.destinationPosition == null
                        ? 'Following your route'
                        : 'Remaining: ${tracking.routeRemainingStr}',
                    style: textTheme.bodySmall,
                  ),
                  SizedBox(height: 16.h),
                  Text('Running time', style: textTheme.bodySmall),
                  SizedBox(height: 4.h),
                  Text(
                    _formatDuration(session.elapsed),
                    style: textTheme.displayLarge?.copyWith(
                      fontSize: 36.sp,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        _LiveMetric(
                          icon: Icons.straighten,
                          value: session.distanceKm.toStringAsFixed(1),
                          unit: 'km',
                        ),
                        _LiveMetricDivider(),
                        _LiveMetric(
                          icon: Icons.speed,
                          value: session.paceLabel.split(' ').first,
                          unit: '/km',
                        ),
                        _LiveMetricDivider(),
                        _LiveMetric(
                          icon: Icons.local_fire_department_outlined,
                          value: '${session.calories}',
                          unit: 'Kcal',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _onPause(run),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                          ),
                          child: Text(
                            run.isPaused ? 'Resume' : 'Pause',
                            style: textTheme.labelLarge,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _finishRun(run),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                          ),
                          child: Text('Stop', style: textTheme.labelLarge),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                height: 64.h,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(color: AppColors.white.withValues(alpha: 0.06)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BottomAction(
                      label: 'SOS',
                      isSos: true,
                      onTap: _showSosDialog,
                    ),
                    _BottomAction(
                      icon: Icons.music_note_outlined,
                      onTap: () {},
                    ),
                    _BottomAction(
                      icon: run.isRunning ? Icons.pause : Icons.play_arrow,
                      isPrimary: true,
                      onTap: () => _onPause(run),
                    ),
                    _BottomAction(
                      icon: Icons.camera_alt_outlined,
                      onTap: () {},
                    ),
                    _BottomAction(
                      icon: Icons.more_horiz,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({
    required this.icon,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(fontSize: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(unit, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LiveMetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28.h,
      width: 1,
      color: AppColors.border,
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    this.icon,
    this.label,
    this.onTap,
    this.isSos = false,
    this.isPrimary = false,
  });

  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  final bool isSos;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isSos) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            label ?? 'SOS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontSize: 11.sp,
                ),
          ),
        ),
      );
    }

    if (isPrimary) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48.w,
          height: 48.w,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.white, size: 24.sp),
        ),
      );
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textMuted, size: 24.sp),
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
            Icon(Icons.pause_circle_filled, color: AppColors.primary, size: 56.sp),
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
            SecondaryButton(label: 'Finish', onPressed: onEnd),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Assets.sos,
              width: 48.w,
              errorBuilder: (_, __, ___) => Icon(
                Icons.warning_amber,
                color: AppColors.primary,
                size: 48.sp,
              ),
            ),
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
    final textTheme = Theme.of(context).textTheme;

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
                        width: 56.w,
                        errorBuilder: (_, __, ___) => Text(
                          'SOS',
                          style: textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'SOS Activated. Your location is now being shared with your emergency contacts.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Emergency Contacts Notified',
                    style: textTheme.titleMedium,
                  ),
                  SizedBox(height: 10.h),
                  ...settings.contacts.map(
                    (c) => Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18.r,
                            backgroundColor: AppColors.surfaceLight,
                            child: Text(
                              c.name[0],
                              style: textTheme.labelLarge,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: textTheme.titleMedium?.copyWith(fontSize: 14.sp)),
                                Text(c.phone, style: textTheme.bodySmall),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80.w,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: const LinearProgressIndicator(
                                value: 1,
                                color: AppColors.success,
                                backgroundColor: AppColors.surfaceLight,
                              ),
                            ),
                          ),
                        ],
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
                    label: 'Send Current Location',
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
