import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/services/community_service.dart';
import 'package:saefra_run/core/widgets/app_bottom_nav.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/core/widgets/search_route_bar.dart';
import 'package:saefra_run/generated/assets.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: community.isLoading && community.popularRoutes.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                children: [
                  Text(
                    'Community',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 14.h),
                  const SearchRouteBar(readOnly: true),
                  SizedBox(height: 24.h),
                  _SectionHeader(
                    title: 'Popular Routes',
                    onViewAll: () => context.pushNamed('search'),
                  ),
                  SizedBox(height: 10.h),
                  ...community.popularRoutes.map(
                    (route) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: CommunityRouteCard(
                        route: route,
                        onTap: () => context.pushNamed(
                          'communityRouteDetail',
                          pathParameters: {'id': route.id},
                        ),
                        onLike: () => community.toggleLike(route.id),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _SectionHeader(
                    title: 'Top Rated Routes',
                    onViewAll: () => context.pushNamed('search'),
                  ),
                  SizedBox(height: 10.h),
                  ...community.topRatedRoutes.map(
                    (route) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: CommunityRouteCard(
                        route: route,
                        onTap: () => context.pushNamed(
                          'communityRouteDetail',
                          pathParameters: {'id': route.id},
                        ),
                        onLike: () => community.toggleLike(route.id),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 1),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            'View All',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ],
    );
  }
}

class CommunityRouteCard extends StatelessWidget {
  const CommunityRouteCard({
    super.key,
    required this.route,
    required this.onTap,
    this.onLike,
  });

  final CommunityRouteModel route;
  final VoidCallback onTap;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
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
                    color: const Color(0xFF1E2A20),
                    child: const Icon(Icons.route, color: AppColors.success),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14.sp)),
                  SizedBox(height: 4.h),
                  Text(
                    '${route.location} • ${route.distanceKm.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      SizedBox(width: 4.w),
                      Text(
                        route.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onLike,
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_border, size: 16, color: AppColors.textMuted),
                            SizedBox(width: 4.w),
                            Text('${route.likeCount}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textMuted),
                          SizedBox(width: 4.w),
                          Text('${route.commentCount}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
