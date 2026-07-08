import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/widgets/app_asset_icon.dart';

import '../../generated/assets.dart';
import '../constants/app_colors.dart';
import '../utils/map_style_service.dart';

void showMapStyleBottomSheet(
    BuildContext context,
    GoogleMapController controller,
    ) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
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
                    "Select Map Style",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18.sp,
                    ),
                   ),
                   GestureDetector(
                     onTap: (){
                       Navigator.pop(context);
                     },
                       child: Image.asset(Assets.closeIcon,scale: 2.3,)
                   )
                 ],
               ),
               SizedBox(height: 22.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await MapStyleService.applyStyle(
                        controller: controller,
                        theme: MapTheme.park,
                      );
                      Navigator.pop(context);
                    },
                    child: Column(
                      spacing: 10.h,
                      children: [
                        InkWell(
                            child: Image.asset(Assets.prrakImage,scale: 3.3,)
                        ),
                        Text(
                          "Park",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                        ),

                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await MapStyleService.applyStyle(
                        controller: controller,
                        theme: MapTheme.light,
                      );
                      Navigator.pop(context);
                    },
                    child: Column(
                      spacing: 10.h,
                      children: [
                        InkWell(
                            child: Image.asset(Assets.lightMapImage,scale: 3.3,)
                        ),

                        Text(
                          "Light",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await MapStyleService.applyStyle(
                        controller: controller,
                        theme: MapTheme.dark,
                      );
                      Navigator.pop(context);
                    },
                    child: Column(
                      spacing: 10.h,
                      children: [
                        InkWell(
                            child: Image.asset(Assets.darkMapImage,scale: 3.3,),
                        ),
                        Text(
                          "Dark",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),

              // ListTile(
              //   leading: const Icon(Icons.light_mode),
              //   title: const Text("Light"),

              // ),
              //
              // ListTile(
              //   leading: const Icon(Icons.dark_mode),
              //   title: const Text("Dark"),

              // ),
              //
              // ListTile(
              //   leading: const Icon(Icons.park),
              //   title: const Text("Park"),

              // ),
            ],
          ),
        ),
      );
    },
  );
}