import 'package:saefra_run/core/config/api_config.dart';

class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final String? imageUrl;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.imageUrl,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: '${json['id'] ?? json['contact_id'] ?? ''}',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ??
          json['phone_number'] as String? ??
          '',
      imageUrl: json['image'] as String? ??
          json['image_url'] as String? ??
          json['contact_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        if (imageUrl != null) 'image': imageUrl,
      };

  String? get resolvedImageUrl {
    final raw = imageUrl;
    if (raw == null || raw.trim().isEmpty) return null;
    final url = raw.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  EmergencyContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? imageUrl,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
