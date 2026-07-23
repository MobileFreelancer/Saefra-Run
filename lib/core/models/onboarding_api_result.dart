import 'package:saefra_run/core/models/onboarding_model.dart';
import 'package:saefra_run/core/utils/api_response_parser.dart';

class OnboardingApiResult {
  final OnboardingModel data;
  final bool isComplete;

  const OnboardingApiResult({
    required this.data,
    required this.isComplete,
  });

  factory OnboardingApiResult.fromResponse(Map<String, dynamic> json) {
    final payload = ApiResponseParser.payload(json);
    final onboardingMap = _extractOnboardingMap(payload);

    final isComplete =
        _readCompleteFlag(payload) || _readCompleteFlag(onboardingMap);
    final data = OnboardingModel.fromServerJson(onboardingMap);

    return OnboardingApiResult(
      data: data,
      isComplete: isComplete || _inferCompleteFromFields(data),
    );
  }

  static Map<String, dynamic> _extractOnboardingMap(
    Map<String, dynamic> payload,
  ) {
    final nested = payload['onboarding'];
    if (nested is Map) {
      return ApiResponseParser.asMap(nested);
    }
    return payload;
  }

  static bool _readCompleteFlag(Map<String, dynamic> map) {
    for (final key in const [
      'is_onboarding_complete',
      'onboarding_complete',
      'is_completed',
      'completed',
      'onboarding_completed',
    ]) {
      final value = map[key];
      if (value == true || value == 1 || value == '1') return true;
      if (value is String && value.toLowerCase() == 'true') return true;
    }
    return false;
  }

  static bool _inferCompleteFromFields(OnboardingModel model) {
    return _hasText(model.gender) &&
        _hasText(model.activityLevel) &&
        _hasText(model.goal);
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
