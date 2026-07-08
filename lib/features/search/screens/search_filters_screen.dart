import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/search_filter_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

class SearchFiltersScreen extends StatelessWidget {
  const SearchFiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<SearchFilterService>();
    final model = filters.filters;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Filters',
              trailing: TextButton(
                onPressed: filters.reset,
                child: Text(
                  'Reset',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  _FilterCard(
                    title: 'Select Route Type',
                    expanded: model.routeTypeExpanded,
                    onToggle: filters.toggleRouteTypeExpanded,
                    child: model.routeTypeExpanded
                        ? Wrap(
                            spacing: 8.w,
                            children: ['Loop', 'One way', 'Trail']
                                .map(
                                  (v) => ChoiceChip(
                                    label: Text(v),
                                    selected: model.routeType == v,
                                    onSelected: (_) =>
                                        filters.setRouteType(v),
                                  ),
                                )
                                .toList(),
                          )
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  _FilterCard(
                    title: 'Select Route Difficulty',
                    expanded: model.difficultyExpanded,
                    onToggle: filters.toggleDifficultyExpanded,
                    child: model.difficultyExpanded
                        ? Wrap(
                            spacing: 8.w,
                            children: ['Easy', 'Medium', 'Hard']
                                .map(
                                  (v) => ChoiceChip(
                                    label: Text(v),
                                    selected: model.difficulty == v,
                                    onSelected: (_) =>
                                        filters.setDifficulty(v),
                                  ),
                                )
                                .toList(),
                          )
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  _FilterCard(
                    title: 'Distance',
                    expanded: model.distanceExpanded,
                    onToggle: filters.toggleDistanceExpanded,
                    subtitle: model.distanceLabel,
                    child: model.distanceExpanded
                        ? SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.white,
                              inactiveTrackColor: AppColors.surfaceLight,
                              thumbColor: AppColors.white,
                              overlayColor:
                                  AppColors.white.withValues(alpha: 0.12),
                            ),
                            child: RangeSlider(
                              values: model.distanceRange,
                              min: 0,
                              max: 20,
                              divisions: 20,
                              onChanged: filters.setDistanceRange,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  _FilterCard(
                    title: 'Rating',
                    expanded: model.ratingExpanded,
                    onToggle: filters.toggleRatingExpanded,
                    subtitle: model.ratingLabel,
                    child: model.ratingExpanded
                        ? SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.white,
                              inactiveTrackColor: AppColors.surfaceLight,
                              thumbColor: AppColors.white,
                              overlayColor:
                                  AppColors.white.withValues(alpha: 0.12),
                            ),
                            child: RangeSlider(
                              values: model.ratingRange,
                              min: 1,
                              max: 5,
                              divisions: 4,
                              onChanged: filters.setRatingRange,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: PrimaryButton(
                label: 'Apply',
                onPressed: () => context.pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.subtitle,
    this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: textTheme.titleMedium),
                ),
                Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.white,
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(subtitle!, style: textTheme.bodyLarge),
          ],
          if (expanded && child != null) ...[
            SizedBox(height: 12.h),
            child!,
          ],
        ],
      ),
    );
  }
}
