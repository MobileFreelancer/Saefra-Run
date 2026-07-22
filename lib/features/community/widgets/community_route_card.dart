import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/generated/assets.dart';

class CommunityRouteCard extends StatelessWidget {
  const CommunityRouteCard({
    super.key,
    required this.route,
    required this.bodyStyle,
    required this.onTap,
    this.onLike,
  });

  final CommunityRouteModel route;
  final TextStyle bodyStyle;
  final VoidCallback onTap;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    final difficulty = route.difficultyTag ?? 'Easy';
    final isHard = difficulty.toLowerCase() == 'hard';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surfaced1B,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    width: 72.w,
                    height: 72.w,
                    child: AssetOrFallback(
                      assetPath: route.imageAsset ?? Assets.background,
                      fallback: Container(
                        color: AppColors.surfaced2C,
                        child: const Icon(Icons.route, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              route.name,
                              style: bodyStyle.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: isHard
                                  ? AppColors.primary.withValues(alpha: 0.18)
                                  : AppColors.success.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              difficulty,
                              style: bodyStyle.copyWith(
                                fontSize: 10.sp,
                                color: isHard
                                    ? AppColors.primary
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (route.location.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14.sp,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                route.location,
                                style: bodyStyle.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Text(
                            '${route.distanceKm.toStringAsFixed(2)} km',
                            style: bodyStyle.copyWith(
                              color: const Color(0xFFE5BDBE),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.star, color: Colors.amber, size: 14.sp),
                          SizedBox(width: 4.w),
                          Text(
                            '${route.rating.toStringAsFixed(1)} (${route.reviewCount})',
                            style: bodyStyle.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: AppColors.primary, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text('${route.likeCount}', style: bodyStyle),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: const Color(0xFFE5BDBE),
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${route.commentCount}',
                      style: bodyStyle.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.bookmark_border,
                  color: const Color(0xFFE5BDBE),
                  size: 18.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
