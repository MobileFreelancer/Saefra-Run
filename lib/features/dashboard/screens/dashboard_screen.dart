import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/recent_route_tile.dart';
import 'package:saefra_run/core/widgets/recommended_route_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/services/dashboard_services.dart';
import '../../../generated/assets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(21.205194905801783, 72.77568113625402),
    zoom: 10,
  );

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {


  @override
  void initState() {
    context.read<DashboardServices>().fetchSafeRoute(
      originLat: 21.205194905801783,
      originLng: 72.77568113625402,
      destLat: 21.205194905801783,
      destLng: 72.77568113625402,
    );
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    // Schedule location fetch on layout render pass safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardServices>().getCurrentLocation();

    });

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
                    child: Consumer<DashboardServices>(
                      builder: (context, services, child) {
                        final mapTarget =
                            (services.latitude != null &&
                                services.longitude != null)
                            ? LatLng(services.latitude!, services.longitude!)
                            : DashboardScreen._initialPosition.target;

                        return GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: mapTarget,
                            zoom: DashboardScreen._initialPosition.zoom,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          circles: services.getMapCircles(),
                          markers: services.getMapMarkers(context),
                          polylines: {
                            if (services.routePolylinePoints.isNotEmpty)
                              Polyline(
                                polylineId: const PolylineId('safe_route_polyline'),
                                points: services.routePolylinePoints,
                                color: AppColors.primary,
                                width: 5,
                              ),
                          },
                          onMapCreated: (controller) {
                            context.read<DashboardServices>().setMapController(
                              controller,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // "+" quick-add FAB over map layer
                  Positioned(
                    right: 16,
                    bottom: 43.h,
                    child: GestureDetector(
                      onTap: () => _todo(context, 'Create a route'),
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

            // ---- Scrollable content sheet bottom overlay ----
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
                              isSecure: services.recommendedRoute!['is_secure'] ?? true,
                              onQuickStart: () => _todo(context, 'Quick start run'),
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
                                      final double originLat = services.latitude ?? 21.2158;
                                      final double originLng = services.longitude ?? 72.8372;
                                      services.fetchSafeRoute(
                                        originLat: originLat,
                                        originLng: originLng,
                                        destLat: 21.2035,
                                        destLng: 72.7997,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Routes',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _todo(context, 'View all routes'),
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
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
                                final distance = route['distance'] ?? 0.0;
                                final duration = route['duration'] ?? 0;
                                final tag = route['tag'] ?? 'NA';
                                final title = route['route_name'] ?? 'Route';
                                final dateStr = route['date'];

                                String dateLabel = 'Recent';
                                if (dateStr != null) {
                                  try {
                                    final parsed = DateTime.parse(dateStr);
                                    dateLabel = '${parsed.day}/${parsed.month}/${parsed.year}';
                                  } catch (_) {}
                                }

                                return RecentRouteTile(
                                  title: title,
                                  subtitle: '$dateLabel • $distance km • $duration mins',
                                  tag: tag == 'Na' || tag == 'NA' ? 'Route' : tag,
                                  thumbnailAssetPath: route['route_image']?.isNotEmpty == true
                                      ? route['route_image']
                                      : Assets.background,
                                  onTap: () => _todo(context, 'Open route detail'),
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
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Welcome to app 💪',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _todo(context, 'Notifications'),
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
                    const SearchRouteField(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF070707),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          top: false,
          child: Consumer<DashboardServices>(
            builder: (context, services, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomBarItem(
                    index: 0,
                    assetPath: Assets.bottomBarHomeIcon,
                    fallback: Icons.grid_view,
                    isSelected: services.currentBottomIndex == 0,
                    onTap: () => services.setBottomIndex(0),
                  ),
                  _BottomBarItem(
                    index: 1,
                    assetPath: Assets.bottomBarFireIcon,
                    fallback: Icons.local_fire_department_outlined,
                    isSelected: services.currentBottomIndex == 1,
                    onTap: () => services.setBottomIndex(1),
                  ),
                  _BottomBarItem(
                    index: 2,
                    assetPath: Assets.bottomBarLevelIcon,
                    fallback: Icons.bar_chart,
                    isSelected: services.currentBottomIndex == 2,
                    onTap: () => services.setBottomIndex(2),
                  ),
                  _BottomBarItem(
                    index: 3,
                    assetPath: Assets.bottomBarProfileIcon,
                    fallback: Icons.person_outline,
                    isSelected: services.currentBottomIndex == 3,
                    onTap: () => services.setBottomIndex(3),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SearchRouteField extends StatefulWidget {
  const SearchRouteField({super.key});

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 41.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              services.searchLocation(value);
            },
            decoration: InputDecoration(
              hintText: "Search Route...",
              hintStyle: TextStyle(color: Colors.white54, fontSize: 16.sp),
              filled: true,
              fillColor: const Color(0xFF222222),
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              prefixIcon: Image.asset(Assets.Search, scale: 2.5),
              prefixIconConstraints: const BoxConstraints(minWidth: 60),
              suffixIcon: Consumer<DashboardServices>(
                builder: (context, svc, _) {
                  if (svc.isSearching) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }
                  return Image.asset(Assets.filter, scale: 2.5);
                },
              ),
              suffixIconConstraints: BoxConstraints(minWidth: 50.w),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(
                  width: 1.2,
                  color: Color(0xFF131315),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(
                  width: 1.2,
                  color: Color(0xFF131315),
                ),
              ),
            ),
          ),
        ),

        // Dynamic Dropdown Overlay list for Location Autocomplete
        Consumer<DashboardServices>(
          builder: (context, svc, child) {
            if (svc.placePredictions.isEmpty) return const SizedBox.shrink();

            return Container(
              height: 220.h,
              margin: EdgeInsets.only(top: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: svc.placePredictions.length,
                itemBuilder: (context, index) {
                  final prediction = svc.placePredictions[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    title: Text(
                      prediction['description'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _searchController.text = prediction['description'] ?? '';
                      svc.selectPrediction(prediction['place_id']);
                      FocusScope.of(
                        context,
                      ).unfocus(); // Close standard keyboard layout
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
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

class _MapAssetButton extends StatelessWidget {
  const _MapAssetButton({
    required this.assetPath,
    required this.fallback,
    this.onTap,
  });
  final String assetPath;
  final IconData fallback;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(9),
        child: Image.asset(
          assetPath,
          color: AppColors.white,
          errorBuilder: (_, __, ___) => Icon(
            fallback,
            size: 16,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.index,
    required this.assetPath,
    required this.fallback,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final String assetPath;
  final IconData fallback;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: 22,
          height: 22,
          child: Image.asset(
            assetPath,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              fallback,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

void _todo(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label — coming soon'),
      duration: const Duration(milliseconds: 900),
      backgroundColor: AppColors.surfaceLight,
    ),
  );
}
