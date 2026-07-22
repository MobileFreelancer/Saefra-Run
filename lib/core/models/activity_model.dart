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
      totalDistanceKm: ActivityValueParser.distanceKm(
        json['total_distance'] ??
            json['total_distance_km'] ??
            json['distance'],
      ),
      totalMinutes: ActivityValueParser.durationMinutes(
        json['total_running_time'] ??
            json['total_minutes'] ??
            json['duration'],
      ),
      totalCalories: _toInt(json['total_calories'] ?? json['calories']),
      avgPaceMinPerKm: ActivityValueParser.paceMinPerKm(
        json['average_pace'] ?? json['avg_pace'] ?? json['avg_pace_min_per_km'],
      ),
    );
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 0;
  }
}

class RecentActivityModel {
  final String id;
  final String name;
  final String dateLabel;
  final double distanceKm;
  final int durationMinutes;
  final String? durationLabel;
  final String paceLabel;
  final String? mapImageAsset;
  final String? difficulty;
  final String? location;
  final int? safetyScore;
  final int? calories;

  const RecentActivityModel({
    required this.id,
    required this.name,
    required this.dateLabel,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.durationLabel,
    this.paceLabel = '',
    this.mapImageAsset,
    this.difficulty,
    this.location,
    this.safetyScore,
    this.calories,
  });

  String get formattedDuration =>
      durationLabel ?? (durationMinutes > 0 ? '$durationMinutes min' : '0 min');

  String get formattedDistance =>
      distanceKm > 0 ? '${distanceKm.toStringAsFixed(2)} km' : '0 km';

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    final durationRaw = json['duration_minutes'] ?? json['duration'];
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
      distanceKm: ActivityValueParser.distanceKm(
        json['distance_km'] ?? json['distance'],
      ),
      durationMinutes: ActivityValueParser.durationMinutes(durationRaw),
      durationLabel: durationRaw is String ? durationRaw : null,
      paceLabel: json['pace'] as String? ??
          json['pace_label'] as String? ??
          json['avg_pace'] as String? ??
          '',
      mapImageAsset: ActivityValueParser.nullableString(
        json['map_image'] ?? json['route_image'] ?? json['image'],
      ),
      difficulty: json['difficulty'] as String?,
      location: json['location'] as String?,
      safetyScore: _toInt(json['safety_score']),
      calories: _toInt(json['calories']),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
    return null;
  }
}

class LifetimeStatsModel {
  final double totalDistanceKm;
  final int totalHours;
  final int totalMinutesRemainder;
  final int totalCalories;
  final int totalSteps;
  final int totalRuns;
  final double avgPaceMinPerKm;
  final String? totalTimeDisplay;
  final String? avgPaceDisplay;
  final List<double> paceTrend;

  const LifetimeStatsModel({
    this.totalDistanceKm = 0,
    this.totalHours = 0,
    this.totalMinutesRemainder = 0,
    this.totalCalories = 0,
    this.totalSteps = 0,
    this.totalRuns = 0,
    this.avgPaceMinPerKm = 0,
    this.totalTimeDisplay,
    this.avgPaceDisplay,
    this.paceTrend = const [],
  });

  String get formattedTotalTime {
    if (totalTimeDisplay != null && totalTimeDisplay!.trim().isNotEmpty) {
      return totalTimeDisplay!.trim();
    }
    if (totalHours <= 0 && totalMinutesRemainder <= 0) return '0 min';
    if (totalHours <= 0) return '${totalMinutesRemainder}m';
    if (totalMinutesRemainder <= 0) return '${totalHours}h';
    return '${totalHours}h ${totalMinutesRemainder}m';
  }

  String get formattedPace {
    if (avgPaceDisplay != null && avgPaceDisplay!.trim().isNotEmpty) {
      return avgPaceDisplay!.trim();
    }
    if (avgPaceMinPerKm <= 0) return '--';
    final minutes = avgPaceMinPerKm.floor();
    final seconds = ((avgPaceMinPerKm - minutes) * 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\" /km";
  }

  factory LifetimeStatsModel.fromJson(Map<String, dynamic> json) {
    final runningTime = ActivityValueParser.runningTime(
      json['total_running_time'] ?? json['total_time'],
    );
    final totalMinutes = ActivityValueParser.durationMinutes(
      json['total_minutes'] ?? json['duration_minutes'],
    );
    final parsedHours = _toInt(json['total_hours']);
    final parsedMinutesRemainder = _toInt(
      json['total_minutes_remainder'] ?? json['minutes_remainder'],
    );
    final avgPaceRaw = json['average_pace'] ??
        json['avg_pace'] ??
        json['avg_pace_min_per_km'];

    return LifetimeStatsModel(
      totalDistanceKm: ActivityValueParser.distanceKm(
        json['total_distance'] ??
            json['total_distance_km'] ??
            json['distance_km'] ??
            json['distance'],
      ),
      totalHours: runningTime.$1 > 0
          ? runningTime.$1
          : (parsedHours > 0 ? parsedHours : totalMinutes ~/ 60),
      totalMinutesRemainder: runningTime.$2 > 0
          ? runningTime.$2
          : (parsedMinutesRemainder > 0
              ? parsedMinutesRemainder
              : totalMinutes % 60),
      totalCalories: _toInt(json['total_calories'] ?? json['calories']),
      totalSteps: _toInt(json['total_steps'] ?? json['steps']),
      totalRuns: _toInt(json['total_runs'] ?? json['runs_count']),
      avgPaceMinPerKm: ActivityValueParser.paceMinPerKm(avgPaceRaw),
      totalTimeDisplay: json['total_running_time'] as String? ??
          json['total_time'] as String?,
      avgPaceDisplay: avgPaceRaw is String ? avgPaceRaw : null,
      paceTrend: (json['pace_trend'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
    );
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 0;
  }
}

class ActivityDashboardResult {
  const ActivityDashboardResult({
    required this.recentRuns,
    this.lifetime,
    this.summary,
  });

  final List<RecentActivityModel> recentRuns;
  final LifetimeStatsModel? lifetime;
  final ActivitySummaryModel? summary;

  factory ActivityDashboardResult.fromPayload(Map<String, dynamic> payload) {
    final recentRaw = payload['activities'] ??
        payload['recent_runs'] ??
        payload['recent_activities'] ??
        payload['recentRuns'] ??
        payload['runs'];

    final statisticsRaw = payload['statistics'] ??
        payload['lifetime'] ??
        payload['lifetime_stats'] ??
        payload['lifetimeStats'] ??
        payload['lifetime_performance'];

    final summaryRaw = payload['summary'] ??
        payload['weekly_summary'] ??
        payload['stats'] ??
        statisticsRaw;

    LifetimeStatsModel? lifetime;
    ActivitySummaryModel? summary;

    if (statisticsRaw is Map) {
      final statsMap = Map<String, dynamic>.from(statisticsRaw);
      lifetime = LifetimeStatsModel.fromJson(statsMap);
      summary = ActivitySummaryModel.fromJson(statsMap);
    }

    if (summaryRaw is Map && summary == null) {
      summary = ActivitySummaryModel.fromJson(
        Map<String, dynamic>.from(summaryRaw),
      );
    }

    if (lifetime == null && summaryRaw is Map) {
      lifetime = LifetimeStatsModel.fromJson(
        Map<String, dynamic>.from(summaryRaw),
      );
    }

    return ActivityDashboardResult(
      recentRuns: _parseRecentList(recentRaw),
      lifetime: lifetime,
      summary: summary,
    );
  }

  static List<RecentActivityModel> _parseRecentList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (item) => RecentActivityModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}

class ActivityValueParser {
  ActivityValueParser._();

  static double distanceKm(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  static int durationMinutes(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) {
      final value = v.trim().toLowerCase();
      final hours = RegExp(r'(\d+)\s*h').firstMatch(value)?.group(1);
      final minutes = RegExp(r'(\d+)\s*m').firstMatch(value)?.group(1);
      final hourValue = int.tryParse(hours ?? '0') ?? 0;
      final minuteValue = int.tryParse(minutes ?? '0') ?? 0;
      if (hourValue > 0 || minuteValue > 0 || value.contains('h') || value.contains('m')) {
        return hourValue * 60 + minuteValue;
      }
      return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return 0;
  }

  static (int hours, int minutes) runningTime(dynamic v) {
    if (v is! String) {
      final totalMinutes = durationMinutes(v);
      return (totalMinutes ~/ 60, totalMinutes % 60);
    }

    final value = v.trim().toLowerCase();
    final hours = int.tryParse(
          RegExp(r'(\d+)\s*h').firstMatch(value)?.group(1) ?? '0',
        ) ??
        0;
    final minutes = int.tryParse(
          RegExp(r'(\d+)\s*m').firstMatch(value)?.group(1) ?? '0',
        ) ??
        0;
    return (hours, minutes);
  }

  static double paceMinPerKm(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is! String) return 0;

    final value = v.trim();
    final pacePart = value.split('/').first.trim();
    final segments = pacePart.split(':');
    if (segments.length == 2) {
      final minutes = int.tryParse(segments[0]) ?? 0;
      final seconds = int.tryParse(segments[1]) ?? 0;
      return minutes + (seconds / 60);
    }

    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  static String? nullableString(dynamic v) {
    if (v == null) return null;
    final value = '$v'.trim();
    return value.isEmpty ? null : value;
  }
}
