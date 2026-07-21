import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/config/firebase_config.dart';
import 'package:saefra_run/core/router/app_router.dart';
import 'package:saefra_run/core/services/activity_service.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/services/contact_service.dart';
import 'package:saefra_run/core/services/community_service.dart';
import 'package:saefra_run/core/services/generate_route_service.dart';
import 'package:saefra_run/core/services/notification_inbox_service.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/core/services/route_detail_service.dart';
import 'package:saefra_run/core/services/route_search_service.dart';
import 'package:saefra_run/core/services/run_review_service.dart';
import 'package:saefra_run/core/services/run_service.dart';
import 'package:saefra_run/core/services/safety_checkin_service.dart';
import 'package:saefra_run/core/services/search_filter_service.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/theme/app_theme.dart';
import 'package:saefra_run/firebase_options.dart';

import 'core/services/dashboard_services.dart';
import 'core/services/firebase_messaging_background.dart';
import 'core/services/fcm_service.dart';
import 'core/services/live_running_services.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await FirebaseConfig.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
  await authService.initialize();
  await onboardingService.initialize();
  final authStateNotifier = _AuthStateNotifier(
    authService,
    onboardingService,
  );

  AppRouter.init(authStateNotifier);
  await FcmService.setup();
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
        ChangeNotifierProvider(
          create: (_) => DashboardServices(),
        ),
        ChangeNotifierProvider(create: (_) => RouteSearchService()),
        ChangeNotifierProvider(create: (_) => GenerateRouteService()),
        ChangeNotifierProvider(create: (_) => RouteDetailService()),
        ChangeNotifierProvider(
          create: (context) => SettingsService(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(create: (_) => ContactService()),
        ChangeNotifierProvider(create: (_) => NotificationInboxService()),
        ChangeNotifierProvider(create: (_) => SearchFilterService()),
        ChangeNotifierProvider(create: (_) => SafetyCheckInService()),
        ChangeNotifierProvider(create: (_) => CommunityService()),
        ChangeNotifierProvider(create: (_) => ActivityService()),
        ChangeNotifierProvider(create: (_) => RunService()),
        ChangeNotifierProvider(create: (_) => RunReviewService()),
        ChangeNotifierProvider(create: (_) => RunningProvider()),
      ],
      child: _AppWithFcm(scaffoldMessengerKey: scaffoldMessengerKey),
    ),
  );
}

/// Wires FCM push events to [NotificationInboxService] after providers exist.
class _AppWithFcm extends StatefulWidget {
  const _AppWithFcm({required this.scaffoldMessengerKey});

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  State<_AppWithFcm> createState() => _AppWithFcmState();
}

class _AppWithFcmState extends State<_AppWithFcm> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FcmService.requestPermissionAndSync();
      if (!mounted) return;

      FcmService.setPushReceivedCallback((message) {
        if (!mounted) return;
        final title = message.notification?.title ??
            message.data['title']?.toString() ??
            'Notification';
        final body = message.notification?.body ??
            message.data['body']?.toString() ??
            '';

        final inbox = context.read<NotificationInboxService>();
        inbox.prependFromPush(
          title: title,
          body: body,
          data: message.data,
        );
      });
    });
  }

  @override
  void dispose() {
    FcmService.setPushReceivedCallback(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SaefraRunApp(
        scaffoldMessengerKey: widget.scaffoldMessengerKey,
      );
}

class SaefraRunApp extends StatelessWidget {
  const SaefraRunApp({super.key, required this.scaffoldMessengerKey});

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
     onTap: () => FocusScope.of(context).unfocus(),
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp.router(
          title: 'Saefra Run',
          theme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
        ),
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
