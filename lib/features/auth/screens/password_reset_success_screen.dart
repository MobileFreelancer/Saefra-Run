import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/assets.dart';
import '../../onboarding/widgets/common_app_button.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 146.w,
                height: 137.h,
                child: Image.asset(
                  Assets.successMark,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 100.sp,
                  ),
                ),
              ),
            ),
          Text(
            "Password Changed!",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 26.sp,
            ),
          ),
          SizedBox(height: 8.h,),
          Text(
            "Your password has been\nchanged successfully.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withOpacity(0.6),
              fontWeight: FontWeight.w400,
              fontSize: 15.sp,
            ),

          ),
          Padding(
            padding:   EdgeInsets.symmetric(horizontal: 12.w,vertical: 35.h),
            child: AppPrimaryButton(
              label: 'Back to Login',
              onTap: (){
                context.goNamed('login');
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}
