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
    return true;
  }

  static bool get isDevelopment =>
      currentEnvironment == Environment.development;
  static bool get isProduction => currentEnvironment == Environment.production;

  static const Duration connectTimeout = Duration(seconds: 40);
  static const Duration receiveTimeout = Duration(seconds: 40);

  static const String storageKeyAccessToken = 'access_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyOnboardingComplete = 'onboarding_complete';
}
