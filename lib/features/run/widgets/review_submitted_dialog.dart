import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class ReviewSubmittedDialog extends StatelessWidget {
  const ReviewSubmittedDialog({
    super.key,
    required this.onDone,
  });

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surfaced1B,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Assets.reviewSubmittedDialogImg,
              height: 110.h,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.thumb_up_alt_rounded,
                color: Colors.amberAccent,
                size: 72.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Review Submitted',
              style: textTheme.titleLarge?.copyWith(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Your review has been submitted successfully and will help improve future running experiences for the community.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Done',
                onPressed: onDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
