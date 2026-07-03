import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/run_session_model.dart';
import 'package:saefra_run/core/services/run_service.dart';
import 'package:saefra_run/core/widgets/app_route_map.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class RunSummaryScreen extends StatefulWidget {
  const RunSummaryScreen({super.key});

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen> {
  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunService>();
    final session = run.session;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Run Summary'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  Center(
                    child: Image.asset(
                      Assets.successMark,
                      height: 56.h,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.emoji_events,
                        color: AppColors.primary,
                        size: 56,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Great Job!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'You completed your run!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _Stat(label: 'Distance', value: '${session.distanceKm.toStringAsFixed(2)} km'),
                      _Stat(label: 'Total Time', value: session.durationLabel),
                      _Stat(label: 'Pace', value: session.paceLabel),
                      _Stat(label: 'Kcal', value: '${session.calories}'),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: AppRouteMap(height: 140.h, borderRadius: 14),
                  ),
                  SizedBox(height: 16.h),
                  Text('Splits Rate', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8.h),
                  ...session.splits.map(
                    (split) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Text('KM ${split.km}', style: Theme.of(context).textTheme.bodySmall),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: split.paceFactor,
                                color: AppColors.primary,
                                backgroundColor: AppColors.surfaceLight,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(split.timeLabel, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('How did the run feel?', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: RunMood.values.map((mood) {
                      final selected = run.mood == mood;
                      return GestureDetector(
                        onTap: () => run.setMood(mood),
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(_moodEmoji(mood), style: TextStyle(fontSize: 22.sp)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Save Activity',
                    onPressed: () async {
                      await run.saveActivity();
                      if (context.mounted) context.pushNamed('runRate');
                    },
                  ),
                  SizedBox(height: 8.h),
                  SecondaryButton(
                    label: 'Discard Activity',
                    onPressed: () async {
                      await run.discardActivity();
                      if (context.mounted) context.goNamed('dashboard');
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

  String _moodEmoji(RunMood mood) => switch (mood) {
        RunMood.sore => '😣',
        RunMood.tired => '😮‍💨',
        RunMood.okay => '😐',
        RunMood.good => '🙂',
        RunMood.great => '🤩',
      };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 6.w),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 11.sp)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
