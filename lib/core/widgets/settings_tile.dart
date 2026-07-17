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
    this.dividerColors=AppColors.border
  });

  final String label;
  final VoidCallback onTap;
  final String? iconAssetPath;
  final IconData fallbackIcon;
  final String? subtitle;
  final Color? dividerColors;
  final Widget? trailing;
  final bool showChevron;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelColor = isDestructive ? AppColors.primary : AppColors.white;
    final chevronColor =
        isDestructive ? AppColors.primary : AppColors.white;

    return InkWell(
      onTap: onTap,
      child: Column(
        spacing: 5.h,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
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
          Divider(
            height: 0.5,
            thickness: 1.2,
            color: dividerColors,
            indent: 16.w,
            endIndent: 16.w,
          )
        ],
      ),
    );
  }
}
