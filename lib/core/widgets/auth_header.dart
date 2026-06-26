import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../../generated/assets.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 60.h),

        SizedBox(
          height: 126.h,
          width: 155.w,
          child: Image.asset(
            Assets.imagesLogowithtext,
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