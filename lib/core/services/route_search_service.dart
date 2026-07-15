import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/data/app_mock_data.dart';
import 'package:saefra_run/core/models/place_prediction_model.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/places_search_service.dart';

enum RouteSearchStatus { idle, loadingRecent, loading, notFound, results }

class RouteSearchService extends ChangeNotifier {
  RouteSearchService();

  final ApiService _api = ApiService();
  final PlacesSearchService _places = PlacesSearchService();

  String _query = '';
  RouteSearchStatus _status = RouteSearchStatus.idle;
  List<RouteModel> _results = [];
  List<RouteModel> _recentRoutes = [];
  List<PlacePrediction> _placeResults = [];
  String? _error;

  String get query => _query;
  RouteSearchStatus get status => _status;
  List<RouteModel> get results => _results;
  List<RouteModel> get recentRoutes => _recentRoutes;
  List<PlacePrediction> get placeResults => _placeResults;
  bool get isLoadingRecent => _status == RouteSearchStatus.loadingRecent;
  bool get isLoading => _status == RouteSearchStatus.loading;
  bool get showRecentRoutes =>
      _query.trim().isEmpty &&
      (_status == RouteSearchStatus.idle ||
          _status == RouteSearchStatus.loadingRecent);
  String? get error => _error;

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> loadRecentRoutes({
    double? latitude,
    double? longitude,
    bool force = false,
  }) async {
    if (!force && _status == RouteSearchStatus.loadingRecent) return;

    _status = RouteSearchStatus.loadingRecent;
    notifyListeners();

    final lat = latitude ?? AppMockData.defaultMapTarget.latitude;
    final lng = longitude ?? AppMockData.defaultMapTarget.longitude;

    try {
      final result = await _api.generateSafeRoute(
        originLat: lat,
        originLng: lng,
        destLat: lat,
        destLng: lng,
      );

      final routeData = result['route'] as Map<String, dynamic>?;
      final list = routeData?['recent_routes'] as List<dynamic>? ?? [];
      _recentRoutes = list
          .map(
            (item) => RouteModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      _recentRoutes = AppMockData.recentRoutesJson
          .map(
            (item) => RouteModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    if (_query.trim().isEmpty) {
      _status = RouteSearchStatus.idle;
    }
    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    _results = [];
    _placeResults = [];
    _error = null;
    _status = RouteSearchStatus.idle;
    notifyListeners();
  }

  /// Search only from filtered recent routes + Google Places API.
  /// There is no backend `/routes/search` endpoint.
  Future<void> search(
    String? queryOverride, {
    double? latitude,
    double? longitude,
  }) async {
    final q = (queryOverride ?? _query).trim();
    _query = q;
    _error = null;

    if (q.isEmpty) {
      clearSearch();
      return;
    }

    _status = RouteSearchStatus.loading;
    notifyListeners();

    _results = _filterRecentRoutes(q);
    _placeResults = await _fetchPlaces(q, latitude, longitude);

    _status = _results.isEmpty && _placeResults.isEmpty
        ? RouteSearchStatus.notFound
        : RouteSearchStatus.results;

    notifyListeners();
  }

  Future<List<PlacePrediction>> _fetchPlaces(
    String query,
    double? latitude,
    double? longitude,
  ) async {
    try {
      return await _places.search(
        query,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('RouteSearchService._fetchPlaces failed: $e');
      return [];
    }
  }

  List<RouteModel> _filterRecentRoutes(String query) {
    final lower = query.toLowerCase();
    return _recentRoutes
        .where((route) => route.name.toLowerCase().contains(lower))
        .toList();
  }

  Future<LatLng?> resolvePlace(PlacePrediction prediction) {
    return _places.resolvePlace(prediction);
  }

  void reset() {
    _query = '';
    _status = RouteSearchStatus.idle;
    _results = [];
    _placeResults = [];
    _recentRoutes = [];
    _error = null;
    notifyListeners();
  }
}
