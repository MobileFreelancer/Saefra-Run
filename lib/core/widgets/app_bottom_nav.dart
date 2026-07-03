import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/generated/assets.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, this.activeIndex = 0});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              assetPath: Assets.bottomBarHomeIcon,
              fallback: Icons.grid_view,
              isSelected: activeIndex == 0,
              onTap: () => context.goNamed('dashboard'),
            ),
            _NavItem(
              assetPath: Assets.bottomBarFireIcon,
              fallback: Icons.local_fire_department_outlined,
              isSelected: activeIndex == 1,
              onTap: () => context.goNamed('community'),
            ),
            GestureDetector(
              onTap: () {
                final services = context.read<DashboardServices>();
                final route = services.recommendedRoute;
                final id = '${route?['route_id'] ?? route?['id'] ?? '2'}';
                context.pushNamed('liveRunning', queryParameters: {'routeId': id});
              },
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                Assets.pluseIcon,
                fit: BoxFit.contain,
                width: 60.w,
                height: 60.w,
                errorBuilder: (_, __, ___) => Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: AppColors.white, size: 32),
                ),
              ),
            ),
            _NavItem(
              assetPath: Assets.bottomBarLevelIcon,
              fallback: Icons.bar_chart,
              isSelected: activeIndex == 2,
              onTap: () => context.goNamed('activity'),
            ),
            _NavItem(
              assetPath: Assets.bottomBarProfileIcon,
              fallback: Icons.person_outline,
              isSelected: activeIndex == 3,
              onTap: () => context.goNamed('settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.assetPath,
    required this.fallback,
    required this.isSelected,
    required this.onTap,
  });

  final String assetPath;
  final IconData fallback;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHome = assetPath == Assets.bottomBarHomeIcon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D070A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            assetPath,
            color: isHome
                ? (isSelected ? null : const Color(0xFF707070))
                : (isSelected ? const Color(0xFFEF4444) : const Color(0xFF707070)),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              fallback,
              color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF707070),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
