import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'About Us'),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Image.asset(
                      Assets.imagesLogowithtext,
                      height: 72.h,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.directions_run,
                        size: 72.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Saefra Run helps you discover safe running routes, track activity, and stay connected with your community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    TextButton(
                      onPressed: () => context.pushNamed(
                        'legalContent',
                        queryParameters: {'type': 'terms'},
                      ),
                      child: const Text('Terms of Use'),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed(
                        'legalContent',
                        queryParameters: {'type': 'privacy'},
                      ),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: PrimaryButton(
                label: 'Back',
                onPressed: () => safePop(context, fallback: '/settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
