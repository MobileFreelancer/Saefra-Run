import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/run_review_form_model.dart';
import 'package:saefra_run/core/services/run_review_service.dart';
import 'package:saefra_run/core/services/run_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/app_route_map.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/features/run/widgets/review_submitted_dialog.dart';

class RunRateScreen extends StatefulWidget {
  const RunRateScreen({super.key});

  @override
  State<RunRateScreen> createState() => _RunRateScreenState();
}

class _RunRateScreenState extends State<RunRateScreen> {
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final review = context.read<RunReviewService>();
    review.setReviewText(_reviewController.text);
    final ok = await review.submit(
      runId: context.read<RunService>().session.routeId,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review. Please try again.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => ReviewSubmittedDialog(
        onBackHome: () {
          Navigator.pop(ctx);
          review.reset();
          context.goNamed('dashboard');
        },
      ),
    );
  }

  void _addImage() {
    final review = context.read<RunReviewService>();
    if (review.form.imagePaths.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload up to 3 images')),
      );
      return;
    }
    review.addImage('assets/images/background.png');
  }

  @override
  Widget build(BuildContext context) {
    final review = context.watch<RunReviewService>();
    final session = context.watch<RunService>().session;
    final form = review.form;
    final textTheme = Theme.of(context).textTheme;
    final routeName = session.routeName ?? 'your route';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Run Rate'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                children: [
                  Text(
                    'Great Run!',
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
                      children: [
                        const TextSpan(text: 'How was your experience on the '),
                        TextSpan(
                          text: routeName,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: session.routePath.length > 1
                        ? AppRouteMap(
                            height: 130.h,
                            borderRadius: 16,
                            polylinePoints: session.routePath,
                            showLocationMarker: false,
                          )
                        : AppRouteMap(height: 130.h, borderRadius: 16),
                  ),
                  SizedBox(height: 16.h),
                  _FeedbackCard(
                    title: 'How did this route feel?',
                    child: _RadioOptionGroup<RouteFeel>(
                      options: RouteFeel.values,
                      selected: form.routeFeel,
                      labelBuilder: (v) => v.label,
                      onChanged: review.setRouteFeel,
                      textTheme: textTheme,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _FeedbackCard(
                    title: 'What was the running surface like?',
                    child: _RadioOptionGroup<RouteSurfaceType>(
                      options: RouteSurfaceType.values,
                      selected: form.surfaceType,
                      labelBuilder: (v) => v.label,
                      onChanged: review.setSurfaceType,
                      textTheme: textTheme,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _FeedbackCard(
                    title: 'Were sidewalks available?',
                    child: _RadioOptionGroup<SidewalkAvailability>(
                      options: SidewalkAvailability.values,
                      selected: form.sidewalks,
                      labelBuilder: (v) => v.label,
                      onChanged: review.setSidewalks,
                      textTheme: textTheme,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: _addImage,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 22.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: AppColors.textMuted,
                            size: 28.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Upload Route images',
                            style: textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Tap to upload images (max 3)',
                            style: textTheme.bodySmall?.copyWith(fontSize: 12.sp),
                          ),
                          if (form.imagePaths.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            Text(
                              '${form.imagePaths.length} image(s) added',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Add Your Review',
                    style: textTheme.titleMedium?.copyWith(fontSize: 16.sp),
                  ),
                  SizedBox(height: 10.h),
                  _StarRatingBar(
                    rating: form.starRating,
                    onChanged: review.setStarRating,
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    onChanged: review.setReviewText,
                    style: textTheme.bodyLarge?.copyWith(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Enter your experience about this route...',
                      hintStyle: textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Submit Review',
                    isLoading: review.isSubmitting,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 10.h),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Cancel',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 14.sp,
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

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontSize: 14.sp),
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

class _RadioOptionGroup<T> extends StatelessWidget {
  const _RadioOptionGroup({
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    required this.textTheme,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onChanged(option),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              children: [
                Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    labelBuilder(option),
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13.sp,
                      color: isSelected ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StarRatingBar extends StatelessWidget {
  const _StarRatingBar({
    required this.rating,
    required this.onChanged,
  });

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final filled = starIndex <= rating;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
          onPressed: () => onChanged(starIndex),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amberAccent,
            size: 30.sp,
          ),
        );
      }),
    );
  }
}
