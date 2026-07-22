import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/services/activity_service.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_bottom_nav.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/generated/assets.dart';

import '../../../core/widgets/activity_shimmer_screen.dart';

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

  TextStyle _body(BuildContext context, {Color? color, FontWeight? weight}) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: color ?? AppColors.white,
          fontWeight: weight,
        );
  }

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityService>();
    final lifetime = activity.lifetime;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleRootBack(context);
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: activity.isLoading && activity.recentRuns.isEmpty
            ? ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          itemBuilder: (context, index) {
            return   const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ActivityCardShimmer(isActivity: true,),
            );
          },
        )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    context.read<ActivityService>().load(refresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  Center(
                    child: Text(
                      'Activity',
                      style: _body(context, weight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _SectionHeader(
                    title: 'Recent Runs',
                    onViewAll: () {},
                    bodyStyle: _body(context),
                  ),
                  SizedBox(height: 12.h),
                  ...activity.recentRuns.map(
                    (run) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _RecentRunCard(
                        run: run,
                        bodyStyle: _body(context),
                        onTap: () => context.pushNamed('runSummary'),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Lifetime Performance',
                    style: _body(context, weight: FontWeight.w700),
                  ),
                  SizedBox(height: 12.h),
                  _TotalDistanceCard(
                    distanceKm: lifetime?.totalDistanceKm ?? 0,
                    bodyStyle: _body(context),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _LifetimeMetricCard(
                          icon: Icons.access_time,
                          label: 'Total Time',
                          value: lifetime?.formattedTotalTime ?? '--',
                          bodyStyle: _body(context),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _LifetimeMetricCard(
                          icon: Icons.directions_run_rounded,
                          label: 'Steps',
                          value: _formatSteps(lifetime?.totalSteps ?? 0),
                          bodyStyle: _body(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _AveragePaceCard(
                    pace: lifetime?.formattedPace ?? '--',
                    trend: lifetime?.paceTrend ?? const [],
                    bodyStyle: _body(context),
                  ),
                ],
              ),
            ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 2),
    ),
    );
  }

  String _formatSteps(int steps) {
    final text = steps.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onViewAll,
    required this.bodyStyle,
  });

  final String title;
  final VoidCallback onViewAll;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: bodyStyle.copyWith(fontWeight: FontWeight.w700,fontSize: 16.sp)),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View All',
            style: bodyStyle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13.sp
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentRunCard extends StatelessWidget {
  const _RecentRunCard({
    required this.run,
    required this.bodyStyle,
    required this.onTap,
  });

  final RecentActivityModel run;
  final TextStyle bodyStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surfaced1B,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    width: 72.w,
                    height: 72.w,
                    child: AssetOrFallback(
                      assetPath: run.mapImageAsset ?? Assets.background,
                      fallback: Container(
                        color: AppColors.surfaced2C,
                        child: const Icon(Icons.map, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              run.name,
                              style: bodyStyle.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _DifficultyBadge(
                            label: run.difficulty ?? 'Easy',
                            bodyStyle: bodyStyle,
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Image.asset(Assets.locations,scale: 3.1),
                          // Icon(
                          //   CupertinoIcons.location_solid,
                          //   size: 14.sp,
                          //   color: AppColors.primary,
                          // ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              run.location ?? 'Unknown location',
                              style: bodyStyle.copyWith(
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        run.dateLabel,
                        style: bodyStyle.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _RunStatTile(
                    icon: Assets.route,
                    label: 'Distance',
                    value: run.formattedDistance,
                    bodyStyle: bodyStyle,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _RunStatTile(
                    icon: Assets.time,
                    label: 'Est. Time',
                    value: run.formattedDuration,
                    bodyStyle: bodyStyle,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _RunStatTile(
                    icon: Assets.verifaction,
                    label: 'Safety',
                    value: '${run.safetyScore ?? 0}/100',
                    valueColor: AppColors.success,
                    bodyStyle: bodyStyle,
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

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.label, required this.bodyStyle});

  final String label;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final isHard = label.toLowerCase() == 'hard';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isHard
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.success.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: bodyStyle.copyWith(
          fontSize: 10.sp,
          color: isHard ? AppColors.primary : AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RunStatTile extends StatelessWidget {
  const _RunStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.bodyStyle,
    this.valueColor,
  });

  final String icon;
  final String label;
  final String value;
  final TextStyle bodyStyle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surfaced,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Image.asset(icon,scale: 3.1,),
          //Icon(icon, color: AppColors.primary, size: 16.sp),
          SizedBox(height: 4.h),
          Text(
            label,
            style: bodyStyle.copyWith(
              color: Color(0xFFE5BDBE),
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.white,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalDistanceCard extends StatelessWidget {
  const _TotalDistanceCard({
    required this.distanceKm,
    required this.bodyStyle,
  });

  final double distanceKm;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child:Image.asset(Assets.route,scale: 3.1,),
            //child: Icon(Icons.route, color: AppColors.primary, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Distance',
                  style: bodyStyle.copyWith(color: AppColors.textMuted),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: bodyStyle.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LifetimeMetricCard extends StatelessWidget {
  const _LifetimeMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.bodyStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20.sp),
          SizedBox(height: 10.h),
          Text(label, style: bodyStyle.copyWith(color: AppColors.textMuted)),
          SizedBox(height: 4.h),
          Text(
            value,
            style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AveragePaceCard extends StatelessWidget {
  const _AveragePaceCard({
    required this.pace,
    required this.trend,
    required this.bodyStyle,
  });

  final String pace;
  final List<double> trend;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Pace',
                  style: bodyStyle.copyWith(color: AppColors.textMuted),
                ),
                SizedBox(height: 6.h),
                Text(
                  pace,
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48.h,
            width: 120.w,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: (trend.isEmpty ? [0.4, 0.7, 0.5, 0.8, 0.6] : trend)
                  .map(
                    (v) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 4.w),
                        child: Container(
                          height: 48.h * v,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
