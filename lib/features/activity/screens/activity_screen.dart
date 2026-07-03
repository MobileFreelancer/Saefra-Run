import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/services/activity_service.dart';
import 'package:saefra_run/core/widgets/app_bottom_nav.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/core/widgets/segment_selector.dart';
import 'package:saefra_run/generated/assets.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityService>();
    final summary = activity.summary;
    final lifetime = activity.lifetime;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: activity.isLoading && summary == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                children: [
                  Text('Activity', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16.h),
                  SegmentSelector<ActivityPeriod>(
                    options: ActivityPeriod.values,
                    selected: activity.period,
                    onChanged: activity.setPeriod,
                    labelBuilder: (p) => switch (p) {
                      ActivityPeriod.weekly => 'Weekly',
                      ActivityPeriod.monthly => 'Monthly',
                      ActivityPeriod.yearly => 'Yearly',
                    },
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _StatCard(
                        label: 'Distance',
                        value: '${summary?.totalDistanceKm.toStringAsFixed(1) ?? 0} km',
                      ),
                      SizedBox(width: 8.w),
                      _StatCard(
                        label: 'Time',
                        value: '${summary?.totalMinutes ?? 0} min',
                      ),
                      SizedBox(width: 8.w),
                      _StatCard(
                        label: 'Calories',
                        value: '${summary?.totalCalories ?? 0}',
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Text('Recent Runs', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 10.h),
                  ...activity.recentRuns.map(
                    (run) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _RecentRunTile(run: run),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('Lifetime Performance', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lifetime?.totalDistanceKm.toStringAsFixed(1) ?? 0} km total',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${lifetime?.totalHours ?? 0} hrs • ${lifetime?.totalCalories ?? 0} kcal',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Avg pace ${lifetime?.avgPaceMinPerKm.toStringAsFixed(1) ?? 0} min/km',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: (lifetime?.paceTrend ?? [])
                              .map(
                                (v) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 4.w),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4.r),
                                      child: LinearProgressIndicator(
                                        value: v,
                                        minHeight: 40.h * v,
                                        backgroundColor: AppColors.surfaceLight,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 2),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 4.h),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RecentRunTile extends StatelessWidget {
  const _RecentRunTile({required this.run});

  final RecentActivityModel run;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: SizedBox(
              width: 48.w,
              height: 48.w,
              child: AssetOrFallback(
                assetPath: run.mapImageAsset ?? Assets.background,
                fallback: const Icon(Icons.map, color: AppColors.primary),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(run.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13.sp)),
                Text(run.dateLabel, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${run.distanceKm} km • ${run.durationMinutes} min • ${run.paceLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.pushNamed('runSummary'),
            icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
