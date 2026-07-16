import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/models/generate_route_filters.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/models/save_route_payload.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/route_service.dart';
import 'package:saefra_run/core/utils/polyline_decoder.dart';

class GenerateRouteService extends ChangeNotifier {
  GenerateRouteService();

  final ApiService _api = ApiService();
  final RouteService _routeService = RouteService();

  GenerateRouteFilters _filters = const GenerateRouteFilters();
  RouteModel? _generatedRoute;
  List<LatLng> _previewPolylinePoints = [];
  bool _isLoading = false;
  bool _isPreviewLoading = false;
  String? _error;
  Timer? _previewDebounce;
  double? _previewLatitude;
  double? _previewLongitude;

  GenerateRouteFilters get filters => _filters;
  RouteModel? get generatedRoute => _generatedRoute;
  List<LatLng> get previewPolylinePoints => _previewPolylinePoints;
  bool get isLoading => _isLoading;
  bool get isPreviewLoading => _isPreviewLoading;
  String? get error => _error;

  void setDistance(double km) {
    _filters = _filters.copyWith(distanceKm: km);
    notifyListeners();
    _schedulePreview();
  }

  void setDifficulty(RouteDifficulty value) {
    _filters = _filters.copyWith(difficulty: value);
    notifyListeners();
    _schedulePreview();
  }

  void setShape(RouteShape value) {
    _filters = _filters.copyWith(shape: value);
    notifyListeners();
    _schedulePreview();
  }

  void setLighting(RouteLighting value) {
    _filters = _filters.copyWith(lighting: value);
    notifyListeners();
    _schedulePreview();
  }

  void clearPreview() {
    _previewDebounce?.cancel();
    _previewPolylinePoints = [];
    _generatedRoute = null;
    _error = null;
    notifyListeners();
  }

  void bindLocation({required double? latitude, required double? longitude}) {
    _previewLatitude = latitude;
    _previewLongitude = longitude;
    updatePreview(latitude: latitude, longitude: longitude);
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 450), () {
      updatePreview(
        latitude: _previewLatitude,
        longitude: _previewLongitude,
      );
    });
  }

  Future<void> updatePreview({
    required double? latitude,
    required double? longitude,
  }) async {
    if (latitude == null || longitude == null) {
      _previewPolylinePoints = [];
      notifyListeners();
      return;
    }

    _isPreviewLoading = true;
    _error = null;
    notifyListeners();

    try {
      final origin = LatLng(latitude, longitude);
      final result = _filters.shape == RouteShape.loop
          ? await _routeService.createLoopRoute(
              currentLocation: origin,
              distanceKm: _filters.distanceKm,
              difficulty: _filters.difficulty.apiValue,
              routeType: 'loop',
              lighting: _filters.lighting.apiValue,
            )
          : await _routeService.createOneWayRoute(
              origin: origin,
              distanceKm: _filters.distanceKm,
              difficulty: _filters.difficulty.apiValue,
              lighting: _filters.lighting.apiValue,
            );

      _previewPolylinePoints = result == null
          ? []
          : PolylineDecoder.decode(result.encodedPolyline);
    } catch (e) {
      debugPrint('GenerateRouteService.updatePreview failed: $e');
      _previewPolylinePoints = [];
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  Future<RouteModel?> generate({
    required double? latitude,
    required double? longitude,
  }) async {
    if (latitude == null || longitude == null) {
      _error = 'Location is required to generate a route.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final origin = LatLng(latitude, longitude);

      final loopResult = _filters.shape == RouteShape.loop
          ? await _routeService.createLoopRoute(
              currentLocation: origin,
              distanceKm: _filters.distanceKm,
              difficulty: _filters.difficulty.apiValue,
              routeType: 'loop',
              lighting: _filters.lighting.apiValue,
            )
          : await _routeService.createOneWayRoute(
              origin: origin,
              distanceKm: _filters.distanceKm,
              difficulty: _filters.difficulty.apiValue,
              lighting: _filters.lighting.apiValue,
            );

      if (loopResult == null) {
        _error = 'Could not generate a route. Please try again.';
        return null;
      }

      _previewPolylinePoints =
          PolylineDecoder.decode(loopResult.encodedPolyline);
      notifyListeners();

      final coordinates = loopResult.coordinates;
      final start = coordinates.isNotEmpty ? coordinates.first : null;
      final end = coordinates.isNotEmpty ? coordinates.last : null;

      final payload = SaveRoutePayload.fromLoopResult(
        loopResult,
        startLatitude: start?['latitude'],
        startLongitude: start?['longitude'],
        endLatitude: end?['latitude'],
        endLongitude: end?['longitude'],
      );

      _generatedRoute = await _api.saveRoute(payload);
      return _generatedRoute;
    } catch (e) {
      _error = e.toString();
      debugPrint('GenerateRouteService.generate failed: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
  }
}
