import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

import '../../../generated/assets.dart';
import '../widgets/common_app_button.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.transparent, // Fades to solid black at the bottom
                ],
                stops: [0.3, 0.85],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              Assets.onboardingRunnerImg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),

          // Content Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // Typography matching the style hierarchy
                  Text.rich(
                    TextSpan(
                      text: 'Every Run Starts',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        height: 1.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                        fontSize: 25.sp,
                      ),
                      children: [
                        TextSpan(
                          text: '\nWith',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w400,
                            fontSize: 25.sp,
                          ),

                        ),
                        TextSpan(
                          text: ' Confidence',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 27.sp,
                          ),

                        ),
                      ],
                    ),
                  ),
                    SizedBox(height: 30.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context.goNamed('signup');
                          },
                          child: Container(
                            alignment: Alignment.center,
                            width: 155.w,
                            height: 53.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(50.r)),
                              border: BoxBorder.all(
                                color: AppColors.buttonColor
                              )
                            ),
                            child: Text("Join for Free",style:   Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp
                            ),),
                          ),
                        ),
                      ),
                      SizedBox(width: 15.w,),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Login',
                          height: 55.h,
                          onTap: (){
                            context.goNamed('login');
                          },
                        ),
                      ),
                    ],
                  ),

                    SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}