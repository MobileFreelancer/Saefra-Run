import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/config/firebase_config.dart';
import 'package:saefra_run/core/router/app_router.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/theme/app_theme.dart';
import 'package:saefra_run/firebase_options.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await FirebaseConfig.initialize();
  await Firebase.initializeApp();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  await GoogleFonts.pendingFonts([
    GoogleFonts.manrope(),
    GoogleFonts.inter(),
  ]);
  // Warm cached theme before first frame.
  final _ = AppTheme.darkTheme;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final authService = AuthService();
  final onboardingService = OnboardingService();
  final authStateNotifier = _AuthStateNotifier(
    authService,
    onboardingService,
  );

  AppRouter.init(authStateNotifier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
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
}

class SaefraRunApp extends StatelessWidget {
  const SaefraRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        title: 'Saefra Run',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Rebuilds GoRouter whenever auth or onboarding state changes.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this.authService, this.onboardingService) {
    authService.addListener(_onStateChanged);
    onboardingService.addListener(_onStateChanged);
    _wasLoggedIn = authService.isLoggedIn;
    _wasOnboardingComplete = onboardingService.isComplete;
    _hadPendingSignup = authService.hasPendingSignup;
  }

  final AuthService authService;
  final OnboardingService onboardingService;

  late bool _wasLoggedIn;
  late bool _wasOnboardingComplete;
  late bool _hadPendingSignup;

  void _onStateChanged() {
    final isLoggedIn = authService.isLoggedIn;
    final isOnboardingComplete = onboardingService.isComplete;
    final hasPendingSignup = authService.hasPendingSignup;

    if (isLoggedIn != _wasLoggedIn ||
        isOnboardingComplete != _wasOnboardingComplete ||
        hasPendingSignup != _hadPendingSignup) {
      _wasLoggedIn = isLoggedIn;
      _wasOnboardingComplete = isOnboardingComplete;
      _hadPendingSignup = hasPendingSignup;
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
