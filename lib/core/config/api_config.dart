import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { development, staging, production }

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const dartDefine = String.fromEnvironment('BASE_URL');
    if (dartDefine.isNotEmpty) return dartDefine;
    final envVal = dotenv.env['BASE_URL'];
    if (envVal != null && envVal.isNotEmpty) return envVal;
    return 'https://api.saefra.run';
  }

  static Environment get currentEnvironment {
    const dartDefine = String.fromEnvironment('ENVIRONMENT');
    final envVal = dartDefine.isNotEmpty
        ? dartDefine
        : (dotenv.env['ENVIRONMENT'] ?? 'development');
    switch (envVal.toLowerCase()) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.development;
    }
  }

  /// ngrok free tier requires this header to avoid HTML warning pages.
  static const String ngrokSkipBrowserWarning = 'Ngrok-Skip-Browser-Warning';

  static bool get isDevelopment => currentEnvironment == Environment.development;
  static bool get isProduction => currentEnvironment == Environment.production;

  /// Search place key — Places API (New).
  static String get googlePlacesApiKey => _envKey(
        'GOOGLE_PLACES_API_KEY',
        fallback: 'AIzaSyB-fBCkeBi5ydRGaBFbfk1yVJ8f0y2teHw',
      );

  /// Routes API key — route generation (computeRoutes).
  static String get googleRoutesApiKey => _envKey(
        'GOOGLE_ROUTES_API_KEY',
        fallback: 'AIzaSyCFgFs0MnJiOwHH30fwolYKxr64QMHqDaw',
      );

  /// Directions API key — polylines / turn-by-turn paths.
  static String get googleDirectionsApiKey => _envKey(
        'GOOGLE_DIRECTIONS_API_KEY',
        fallback: 'AIzaSyCCXvHr8n7vr76nDUiiavqN46IhVIqei8Y',
      );

  /// Android key (Firebase) — Maps SDK on Android.
  static String get googleMapsAndroidApiKey => _envKey(
        'GOOGLE_MAPS_ANDROID_API_KEY',
        fallback: 'AIzaSyDCeFCXrcID6-SEIVmdloN3rOfRINqGXbE',

      );

  /// iOS key (Firebase) — Maps SDK on iOS.
  static String get googleMapsIosApiKey => _envKey(
        'GOOGLE_MAPS_IOS_API_KEY',
        fallback: 'AIzaSyAGn_QWJqJB6imawsTUNMWYx_DCb76SGlQ',
      );

  /// Generic maps key fallback (Dart-side map helpers).
  static String get googleMapsApiKey => googleMapsAndroidApiKey;

  static String _envKey(String name, {required String fallback}) {
    final dartDefine = String.fromEnvironment(name);
    if (dartDefine.isNotEmpty) return dartDefine;
    final envVal = dotenv.env[name];
    if (envVal != null && envVal.isNotEmpty) return envVal;
    return fallback;
  }

  static const Duration connectTimeout = Duration(seconds: 40);
  static const Duration receiveTimeout = Duration(seconds: 40);

  static const String storageKeyAccessToken = 'access_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyUserEmail = 'user_email';
  static const String storageKeyUserPassword = 'user_password';
  static const String storageKeyOnboardingComplete = 'onboarding_complete';
  static const String storageKeyOnboardingDraft = 'onboarding_draft';
  static const String storageKeyOnboardingRoute = 'onboarding_last_route';
  static const String storageKeyPendingSignup = 'pending_signup';
  static const String storageKeyEmergencyContacts = 'emergency_contacts_local';
  static const String storageKeySafetySettings = 'safety_settings_local';
  static const String storageKeyTermsAccepted = 'terms_accepted';
  static const String storageKeyPrivacyAccepted = 'privacy_accepted';
}
