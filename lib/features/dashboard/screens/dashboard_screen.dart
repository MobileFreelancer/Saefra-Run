import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/recent_route_tile.dart';
import 'package:saefra_run/core/widgets/recommended_route_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/route_model.dart';
import '../../../core/services/dashboard_services.dart';
import '../../../core/services/route_service.dart';
import '../../../core/utils/app_tost.dart';
import '../../../core/utils/map_style_service.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/show_bottom_sheet.dart';
import '../../../generated/assets.dart';
import '../widgets/dashboard_map.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(21.205194905801783, 72.77568113625402),
    zoom: 16,
  );

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final services = context.read<DashboardServices>();
      await services.getCurrentLocation();
      //fetchAndShowRouteData();
    });
  }
  late final services = context.read<DashboardServices>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final screenSize = MediaQuery.of(context).size;
    final greetingName = user?.email ?? 'Jenny Wilson';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Map Layer Section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenSize.height * 0.42,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DashboardMap(
                      initialTarget: DashboardScreen._initialPosition.target,
                      initialZoom: DashboardScreen._initialPosition.zoom,
                    ),
                  ),

                  // "+" quick-add FAB over map layer
                  Positioned(
                    right: 16,
                    bottom: 43.h,
                    child: GestureDetector(
                      onTap: () => context.pushNamed('generateRoute'),
                      child: Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 26,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            Positioned.fill(
              top: screenSize.height * 0.40,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Consumer<DashboardServices>(
                    builder: (context, services, child) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
                        children: [
                          const Text(
                            'Recommended Route',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (services.isRouteLoading) ...[
                            Container(
                              height: 168,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.white.withValues(alpha: 0.04)),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Generating safest route...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (services.recommendedRoute != null) ...[
                            RecommendedRouteCard(
                              routeName: services.recommendedRoute!['route_name'] ?? 'Safest Route',
                              distanceLabel: '${services.recommendedRoute!['distance']} km • ${services.recommendedRoute!['safepoints']} SafePoints • Safety: ${services.recommendedRoute!['safety_score']}',
                              runnersNearbyLabel: '${services.recommendedRoute!['runner_count']} Runners active nearby',
                              imageAssetPath: services.recommendedRoute!['route_image']?.isNotEmpty == true
                                  ? services.recommendedRoute!['route_image']
                                  : Assets.background,
                              isSecure: RouteModel.readBool(
                                services.recommendedRoute!['is_secure'],
                              ),
                              onQuickStart: () {
                                final id =
                                    '${services.recommendedRoute?['route_id'] ?? services.recommendedRoute?['id'] ?? '2'}';
                                context.pushNamed(
                                  'routeDetail',
                                  pathParameters: {'id': id},
                                );
                              },
                            ),
                          ] else if (services.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.white.withValues(alpha: 0.04)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    services.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      if (services.latitude == null ||
                                          services.longitude == null) {
                                        AppToast.info(
                                          'Current location is required.',
                                        );
                                        return;
                                      }

                                      if (services.hasSelectedDestination) {
                                        services.fetchSafeRoute(
                                          originLat: services.latitude!,
                                          originLng: services.longitude!,
                                          destLat:
                                              services.destinationPositionLatitude!,
                                          destLng:
                                              services.destinationPositionLongitude!,
                                        );
                                        return;
                                      }

                                      AppToast.info(
                                        'Search and select a destination first.',
                                      );
                                    },
                                    child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'No route loaded.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          RecentRoutesSectionHeader(
                            trailing: TextButton(
                              onPressed: () => context.pushNamed('search'),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (services.isRouteLoading) ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                          ] else if (services.recentRoutes.isNotEmpty) ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: services.recentRoutes.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final route = services.recentRoutes[index];

                                return RecentRouteTile.fromRawMap(
                                  Map<String, dynamic>.from(route as Map),
                                  onTap: () {
                                    final id =
                                        '${route['route_id'] ?? route['id'] ?? index + 1}';
                                    context.pushNamed(
                                      'routeDetail',
                                      pathParameters: {'id': id},
                                    );
                                  },
                                );
                              },
                            ),
                          ] else ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No recent routes found.',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Top Header Profile and Search Bar Layer
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                color: AppColors.background,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _UserAvatar(name: greetingName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $greetingName',
                                style:   Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                  fontSize: 16.sp,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                                Text(
                                'Welcome to app 💪🏼',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.welcomeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pushNamed('notificationsInbox'),
                          child: Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            padding: const EdgeInsets.all(9),
                            child: Image.asset(
                              Assets.homeNotificationIcon,
                              color: AppColors.white,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.notifications_none,
                                size: 18,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                      SearchRouteField(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 0),
    );
  }
}




class SearchRouteField extends StatefulWidget {

  const  SearchRouteField({super.key,});

  @override
  State<SearchRouteField> createState() => _SearchRouteFieldState();
}

class _SearchRouteFieldState extends State<SearchRouteField> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<DashboardServices>();


    return Container(
      width: 355.w,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 10.h,vertical: 5.h),
      decoration: BoxDecoration(
          color: AppColors.textBorder,
          border: Border.all(color: AppColors.textBorder),
          borderRadius: BorderRadius.all(Radius.circular(10.r))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: (){
                final query = _searchController.text.trim();
                context.pushNamed(
                  'search',
                  queryParameters: query.isNotEmpty ? {'q': query} : {},
                );
              },
              child: Row(
                children: [
                  Image.asset(Assets.Search, scale: 2.5),
                  SizedBox(width: 13.w,),
                  Text("Search Route...",style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.searchColors,
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp
                  ),)
                ],
              ),
            ),
          ),
          GestureDetector(
              onTap: (){
                showMapStyleBottomSheet(context);
              },
              child: Image.asset(Assets.filter, scale: 2.5)
          )
        ],
      ),
    );
  }
}






class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase();

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surfaceLight,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
