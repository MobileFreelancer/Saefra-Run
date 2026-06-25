import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/features/auth/screens/forgot_password_screen.dart';
import 'package:saefra_run/features/auth/screens/login_screen.dart';
import 'package:saefra_run/features/auth/screens/reset_password_screen.dart';
import 'package:saefra_run/features/auth/screens/signup_screen.dart';
import 'package:saefra_run/features/auth/screens/verification_code_screen.dart';
import 'package:saefra_run/features/dashboard/screens/dashboard_screen.dart';
import 'package:saefra_run/features/onboarding/screens/activity_level_screen.dart';
import 'package:saefra_run/features/onboarding/screens/date_of_birth_screen.dart';
import 'package:saefra_run/features/onboarding/screens/enable_location_screen.dart';
import 'package:saefra_run/features/onboarding/screens/gender_screen.dart';
import 'package:saefra_run/features/onboarding/screens/goal_screen.dart';
import 'package:saefra_run/features/onboarding/screens/notifications_screen.dart';
import 'package:saefra_run/features/onboarding/screens/onboarding_intro_screen.dart';
import 'package:saefra_run/features/onboarding/screens/splash_screen.dart';

import '../../features/auth/screens/password_reset_success_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(Listenable refreshListenable) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = context.read<AuthService>();
      final onboarding = context.read<OnboardingService>();
      final isLoggedIn = auth.isLoggedIn;
      final isOnboardingComplete = onboarding.isComplete;
      final location = state.matchedLocation;

      final isSplash = location == '/splash';
      final isOnboardingRoute = location.startsWith('/onboarding');
      final isAuthRoute = location.startsWith('/auth');

      if (isSplash) return null;

      if (!isOnboardingComplete && !isOnboardingRoute) {
        return '/onboarding/intro';
      }

      if (isOnboardingComplete && isOnboardingRoute) {
        return isLoggedIn ? '/dashboard' : '/auth/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      if (!isLoggedIn &&
          !isAuthRoute &&
          !isOnboardingRoute &&
          location != '/splash') {
        return '/auth/login';
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
        builder: (context, state) => const DateOfBirthScreen(),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
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
