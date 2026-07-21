import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/run_session_model.dart';
import 'package:saefra_run/core/services/run_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/app_route_map.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class RunSummaryScreen extends StatefulWidget {
  const RunSummaryScreen({super.key});

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen> {
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final run = context.read<RunService>();
      if (run.mood == null) {
        run.setMood(RunMood.great);
      }
      if (run.session.runId != null) {
        await run.loadRunSummary();
      }
    });
  }

  Future<void> _saveActivity() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final runService = context.read<RunService>();
    final ok = await runService.saveActivity();
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (!ok) {
      setState(
        () => _saveError =
            runService.apiError ?? 'Failed to save run feeling. Please try again.',
      );
      return;
    }

    context.goNamed('dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunService>();
    final session = run.session;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Run Summary'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                children: [
                  _SuccessHeader(textTheme: textTheme),
                  SizedBox(height: 20.h),
                  _StatsGrid(session: session, textTheme: textTheme),
                  SizedBox(height: 20.h),
                  Text(
                    'Route Preview',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: _RoutePreviewMap(routePath: session.routePath),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Splits Pace',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _SplitsCard(splits: session.splits, textTheme: textTheme),
                  SizedBox(height: 20.h),
                  Text(
                    'How Did This Run Feel?',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _MoodSelector(
                    selected: run.mood ?? RunMood.great,
                    onSelected: run.setMood,
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                children: [
                  if (_saveError != null) ...[
                    Text(
                      _saveError!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Save Activity',
                      isLoading: _isSaving,
                      onPressed: _saveActivity,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pushNamed('runRate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.17),
                        side: const BorderSide(color: AppColors.white),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        'Rate For Route',
                        style: textTheme.labelLarge?.copyWith(fontSize: 14.sp),
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

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          Assets.runSummaryImg,
          width: 150.w,
          height: 150.w,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.emoji_events_rounded,
            color: AppColors.primary,
            size: 72.sp,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Great Job!',
          style: textTheme.headlineMedium?.copyWith(
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'You completed your run.',
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.session, required this.textTheme});

  final RunSessionModel session;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final paceParts = _splitPace(session.paceDisplayLabel);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeShadow.withValues(alpha: 0.15),
            blurRadius: 20
          )
        ],
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatCell(
                label: 'Distance',
                value: session.distanceKm.toStringAsFixed(2),
                unit: ' km',
                textTheme: textTheme,
              ),
              _StatCell(
                label: 'Total Time',
                value: session.durationLabel,
                textTheme: textTheme,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _StatCell(
                label: 'Avg. Pace',
                value: paceParts.$1,
                unit: paceParts.$2,
                textTheme: textTheme,
              ),
              _StatCell(
                label: 'Steps',
                value: '${session.steps}',
                textTheme: textTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, String) _splitPace(String pace) {
    final index = pace.indexOf(' /km');
    if (index == -1) return (pace, '');
    return (pace.substring(0, index), pace.substring(index));
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.textTheme,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12.sp,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 4.h),
          RichText(
            text: TextSpan(
              style: textTheme.titleMedium?.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: unit,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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

class _RoutePreviewMap extends StatelessWidget {
  const _RoutePreviewMap({required this.routePath});

  final List<LatLng> routePath;

  @override
  Widget build(BuildContext context) {
    if (routePath.length > 1) {
      return AppRouteMap(
        height: 150.h,
        borderRadius: 16,
        polylinePoints: routePath,
        showLocationMarker: true,
      );
    }
    return AppRouteMap(height: 150.h, borderRadius: 16);
  }
}

class _SplitsCard extends StatelessWidget {
  const _SplitsCard({
    required this.splits,
    required this.textTheme,
  });

  final List<RunSplitModel> splits;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        boxShadow: [
          BoxShadow(
              color: AppColors.orangeShadow.withValues(alpha: 0.15),
              blurRadius: 20,
          ),
        ],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: splits.map((split) {
          return Padding(
            padding: EdgeInsets.only(bottom: split == splits.last ? 0 : 10.h),
            child: _SplitPaceRow(split: split, textTheme: textTheme),
          );
        }).toList(),
      ),
    );
  }
}

class _SplitPaceRow extends StatelessWidget {
  const _SplitPaceRow({required this.split, required this.textTheme});

  final RunSplitModel split;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42.w,
          child: Text(
            'Km ${split.km}',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12.sp,
              color: AppColors.textThird,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: split.paceFactor.clamp(0.1, 1.0),
              minHeight: 6.h,
              color: AppColors.white,
              backgroundColor: AppColors.surfaceLight,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          split.timeLabel,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 12.sp,
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({
    required this.selected,
    required this.onSelected,
    required this.textTheme,
  });

  final RunMood selected;
  final ValueChanged<RunMood> onSelected;
  final TextTheme textTheme;

  static const _options = [
    _MoodOption(RunMood.great, 'Great', '😄', Color(0xFF22C55E)),
    _MoodOption(RunMood.good, 'Good', '🙂', Color(0xFF3B82F6)),
    _MoodOption(RunMood.okay, 'Okay', '😐', Color(0xFFA855F7)),
    _MoodOption(RunMood.tough, 'Tough', '😓', Color(0xFFF97316)),
    _MoodOption(RunMood.exhausted, 'Exhausted', '😫', Color(0xFFEAB308)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _options.map((option) {
        final isSelected = selected == option.mood;
        return GestureDetector(
          onTap: () => onSelected(option.mood),
          child: Column(
            children: [
              Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? option.color.withValues(alpha: 0.22)
                      : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? option.color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.emoji,
                  style: TextStyle(fontSize: 24.sp),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                option.label,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? option.color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MoodOption {
  const _MoodOption(this.mood, this.label, this.emoji, this.color);

  final RunMood mood;
  final String label;
  final String emoji;
  final Color color;
}
