import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../generated/assets.dart';
import '../constants/app_colors.dart';
import '../services/dashboard_services.dart';
import '../utils/map_style_service.dart';

void showMapStyleBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Map Style',
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18.sp,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Image.asset(Assets.closeIcon, scale: 2.3),
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MapStyleOption(
                    label: 'Park',
                    imageAsset: Assets.prrakImage,
                    onTap: () => _selectTheme(sheetContext, MapTheme.park),
                  ),
                  _MapStyleOption(
                    label: 'Light',
                    imageAsset: Assets.lightMapImage,
                    onTap: () => _selectTheme(sheetContext, MapTheme.light),
                  ),
                  _MapStyleOption(
                    label: 'Dark',
                    imageAsset: Assets.darkMapImage,
                    onTap: () => _selectTheme(sheetContext, MapTheme.dark),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _selectTheme(BuildContext context, MapTheme theme) async {
  await context.read<DashboardServices>().setMapTheme(theme);
  if (context.mounted) Navigator.pop(context);
}

class _MapStyleOption extends StatelessWidget {
  const _MapStyleOption({
    required this.label,
    required this.imageAsset,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(imageAsset, scale: 3.3),
          SizedBox(height: 10.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
          ),
        ],
      ),
    );
  }
}
