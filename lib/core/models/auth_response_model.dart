import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/utils/api_response_parser.dart';



class AuthResponseModel {
  final String accessToken;
  final UserModel user;
  final bool? needsOnboarding;

  const AuthResponseModel({
    required this.accessToken,
    required this.user,
    this.needsOnboarding,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = ApiResponseParser.payload(json);
    final userJson = ApiResponseParser.userFromPayload(data);

    // Read needs_onboarding from data or check the root if not present
    final needsOnboardingVal = data['needs_onboarding'] ?? json['needs_onboarding'];
    bool? needsOnboarding;
    if (needsOnboardingVal is bool) {
      needsOnboarding = needsOnboardingVal;
    } else if (needsOnboardingVal is String) {
      needsOnboarding = needsOnboardingVal.toLowerCase() == 'true';
    } else if (needsOnboardingVal is num) {
      needsOnboarding = needsOnboardingVal == 1;
    }

    return AuthResponseModel(
      accessToken: _readToken(data),
      user: UserModel.fromJson(userJson),
      needsOnboarding: needsOnboarding,
    );
  }

  static String _readToken(Map<String, dynamic> data) {
    final token = data['token'] ?? data['access_token'] ?? data['accessToken'];
    if (token == null) return '';
    return token.toString();
  }
}
