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
import 'package:saefra_run/core/widgets/search_route_bar.dart';
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
      search.setQuery(widget.initialQuery);
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
              child: SearchRouteBar(
                controller: _controller,
                autofocus: true,
                onChanged: _onQueryChanged,
                onFilterTap: () async {
                  await context.pushNamed('searchFilters');
                },
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(child: _buildBody(search)),
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      case RouteSearchStatus.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 12.h),
              Text('Loading...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      case RouteSearchStatus.notFound:
        return _NotFoundState(query: search.query);
      case RouteSearchStatus.results:
        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          children: [
            Text('Find Routes', style: Theme.of(context).textTheme.titleMedium),
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
                  thumbnailAssetPath: route.imageAsset ?? Assets.background,
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
            Text('Not Found', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8.h),
            Text(
              query.isEmpty
                  ? 'Try searching for a route name or area.'
                  : 'We couldn\'t find a route that matches your preferences. Try adjusting your settings and search again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
