import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/route_search_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/recent_route_tile.dart';
import 'package:saefra_run/generated/assets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final search = context.read<RouteSearchService>();
      if (widget.initialQuery.isNotEmpty) {
        search.search(widget.initialQuery);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<RouteSearchService>().setQuery(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      context.read<RouteSearchService>().search(value);
    });
  }

  void _openRoute(RouteModel route) {
    context.pushNamed('routeDetail', pathParameters: {'id': route.id});
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<RouteSearchService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppPageHeader(title: 'Search'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.white),
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search routes...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: Image.asset(
                    Assets.homeSearchIcon,
                    width: 20,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.search,
                      color: AppColors.textMuted,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: _buildBody(search),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RouteSearchService search) {
    switch (search.status) {
      case RouteSearchStatus.idle:
        return Center(
          child: Text(
            'Find safe routes near you',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
          ),
        );
      case RouteSearchStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 12),
              Text('Loading...', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        );
      case RouteSearchStatus.notFound:
        return _NotFoundState(query: search.query);
      case RouteSearchStatus.results:
        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          children: [
            Text(
              'Find Routes',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12.h),
            ...search.results.map(
              (route) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: RecentRouteTile(
                  title: route.name,
                  subtitle: route.subtitleLabel.isNotEmpty
                      ? route.subtitleLabel
                      : '${route.distanceLabel} • ${route.durationMinutes} mins',
                  tag: route.tag ?? 'Route',
                  thumbnailAssetPath: route.imageAsset,
                  onTap: () => _openRoute(route),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Assets.searchNotFoundIllustration,
              height: 120.h,
              errorBuilder: (_, __, ___) => Icon(
                Icons.search_off,
                size: 72.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Not Found',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              query.isEmpty
                  ? 'Try searching for a route name or area.'
                  : 'We couldn\'t find a route that matches your preferences. Try adjusting your settings and search again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
