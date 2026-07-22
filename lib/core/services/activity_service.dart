import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/mock/feature_mock_data.dart';
import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class ActivityService extends ChangeNotifier {
  ActivityService();

  final ApiService _api = ApiService();

  ActivityPeriod _period = ActivityPeriod.weekly;
  ActivitySummaryModel? _summary;
  List<RecentActivityModel> _recentRuns = [];
  LifetimeStatsModel? _lifetime;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  ActivityPeriod get period => _period;
  ActivitySummaryModel? get summary => _summary;
  List<RecentActivityModel> get recentRuns => _recentRuns;
  LifetimeStatsModel? get lifetime => _lifetime;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && _hasLoaded && _recentRuns.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dashboard = await _api.getActivityDashboard();
      _recentRuns = dashboard.recentRuns;
      _lifetime = dashboard.lifetime;
      _summary = dashboard.summary;
    } catch (e) {
      _error = e.toString();
      if (_recentRuns.isEmpty) _applyMockData();
    } finally {
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyMockData() {
    _recentRuns = FeatureMockData.recentRuns;
    _lifetime = FeatureMockData.lifetime;
    _summary ??= const ActivitySummaryModel(
      totalDistanceKm: 15.06,
      totalMinutes: 120,
      totalCalories: 780,
      avgPaceMinPerKm: 5.57,
    );
  }

  Future<void> setPeriod(ActivityPeriod period) async {
    _period = period;
    notifyListeners();
    await load(refresh: true);
  }
}
