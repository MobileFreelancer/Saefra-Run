class UserModel {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? fullName;
  final String? activityLevel;
  final String? goal;
  final int? age;

  const UserModel({
    required this.id,
    this.email,
    this.phoneNumber,
    this.fullName,
    this.activityLevel,
    this.goal,
    this.age,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? json['user_id'] as String? ?? '',
        email: json['email'] as String?,
        phoneNumber: json['phone_number'] as String? ??
            json['phoneNumber'] as String?,
        fullName: json['full_name'] as String? ?? json['fullName'] as String?,
        activityLevel: json['activity_level'] as String? ??
            json['activityLevel'] as String?,
        goal: json['goal'] as String?,
        age: json['age'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (fullName != null) 'full_name': fullName,
        if (activityLevel != null) 'activity_level': activityLevel,
        if (goal != null) 'goal': goal,
        if (age != null) 'age': age,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? fullName,
    String? activityLevel,
    String? goal,
    int? age,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      age: age ?? this.age,
    );
  }
}
