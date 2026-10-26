import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/reverse_geocoding_service.dart';
import 'package:saefra_run/core/services/run_location_cache.dart';

class ActivityService extends ChangeNotifier {
  ActivityService({
    ApiService? api,
    ReverseGeocodingService? reverseGeocoder,
  })  : _api = api ?? ApiService(),
        _reverseGeocoder = reverseGeocoder ?? ReverseGeocodingService();

  final ApiService _api;
  final ReverseGeocodingService _reverseGeocoder;

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
      debugPrint(
        '[ActivityLocation] Loaded ${_recentRuns.length} activities; '
        'enriching locations that need reverse-geocode',
      );
      _recentRuns = await _enrichLocations(_recentRuns);
    } catch (e) {
      _error = e.toString();
    } finally {
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<RecentActivityModel>> _enrichLocations(
    List<RecentActivityModel> runs,
  ) async {
    if (runs.isEmpty) return runs;

    final enriched = <RecentActivityModel>[];
    for (final run in runs) {
      final cached = await RunLocationCache.read(run.id);
      if (cached != null && cached.isNotEmpty) {
        debugPrint(
          '[ActivityLocation] Using cached finish location for run ${run.id} '
          '→ $cached (api location=${run.location ?? run.fallbackLocation})',
        );
        enriched.add(run.copyWith(location: cached));
        continue;
      }

      if (!run.needsReverseGeocode) {
        enriched.add(run);
        continue;
      }

      final resolved = await _reverseGeocoder.cityStateFromCoordinates(
        latitude: run.latitude!,
        longitude: run.longitude!,
      );
      if (resolved != null && resolved.isNotEmpty) {
        debugPrint('[ActivityLocation] Enriched run ${run.id} → $resolved');
        await RunLocationCache.save(run.id, resolved);
        enriched.add(run.copyWith(location: resolved));
        continue;
      }

      final fallback = run.fallbackLocation;
      if (fallback != null && fallback.isNotEmpty) {
        debugPrint(
          '[ActivityLocation] Reverse-geocode failed for run ${run.id}; '
          'using fallback location=$fallback',
        );
        enriched.add(run.copyWith(location: fallback));
      } else {
        enriched.add(run);
      }
    }
    return enriched;
  }

  Future<void> setPeriod(ActivityPeriod period) async {
    _period = period;
    notifyListeners();
    await load(refresh: true);
  }
}
