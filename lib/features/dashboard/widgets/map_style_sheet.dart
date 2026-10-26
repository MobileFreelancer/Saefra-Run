import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/generated/assets.dart';

Future<void> showMapStyleSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) => const _MapStyleSheet(),
  );
}

class _MapStyleSheet extends StatelessWidget {
  const _MapStyleSheet();

  @override
  Widget build(BuildContext context) {
    final services = context.watch<DashboardServices>();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select Map style',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: DashboardMapStyle.values.map((style) {
              final selected = services.mapStyle == style;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: style != DashboardMapStyle.values.last ? 10.w : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      services.setMapStyle(style);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 72.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40.r),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 2 : 1,
                            ),
                            image: DecorationImage(
                              image: AssetImage(_previewAsset(style)),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            ),
                            color: AppColors.surfaceLight,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          style.label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _previewAsset(DashboardMapStyle style) {
    return switch (style) {
      DashboardMapStyle.darkBase => Assets.mapStyleDarkBase,
      DashboardMapStyle.light => Assets.mapStyleLight,
      DashboardMapStyle.dark => Assets.mapStyleDark,
    };
  }
}
