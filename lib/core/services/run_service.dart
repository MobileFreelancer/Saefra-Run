import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/models/run_session_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class RunService extends ChangeNotifier {
  RunService();

  final ApiService _api = ApiService();
  Timer? _timer;

  RunStatus _status = RunStatus.idle;
  RunSessionModel _session = const RunSessionModel();
  bool _sosActive = false;
  bool _sosDialogVisible = false;
  bool _sosLoading = false;
  String? _sosError;
  String? _sosMessage;
  List<EmergencyContactModel> _sosNotifiedContacts = [];
  RunMood? _mood;

  RunStatus get status => _status;
  RunSessionModel get session => _session;
  bool get sosActive => _sosActive;
  bool get sosDialogVisible => _sosDialogVisible;
  bool get sosLoading => _sosLoading;
  String? get sosError => _sosError;
  String? get sosMessage => _sosMessage;
  List<EmergencyContactModel> get sosNotifiedContacts => _sosNotifiedContacts;
  RunMood? get mood => _mood;
  bool get isRunning => _status == RunStatus.running;
  bool get isPaused => _status == RunStatus.paused;

  Future<void> startRun({String? routeId, String? routeName}) async {
    _session = RunSessionModel(
      routeId: routeId,
      routeName: routeName ?? 'Your Route',
      routeRemainingMeters: 300,
    );
    _status = RunStatus.running;
    _sosActive = false;
    _sosError = null;
    _sosMessage = null;
    _sosNotifiedContacts = [];
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    if (_status != RunStatus.running) return;
    final elapsed = _session.elapsed + const Duration(seconds: 1);
    final km = _session.distanceKm + 0.0028;
    final remaining = (_session.routeRemainingMeters - 1).clamp(0, 99999);
    final paceMin = elapsed.inSeconds > 0 ? (elapsed.inMinutes / km).clamp(4.0, 12.0) : 5.0;
    final paceLabel = '${paceMin.floor()}:${((paceMin % 1) * 60).round().toString().padLeft(2, '0')} min/km';

    _session = _session.copyWith(
      elapsed: elapsed,
      distanceKm: double.parse(km.toStringAsFixed(2)),
      routeRemainingMeters: remaining,
      paceLabel: paceLabel,
      calories: (km * 72).round(),
    );
    notifyListeners();
  }

  void pause() {
    if (_status != RunStatus.running) return;
    _status = RunStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != RunStatus.paused) return;
    _status = RunStatus.running;
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
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
    _timer?.cancel();
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
    try {
      await _api.submitRunSummary(_session.toSubmitJson(mood: _mood));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> discardActivity() async {
    _timer?.cancel();
    _status = RunStatus.idle;
    _session = const RunSessionModel();
    _mood = null;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _status = RunStatus.idle;
    _session = const RunSessionModel();
    _sosActive = false;
    _sosDialogVisible = false;
    _sosLoading = false;
    _sosError = null;
    _sosMessage = null;
    _sosNotifiedContacts = [];
    _mood = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
