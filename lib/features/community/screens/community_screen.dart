import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/community_service.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_bottom_nav.dart';
import 'package:saefra_run/core/widgets/search_route_bar.dart';
import 'package:saefra_run/features/community/widgets/community_route_card.dart';

import '../../../core/widgets/activity_shimmer_screen.dart';

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

  TextStyle _body(BuildContext context, {Color? color, FontWeight? weight}) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: color ?? AppColors.white,
          fontWeight: weight,
        );
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityService>();
    final bodyStyle = _body(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleRootBack(context);
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: community.isLoading && community.popularRoutes.isEmpty
            ?   ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          itemBuilder: (context, index) {
            return   const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ActivityCardShimmer(),
            );
          },
        )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    context.read<CommunityService>().load(refresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  Center(
                    child: Text(
                      'Community',
                      style: bodyStyle.copyWith(fontWeight: FontWeight.w700,fontSize: 18.sp,),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  SearchRouteBar(
                    hintText: "Search routes, people or places...",
                    controller: community.searchController,
                    onChanged: community.search,
                  ),
                  SizedBox(height: 20.h),
                  _SectionHeader(
                    title: 'Popular Routes',
                    onViewAll: () => context.pushNamed(
                      'communityRoutesList',
                      queryParameters: {'type': 'popular'},
                    ),
                    bodyStyle: bodyStyle,
                  ),
                  SizedBox(height: 12.h),
                  ...community.popularRoutes.map(
                    (route) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: CommunityRouteCard(
                        route: route,
                        bodyStyle: bodyStyle,
                        onTap: () => context.pushNamed(
                          'routeReviews',
                          pathParameters: {'id': route.id},
                        ),
                        onLike: () => community.toggleLike(route.id),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _SectionHeader(
                    title: 'Recent Routes',
                    onViewAll: () => context.pushNamed(
                      'communityRoutesList',
                      queryParameters: {'type': 'recent'},
                    ),
                    bodyStyle: bodyStyle,
                  ),
                  SizedBox(height: 12.h),
                  ...community.topRatedRoutes.map(
                    (route) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: CommunityRouteCard(
                        route: route,
                        bodyStyle: bodyStyle,
                        onTap: () => context.pushNamed(
                          'routeReviews',
                          pathParameters: {'id': route.id},
                        ),
                        onLike: () => community.toggleLike(route.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 1),
    ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onViewAll,
    required this.bodyStyle,
  });

  final String title;
  final VoidCallback onViewAll;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: bodyStyle.copyWith(fontWeight: FontWeight.w700,fontSize: 16.sp)),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View All',
            style: bodyStyle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp
            ),
          ),
        ),
      ],
    );
  }
}
