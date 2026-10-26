import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_asset_icon.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.backAssetPath,
    this.fallbackRoute = '/dashboard',
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final String? backAssetPath;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing ??
        SizedBox(width: 48.w);

    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ??
                () => safePop(context, fallback: fallbackRoute),
            icon: backAssetPath != null
                ? AppAssetIcon(
                    assetPath: backAssetPath!,
                    fallbackIcon: Icons.arrow_back_ios_new,
                    size: 20,
                  )
                : const Icon(Icons.arrow_back_ios_new, size: 18),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18.sp,
                  ),
            ),
          ),
          trailingWidget,
        ],
      ),
    );
  }
}
