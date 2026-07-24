import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RunStatus { idle, running, paused, stopped }

enum RunMood { great, good, okay, tough, exhausted }

class RunSessionModel {
  final String? runId;
  final String? routeId;
  final String? routeName;
  final double distanceKm;
  final Duration elapsed;
  final String paceLabel;
  final int calories;
  final int steps;
  final int routeRemainingMeters;
  final List<RunSplitModel> splits;
  final List<LatLng> routePath;
  final DateTime? startedAt;

  const RunSessionModel({
    this.runId,
    this.routeId,
    this.routeName,
    this.distanceKm = 0,
    this.elapsed = Duration.zero,
    this.paceLabel = '0:00 min/km',
    this.calories = 0,
    this.steps = 0,
    this.routeRemainingMeters = 0,
    this.splits = const [],
    this.routePath = const [],
    this.startedAt,
  });

  RunSessionModel copyWith({
    String? runId,
    String? routeId,
    String? routeName,
    double? distanceKm,
    Duration? elapsed,
    String? paceLabel,
    int? calories,
    int? steps,
    int? routeRemainingMeters,
    List<RunSplitModel>? splits,
    List<LatLng>? routePath,
    DateTime? startedAt,
  }) {
    return RunSessionModel(
      runId: runId ?? this.runId,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      distanceKm: distanceKm ?? this.distanceKm,
      elapsed: elapsed ?? this.elapsed,
      paceLabel: paceLabel ?? this.paceLabel,
      calories: calories ?? this.calories,
      steps: steps ?? this.steps,
      routeRemainingMeters: routeRemainingMeters ?? this.routeRemainingMeters,
      splits: splits ?? this.splits,
      routePath: routePath ?? this.routePath,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  String get elapsedLabel {
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get durationLabel {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get paceDisplayLabel {
    if (paceLabel.isNotEmpty && paceLabel.contains('/km')) return paceLabel;
    if (distanceKm <= 0) return paceLabel;
    final paceSeconds = elapsed.inSeconds / distanceKm;
    final min = paceSeconds ~/ 60;
    final sec = (paceSeconds % 60).round().toString().padLeft(2, '0');
    return "$min'$sec\" /km";
  }

  factory RunSessionModel.fromJson(Map<String, dynamic> json) {
    final distance = (json['distance_km'] as num?)?.toDouble() ??
        (json['distance'] as num?)?.toDouble() ??
        0;

    int durationSeconds = 0;
    final durationRaw = json['elapsed_seconds'] ?? json['duration'];
    if (durationRaw is int) {
      durationSeconds = durationRaw;
    } else if (durationRaw is String) {
      // Parse "MM:SS" or "HH:MM:SS"
      final parts = durationRaw.split(':').map(int.tryParse).toList();
      if (parts.length == 2) {
        durationSeconds = (parts[0] ?? 0) * 60 + (parts[1] ?? 0);
      } else if (parts.length == 3) {
        durationSeconds = (parts[0] ?? 0) * 3600 + (parts[1] ?? 0) * 60 + (parts[2] ?? 0);
      }
    }

    final pace = json['pace']?.toString() ??
        json['pace_label']?.toString() ??
        json['avg_pace']?.toString() ??
        '';

    return RunSessionModel(
      runId: json['run_id']?.toString() ?? json['id']?.toString(),
      routeId: json['route_id']?.toString(),
      routeName: json['route_name']?.toString(),
      distanceKm: distance,
      elapsed: Duration(seconds: durationSeconds),
      paceLabel: pace.isNotEmpty ? pace : '0:00 min/km',
      calories: json['calories'] as int? ?? 0,
      steps: json['steps'] as int? ?? 0,
      routeRemainingMeters: json['route_remaining_m'] as int? ?? 0,
      splits: (json['splits'] as List<dynamic>?)
              ?.map((e) => RunSplitModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      startedAt: _parseDateTime(json['started_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  Map<String, dynamic> toSubmitJson({RunMood? mood}) => {
        if (runId != null) 'run_id': runId,
        if (routeId != null) 'route_id': routeId,
        'distance_km': distanceKm,
        'elapsed_seconds': elapsed.inSeconds,
        'pace': paceLabel,
        'calories': calories,
        'steps': steps,
        if (mood != null) 'mood': mood.name,
        'splits': splits.map((s) => s.toJson()).toList(),
      };
}

class RunSplitModel {
  final int km;
  final String timeLabel;
  final double paceFactor;

  const RunSplitModel({
    required this.km,
    required this.timeLabel,
    this.paceFactor = 0.5,
  });

  factory RunSplitModel.fromJson(Map<String, dynamic> json) {
    return RunSplitModel(
      km: json['km'] as int? ?? 0,
      timeLabel: json['time'] as String? ?? '',
      paceFactor: (json['pace_factor'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'km': km,
        'time': timeLabel,
        'pace_factor': paceFactor,
      };
}
