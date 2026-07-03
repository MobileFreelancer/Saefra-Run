class RouteModel {
  final String id;
  final String name;
  final String? imageAsset;
  final double distanceKm;
  final int durationMinutes;
  final int runnerCount;
  final bool isSecure;
  final String? safetyScore;
  final int? safePoints;
  final String? tag;
  final String? dateIso;
  final String? locationLabel;
  final String? visibilityLabel;
  final double? saefraScore;
  final String? trafficLevel;
  final String? lightingLevel;
  final double? communityRating;

  const RouteModel({
    required this.id,
    required this.name,
    this.imageAsset,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.runnerCount = 0,
    this.isSecure = true,
    this.safetyScore,
    this.safePoints,
    this.tag,
    this.dateIso,
    this.locationLabel,
    this.visibilityLabel,
    this.saefraScore,
    this.trafficLevel,
    this.lightingLevel,
    this.communityRating,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: '${json['route_id'] ?? json['id'] ?? ''}',
      name: json['route_name'] as String? ??
          json['name'] as String? ??
          'Route',
      imageAsset: json['route_image'] as String? ?? json['image'] as String?,
      distanceKm: _toDouble(json['distance'] ?? json['distance_km']),
      durationMinutes: _toInt(json['duration'] ?? json['estimated_duration']),
      runnerCount: _toInt(json['runner_count']),
      isSecure: readBool(json['is_secure']),
      safetyScore: json['safety_score'] as String?,
      safePoints: _toInt(json['safepoints'] ?? json['safe_points']),
      tag: json['tag'] as String?,
      dateIso: json['date'] as String?,
      locationLabel: json['location'] as String? ?? json['ending_point'] as String?,
      visibilityLabel: json['visibility'] as String?,
      saefraScore: _toDouble(json['saefra_score'] ?? json['safety_score_value']),
      trafficLevel: json['traffic_level'] as String?,
      lightingLevel: json['lighting_level'] as String?,
      communityRating: _toDouble(json['community_rating']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll('%', '')) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Laravel often returns 0/1 for booleans.
  static bool readBool(dynamic value, {bool defaultValue = true}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return defaultValue;
  }

  String get distanceLabel {
    if (distanceKm >= 1) return '${distanceKm.toStringAsFixed(1)} km';
    return '${(distanceKm * 1000).round()} m';
  }

  String get subtitleLabel {
    final parts = <String>[];
    if (dateIso != null) parts.add(_formatDate(dateIso!));
    if (distanceKm > 0) parts.add(distanceLabel);
    if (durationMinutes > 0) parts.add('$durationMinutes mins');
    return parts.join(' • ');
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return 'Recent';
    }
  }
}
