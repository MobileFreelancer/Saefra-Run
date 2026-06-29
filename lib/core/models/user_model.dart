class UserModel {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? fullName;
  final String? gender;
  final String? visitReason;
  final String? runPreference;
  final DateTime? birthdate;
  final String? profileImage;
  final int? age;

  const UserModel({
    required this.id,
    this.email,
    this.phoneNumber,
    this.fullName,
    this.gender,
    this.visitReason,
    this.runPreference,
    this.birthdate,
    this.profileImage,
    this.age,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedBirthdate;
    final birthRaw = json['birthdate'] as String? ?? json['birth_date'] as String?;
    if (birthRaw != null && birthRaw.isNotEmpty) {
      parsedBirthdate = DateTime.tryParse(birthRaw);
    }

    final preference = json['preference'];
    String? runPreference;
    if (preference is Map<String, dynamic>) {
      runPreference = preference['run_preference'] as String?;
    }

    return UserModel(
      id: '${json['id'] ?? json['user_id'] ?? ''}',
      email: json['email'] as String?,
      phoneNumber: json['phone'] as String? ?? json['phone_number'] as String?,
      fullName: json['full_name'] as String? ?? json['fullName'] as String?,
      gender: json['gender'] as String?,
      visitReason: json['visit_reason'] as String?,
      runPreference: runPreference ?? json['run_preference'] as String?,
      birthdate: parsedBirthdate,
      profileImage: json['profile_image'] as String?,
      age: json['age'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone': phoneNumber,
        if (fullName != null) 'full_name': fullName,
        if (gender != null) 'gender': gender,
        if (visitReason != null) 'visit_reason': visitReason,
        if (runPreference != null) 'run_preference': runPreference,
        if (birthdate != null) 'birthdate': birthdate!.toIso8601String(),
        if (profileImage != null) 'profile_image': profileImage,
        if (age != null) 'age': age,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? fullName,
    String? gender,
    String? visitReason,
    String? runPreference,
    DateTime? birthdate,
    String? profileImage,
    int? age,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      visitReason: visitReason ?? this.visitReason,
      runPreference: runPreference ?? this.runPreference,
      birthdate: birthdate ?? this.birthdate,
      profileImage: profileImage ?? this.profileImage,
      age: age ?? this.age,
    );
  }
}
