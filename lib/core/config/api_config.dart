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

  /// Toggle mock API responses. Set USE_MOCK_API=false in .env when backend is ready.
  static bool get useMockApi {
    const dartDefine = String.fromEnvironment('USE_MOCK_API');
    if (dartDefine.isNotEmpty) return dartDefine.toLowerCase() == 'true';
    final envVal = dotenv.env['USE_MOCK_API'];
    if (envVal != null && envVal.isNotEmpty) {
      return envVal.toLowerCase() == 'true';
    }
    return false;
  }

  /// ngrok free tier requires this header to avoid HTML warning pages.
  static const String ngrokSkipBrowserWarning = 'Ngrok-Skip-Browser-Warning';

  static bool get isDevelopment => currentEnvironment == Environment.development;
  static bool get isProduction => currentEnvironment == Environment.production;

  /// Search place key — Places API + Places API (New).
  static String get googlePlacesApiKey => _envKey(
        'GOOGLE_PLACES_API_KEY',
        fallback: 'AIzaSyAwoHdma8dZmKOK3kr3EoaEo3DQE1Mob7g',
      );

  /// Routes API key — route generation (computeRoutes).
  static String get googleRoutesApiKey => _envKey(
        'GOOGLE_ROUTES_API_KEY',
        fallback: 'AIzaSyCRXmM_Ug8WIFuDCFXDAYelmdTGtlgX_8k',
      );

  /// Directions API key — polylines / turn-by-turn paths.
  static String get googleDirectionsApiKey => _envKey(
        'GOOGLE_DIRECTIONS_API_KEY',
        fallback: 'AIzaSyAgFJHr846mDvzFhjro6u1_Nx_lU5DvPdg',
      );

  /// Android key (Firebase) — Maps SDK on Android.
  static String get googleMapsAndroidApiKey => _envKey(
        'GOOGLE_MAPS_ANDROID_API_KEY',
        fallback: 'AIzaSyDeFsri4CcOWEozdu9HcPhebQuVqjHDSSQ',

      );

  /// iOS key (Firebase) — Maps SDK on iOS.
  static String get googleMapsIosApiKey => _envKey(
        'GOOGLE_MAPS_IOS_API_KEY',
        fallback: 'AIzaSyB9RL4Fqf5X6eE6mjGfznc8xcNXKjTdA4M',
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
  static const String storageKeyEmergencyContacts = 'emergency_contacts_local';
  static const String storageKeySafetySettings = 'safety_settings_local';
}
