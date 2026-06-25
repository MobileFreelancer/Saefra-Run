class OnboardingModel {
  final String? gender;
  final String? activityLevel;
  final String? goal;
  final DateTime? dateOfBirth;
  final int? age;
  final bool locationEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;

  const OnboardingModel({
    this.gender,
    this.activityLevel,
    this.goal,
    this.dateOfBirth,
    this.age,
    this.locationEnabled = false,
    this.pushNotificationsEnabled = false,
    this.emailNotificationsEnabled = false,
  });

  OnboardingModel copyWith({
    String? gender,
    String? activityLevel,
    String? goal,
    DateTime? dateOfBirth,
    int? age,
    bool? locationEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
  }) {
    return OnboardingModel(
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        if (gender != null) 'gender': gender,
        if (activityLevel != null) 'activity_level': activityLevel,
        if (goal != null) 'goal': goal,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String(),
        if (age != null) 'age': age,
        'location_enabled': locationEnabled,
        'push_notifications_enabled': pushNotificationsEnabled,
        'email_notifications_enabled': emailNotificationsEnabled,
      };
}
