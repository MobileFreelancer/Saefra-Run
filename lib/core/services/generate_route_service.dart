import 'package:flutter/foundation.dart';
import 'package:saefra_run/core/data/app_mock_data.dart';
import 'package:saefra_run/core/models/generate_route_filters.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/api_service.dart';

class GenerateRouteService extends ChangeNotifier {
  GenerateRouteService();

  final ApiService _api = ApiService();

  GenerateRouteFilters _filters = const GenerateRouteFilters();
  RouteModel? _generatedRoute;
  bool _isLoading = false;
  String? _error;

  GenerateRouteFilters get filters => _filters;
  RouteModel? get generatedRoute => _generatedRoute;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setDistance(double km) {
    _filters = _filters.copyWith(distanceKm: km);
    notifyListeners();
  }

  void setDifficulty(RouteDifficulty value) {
    _filters = _filters.copyWith(difficulty: value);
    notifyListeners();
  }

  void setShape(RouteShape value) {
    _filters = _filters.copyWith(shape: value);
    notifyListeners();
  }

  void setLighting(RouteLighting value) {
    _filters = _filters.copyWith(lighting: value);
    notifyListeners();
  }

  Future<RouteModel?> generate() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _generatedRoute = await _api.generateRoute(_filters);
      return _generatedRoute;
    } catch (e) {
      _generatedRoute = RouteModel(
        id: 'generated',
        name: AppMockData.routeDetail('generated').name,
        imageAsset: AppMockData.routeDetail('generated').imageAsset,
        distanceKm: _filters.distanceKm,
        durationMinutes: (_filters.distanceKm * 12).round(),
        runnerCount: 23,
        isSecure: true,
        safetyScore: '94%',
        safePoints: 14,
        locationLabel: 'Central Park, NY',
        visibilityLabel: 'High Visibility Route',
        saefraScore: 94,
        trafficLevel: 'Low',
        lightingLevel: _filters.lighting == RouteLighting.wellLit
            ? 'High'
            : 'Low',
        communityRating: 4.8,
      );
      _error = null;
      return _generatedRoute;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
