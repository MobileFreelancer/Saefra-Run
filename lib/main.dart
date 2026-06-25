import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/config/firebase_config.dart';
import 'package:saefra_run/core/router/app_router.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await FirebaseConfig.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final authStateNotifier = _AuthStateNotifier();
  AppRouter.init(authStateNotifier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => OnboardingService()),
        ChangeNotifierProvider.value(value: authStateNotifier),
      ],
      child: const SaefraRunApp(),
    ),
  );
}

class SaefraRunApp extends StatelessWidget {
  const SaefraRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Saefra Run',
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Rebuilds GoRouter when auth or onboarding state changes.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    AuthService().addListener(_onStateChanged);
    OnboardingService().addListener(_onStateChanged);
    _wasLoggedIn = AuthService().isLoggedIn;
    _wasOnboardingComplete = OnboardingService().isComplete;
  }

  bool _wasLoggedIn = false;
  bool _wasOnboardingComplete = false;

  void _onStateChanged() {
    final isLoggedIn = AuthService().isLoggedIn;
    final isOnboardingComplete = OnboardingService().isComplete;
    if (isLoggedIn != _wasLoggedIn ||
        isOnboardingComplete != _wasOnboardingComplete) {
      _wasLoggedIn = isLoggedIn;
      _wasOnboardingComplete = isOnboardingComplete;
      notifyListeners();
    }
  }
}
