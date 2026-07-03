import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/data/app_mock_data.dart';
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

  ActivityPeriod get period => _period;
  ActivitySummaryModel? get summary => _summary;
  List<RecentActivityModel> get recentRuns => _recentRuns;
  LifetimeStatsModel? get lifetime => _lifetime;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _summary = await _api.getActivitySummary(_period);
      _recentRuns = await _api.getRecentActivities();
      _lifetime = await _api.getLifetimeStats();
    } catch (_) {
      _summary = AppMockData.activitySummary(_period);
      _recentRuns = AppMockData.recentActivities;
      _lifetime = AppMockData.lifetimeStats;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(ActivityPeriod period) async {
    _period = period;
    notifyListeners();
    _isLoading = true;
    notifyListeners();
    try {
      _summary = await _api.getActivitySummary(period);
    } catch (_) {
      _summary = AppMockData.activitySummary(period);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
