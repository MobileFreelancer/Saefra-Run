import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/utils/polyline_decoder.dart';

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
  final String? travelMode;
  final String? difficulty;
  final String? routeType;
  final String? estimatedTimeLabel;
  final double? distanceMeters;
  final int? estimatedCalories;
  final int? estimatedSteps;
  final double? avgSpeedKmh;
  final String? encodedPolyline;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;

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
    this.travelMode,
    this.difficulty,
    this.routeType,
    this.estimatedTimeLabel,
    this.distanceMeters,
    this.estimatedCalories,
    this.estimatedSteps,
    this.avgSpeedKmh,
    this.encodedPolyline,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final estimatedTime = json['estimated_time'] as String? ??
        json['estimated_time_minutes'] as String? ??
        json['formatted_duration'] as String?;

    return RouteModel(
      id: '${json['route_id'] ?? json['id'] ?? ''}',
      name: json['route_name'] as String? ??
          json['name'] as String? ??
          'Route',
      imageAsset: json['route_image'] as String? ?? json['image'] as String?,
      distanceKm: _toDouble(json['distance_km'] ?? json['distance']),
      durationMinutes: _parseDurationMinutes(
        json['estimated_duration'] ?? json['duration'] ?? estimatedTime,
      ),
      runnerCount: _toInt(json['runner_count']),
      isSecure: readBool(json['is_secure']),
      safetyScore: json['safety_score']?.toString(),
      safePoints: _toInt(json['safepoints'] ?? json['safe_points']),
      tag: json['tag'] as String?,
      dateIso: json['date'] as String? ?? json['created_at'] as String?,
      locationLabel: json['location'] as String? ??
          json['ending_point'] as String? ??
          _coordinateLabel(json),
      visibilityLabel: json['visibility'] as String? ??
          _visibilityFromRouteType(json['route_type'] as String?),
      saefraScore: _toDouble(json['safety_score'] ?? json['saefra_score']),
      trafficLevel: json['traffic_level'] as String?,
      lightingLevel: json['lighting'] as String? ?? json['lighting_level'] as String?,
      communityRating: _toDouble(json['community_rating']),
      travelMode: json['travel_mode'] as String?,
      difficulty: json['difficulty'] as String?,
      routeType: json['route_type'] as String?,
      estimatedTimeLabel: estimatedTime,
      distanceMeters: _toDouble(json['distance_meter'] ?? json['distance_meters']),
      estimatedCalories: _toInt(json['estimated_calories']),
      estimatedSteps: _toInt(json['estimated_steps']),
      avgSpeedKmh: _toDouble(json['avg_speed_kmh'] ?? json['average_speed_kmh']),
      encodedPolyline: json['route_encoded_polyline'] as String? ??
          json['encoded_polyline'] as String? ??
          json['route_coordinates'] as String?,
      startLatitude: _toNullableDouble(json['start_latitude']),
      startLongitude: _toNullableDouble(json['start_longitude']),
      endLatitude: _toNullableDouble(json['end_latitude']),
      endLongitude: _toNullableDouble(json['end_longitude']),
    );
  }

  List<LatLng> get polylinePoints => PolylineDecoder.decode(encodedPolyline);

  LatLng? get startPoint {
    if (startLatitude != null && startLongitude != null) {
      return LatLng(startLatitude!, startLongitude!);
    }
    final points = polylinePoints;
    return points.isNotEmpty ? points.first : null;
  }

  LatLng? get endPoint {
    if (endLatitude != null && endLongitude != null) {
      return LatLng(endLatitude!, endLongitude!);
    }
    final points = polylinePoints;
    return points.length > 1 ? points.last : null;
  }

  String get durationLabel {
    if (estimatedTimeLabel != null && estimatedTimeLabel!.isNotEmpty) {
      return estimatedTimeLabel!;
    }
    if (durationMinutes > 0) return '$durationMinutes mins';
    return '—';
  }

  String get routeTypeLabel {
    switch (routeType?.toLowerCase()) {
      case 'loop':
        return 'Loop';
      case 'one_way':
        return 'One way';
      default:
        return routeType ?? 'Route';
    }
  }

  static String? _coordinateLabel(Map<String, dynamic> json) {
    final startLat = _toNullableDouble(json['start_latitude']);
    final startLng = _toNullableDouble(json['start_longitude']);
    if (startLat != null && startLng != null) {
      return '${startLat.toStringAsFixed(4)}, ${startLng.toStringAsFixed(4)}';
    }
    return null;
  }

  static String? _visibilityFromRouteType(String? routeType) {
    if (routeType == null) return null;
    if (routeType.toLowerCase() == 'loop') return 'Loop Route';
    if (routeType.toLowerCase() == 'one_way') return 'One Way Route';
    return routeType;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll('%', '')) ?? 0;
    return 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int _parseDurationMinutes(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) return asInt;

      var total = 0;
      final hours = RegExp(r'(\d+)\s*hr').firstMatch(value);
      if (hours != null) total += int.parse(hours.group(1)!) * 60;
      final minutes = RegExp(r'(\d+)\s*min').firstMatch(value);
      if (minutes != null) total += int.parse(minutes.group(1)!);
      return total;
    }
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
    if (durationMinutes > 0) parts.add(durationLabel);
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
