class OnboardingModel {
  final String? gender;
  final String? activityLevel;
  final String? goal;

  /// Sub-choice shown only when [goal] == 'Training for a goal'.
  /// One of: '5k', 'Half Marathon', 'Full Marathon'.
  final String? goalTrainingTarget;

  final DateTime? dateOfBirth;
  final int? age;
  final String? firstName;
  final String? lastName;
  final bool locationEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;

  const OnboardingModel({
    this.gender,
    this.activityLevel,
    this.goal,
    this.goalTrainingTarget,
    this.dateOfBirth,
    this.age,
    this.firstName,
    this.lastName,
    this.locationEnabled = false,
    this.pushNotificationsEnabled = false,
    this.emailNotificationsEnabled = false,
  });

  /// Standard copyWith. Note: passing null for a field leaves it
  /// unchanged (Dart `??` semantics). To explicitly clear
  /// [goalTrainingTarget], use [clearGoalTrainingTarget] instead.
  OnboardingModel copyWith({
    String? gender,
    String? activityLevel,
    String? goal,
    String? goalTrainingTarget,
    DateTime? dateOfBirth,
    int? age,
    String? firstName,
    String? lastName,
    bool? locationEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool clearGoalTrainingTarget = false,
  }) {
    return OnboardingModel(
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      goalTrainingTarget: clearGoalTrainingTarget
          ? null
          : (goalTrainingTarget ?? this.goalTrainingTarget),
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
    );
  }

  factory OnboardingModel.fromJson(Map<String, dynamic> json) {
    DateTime? dateOfBirth;
    final dobRaw = json['date_of_birth'] as String?;
    if (dobRaw != null && dobRaw.isNotEmpty) {
      dateOfBirth = DateTime.tryParse(dobRaw);
    }

    return OnboardingModel(
      gender: json['gender'] as String?,
      activityLevel: json['activity_level'] as String?,
      goal: json['goal'] as String?,
      goalTrainingTarget: json['goal_training_target'] as String?,
      dateOfBirth: dateOfBirth,
      age: json['age'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      locationEnabled: json['location_enabled'] as bool? ?? false,
      pushNotificationsEnabled:
          json['push_notifications_enabled'] as bool? ?? false,
      emailNotificationsEnabled:
          json['email_notifications_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (gender != null) 'gender': gender,
        if (activityLevel != null) 'activity_level': activityLevel,
        if (goal != null) 'goal': goal,
        if (goalTrainingTarget != null)
          'goal_training_target': goalTrainingTarget,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String(),
        if (age != null) 'age': age,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        'location_enabled': locationEnabled,
        'push_notifications_enabled': pushNotificationsEnabled,
        'email_notifications_enabled': emailNotificationsEnabled,
      };
}
