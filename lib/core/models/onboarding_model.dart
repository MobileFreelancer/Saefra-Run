class OnboardingModel {
  final String? activityLevel;
  final String? goal;
  final int? age;
  final bool locationEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;

  const OnboardingModel({
    this.activityLevel,
    this.goal,
    this.age,
    this.locationEnabled = false,
    this.pushNotificationsEnabled = false,
    this.emailNotificationsEnabled = false,
  });

  OnboardingModel copyWith({
    String? activityLevel,
    String? goal,
    int? age,
    bool? locationEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
  }) {
    return OnboardingModel(
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      age: age ?? this.age,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        if (activityLevel != null) 'activity_level': activityLevel,
        if (goal != null) 'goal': goal,
        if (age != null) 'age': age,
        'location_enabled': locationEnabled,
        'push_notifications_enabled': pushNotificationsEnabled,
        'email_notifications_enabled': emailNotificationsEnabled,
      };
}
