import 'package:saefra_run/core/models/onboarding_model.dart';

/// Maps UI onboarding labels to backend API enum/string values.
class ApiFieldMapper {
  ApiFieldMapper._();

  static String genderToApi(String? uiGender) {
    if (uiGender == null || uiGender.isEmpty) return 'prefer_not_to_say';
    switch (uiGender) {
      case 'Man':
        return 'male';
      case 'Woman':
        return 'female';
      case 'Prefer not to say':
        return 'prefer_not_to_say';
      default:
        return uiGender.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  static String runPreferenceToApi(String? uiActivity) {
    if (uiActivity == null || uiActivity.isEmpty) return 'easy';
    switch (uiActivity) {
      case 'Easy Pace':
        return 'easy';
      case 'Moderate Challenge':
        return 'moderate';
      case 'Push My Limits':
        return 'hard';
      default:
        return uiActivity.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  static String visitReasonToApi(String? uiGoal) {
    if (uiGoal == null || uiGoal.isEmpty) return 'for_fun';
    switch (uiGoal) {
      case 'Just getting started':
        return 'getting_started';
      case 'Building consistency':
        return 'building_consistency';
      case 'Training for a goal':
        return 'training_for_goal';
      case 'Exploring new routes':
        return 'exploring_routes';
      case 'Just for fun':
        return 'for_fun';
      case 'Other':
        return 'other';
      default:
        return uiGoal.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  static String formatBirthdate(DateTime? date) {
    if (date == null) return '';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$mm-$dd-${date.year}';
  }

  static Map<String, dynamic> registerFormFromOnboarding({
    required String email,
    required String password,
    required OnboardingModel onboarding,
  }) {
    return {
      'email': email,
      'password': password,
      'password_confirmation': password,
      'gender': genderToApi(onboarding.gender),
      'birthdate': formatBirthdate(onboarding.dateOfBirth),
      'visit_reason': visitReasonToApi(onboarding.goal),
      'run_preference': runPreferenceToApi(onboarding.activityLevel),
    };
  }

  static Map<String, dynamic> profileFormFromOnboarding(OnboardingModel onboarding) {
    return {
      'gender': genderToApi(onboarding.gender),
      'birthdate': formatBirthdate(onboarding.dateOfBirth),
    };
  }
}
