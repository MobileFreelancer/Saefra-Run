import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/map_view.dart';
import 'package:saefra_run/core/widgets/recent_route_tile.dart';
import 'package:saefra_run/core/widgets/recommended_route_card.dart';

import '../../../generated/assets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentBottomIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final screenSize = MediaQuery.of(context).size;
    final greetingName = user?.fullName ?? 'Jenny Wilson';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ---- Map area (top ~42% of screen) ----
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenSize.height * 0.42,
              child: Stack(
                children: [
                  // Drop-in seam: swap MapView's internals for a real map
                  // SDK later, no call-site changes needed elsewhere.
                  Positioned.fill(
                    child: MapView(onMapTap: () => _todo(context, 'Open full map')),
                  ),

                  // Floating controls, stacked bottom-left over the map.
                  Positioned(
                    left: 16,
                    bottom: 24,
                    child: Column(
                      children: [
                        _MapAssetButton(
                          assetPath: Assets.homeNearbyIcon,
                          fallback: Icons.near_me_outlined,
                          onTap: () => _todo(context, 'Nearby runners'),
                        ),
                        const SizedBox(height: 10),
                        _MapAssetButton(
                          assetPath: Assets.homeRouteFindingIcon,
                          fallback: Icons.alt_route,
                          onTap: () => _todo(context, 'Route finding'),
                        ),
                        const SizedBox(height: 10),
                        _MapAssetButton(
                          assetPath: Assets.onboardingNotificationIcon,
                          fallback: Icons.volume_up_outlined,
                          onTap: () => _todo(context, 'Audio alerts'),
                        ),
                      ],
                    ),
                  ),

                  // "+" quick-add FAB, bottom-right over the map.
                  Positioned(
                    right: 16,
                    bottom: 24,
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
                        child: const Icon(Icons.add, size: 26, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Scrollable content sheet ----
            Positioned.fill(
              top: screenSize.height * 0.40,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: ListView(
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
                      RecommendedRouteCard(
                        routeName: 'North Loop Patrol',
                        distanceLabel: '3.2 miles • 14 SafePoints',
                        runnersNearbyLabel: '12 Runners active nearby',
                        imageAssetPath: Assets.homeRoutePreviewImg,
                        onQuickStart: () => _todo(context, 'Quick start run'),
                      ),
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
                      RecentRouteTile(
                        title: 'Lakeside Perimeter',
                        subtitle: 'Yesterday • 5.2 km • 28mins',
                        tag: 'Safe path',
                        thumbnailAssetPath: Assets.homeRouteThumbnailImg,
                        onTap: () => _todo(context, 'Open route detail'),
                      ),
                      const SizedBox(height: 12),
                      RecentRouteTile(
                        title: 'Lakeside Perimeter',
                        subtitle: 'Yesterday • 5.2 km • 28mins',
                        tag: 'Popular',
                        thumbnailAssetPath: Assets.homeRouteThumbnailImg,
                        onTap: () => _todo(context, 'Open route detail'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---- Floating header: greeting + bell, then search + filter ----
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
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
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
                              border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
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
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.white.withValues(alpha: 0.03)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Image.asset(
                                    Assets.homeSearchIcon,
                                    color: AppColors.textSecondary,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.search,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Search Route...',
                                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (query) {
                                      if (query.trim().isEmpty) return;
                                      _todo(context, 'Search routes: $query');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _todo(context, 'Filter routes'),
                          child: Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              Assets.homeFilterIcon,
                              color: AppColors.white,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.tune,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomBarItem(
                index: 0,
                assetPath: Assets.bottomBarHomeIcon,
                fallback: Icons.grid_view,
                isSelected: _currentBottomIndex == 0,
                onTap: () => setState(() => _currentBottomIndex = 0),
              ),
              _BottomBarItem(
                index: 1,
                assetPath: Assets.bottomBarFireIcon,
                fallback: Icons.local_fire_department_outlined,
                isSelected: _currentBottomIndex == 1,
                onTap: () => setState(() => _currentBottomIndex = 1),
              ),
              _BottomBarItem(
                index: 2,
                assetPath: Assets.bottomBarLevelIcon,
                fallback: Icons.bar_chart,
                isSelected: _currentBottomIndex == 2,
                onTap: () => setState(() => _currentBottomIndex = 2),
              ),
              _BottomBarItem(
                index: 3,
                assetPath: Assets.bottomBarProfileIcon,
                fallback: Icons.person_outline,
                isSelected: _currentBottomIndex == 3,
                onTap: () => setState(() => _currentBottomIndex = 3),
              ),
            ],
          ),
        ),
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
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();

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
  const _MapAssetButton({required this.assetPath, required this.fallback, this.onTap});

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
          errorBuilder: (_, __, ___) => Icon(fallback, size: 16, color: AppColors.white.withValues(alpha: 0.7)),
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
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

/// Placeholder action used by buttons whose destination screen/route
/// doesn't exist yet. Shows a quick snackbar instead of crashing on an
/// undefined go_router path. Replace each call site with a real
/// `context.push('/your-route')` once that route is wired up.
void _todo(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label — coming soon'),
      duration: const Duration(milliseconds: 900),
      backgroundColor: AppColors.surfaceLight,
    ),
  );
}
