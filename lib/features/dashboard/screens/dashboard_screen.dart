import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/notification_inbox_service.dart';
import 'package:saefra_run/core/services/activity_service.dart';
import 'package:saefra_run/core/models/generate_route_filters.dart';
import 'package:saefra_run/core/widgets/recent_route_tile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/services/dashboard_services.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import '../../../core/widgets/activity_shimmer_screen.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/primary_button.dart';
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
  int _selectedTemplateIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final services = context.read<DashboardServices>();
      if (!services.hasHomeData) {
        await services.initializeDashboard();
      }
      if (!mounted) return;
      context.read<NotificationInboxService>().loadIfNeeded();
      context.read<ActivityService>().load();
    });
  }

  void _onFindMyRoutePressed() {
    switch (_selectedTemplateIndex) {
      case 0:
        context.pushNamed(
          'generateRoute',
          queryParameters: {
            'difficulty': RouteDifficulty.easy.name,
            'distance': '3.0',
            'shape': RouteShape.loop.name,
          },
        );
        break;
      case 1:
        context.pushNamed(
          'generateRoute',
          queryParameters: {
            'difficulty': RouteDifficulty.moderate.name,
            'distance': '10.0',
            'shape': RouteShape.loop.name,
          },
        );
        break;
      case 2:
        context.pushNamed('community');
        break;
      case 3:
        context.pushNamed('generateRoute');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final inbox = context.watch<NotificationInboxService>();
    final services = context.watch<DashboardServices>();
    final activity = context.watch<ActivityService>();
    final user = auth.currentUser;

    final greetingName = [
      user?.firstName,
      user?.lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();
    final displayName = greetingName.isNotEmpty
        ? greetingName
        : (user?.email?.split('@').first ?? 'Runner');
    final userProfileImage = user?.profileImage?.toString();

    // Stats variables with fallback values if null/empty
    final summary = activity.summary;
    final calories = summary != null && summary.totalCalories > 0 ? summary.totalCalories : 1250;
    final activeMinutes = summary != null && summary.totalMinutes > 0 ? summary.totalMinutes : 72;
    final distanceKm = summary != null && summary.totalDistanceKm > 0 ? summary.totalDistanceKm : 12.0;

    final templates = [
      _TemplateItem(
        title: 'Easy & Relaxing',
        subtitle: 'A comfortable route to build confidence',
        icon: Assets.onboardingEasyPaceIcon,
      ),
      _TemplateItem(
        title: 'Moderate Challenge',
        subtitle: 'Push yourself just enough with a balanced route',
        icon: Assets.onboardingModerateChallengeIcon,
      ),
      _TemplateItem(
        title: 'Community Favorite',
        subtitle: 'Popular routes loved by runners near by',
        icon: Assets.communityFavIcon,
      ),
      _TemplateItem(
        title: 'Generate My Own',
        subtitle: 'Customize my run based on my preferences',
        icon: Assets.generateOwnIcon,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleRootBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Profile Bar
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                color: AppColors.background,
                child: Row(
                  children: [
                    userProfileImage != null && userProfileImage.isNotEmpty
                        ? AppCircleCachedImage(
                            imageUrl: userProfileImage,
                            width: 42.w,
                            height: 42.h,
                            fit: BoxFit.cover,
                          )
                        : _UserAvatar(name: displayName),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${displayName.toUpperCase()}',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 16.sp,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Welcome back! 💪🏼',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 38.h,
                            width: 38.w,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            padding: EdgeInsets.all(9.r),
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
                          if (inbox.unreadCount > 0)
                            Positioned(
                              top: -2.h,
                              right: -2.w,
                              child: Container(
                                width: 10.w,
                                height: 10.h,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Scrollable
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await services.refreshHomeData();
                    if (!mounted) return;
                    await context.read<NotificationInboxService>().load(refresh: true);
                    await context.read<ActivityService>().load(refresh: true);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                    children: [
                      // Header title
                      Text(
                        'What kind of route do you want today?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Choose one to get started',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.textMuted,
                            ),
                      ),
                      SizedBox(height: 16.h),

                      // Templates List
                      ...List.generate(templates.length, (index) {
                        final item = templates[index];
                        final isSelected = _selectedTemplateIndex == index;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTemplateIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.surfaceLight : AppColors.surface,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.borderColor,
                                  width: 1.5.w,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icon Container
                                  Image.asset(
                                    item.icon,
                                    color: isSelected ? AppColors.primary : AppColors.white.withValues(alpha: 0.6),
                                    height: 30.r,
                                  ),
                                  SizedBox(width: 12.w),
                                  // Titles
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                                color: AppColors.white,
                                              ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          item.subtitle,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontSize: 11.sp,
                                                color: AppColors.textMuted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textMuted,
                                    size: 18.r,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 10.h),

                      // Find My Route Button
                      PrimaryButton(
                        label: 'Get Started',
                        //isLoading: service.isLoading,
                        onPressed: _onFindMyRoutePressed,
                      ),
                      SizedBox(height: 24.h),

                      // Fitness Stats Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Powered by Our Running Community',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                Text(
                                 "Routes improved by runners near you",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.goNamed('activity'),
                            child: Text(
                              'Explore',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people_outline_rounded,
                              iconColor: const Color(0xFFFF4E6A),
                              value: services.nearbyRunners.toString(),
                              unit: '',
                              label: 'Runners active nearby',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.verified_user_outlined,
                              iconColor: const Color(0xFF22C55E),
                              value: services.routesVerifiedToday.toString(),
                              unit: '',
                              label: 'Routes verified today',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.report_problem_outlined,
                              iconColor: const Color(0xFFFF9500),
                              value: services.safetyReportsCount.toString(),
                              unit: '',
                              label: 'New safety reports',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Recent Routes Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Route',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                          ),
                          GestureDetector(
                            onTap: () => context.pushNamed('search'),
                            child: Text(
                              'View all',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      if (services.isRouteLoading) ...[
                        const ActivityCardShimmer(),
                      ] else if (services.recentRoutes.isNotEmpty) ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: services.recentRoutes.length.clamp(0, 2),
                          separatorBuilder: (context, index) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final route = services.recentRoutes[index];
                            return RecentRouteTile.fromRawMap(
                              Map<String, dynamic>.from(route as Map),
                              onTap: () {
                                final id = '${route['route_id'] ?? route['id'] ?? index + 1}';
                                context.pushNamed(
                                  'routeDetail',
                                  pathParameters: {'id': id},
                                );
                              },
                            );
                          },
                        ),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          alignment: Alignment.center,
                          child: Text(
                            'No recent routes found.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12.sp,
                                ),
                          ),
                        ),
                      ],
                      SizedBox(height: 24.h),

                      // Map Overview Section
                      Text(
                        'Map Preview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        height: 180.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.borderColor,
                            width: 1.w,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: DashboardMap(
                            initialTarget: DashboardScreen._initialPosition.target,
                            initialZoom: DashboardScreen._initialPosition.zoom,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNav(activeIndex: 0),
      ),
    );
  }
}

class _TemplateItem {
  final String title;
  final String subtitle;
  final String icon;

  const _TemplateItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24.r,
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
              ),
              SizedBox(width: 2.w),
              Text(
                unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10.sp,
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10.sp,
                  color: AppColors.textMuted,
                ),
          ),
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
      radius: 20.r,
      backgroundColor: AppColors.surfaceLight,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}

/*
OLD DASHBOARD SCREEN IMPLEMENTATION FOR FUTURE REFERENCE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/notification_inbox_service.dart';
import 'package:saefra_run/core/widgets/recent_route_tile.dart';
import 'package:saefra_run/core/widgets/recommended_route_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/route_model.dart';
import '../../../core/services/dashboard_services.dart';
import '../../../core/utils/app_tost.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import '../../../core/widgets/activity_shimmer_screen.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/show_bottom_sheet.dart';
import '../../../generated/assets.dart';
import '../widgets/dashboard_map.dart';

class OldDashboardScreen extends StatefulWidget {
  const OldDashboardScreen({super.key});

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(21.205194905801783, 72.77568113625402),
    zoom: 16,
  );

  @override
  State<OldDashboardScreen> createState() => _OldDashboardScreenState();
}

class _OldDashboardScreenState extends State<OldDashboardScreen> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final services = context.read<DashboardServices>();
      if (!services.hasHomeData) {
        await services.initializeDashboard();
      }
      if (!mounted) return;
      context.read<NotificationInboxService>().loadIfNeeded();
    });
  }

  late final services = context.read<DashboardServices>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final inbox = context.watch<NotificationInboxService>();
    final user = auth.currentUser;
    final screenSize = MediaQuery.of(context).size;
    final greetingName = [
      user?.firstName,
      user?.lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();
    final displayName = greetingName.isNotEmpty
        ? greetingName
        : (user?.email?.split('@').first ?? 'Runner');
    final userProFileImage=user?.profileImage.toString();
    print("+++++++++++++++");
    print(userProFileImage);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleRootBack(context);
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              color: AppColors.background,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      userProFileImage != null && userProFileImage.isNotEmpty
                          ? AppCircleCachedImage(
                        imageUrl: userProFileImage,
                        width: 42.w,
                        height: 42.h,
                        fit: BoxFit.cover,
                      )
                          : _OldUserAvatar(name: displayName),
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
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
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
                            if (inbox.unreadCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OldSearchRouteField(),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Map Layer Section
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: screenSize.height * 0.28,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DashboardMap(
                            initialTarget: OldDashboardScreen._initialPosition.target,
                            initialZoom: OldDashboardScreen._initialPosition.zoom,
                          ),
                        ),

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
                    top: screenSize.height * 0.25,
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
                            return RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () async {
                                await services.refreshHomeData();
                                if (!context.mounted) return;
                                await context
                                    .read<NotificationInboxService>()
                                    .load(refresh: true);
                              },
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
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
                                        ActivityCardShimmer()
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
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: ListView.builder(
                                         shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: 3,
                                        itemBuilder: (context, index) {
                                          return   const Padding(
                                            padding: EdgeInsets.only(bottom: 12),
                                            child: ActivityCardShimmer(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ]
                                else if (services.recentRoutes.isNotEmpty) ...[
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
                            ),
                          );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 0),
    ),
    );
  }
}




class OldSearchRouteField extends StatefulWidget {

  const  OldSearchRouteField({super.key,});

  @override
  State<OldSearchRouteField> createState() => _OldSearchRouteFieldState();
}

class _OldSearchRouteFieldState extends State<OldSearchRouteField> {
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
              onTap: () {
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

class _OldUserAvatar extends StatelessWidget {
  const _OldUserAvatar({required this.name});
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
*/
