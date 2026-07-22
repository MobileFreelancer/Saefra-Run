import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/features/auth/screens/forgot_password_screen.dart';
import 'package:saefra_run/features/auth/screens/login_screen.dart';
import 'package:saefra_run/features/auth/screens/password_reset_success_screen.dart';
import 'package:saefra_run/features/auth/screens/reset_password_screen.dart';
import 'package:saefra_run/features/auth/screens/signup_screen.dart';
import 'package:saefra_run/features/auth/screens/verification_code_screen.dart';
import 'package:saefra_run/features/dashboard/screens/dashboard_screen.dart';
import 'package:saefra_run/features/onboarding/screens/activity_level_screen.dart';
import 'package:saefra_run/features/onboarding/screens/basic_info_screen.dart';
import 'package:saefra_run/features/onboarding/screens/enable_location_screen.dart';
import 'package:saefra_run/features/onboarding/screens/gender_screen.dart';
import 'package:saefra_run/features/onboarding/screens/goal_screen.dart';
import 'package:saefra_run/features/onboarding/screens/notifications_screen.dart';
import 'package:saefra_run/features/notifications/screens/notifications_inbox_screen.dart';
import 'package:saefra_run/features/onboarding/screens/onboarding_intro_screen.dart';
import 'package:saefra_run/features/onboarding/screens/splash_screen.dart';
import 'package:saefra_run/features/community/screens/community_route_detail_screen.dart';
import 'package:saefra_run/features/community/screens/community_routes_list_screen.dart';
import 'package:saefra_run/features/community/screens/community_screen.dart';
import 'package:saefra_run/core/services/community_route_list_service.dart';
import 'package:saefra_run/features/community/screens/route_reviews_screen.dart';
import 'package:saefra_run/features/activity/screens/activity_screen.dart';
import 'package:saefra_run/features/routes/screens/generate_route_screen.dart';
import 'package:saefra_run/features/routes/screens/route_detail_screen.dart';
import 'package:saefra_run/features/run/screens/add_run_images_screen.dart';
import 'package:saefra_run/features/run/screens/live_running_screen.dart';
import 'package:saefra_run/features/run/screens/run_rate_screen.dart';
import 'package:saefra_run/features/run/screens/run_summary_screen.dart';
import 'package:saefra_run/features/search/screens/search_screen.dart';
import 'package:saefra_run/features/search/screens/search_filters_screen.dart';
import 'package:saefra_run/features/run/screens/safety_checkin_screen.dart';
import 'package:saefra_run/features/settings/screens/about_us_screen.dart';
import 'package:saefra_run/features/settings/screens/add_emergency_contact_screen.dart';
import 'package:saefra_run/features/settings/screens/change_password_screen.dart';
import 'package:saefra_run/features/settings/screens/contact_us_screen.dart';
import 'package:saefra_run/features/settings/screens/edit_profile_screen.dart';
import 'package:saefra_run/features/settings/screens/emergency_contacts_screen.dart';
import 'package:saefra_run/features/settings/screens/legal_content_screen.dart';
import 'package:saefra_run/features/settings/screens/notification_settings_screen.dart';
import 'package:saefra_run/features/settings/screens/safety_settings_screen.dart';
import 'package:saefra_run/features/settings/screens/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static bool _isPasswordResetRoute(String location) {
    return location.startsWith('/auth/forgot-password') ||
        location.startsWith('/auth/verification') ||
        location.startsWith('/auth/reset-password');
  }

  static GoRouter createRouter(Listenable refreshListenable) => GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = context.read<AuthService>();
      final isLoggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;

      if (location == '/splash') return null;

      // 1. User agar logged in NAHI hai:
      if (!isLoggedIn) {
        if (location == '/onboarding/intro') return null;
        if (location.startsWith('/auth')) return null;
        if (location.startsWith('/onboarding') && auth.hasPendingSignup) {
          return null;
        }
        if (location.startsWith('/onboarding')) {
          return '/auth/login';
        }
        return '/onboarding/intro';
      }

      // 2. User agar logged in HAI:
      // Password reset screens ko access karne dein bina interrupt kiye
      if (_isPasswordResetRoute(location)) return null;

      // Agar user logged in hai aur login/signup paths par jaane ki koshish kare,
      // ya fir kisi onboarding screen par ho, toh directly bina conditions ke dashboard bhej do.
      if (location.startsWith('/auth') || location.startsWith('/onboarding')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding/intro',
        name: 'onboardingIntro',
        builder: (context, state) => const OnboardingIntroScreen(),
      ),
      GoRoute(
        path: '/onboarding/gender',
        name: 'gender',
        builder: (context, state) => const GenderScreen(),
      ),
      GoRoute(
        path: '/onboarding/basic-info',
        name: 'basicInfo',
        builder: (context, state) => const BasicInfoScreen(),
      ),
      GoRoute(
        path: '/onboarding/activity-level',
        name: 'activityLevel',
        builder: (context, state) => const ActivityLevelScreen(),
      ),
      GoRoute(
        path: '/onboarding/goal',
        name: 'goal',
        builder: (context, state) => const GoalScreen(),
      ),
      GoRoute(
        path: '/onboarding/dob',
        name: 'dateOfBirth',
        builder: (context, state) => const BasicInfoScreen(),
      ),
      GoRoute(
        path: '/onboarding/location',
        name: 'location',
        builder: (context, state) => const EnableLocationScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/verification',
        name: 'verification',
        builder: (context, state) => const VerificationCodeScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password-successfully',
        name: 'resetPasswordSuccessfully',
        builder: (context, state) => const PasswordResetSuccessScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notificationsInbox',
        builder: (context, state) => const NotificationsInboxScreen(),
      ),
      GoRoute(
        path: '/search/filters',
        name: 'searchFilters',
        builder: (context, state) => const SearchFiltersScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/routes/generate',
        name: 'generateRoute',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          final destLat = double.tryParse(params['destLat'] ?? '');
          final destLng = double.tryParse(params['destLng'] ?? '');
          return GenerateRouteScreen(
            destLat: destLat,
            destLng: destLng,
            destName: params['destName'],
          );
        },
      ),
      GoRoute(
        path: '/routes/:id',
        name: 'routeDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RouteDetailScreen(routeId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings/safety',
        name: 'safetySettings',
        builder: (context, state) => const SafetySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/emergency-contacts',
        name: 'emergencyContacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/settings/emergency-contacts/add',
        name: 'addEmergencyContact',
        builder: (context, state) => const AddEmergencyContactScreen(),
      ),
      GoRoute(
        path: '/settings/change-password',
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/legal',
        name: 'legalContent',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'terms';
          return LegalContentScreen(type: type);
        },
      ),
      GoRoute(
        path: '/settings/contact-us',
        name: 'contactUs',
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        name: 'aboutUs',
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        path: '/community/routes-list',
        name: 'communityRoutesList',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'popular';
          final kind = type == 'recent'
              ? CommunityRouteListKind.recent
              : CommunityRouteListKind.popular;
          return CommunityRoutesListScreen(kind: kind);
        },
      ),
      GoRoute(
        path: '/community',
        name: 'community',
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: '/community/routes/:id',
        name: 'communityRouteDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CommunityRouteDetailScreen(routeId: id);
        },
      ),
      GoRoute(
        path: '/community/routes/:id/reviews',
        name: 'routeReviews',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RouteReviewsScreen(routeId: id);
        },
      ),
      GoRoute(
        path: '/activity',
        name: 'activity',
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/run/safety-checkin',
        name: 'safetyCheckIn',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          return SafetyCheckInScreen(
            routeId: qp['routeId'],
            routeName: qp['routeName'],
          );
        },
      ),
      GoRoute(
        path: '/run/live',
        name: 'liveRunning',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          return LiveRunningScreen(
            routeId: qp['routeId'],
            routeName: qp['routeName'],
          );
        },
      ),
      GoRoute(
        path: '/run/sos',
        name: 'sosActive',
        builder: (context, state) => const SosActiveScreen(),
      ),
      GoRoute(
        path: '/run/summary',
        name: 'runSummary',
        builder: (context, state) => const RunSummaryScreen(),
      ),
      GoRoute(
        path: '/run/rate',
        name: 'runRate',
        builder: (context, state) => const RunRateScreen(),
      ),
      GoRoute(
        path: '/run/images',
        name: 'addRunImages',
        builder: (context, state) => const AddRunImagesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter? _router;

  static GoRouter get router {
    assert(_router != null, 'Call AppRouter.init() before accessing router');
    return _router!;
  }

  static void init(Listenable refreshListenable) {
    _router = createRouter(refreshListenable);
  }
}