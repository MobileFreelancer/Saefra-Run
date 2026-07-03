import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
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
    final run = context.watch<RunService>();
    final session = run.session;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Live Running'),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      image: DecorationImage(
                        image: AssetImage(Assets.background),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.35),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24.h,
                    right: 24.w,
                    child: GestureDetector(
                      onTap: _showSosDialog,
                      child: Image.asset(
                        Assets.sos,
                        width: 44,
                        errorBuilder: (_, __, ___) => Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('SOS', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Track Details', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    'Route Remaining ${session.routeRemainingMeters}m',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    session.elapsedLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36.sp),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      _RunStat(label: 'Distance', value: '${session.distanceKm.toStringAsFixed(1)} km'),
                      _RunStat(label: 'Avg Pace', value: session.paceLabel),
                      _RunStat(label: 'Calories', value: '${session.calories} kcal'),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Pause',
                          onPressed: run.isRunning
                              ? () {
                                  run.pause();
                                  _showPauseDialog();
                                }
                              : null,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Stop',
                          onPressed: () {
                            run.stop();
                            context.pushReplacementNamed('runSummary');
                          },
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
    );
  }
}

class _RunStat extends StatelessWidget {
  const _RunStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 6.w),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 12.sp)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
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
