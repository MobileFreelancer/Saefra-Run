import 'dart:async';

import 'package:flutter/foundation.dart';
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
  RunMood? _mood;

  RunStatus get status => _status;
  RunSessionModel get session => _session;
  bool get sosActive => _sosActive;
  bool get sosDialogVisible => _sosDialogVisible;
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

  List<RunSplitModel> _buildSplits(double totalKm) {
    final count = totalKm.floor().clamp(1, 10);
    return List.generate(count, (i) {
      final km = i + 1;
      return RunSplitModel(
        km: km,
        timeLabel: '${5 + i}:${(20 + i * 3).toString().padLeft(2, '0')}',
        paceFactor: 0.4 + (i % 3) * 0.2,
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

  Future<void> activateSos() async {
    _sosDialogVisible = false;
    _sosActive = true;
    notifyListeners();
    try {
      await _api.sendSos(
        routeId: _session.routeId,
        latitude: 0,
        longitude: 0,
      );
    } catch (_) {}
  }

  void markSafe() {
    _sosActive = false;
    notifyListeners();
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
    _mood = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
