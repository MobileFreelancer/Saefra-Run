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
  static const _maxReviewLength = 500;

  final _reviewController = TextEditingController();
  String? _submitError;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final review = context.read<RunReviewService>();
    final form = review.form;

    if (form.starRating < 1) {
      setState(() => _submitError = 'Please select a star rating');
      return;
    }

    setState(() => _submitError = null);
    review.setReviewText(_reviewController.text);

    final ok = await review.submit(
      runId: context.read<RunService>().session.routeId,
    );
    if (!mounted) return;

    if (!ok) {
      setState(() => _submitError = 'Failed to submit review. Please try again.');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => ReviewSubmittedDialog(
        onDone: () {
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
      setState(() => _submitError = 'You can upload up to 3 images');
      return;
    }
    setState(() => _submitError = null);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Great Run!',
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.white,
                      ),
                      children: [
                        const TextSpan(text: 'How was your experience on the \n'),
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

                    child: session.routePath.length > 1
                        ? AppRouteMap(
                            height: 140.h,
                            borderRadius: 16,
                            polylinePoints: session.routePath,
                            showLocationMarker: true,
                          )
                        : AppRouteMap(height: 140.h, borderRadius: 16),
                  ),
                  SizedBox(height: 18.h),
                  _QuestionSection(
                    title: 'How did this route feel?',
                    child: _RadioOptionGroup<RouteFeel>(
                      options: RouteFeel.values,
                      selected: form.routeFeel,
                      labelBuilder: (v) => v.label,
                      onChanged: review.setRouteFeel,
                      textTheme: textTheme,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _QuestionSection(
                    title: 'What was the running surface like?',
                    child: _RadioOptionGroup<RouteSurfaceType>(
                      options: RouteSurfaceType.values,
                      selected: form.surfaceType,
                      labelBuilder: (v) => v.label,
                      onChanged: review.setSurfaceType,
                      textTheme: textTheme,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _QuestionSection(
                    title: 'Were sidewalks available?',
                    child: _RadioOptionGroup<SidewalkAvailability>(
                      options: SidewalkAvailability.values,
                      selected: form.sidewalks,
                      labelBuilder: (v) => v.label,
                      onChanged: review.setSidewalks,
                      textTheme: textTheme,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Upload Route Images',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: _addImage,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.borderColorB0),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: AppColors.searchColors,
                            size: 30.sp,
                          ),
                          SizedBox(height: 8.h),
                          RichText(
                            text: TextSpan(
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.searchColors,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Click to upload',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' and tag photos'),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '(Up to 3 images, max 10MB)',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.searchColors,
                            ),
                          ),
                          if (form.imagePaths.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            Text(
                              '${form.imagePaths.length} image(s) added',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaced1B,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Your Review',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _StarRatingBar(
                          rating: form.starRating,
                          onChanged: review.setStarRating,
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _reviewController,
                          maxLines: 5,
                          maxLength: _maxReviewLength,
                          onChanged: review.setReviewText,
                          style: textTheme.bodyLarge?.copyWith(fontSize: 14.sp),
                          decoration: InputDecoration(
                            hintText: 'Share your experience about this route...',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            counterStyle: textTheme.bodySmall?.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                            contentPadding: EdgeInsets.all(14.w),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                children: [
                  if (_submitError != null) ...[
                    Text(
                      _submitError!,
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
                      label: 'Submit Review',
                      isLoading: review.isSubmitting,
                      onPressed: _submit,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: review.isSubmitting ? null : () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.border),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
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

class _QuestionSection extends StatelessWidget {
  const _QuestionSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: AppColors.orangeShadow.withValues(alpha: 0.15),
              blurRadius: 20
          )
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
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
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: GestureDetector(
            onTap: () => onChanged(option),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surfaced2C,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? AppColors.buttonColor.withValues(alpha: 0.71) : AppColors.borderColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labelBuilder(option),
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13.sp,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.buttonColor.withValues(alpha: 0.71) : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final filled = starIndex <= rating;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
          onPressed: () => onChanged(starIndex),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFFFB800),
            size: 32.sp,
          ),
        );
      }),
    );
  }
}
