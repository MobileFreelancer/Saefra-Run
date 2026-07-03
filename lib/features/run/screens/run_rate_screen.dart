import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/run_review_form_model.dart';
import 'package:saefra_run/core/services/run_review_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/core/widgets/secondary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class RunRateScreen extends StatefulWidget {
  const RunRateScreen({super.key});

  @override
  State<RunRateScreen> createState() => _RunRateScreenState();
}

class _RunRateScreenState extends State<RunRateScreen> {
  final _feedback = TextEditingController();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final review = context.read<RunReviewService>();
    review.setFeedback(_feedback.text);
    final ok = await review.submit();
    if (!mounted) return;
    if (ok) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                Assets.successMark,
                height: 64,
                errorBuilder: (_, __, ___) => const Icon(Icons.thumb_up, color: AppColors.primary, size: 64),
              ),
              SizedBox(height: 12.h),
              Text('Review Submitted!', style: Theme.of(ctx).textTheme.titleLarge),
              SizedBox(height: 8.h),
              Text(
                'Your feedback has been submitted successfully.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              SizedBox(height: 12.h),
              PrimaryButton(
                label: 'Back to Home',
                onPressed: () {
                  Navigator.pop(ctx);
                  review.reset();
                  context.goNamed('dashboard');
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = context.watch<RunReviewService>();
    final form = review.form;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Run Rate'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  Text('Great Job!', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      height: 100.h,
                      child: AssetOrFallback(
                        assetPath: Assets.background,
                        fallback: Container(color: AppColors.surface),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('Who did you run with?', style: Theme.of(context).textTheme.titleMedium),
                  ...RunCompanion.values.map(
                    (v) => RadioListTile<RunCompanion>(
                      value: v,
                      groupValue: form.companion,
                      onChanged: (val) {
                        if (val != null) review.setCompanion(val);
                      },
                      title: Text(_companionLabel(v)),
                    ),
                  ),
                  Text('How was the running environment?', style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8.w,
                    children: ['Pedestrians', 'Traffic lights', 'Well-lit', 'Crowded']
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag),
                            selected: form.environmentTags.contains(tag),
                            onSelected: (_) => review.toggleEnvironmentTag(tag),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 12.h),
                  Text('Was information accurate?', style: Theme.of(context).textTheme.titleMedium),
                  ...['yes', 'no', 'somewhat'].map(
                    (v) => RadioListTile<String>(
                      value: v,
                      groupValue: form.accuracyRating,
                      onChanged: (val) {
                        if (val != null) review.setAccuracy(val);
                      },
                      title: Text(v[0].toUpperCase() + v.substring(1)),
                    ),
                  ),
                  Text('Running surface', style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8.w,
                    children: RunSurface.values
                        .map(
                          (s) => ChoiceChip(
                            label: Text(s.name),
                            selected: form.surface == s,
                            onSelected: (_) => review.setSurface(s),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 12.h),
                  Text('Weather conditions', style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8.w,
                    children: RunWeather.values
                        .map(
                          (w) => ChoiceChip(
                            label: Text(w.name),
                            selected: form.weather == w,
                            onSelected: (_) => review.setWeather(w),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 12.h),
                  Text('Upload Route Images', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () => context.pushNamed('addRunImages'),
                    child: Container(
                      height: 100.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt_outlined, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  if (form.imagePaths.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text('${form.imagePaths.length} image(s) added'),
                  ],
                  SizedBox(height: 12.h),
                  Text('Anything you\'d like to share?', style: Theme.of(context).textTheme.titleMedium),
                  TextField(
                    controller: _feedback,
                    maxLines: 4,
                    onChanged: review.setFeedback,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(hintText: 'Share your experience...'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Submit Review',
                    isLoading: review.isSubmitting,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 8.h),
                  SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _companionLabel(RunCompanion v) => switch (v) {
        RunCompanion.noOne => 'No one',
        RunCompanion.myPet => 'My pet',
        RunCompanion.friend => 'Run with friend',
      };
}
