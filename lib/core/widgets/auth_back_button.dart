import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    super.key,
    this.onPressed,
    this.fallbackRoute = '/onboarding/intro',
  });

  final VoidCallback? onPressed;
  final String fallbackRoute;

  static void navigateBack(
    BuildContext context, {
    String fallback = '/onboarding/intro',
  }) {
    safePop(context, fallback: fallback);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onPressed ??
            () => navigateBack(context, fallback: fallbackRoute),
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.textPrimary,
        padding: EdgeInsets.all(8.w),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}
