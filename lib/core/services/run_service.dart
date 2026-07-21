import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/models/run_session_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class RunService extends ChangeNotifier {
  RunService();

  final ApiService _api = ApiService();
  DateTime? _lastLiveUpdateAt;

  RunStatus _status = RunStatus.idle;
  RunSessionModel _session = const RunSessionModel();
  bool _sosActive = false;
  bool _sosDialogVisible = false;
  bool _sosLoading = false;
  String? _sosError;
  String? _sosMessage;
  List<EmergencyContactModel> _sosNotifiedContacts = [];
  RunMood? _mood;
  String? _apiError;

  RunStatus get status => _status;
  RunSessionModel get session => _session;
  bool get sosActive => _sosActive;
  bool get sosDialogVisible => _sosDialogVisible;
  bool get sosLoading => _sosLoading;
  String? get sosError => _sosError;
  String? get sosMessage => _sosMessage;
  List<EmergencyContactModel> get sosNotifiedContacts => _sosNotifiedContacts;
  RunMood? get mood => _mood;
  String? get apiError => _apiError;
  bool get isRunning => _status == RunStatus.running;
  bool get isPaused => _status == RunStatus.paused;
  bool get hasRunId => _session.runId != null && _session.runId!.isNotEmpty;

  Future<bool> startRun({
    String? routeId,
    String? routeName,
    required double latitude,
    required double longitude,
  }) async {
    _apiError = null;
    _session = RunSessionModel(
      routeId: routeId,
      routeName: routeName ?? 'Your Route',
      routeRemainingMeters: 300,
      startedAt: DateTime.now(),
    );
    _status = RunStatus.running;
    _sosActive = false;
    _sosError = null;
    _sosMessage = null;
    _sosNotifiedContacts = [];
    _lastLiveUpdateAt = null;
    notifyListeners();

    if (routeId == null || routeId.trim().isEmpty) {
      debugPrint('RunService.startRun: no route_id — skipping run-start API');
      return true;
    }

    try {
      final runId = await _api.startRunSession(
        routeId: routeId,
        latitude: latitude,
        longitude: longitude,
        startedAt: _session.startedAt,
      );
      _session = _session.copyWith(runId: runId);
      notifyListeners();
      return true;
    } catch (e) {
      _apiError = e.toString();
      debugPrint('RunService.startRun failed: $e');
      return false;
    }
  }

  Future<void> syncLiveUpdate({
    required double latitude,
    required double longitude,
    required double distanceKm,
    required int durationSeconds,
    required double speedKmh,
    required String pace,
    required int steps,
  }) async {
    final runId = _session.runId;
    if (runId == null || _status != RunStatus.running) return;

    final now = DateTime.now();
    if (_lastLiveUpdateAt != null &&
        now.difference(_lastLiveUpdateAt!) < const Duration(seconds: 10)) {
      return;
    }
    _lastLiveUpdateAt = now;

    try {
      await _api.updateRunSession(
        runId: runId,
        latitude: latitude,
        longitude: longitude,
        distance: double.parse(distanceKm.toStringAsFixed(3)),
        duration: durationSeconds,
        speed: double.parse(speedKmh.toStringAsFixed(2)),
        pace: pace,
        steps: steps,
      );
    } catch (e) {
      debugPrint('RunService.syncLiveUpdate failed: $e');
    }
  }

  Future<bool> pause() async {
    if (_status != RunStatus.running) return false;
    _status = RunStatus.paused;
    notifyListeners();

    final runId = _session.runId;
    if (runId == null) return true;

    try {
      await _api.pauseRunSession(runId: runId);
      return true;
    } catch (e) {
      _apiError = e.toString();
      debugPrint('RunService.pause failed: $e');
      return false;
    }
  }

  Future<bool> resume() async {
    if (_status != RunStatus.paused) return false;
    _status = RunStatus.running;
    notifyListeners();

    final runId = _session.runId;
    if (runId == null) return true;

    try {
      await _api.resumeRunSession(runId: runId);
      return true;
    } catch (e) {
      _apiError = e.toString();
      debugPrint('RunService.resume failed: $e');
      return false;
    }
  }

  void stop() {
    _status = RunStatus.stopped;
    _session = _session.copyWith(
      splits: _buildSplits(_session.distanceKm),
    );
    notifyListeners();
  }

  void completeFromTracking({
    required double distanceKm,
    required int steps,
    required int secondsElapsed,
    required List<LatLng> routePath,
  }) {
    _status = RunStatus.stopped;

    final elapsed = Duration(seconds: secondsElapsed);
    final paceLabel = _formatPaceLabel(elapsed, distanceKm);

    _session = _session.copyWith(
      distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      elapsed: elapsed,
      steps: steps,
      paceLabel: paceLabel,
      calories: (distanceKm * 72).round(),
      routePath: List<LatLng>.from(routePath),
      splits: _buildSplits(distanceKm),
    );
    notifyListeners();
  }

  Future<bool> finishRunOnServer({
    required double latitude,
    required double longitude,
    required List<LatLng> routePath,
  }) async {
    final runId = _session.runId;
    if (runId == null) return true;

    try {
      await _api.finishRunSession(
        runId: runId,
        latitude: latitude,
        longitude: longitude,
        polyline: _encodePolyline(routePath),
        endedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      _apiError = e.toString();
      debugPrint('RunService.finishRunOnServer failed: $e');
      return false;
    }
  }

  Future<bool> loadRunSummary() async {
    final runId = _session.runId;
    if (runId == null) return false;

    try {
      final payload = await _api.getRunSummary(runId);
      final summary = payload['summary'] is Map
          ? Map<String, dynamic>.from(payload['summary'] as Map)
          : payload;

      _session = RunSessionModel.fromJson(summary).copyWith(
        runId: runId,
        routeId: _session.routeId ?? summary['route_id']?.toString(),
        routeName: _session.routeName ?? summary['route_name']?.toString(),
        routePath: _session.routePath.isNotEmpty
            ? _session.routePath
            : _decodePolyline(summary['polyline']),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _apiError = e.toString();
      debugPrint('RunService.loadRunSummary failed: $e');
      return false;
    }
  }

  String _encodePolyline(List<LatLng> path) {
    if (path.isEmpty) return '[]';
    return jsonEncode(
      path
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(growable: false),
    );
  }

  List<LatLng> _decodePolyline(dynamic raw) {
    if (raw == null) return const [];
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) return const [];
        return decoded
            .map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              return LatLng(
                (map['lat'] as num).toDouble(),
                (map['lng'] as num).toDouble(),
              );
            })
            .toList(growable: false);
      }
      if (raw is List) {
        return raw
            .map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              return LatLng(
                (map['lat'] as num).toDouble(),
                (map['lng'] as num).toDouble(),
              );
            })
            .toList(growable: false);
      }
    } catch (e) {
      debugPrint('RunService._decodePolyline failed: $e');
    }
    return const [];
  }

  String _formatPaceLabel(Duration elapsed, double distanceKm) {
    if (distanceKm <= 0) return "0'00\" /km";
    final paceSeconds = elapsed.inSeconds / distanceKm;
    final min = paceSeconds ~/ 60;
    final sec = (paceSeconds % 60).round().toString().padLeft(2, '0');
    return "$min'$sec\" /km";
  }

  List<RunSplitModel> _buildSplits(double totalKm) {
    final count = totalKm.floor().clamp(1, 10);
    return List.generate(count, (i) {
      final km = i + 1;
      final minutes = 5 + i;
      final seconds = 20 + i * 3;
      return RunSplitModel(
        km: km,
        timeLabel: "$minutes'${seconds.toString().padLeft(2, '0')}\"",
        paceFactor: 0.35 + (i % 4) * 0.15,
      );
    });
  }

  void setMood(RunMood mood) {
    _mood = mood;
    notifyListeners();
  }

  void showSosDialog() {
    _sosDialogVisible = true;
    notifyListeners();
  }

  void hideSosDialog() {
    _sosDialogVisible = false;
    notifyListeners();
  }

  Future<bool> activateSos({
    double? latitude,
    double? longitude,
    String? addressLink,
  }) async {
    _sosDialogVisible = false;
    _sosLoading = true;
    _sosError = null;
    notifyListeners();

    try {
      final response = await _api.activateSos(
        latitude: latitude,
        longitude: longitude,
        addressLink: addressLink,
      );
      _sosActive = true;
      _sosMessage = response.message;
      _sosNotifiedContacts = response.contacts;
      _sosError = null;
      return true;
    } catch (e) {
      _sosActive = false;
      _sosError = e.toString();
      debugPrint('RunService.activateSos failed: $e');
      return false;
    } finally {
      _sosLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markSafe() async {
    if (!_sosActive) return true;

    _sosLoading = true;
    notifyListeners();

    try {
      final response = await _api.cancelSos();
      _sosActive = false;
      _sosMessage = response.message;
      _sosNotifiedContacts = [];
      _sosError = null;
      return true;
    } catch (e) {
      _sosError = e.toString();
      debugPrint('RunService.markSafe failed: $e');
      return false;
    } finally {
      _sosLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveActivity() async {
    final runId = _session.runId;
    final mood = _mood;
    if (runId == null || runId.isEmpty) return true;
    if (mood == null) {
      _apiError = 'Please select how your run felt.';
      notifyListeners();
      return false;
    }

    try {
      await _api.submitRunFeeling(
        runId: runId,
        runFeeling: mood.name,
      );
      _apiError = null;
      return true;
    } catch (e) {
      _apiError = e.toString();
      debugPrint('RunService.saveActivity failed: $e');
      return false;
    }
  }

  Future<void> discardActivity() async {
    _status = RunStatus.idle;
    _session = const RunSessionModel();
    _mood = null;
    _apiError = null;
    _lastLiveUpdateAt = null;
    notifyListeners();
  }

  void reset() {
    _status = RunStatus.idle;
    _session = const RunSessionModel();
    _sosActive = false;
    _sosDialogVisible = false;
    _sosLoading = false;
    _sosError = null;
    _sosMessage = null;
    _sosNotifiedContacts = [];
    _mood = null;
    _apiError = null;
    _lastLiveUpdateAt = null;
    notifyListeners();
  }
}
