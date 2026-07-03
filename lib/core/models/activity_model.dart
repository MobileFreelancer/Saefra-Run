enum ActivityPeriod { weekly, monthly, yearly }

class ActivitySummaryModel {
  final double totalDistanceKm;
  final int totalMinutes;
  final int totalCalories;
  final double avgPaceMinPerKm;

  const ActivitySummaryModel({
    this.totalDistanceKm = 0,
    this.totalMinutes = 0,
    this.totalCalories = 0,
    this.avgPaceMinPerKm = 0,
  });

  factory ActivitySummaryModel.fromJson(Map<String, dynamic> json) {
    return ActivitySummaryModel(
      totalDistanceKm: _toDouble(json['total_distance_km'] ?? json['distance']),
      totalMinutes: _toInt(json['total_minutes'] ?? json['duration']),
      totalCalories: _toInt(json['total_calories'] ?? json['calories']),
      avgPaceMinPerKm: _toDouble(json['avg_pace'] ?? json['avg_pace_min_per_km']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class RecentActivityModel {
  final String id;
  final String name;
  final String dateLabel;
  final double distanceKm;
  final int durationMinutes;
  final String paceLabel;
  final String? mapImageAsset;

  const RecentActivityModel({
    required this.id,
    required this.name,
    required this.dateLabel,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.paceLabel = '',
    this.mapImageAsset,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? json['route_name'] as String? ?? 'Run',
      dateLabel: json['date_label'] as String? ?? json['date'] as String? ?? '',
      distanceKm: ActivitySummaryModel._toDouble(json['distance_km']),
      durationMinutes: ActivitySummaryModel._toInt(json['duration_minutes']),
      paceLabel: json['pace'] as String? ?? '',
      mapImageAsset: json['map_image'] as String?,
    );
  }
}

class LifetimeStatsModel {
  final double totalDistanceKm;
  final int totalHours;
  final int totalCalories;
  final double avgPaceMinPerKm;
  final List<double> paceTrend;

  const LifetimeStatsModel({
    this.totalDistanceKm = 0,
    this.totalHours = 0,
    this.totalCalories = 0,
    this.avgPaceMinPerKm = 0,
    this.paceTrend = const [],
  });

  factory LifetimeStatsModel.fromJson(Map<String, dynamic> json) {
    return LifetimeStatsModel(
      totalDistanceKm: ActivitySummaryModel._toDouble(json['total_distance_km']),
      totalHours: ActivitySummaryModel._toInt(json['total_hours']),
      totalCalories: ActivitySummaryModel._toInt(json['total_calories']),
      avgPaceMinPerKm: ActivitySummaryModel._toDouble(json['avg_pace']),
      paceTrend: (json['pace_trend'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
    );
  }
}
