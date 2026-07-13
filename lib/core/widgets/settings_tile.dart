import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/widgets/app_asset_icon.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.label,
    required this.onTap,
    this.iconAssetPath,
    this.fallbackIcon = Icons.settings_outlined,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? iconAssetPath;
  final IconData fallbackIcon;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelColor = isDestructive ? AppColors.primary : AppColors.white;
    final chevronColor =
        isDestructive ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            if (iconAssetPath != null)
              Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: AppAssetIcon(
                  assetPath: iconAssetPath!,
                  fallbackIcon: fallbackIcon,
                  size: 22,
                  color: isDestructive ? AppColors.primary : null,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: Icon(
                  fallbackIcon,
                  size: 22.sp,
                  color: labelColor,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(fontSize: 12.sp),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (showChevron
                    ? Icon(
                        Icons.chevron_right,
                        color: chevronColor,
                        size: 22.sp,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
