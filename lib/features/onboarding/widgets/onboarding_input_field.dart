import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

/// Pill-shaped onboarding input matching the "Let's Get to Know You" design.
class OnboardingInputField extends StatelessWidget {
  const OnboardingInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.iconAssetPath,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? iconAssetPath;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.backgroundBlackTra,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: AppColors.textBorder),
        ),
        child: Row(
          children: [
            if (iconAssetPath != null)
              Image.asset(
                iconAssetPath!,
                width: 20.w,
                height: 20.w,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, color: AppColors.white, size: 20.sp),
              )
            else
              Icon(icon, color: AppColors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Container(
              height: 20.h,
              width: 1,
              color: const Color(0xFF333333),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                onTap: onTap,
                keyboardType: keyboardType,
                onChanged: onChanged,
                style: textTheme.bodyLarge?.copyWith(fontSize: 15.sp),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textThird,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
