import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/models/generate_route_filters.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/models/save_route_payload.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/route_service.dart';
import 'package:saefra_run/core/utils/location_route_utils.dart';
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
  double? _destinationLatitude;
  double? _destinationLongitude;
  String? _destinationName;

  GenerateRouteFilters get filters => _filters;
  RouteModel? get generatedRoute => _generatedRoute;
  List<LatLng> get previewPolylinePoints => _previewPolylinePoints;
  bool get isLoading => _isLoading;
  bool get isPreviewLoading => _isPreviewLoading;
  String? get error => _error;
  bool get hasDestination =>
      _destinationLatitude != null && _destinationLongitude != null;
  double? get destinationLatitude => _destinationLatitude;
  double? get destinationLongitude => _destinationLongitude;
  String? get destinationName => _destinationName;

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
  }

  void bindDestination({
    required double? latitude,
    required double? longitude,
    String? name,
  }) {
    _destinationLatitude = latitude;
    _destinationLongitude = longitude;
    _destinationName = name;
  }

  Future<void> syncRouteContext({
    required double? originLatitude,
    required double? originLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationName,
  }) async {
    bindLocation(latitude: originLatitude, longitude: originLongitude);
    bindDestination(
      latitude: destinationLatitude,
      longitude: destinationLongitude,
      name: destinationName,
    );
    await updatePreview(
      latitude: originLatitude,
      longitude: originLongitude,
    );
  }

  void clearDestination() {
    _destinationLatitude = null;
    _destinationLongitude = null;
    _destinationName = null;
    _schedulePreview();
  }

  Future<LoopRouteResult?> _buildPreviewRoute(LatLng origin) async {
    if (hasDestination) {
      return _routeService.createRouteToDestination(
        origin: origin,
        destination: LatLng(_destinationLatitude!, _destinationLongitude!),
        difficulty: _filters.difficulty.apiValue,
        lighting: _filters.lighting.apiValue,
        routeName: _destinationName,
      );
    }

    if (_filters.shape == RouteShape.loop) {
      return _routeService.createLoopRoute(
        currentLocation: origin,
        distanceKm: _filters.distanceKm,
        difficulty: _filters.difficulty.apiValue,
        routeType: 'loop',
        lighting: _filters.lighting.apiValue,
      );
    }

    return _routeService.createOneWayRoute(
      origin: origin,
      distanceKm: _filters.distanceKm,
      difficulty: _filters.difficulty.apiValue,
      lighting: _filters.lighting.apiValue,
    );
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
      _error = hasDestination
          ? 'Waiting for your current location. Enable GPS and try again.'
          : null;
      notifyListeners();
      return;
    }

    _isPreviewLoading = true;
    _error = null;
    notifyListeners();

    try {
      final origin = LatLng(latitude, longitude);
      if (hasDestination) {
        final destination = LatLng(_destinationLatitude!, _destinationLongitude!);
        final validationError = LocationRouteUtils.routeValidationError(
          origin: origin,
          destination: destination,
          destinationName: _destinationName,
        );
        if (validationError != null) {
          _previewPolylinePoints = [];
          _error = validationError;
          return;
        }
      }

      final result = await _buildPreviewRoute(origin);

      if (result == null) {
        _previewPolylinePoints = [];
        _error = hasDestination
            ? 'Could not draw a route to the selected destination. Check your current location and try again.'
            : 'Could not preview this route. Try adjusting distance or route type.';
      } else {
        _previewPolylinePoints = PolylineDecoder.decode(result.encodedPolyline);
        if (_previewPolylinePoints.length <= 1) {
          _previewPolylinePoints = [];
          _error = hasDestination
              ? 'No walkable route found to the selected destination.'
              : 'No route preview available for these settings.';
        } else {
          _error = null;
        }
      }
    } catch (e) {
      debugPrint('GenerateRouteService.updatePreview failed: $e');
      _previewPolylinePoints = [];
      _error = 'Route preview failed. Please try again.';
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

    if (hasDestination) {
      final validationError = LocationRouteUtils.routeValidationError(
        origin: LatLng(latitude, longitude),
        destination: LatLng(_destinationLatitude!, _destinationLongitude!),
        destinationName: _destinationName,
      );
      if (validationError != null) {
        _error = validationError;
        notifyListeners();
        return null;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final origin = LatLng(latitude, longitude);
      final loopResult = await _buildPreviewRoute(origin);

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
