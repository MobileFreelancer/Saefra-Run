import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/data/app_mock_data.dart';
import 'package:saefra_run/core/models/generate_route_filters.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/models/save_route_payload.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/services/route_service.dart';
import 'package:saefra_run/core/utils/polyline_decoder.dart';

import '../config/api_config.dart';

class GenerateRouteService extends ChangeNotifier {
  GenerateRouteService();

  final ApiService _api = ApiService();
  final RouteService _routeService = RouteService();

  GenerateRouteFilters _filters = const GenerateRouteFilters();
  RouteModel? _generatedRoute;
  List<LatLng> _previewPolylinePoints = [];
  bool _isLoading = false;
  String? _error;

  GenerateRouteFilters get filters => _filters;
  RouteModel? get generatedRoute => _generatedRoute;
  List<LatLng> get previewPolylinePoints => _previewPolylinePoints;
  bool get isLoading => _isLoading;
  String? get error => _error;


  Completer<GoogleMapController> googleMapController = Completer();

  Set<Marker> markers = {};
  Set<Polyline> polyline = {};

  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints(apiKey: ApiConfig.googleDirectionsApiKey);

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

  Future<RouteModel?> generate({
    required double? latitude,
    required double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final origin = LatLng(
        latitude ?? AppMockData.defaultMapTarget.latitude,
        longitude ?? AppMockData.defaultMapTarget.longitude,
      );

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



  Future<void> getPolyline({
    required LatLng originPosition,
    required LatLng destinationPosition,
  }) async {
    polylineCoordinates.clear();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(
          originPosition.latitude,
          originPosition.longitude,
        ),
        destination: PointLatLng(
          destinationPosition.latitude,
          destinationPosition.longitude,
        ),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      for (PointLatLng point in result.points) {
        polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      }
    }
    polyline.clear();

    polyline.add(
      Polyline(
        polylineId: const PolylineId('polyline'),
        color: Colors.red,
        width: 5,
        points: polylineCoordinates,
      ),
    );
     notifyListeners();
  }
}
