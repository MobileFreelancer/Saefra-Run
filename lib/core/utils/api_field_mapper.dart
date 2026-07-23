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

  static String trainingGoalToApi(String? uiTarget) {
    if (uiTarget == null || uiTarget.isEmpty) return '';
    switch (uiTarget) {
      case '5k':
        return '5k';
      case 'Half Marathon':
        return 'half_marathon';
      case 'Full Marathon':
        return 'full_marathon';
      default:
        return uiTarget.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  static String? genderFromApi(String? apiValue) {
    if (apiValue == null || apiValue.trim().isEmpty) return null;
    switch (apiValue.trim().toLowerCase()) {
      case 'male':
      case 'man':
        return 'Man';
      case 'female':
      case 'woman':
        return 'Woman';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return apiValue.trim();
    }
  }

  static String? runPreferenceFromApi(String? apiValue) {
    if (apiValue == null || apiValue.trim().isEmpty) return null;
    switch (apiValue.trim().toLowerCase()) {
      case 'easy':
        return 'Easy Pace';
      case 'moderate':
        return 'Moderate Challenge';
      case 'hard':
        return 'Push My Limits';
      default:
        return apiValue.trim();
    }
  }

  static String? visitReasonFromApi(String? apiValue) {
    if (apiValue == null || apiValue.trim().isEmpty) return null;
    switch (apiValue.trim().toLowerCase()) {
      case 'getting_started':
        return 'Just getting started';
      case 'building_consistency':
        return 'Building consistency';
      case 'training_for_goal':
        return 'Training for a goal';
      case 'exploring_routes':
        return 'Exploring new routes';
      case 'for_fun':
        return 'Just for fun';
      case 'other':
        return 'Other';
      default:
        return apiValue.trim();
    }
  }

  static String? trainingGoalFromApi(String? apiValue) {
    if (apiValue == null || apiValue.trim().isEmpty) return null;
    switch (apiValue.trim().toLowerCase()) {
      case '5k':
        return '5k';
      case 'half_marathon':
        return 'Half Marathon';
      case 'full_marathon':
        return 'Full Marathon';
      default:
        return apiValue.trim();
    }
  }

  static DateTime? parseBirthdate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;

    if (value.contains('.')) {
      final parts = value.split('.');
      if (parts.length == 3) {
        return DateTime.tryParse(
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
        );
      }
    }

    if (value.contains('-')) {
      final parts = value.split('-');
      if (parts.length == 3 && parts.first.length == 4) {
        return DateTime.tryParse(value);
      }
    }

    return null;
  }

  static Map<String, dynamic> onboardingFormFromModel(OnboardingModel onboarding) {
    final payload = <String, dynamic>{};

    if (onboarding.firstName != null && onboarding.firstName!.trim().isNotEmpty) {
      payload['first_name'] = onboarding.firstName!.trim();
    }
    if (onboarding.lastName != null && onboarding.lastName!.trim().isNotEmpty) {
      payload['last_name'] = onboarding.lastName!.trim();
    }

    if (onboarding.gender != null && onboarding.gender!.trim().isNotEmpty) {
      payload['gender'] = genderToApi(onboarding.gender);
    }

    final birthdate = formatBirthdate(onboarding.dateOfBirth);
    if (birthdate.isNotEmpty) {
      payload['birthdate'] = birthdate;
    }

    if (onboarding.goal != null && onboarding.goal!.trim().isNotEmpty) {
      payload['visit_reason'] = visitReasonToApi(onboarding.goal);
    }

    if (onboarding.goalTrainingTarget != null &&
        onboarding.goalTrainingTarget!.trim().isNotEmpty) {
      payload['training_goal'] =
          trainingGoalToApi(onboarding.goalTrainingTarget);
    }

    if (onboarding.activityLevel != null &&
        onboarding.activityLevel!.trim().isNotEmpty) {
      payload['run_preference'] = runPreferenceToApi(onboarding.activityLevel);
    }

    return payload;
  }

  static String formatBirthdate(DateTime? date) {
    if (date == null) return '';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return "${date.year}-$mm-$dd";
   // return '$mm-$dd-${date.year}';
  }

  static String formString(Map<String, dynamic> fields, String key,
      {String fallback = ''}) {
    final value = fields[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
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
      if (onboarding.firstName != null && onboarding.firstName!.isNotEmpty)
        'first_name': onboarding.firstName,
      if (onboarding.lastName != null && onboarding.lastName!.isNotEmpty)
        'last_name': onboarding.lastName,
      'visit_reason': visitReasonToApi(onboarding.goal),
      'run_preference': runPreferenceToApi(onboarding.activityLevel),
      if (onboarding.goalTrainingTarget != null &&
          onboarding.goalTrainingTarget!.isNotEmpty)
        'training_goal': trainingGoalToApi(onboarding.goalTrainingTarget),
    };
  }

  static Map<String, dynamic> profileFormFromOnboarding(OnboardingModel onboarding) {
    return {
      'gender': genderToApi(onboarding.gender),
      'birthdate': formatBirthdate(onboarding.dateOfBirth),
      if (onboarding.firstName != null && onboarding.firstName!.isNotEmpty)
        'first_name': onboarding.firstName,
      if (onboarding.lastName != null && onboarding.lastName!.isNotEmpty)
        'last_name': onboarding.lastName,
    };
  }

  static String routeFeelToApi(String value) {
    switch (value) {
      case 'openWellTraveled':
        return 'open_and_well_traveled';
      case 'balanced':
        return 'balanced';
      case 'quietSecluded':
        return 'quiet_and_secluded';
      default:
        return value.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  static String routeSurfaceToApi(String value) {
    switch (value) {
      case 'mostlyPaved':
        return 'mostly_paved';
      case 'mixedSurfaces':
        return 'mixed_surfaces';
      case 'mostlyUnpaved':
        return 'mostly_unpaved';
      default:
        return value.trim().toLowerCase().replaceAll(' ', '_');
    }
  }

  static String routeSidewalkToApi(String value) {
    switch (value) {
      case 'someSections':
        return 'some_sections';
      case 'yes':
        return 'yes';
      case 'no':
        return 'no';
      default:
        return value.trim().toLowerCase().replaceAll(' ', '_');
    }
  }
}
