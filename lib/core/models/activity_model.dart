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
  final String? difficulty;
  final String? location;
  final int? safetyScore;

  const RecentActivityModel({
    required this.id,
    required this.name,
    required this.dateLabel,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.paceLabel = '',
    this.mapImageAsset,
    this.difficulty,
    this.location,
    this.safetyScore,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: '${json['id'] ?? json['run_id'] ?? ''}',
      name: json['name'] as String? ??
          json['route_name'] as String? ??
          json['title'] as String? ??
          'Run',
      dateLabel: json['date_label'] as String? ??
          json['date'] as String? ??
          json['started_at'] as String? ??
          json['created_at'] as String? ??
          '',
      distanceKm: ActivitySummaryModel._toDouble(
        json['distance_km'] ?? json['distance'],
      ),
      durationMinutes: ActivitySummaryModel._toInt(
        json['duration_minutes'] ?? json['duration'] ?? json['elapsed_minutes'],
      ),
      paceLabel: json['pace'] as String? ??
          json['pace_label'] as String? ??
          json['avg_pace'] as String? ??
          '',
      mapImageAsset: json['map_image'] as String? ??
          json['route_image'] as String? ??
          json['image'] as String?,
      difficulty: json['difficulty'] as String?,
      location: json['location'] as String?,
      safetyScore: ActivitySummaryModel._toInt(json['safety_score']),
    );
  }
}

class LifetimeStatsModel {
  final double totalDistanceKm;
  final int totalHours;
  final int totalMinutesRemainder;
  final int totalCalories;
  final int totalSteps;
  final double avgPaceMinPerKm;
  final List<double> paceTrend;

  const LifetimeStatsModel({
    this.totalDistanceKm = 0,
    this.totalHours = 0,
    this.totalMinutesRemainder = 0,
    this.totalCalories = 0,
    this.totalSteps = 0,
    this.avgPaceMinPerKm = 0,
    this.paceTrend = const [],
  });

  String get formattedTotalTime {
    if (totalHours <= 0 && totalMinutesRemainder <= 0) return '0 min';
    if (totalHours <= 0) return '${totalMinutesRemainder}m';
    if (totalMinutesRemainder <= 0) return '${totalHours}h';
    return '${totalHours}h ${totalMinutesRemainder}m';
  }

  String get formattedPace {
    if (avgPaceMinPerKm <= 0) return '--';
    final minutes = avgPaceMinPerKm.floor();
    final seconds = ((avgPaceMinPerKm - minutes) * 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\" /km";
  }

  factory LifetimeStatsModel.fromJson(Map<String, dynamic> json) {
    final totalMinutes = ActivitySummaryModel._toInt(
      json['total_minutes'] ?? json['duration_minutes'],
    );
    final parsedHours = ActivitySummaryModel._toInt(json['total_hours']);
    final parsedMinutesRemainder = ActivitySummaryModel._toInt(
      json['total_minutes_remainder'] ?? json['minutes_remainder'],
    );

    return LifetimeStatsModel(
      totalDistanceKm: ActivitySummaryModel._toDouble(
        json['total_distance_km'] ?? json['distance_km'] ?? json['distance'],
      ),
      totalHours: parsedHours > 0 ? parsedHours : totalMinutes ~/ 60,
      totalMinutesRemainder: parsedMinutesRemainder > 0
          ? parsedMinutesRemainder
          : totalMinutes % 60,
      totalCalories: ActivitySummaryModel._toInt(
        json['total_calories'] ?? json['calories'],
      ),
      totalSteps: ActivitySummaryModel._toInt(
        json['total_steps'] ?? json['steps'],
      ),
      avgPaceMinPerKm: ActivitySummaryModel._toDouble(
        json['avg_pace'] ??
            json['avg_pace_min_per_km'] ??
            json['average_pace'],
      ),
      paceTrend: (json['pace_trend'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
    );
  }
}
