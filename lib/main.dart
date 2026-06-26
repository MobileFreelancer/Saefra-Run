import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/config/firebase_config.dart';
import 'package:saefra_run/core/router/app_router.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('MAIN START');

    await dotenv.load(fileName: '.env');
    debugPrint('DOTENV LOADED');

    await FirebaseConfig.initialize();
    debugPrint('FIREBASE LOADED');

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    debugPrint('ORIENTATION SET');

    /// Create ONLY ONE instance of each service
    final authService = AuthService();
    final onboardingService = OnboardingService();

    /// Router notifier listens to the SAME instances
    final authStateNotifier = _AuthStateNotifier(
      authService,
      onboardingService,
    );

    AppRouter.init(authStateNotifier);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(
            value: authService,
          ),
          ChangeNotifierProvider<OnboardingService>.value(
            value: onboardingService,
          ),
          ChangeNotifierProvider<_AuthStateNotifier>.value(
            value: authStateNotifier,
          ),
        ],
        child: const SaefraRunApp(),
      ),
    );

    debugPrint('RUNAPP CALLED');
  } catch (e, s) {
    debugPrint('MAIN ERROR: $e');
    debugPrintStack(stackTrace: s);
  }
}

class SaefraRunApp extends StatelessWidget {
  const SaefraRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp.router(
        title: 'Saefra Run',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Rebuilds GoRouter whenever AuthService or OnboardingService changes.
class _AuthStateNotifier extends ChangeNotifier {
  final AuthService authService;
  final OnboardingService onboardingService;

  late bool _wasLoggedIn;
  late bool _wasOnboardingComplete;

  _AuthStateNotifier(
      this.authService,
      this.onboardingService,
      ) {
    authService.addListener(_onStateChanged);
    onboardingService.addListener(_onStateChanged);

    _wasLoggedIn = authService.isLoggedIn;
    _wasOnboardingComplete = onboardingService.isComplete;
  }

  void _onStateChanged() {
    final isLoggedIn = authService.isLoggedIn;
    final isOnboardingComplete = onboardingService.isComplete;

    if (isLoggedIn != _wasLoggedIn ||
        isOnboardingComplete != _wasOnboardingComplete) {
      _wasLoggedIn = isLoggedIn;
      _wasOnboardingComplete = isOnboardingComplete;

      notifyListeners();
    }
  }

  @override
  void dispose() {
    authService.removeListener(_onStateChanged);
    onboardingService.removeListener(_onStateChanged);
    super.dispose();
  }
}