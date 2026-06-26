import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../../generated/assets.dart';
import 'auth_back_button.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = true,
    this.onBack,
    this.fallbackRoute = '/onboarding/intro',
  });

  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBackButton)
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 0),
            child: AuthBackButton(
              onPressed: onBack,
              fallbackRoute: fallbackRoute,
            ),
          ),
        SizedBox(height: showBackButton ? 8.h : 60.h),
        SizedBox(
          height: 126.h,
          width: 155.w,
          child: Center(
            child: Image.asset(
              Assets.imagesLogowithtext,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_run,
                color: AppColors.white,
                size: 48,
              ),
            ),
          ),
        ),
        SizedBox(height: 35.h),
        Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                ),
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}
