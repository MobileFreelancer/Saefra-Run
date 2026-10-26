import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/models/place_prediction_model.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/core/services/route_search_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/recent_route_tile.dart';
import 'package:saefra_run/core/widgets/search_route_bar.dart';
import 'package:saefra_run/core/widgets/show_bottom_sheet.dart';
import 'package:saefra_run/generated/assets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  late final DashboardServices _dashboard;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _dashboard = context.read<DashboardServices>();
    _dashboard.addListener(_syncRecentFromDashboard);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final search = context.read<RouteSearchService>();

      search.clearSearch();
      _syncRecentFromDashboard();

      search.setQuery(widget.initialQuery);
      if (widget.initialQuery.isNotEmpty) {
        search.search(
          widget.initialQuery,
          latitude: _dashboard.latitude,
          longitude: _dashboard.longitude,
        );
      }
    });
  }

  void _syncRecentFromDashboard() {
    if (!mounted) return;
    final search = context.read<RouteSearchService>();
    if (search.query.trim().isNotEmpty) return;
    search.syncRecentRoutesFromDashboard(_dashboard.recentRoutes);
  }

  Future<void> _refreshRecentRoutes() async {
    final search = context.read<RouteSearchService>();

    await _dashboard.refreshHomeData();
    if (!mounted) return;
    search.syncRecentRoutesFromDashboard(_dashboard.recentRoutes);
  }

  @override
  void dispose() {
    _dashboard.removeListener(_syncRecentFromDashboard);
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    final dashboard = context.read<DashboardServices>();
    final search = context.read<RouteSearchService>();
    search.setQuery(value);
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      search.clearSearch();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      search.search(
        value,
        latitude: dashboard.latitude,
        longitude: dashboard.longitude,
      );
    });
  }

  void _openRoute(RouteModel route) {
    context.pushNamed('routeDetail', pathParameters: {'id': route.id});
  }

  Future<void> _openPlace(PlacePrediction place) async {
    final search = context.read<RouteSearchService>();
    final dashboard = context.read<DashboardServices>();
    final latLng = await search.resolvePlace(place);

    if (!mounted) return;

    if (latLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not resolve this place. Please try another location.',
          ),
        ),
      );
      return;
    }

    await dashboard.focusOnLocation(
      latLng.latitude,
      latLng.longitude,
      name: place.description,
    );
    if (!mounted) return;

    context.pushNamed(
      'generateRoute',
      queryParameters: {
        'destLat': '${latLng.latitude}',
        'destLng': '${latLng.longitude}',
        'destName': place.description,
      },
    );
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
                onFilterTap: () => showMapStyleBottomSheet(context),
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
    if (search.showRecentRoutes) {
      if (search.recentRoutes.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshRecentRoutes,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Text(
                  'Find safe routes near you',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshRecentRoutes,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          itemCount: search.recentRoutes.length + 1,
          separatorBuilder: (_, index) {
            if (index == 0) return const SizedBox(height: 6);
            return const SizedBox(height: 12);
          },
          itemBuilder: (context, index) {
            if (index == 0) return const RecentRoutesSectionHeader();
            final route = search.recentRoutes[index - 1];
            return RecentRouteTile.fromRouteModel(
              route,
              onTap: () => _openRoute(route),
            );
          },
        ),
      );
    }

    switch (search.status) {
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
            ...search.placeResults.map(
              (place) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: RecentRouteTile(
                  title: place.description,
                  subtitle: 'Location',
                  tag: 'Place',
                  thumbnailAssetPath: Assets.background,
                  onTap: () => _openPlace(place),
                ),
              ),
            ),
            ...search.results.map(
              (route) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: RecentRouteTile.fromRouteModel(
                  route,
                  onTap: () => _openRoute(route),
                ),
              ),
            ),
          ],
        );
      case RouteSearchStatus.idle:
      case RouteSearchStatus.loadingRecent:
        return const SizedBox.shrink();
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
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                Assets.noLocationFoundImg,
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
                    ? 'We couldn’t find a route that matches your preferences. Try adjusting your settings and we’ll look again'
                    : 'We couldn’t find a route that matches your preferences. Try adjusting your settings and we’ll look again',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
