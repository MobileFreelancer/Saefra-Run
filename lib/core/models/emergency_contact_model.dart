class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? json['phone_number'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
      };
}
