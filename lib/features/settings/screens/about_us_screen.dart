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
                      Assets.aboutlogo,
                      height: 72.h,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.directions_run,
                        size: 72.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Saefra Run',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700
                      ),
                    ),
                    SizedBox(height: 10.h,),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 10.h,),
                    Text(
                      'Run Safe. Run Smart.',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Saefra Run helps you discover safe running routes, track activity, and stay connected with your community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE1E1E1),
                        fontSize: 14.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.surfaced1B,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [ BoxShadow( color: AppColors.orangeShadow.withValues(alpha: 0.15), blurRadius: 20 ) ],
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Version", style: TextStyle(color: AppColors.white, fontSize: 14.sp,fontWeight: FontWeight.w500),),
                              Text("1.0.0", style: TextStyle(color: AppColors.white, fontSize: 14.sp,fontWeight: FontWeight.w500),),
                            ],
                          ),
                          SizedBox(height: 12.h,),
                          Divider(
                            height: 0.5,
                            thickness: 1.2,
                            color: AppColors.border,
                            indent: 16.w,
                            endIndent: 16.w,
                          ),
                          SizedBox(height: 12.h,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Rate App", style: TextStyle(color: AppColors.white, fontSize: 14.sp,fontWeight: FontWeight.w500),),
                              Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 14.sp,),
                            ],
                          ),
                          SizedBox(height: 12.h,),
                          Divider(
                            height: 0.5,
                            thickness: 1.2,
                            color: AppColors.border,
                            indent: 16.w,
                            endIndent: 16.w,
                          ),
                          SizedBox(height: 12.h,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Share App", style: TextStyle(color: AppColors.white, fontSize: 14.sp,fontWeight: FontWeight.w500),),
                              Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 14.sp,),
                            ],
                          ),
                        ],
                      ),
                    )
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
