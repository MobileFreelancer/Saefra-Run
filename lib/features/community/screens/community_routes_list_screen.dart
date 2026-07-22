import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/community_route_list_service.dart';
import 'package:saefra_run/core/services/community_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/search_route_bar.dart';
import 'package:saefra_run/features/community/widgets/community_route_card.dart';

class CommunityRoutesListScreen extends StatefulWidget {
  const CommunityRoutesListScreen({super.key, required this.kind});

  final CommunityRouteListKind kind;

  @override
  State<CommunityRoutesListScreen> createState() =>
      _CommunityRoutesListScreenState();
}

class _CommunityRoutesListScreenState extends State<CommunityRoutesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listService = context.read<CommunityRouteListService>();
      listService.init(widget.kind);
      listService.load(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      context.read<CommunityRouteListService>().loadMore();
    }
  }

  TextStyle _body(BuildContext context, {Color? color, FontWeight? weight}) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: color ?? AppColors.white,
          fontWeight: weight,
        );
  }

  @override
  Widget build(BuildContext context) {
    final listService = context.watch<CommunityRouteListService>();
    final community = context.read<CommunityService>();
    final bodyStyle = _body(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: listService.title,
              fallbackRoute: '/community',
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SearchRouteBar(
                hintText: 'Search ${listService.title.toLowerCase()}...',
                controller: listService.searchController,
                onChanged: listService.search,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(child: _buildBody(listService, community, bodyStyle)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    CommunityRouteListService listService,
    CommunityService community,
    TextStyle bodyStyle,
  ) {
    if (listService.isLoading && listService.routes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (listService.routes.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => listService.load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Text(
                listService.error ?? 'No routes found',
                textAlign: TextAlign.center,
                style: bodyStyle.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => listService.load(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        itemCount: listService.routes.length + (listService.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          if (index >= listService.routes.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final route = listService.routes[index];
          return CommunityRouteCard(
            route: route,
            bodyStyle: bodyStyle,
            onTap: () => context.pushNamed(
              'routeReviews',
              pathParameters: {'id': route.id},
            ),
            onLike: () => community.toggleLike(route.id),
          );
        },
      ),
    );
  }
}
