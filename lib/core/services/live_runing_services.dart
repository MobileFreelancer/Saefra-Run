import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:saefra_run/core/config/api_config.dart';

class RunningProvider extends ChangeNotifier {
  final Completer<GoogleMapController> _mapController = Completer();
  Completer<GoogleMapController> get mapController => _mapController;

  LatLng? _currentPosition;
  LatLng? get currentPosition => _currentPosition;

  LatLng? _destinationPosition;
  LatLng? get destinationPosition => _destinationPosition;

  final List<LatLng> _runningPathCoordinates = [];
  List<LatLng> get runningPathCoordinates => _runningPathCoordinates;

  final Map<PolylineId, Polyline> _polylines = {};
  Map<PolylineId, Polyline> get polylines => _polylines;

  final Map<MarkerId, Marker> _markers = {};
  Map<MarkerId, Marker> get markers => _markers;

  StreamSubscription<Position>? _locationSubscription;
  Timer? _runningTimer;

  PolylinePoints get _polylinePoints =>
      PolylinePoints(apiKey: ApiConfig.googleDirectionsApiKey);

  bool _isLoadingRoute = false;
  bool get isLoadingRoute => _isLoadingRoute;

  bool _isSafeRouteSelected = false;
  bool get isSafeRouteSelected => _isSafeRouteSelected;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  int _secondsElapsed = 0;
  int get secondsElapsed => _secondsElapsed;

  double _totalDistanceKm = 0.0;
  double get totalDistanceKm => _totalDistanceKm;

  int _totalSteps = 0;
  int get totalSteps => _totalSteps;

  double _currentSpeedKmh = 0.0;
  double get currentSpeedKmh => _currentSpeedKmh;

  String _routeRemainingStr = "0m";
  String get routeRemainingStr => _routeRemainingStr;

  void initTracking() {
    try {
      _initLocationPermission();
    } catch (e) {
      debugPrint("❌ Error inside initTracking: $e");
    }
  }

  Future<void> _initLocationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint("⚠️ Location service is disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        debugPrint('Location not granted — skipping live tracking init.');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng newPosition = LatLng(position.latitude, position.longitude);

      if (_currentPosition != newPosition && !_isTracking) {
        _currentPosition = newPosition;
        _updateMarker(_currentPosition!, "runner_location", BitmapDescriptor.hueRose);

        if (_mapController.isCompleted) {
          final GoogleMapController controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 16));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error initializing location permissions: $e");
    }
  }

  void selectDestination({
    required LatLng startPoint,
    required LatLng endPoint,
    List<LatLng>? routePolyline,
  }) {
    try {
      if (_isTracking) return;

      _totalDistanceKm = 0.0;
      _totalSteps = 0;
      _currentSpeedKmh = 0.0;
      _secondsElapsed = 0;
      _routeRemainingStr = "0m";

      _currentPosition = startPoint;
      _updateMarker(startPoint, "runner_location", BitmapDescriptor.hueRose);

      _destinationPosition = endPoint;
      _isSafeRouteSelected = true;
      _updateMarker(endPoint, "destination_location", BitmapDescriptor.hueRed);

      _adjustCameraToFitRoute();

      if (routePolyline != null && routePolyline.length > 1) {
        _runningPathCoordinates
          ..clear()
          ..addAll(routePolyline);
        _drawRunningPolyline(const Color(0xFFE91E63));
        _calculateRemainingDistance();
        notifyListeners();
      } else {
        _getStandardRoute();
      }
    } catch (e) {
      debugPrint("❌ Error selecting destination: $e");
    }
  }

  Future<void> _adjustCameraToFitRoute() async {
    try {
      if (_currentPosition == null || _destinationPosition == null) return;
      if (!_mapController.isCompleted) return;

      final GoogleMapController controller = await _mapController.future;

      LatLngBounds bounds;
      if (_currentPosition!.latitude > _destinationPosition!.latitude) {
        bounds = LatLngBounds(
          southwest: LatLng(_destinationPosition!.latitude, _destinationPosition!.longitude < _currentPosition!.longitude ? _destinationPosition!.longitude : _currentPosition!.longitude),
          northeast: LatLng(_currentPosition!.latitude, _destinationPosition!.longitude > _currentPosition!.longitude ? _destinationPosition!.longitude : _currentPosition!.longitude),
        );
      } else {
        bounds = LatLngBounds(
          southwest: LatLng(_currentPosition!.latitude, _currentPosition!.longitude < _destinationPosition!.longitude ? _currentPosition!.longitude : _destinationPosition!.longitude),
          northeast: LatLng(_destinationPosition!.latitude, _currentPosition!.longitude > _destinationPosition!.longitude ? _destinationPosition!.longitude : _currentPosition!.longitude),
        );
      }

      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
    } catch (e) {
      debugPrint("❌ Error moving camera bounds: $e");
    }
  }

  Future<void> _getStandardRoute() async {
    if (_currentPosition == null || _destinationPosition == null) return;

    _isLoadingRoute = true;
    notifyListeners();

    try {
      debugPrint("🌐 Requesting Routes API v2 via PolylinePoints...");

      RoutesApiResponse response = await _polylinePoints.getRouteBetweenCoordinatesV2(
        request: RoutesApiRequest(
          origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destination: PointLatLng(_destinationPosition!.latitude, _destinationPosition!.longitude),
          travelMode: TravelMode.walking,
          // ⭐ FIXED: Walking mode ke liye unspecified preference hona mandatory hai
          routingPreference: RoutingPreference.unspecified,
        ),
      );

      if (response.errorMessage != null && response.errorMessage!.isNotEmpty) {
        debugPrint("🚨 GOOGLE API ERROR RESPONSE: ${response.errorMessage}");
      }

      if (response.routes.isNotEmpty && response.routes.first.polylinePoints != null) {
        _runningPathCoordinates.clear();

        final decodedPoints = response.routes.first.polylinePoints!;
        for (var point in decodedPoints) {
          _runningPathCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        // DRAWING LINE TO MAP
        _drawRunningPolyline(const Color(0xFFE91E63));
        _calculateRemainingDistance();

        debugPrint("✅ POLYLINE DRAWN SUCCESSFULLY! Total Nodes: ${_runningPathCoordinates.length}");
      } else {
        debugPrint("⚠️ API Success but no points found. Status: ${response.status}");
        _calculateRemainingDistance();
      }
    } catch (e) {
      debugPrint("❌ Runtime Network Crash inside PolylinePoints Call: $e");
      _calculateRemainingDistance();
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  void _calculateRemainingDistance() {
    try {
      double totalMeters = 0.0;

      if (_runningPathCoordinates.isNotEmpty && _currentPosition != null) {
        totalMeters += Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _runningPathCoordinates.first.latitude,
          _runningPathCoordinates.first.longitude,
        );

        for (int i = 0; i < _runningPathCoordinates.length - 1; i++) {
          totalMeters += Geolocator.distanceBetween(
            _runningPathCoordinates[i].latitude,
            _runningPathCoordinates[i].longitude,
            _runningPathCoordinates[i + 1].latitude,
            _runningPathCoordinates[i + 1].longitude,
          );
        }
      } else if (_currentPosition != null && _destinationPosition != null) {
        totalMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _destinationPosition!.latitude,
          _destinationPosition!.longitude,
        );
      }

      if (totalMeters <= 8) {
        _routeRemainingStr = "0m";
        return;
      }

      if (totalMeters >= 1000) {
        _routeRemainingStr = "${(totalMeters / 1000).toStringAsFixed(2)}km";
      } else {
        _routeRemainingStr = "${totalMeters.round()}m";
      }
    } catch (e) {
      debugPrint("❌ Error calculating remaining distance: $e");
    }
  }

  void startRunSession() {
    try {
      if (_destinationPosition == null) return;
      _isTracking = true;
      _startTimer();
      _startLiveLocationTracking();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error starting run session: $e");
    }
  }

  void _startTimer() {
    try {
      _runningTimer?.cancel();
      _runningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isTracking) {
          _secondsElapsed++;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint("❌ Error in timer routine: $e");
    }
  }

  String get formattedDuration {
    try {
      int hours = _secondsElapsed ~/ 3600;
      int minutes = (_secondsElapsed % 3600) ~/ 60;
      int seconds = _secondsElapsed % 60;
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } catch (e) {
      return "00:00:00";
    }
  }

  void _startLiveLocationTracking() {
    try {
      _locationSubscription?.cancel();
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen(
            (Position position) async {
          try {
            if (!_isTracking) return;

            LatLng newPos = LatLng(position.latitude, position.longitude);

            if (_currentPosition != null) {
              double distanceMovedMeters = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                newPos.latitude,
                newPos.longitude,
              );

              if (distanceMovedMeters > 0.1) {
                _totalDistanceKm += (distanceMovedMeters / 1000);
                _totalSteps += (distanceMovedMeters * 1.31).round();
              }

              _currentSpeedKmh = position.speed * 3.6;
              if (_currentSpeedKmh < 0.5) _currentSpeedKmh = 0.0;

              if (_runningPathCoordinates.isNotEmpty) {
                int closestIndex = 0;
                double shortestDistance = double.infinity;

                for (int i = 0; i < _runningPathCoordinates.length; i++) {
                  double dist = Geolocator.distanceBetween(
                    newPos.latitude,
                    newPos.longitude,
                    _runningPathCoordinates[i].latitude,
                    _runningPathCoordinates[i].longitude,
                  );
                  if (dist < shortestDistance) {
                    shortestDistance = dist;
                    closestIndex = i;
                  }
                }

                if (closestIndex > 0) {
                  _runningPathCoordinates.removeRange(0, closestIndex);
                  _drawRunningPolyline(const Color(0xFFE91E63));
                }
              }
            }

            _currentPosition = newPos;
            _updateMarker(newPos, "runner_location", BitmapDescriptor.hueRose);
            _calculateRemainingDistance();

            if (_mapController.isCompleted) {
              final GoogleMapController controller = await _mapController.future;
              controller.animateCamera(CameraUpdate.newLatLng(newPos));
            }

            notifyListeners();
          } catch (innerError) {
            debugPrint("❌ Tracking Update Error: $innerError");
          }
        },
        onError: (error) => debugPrint("❌ GPS Stream Failure: $error"),
      );
    } catch (e) {
      debugPrint("❌ Error setting up live data: $e");
    }
  }

  void _drawRunningPolyline(Color polylineColor) {
    try {
      PolylineId id = const PolylineId("running_path");
      _polylines[id] = Polyline(
        polylineId: id,
        color: polylineColor,
        points: List<LatLng>.from(_runningPathCoordinates),
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );
    } catch (e) {
      debugPrint("❌ Error drawing polyline: $e");
    }
  }

  void _updateMarker(LatLng position, String idStr, double colorHue) {
    try {
      MarkerId id = MarkerId(idStr);
      _markers[id] = Marker(
        markerId: id,
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(colorHue),
      );
    } catch (e) {
      debugPrint("❌ Error updating marker: $e");
    }
  }

  void togglePauseResume() {
    try {
      _isTracking = !_isTracking;
      if (_isTracking) {
        _startLiveLocationTracking();
      } else {
        _locationSubscription?.cancel();
        _currentSpeedKmh = 0.0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error toggling state: $e");
    }
  }

  void resumeSession() {
    if (_isTracking) return;
    _isTracking = true;
    _startLiveLocationTracking();
    notifyListeners();
  }

  void finishRun() {
    try {
      _isTracking = false;
      _isSafeRouteSelected = false;
      _currentSpeedKmh = 0.0;
      _totalDistanceKm = 0.0;
      _totalSteps = 0;
      _secondsElapsed = 0;
      _routeRemainingStr = "0m";
      _runningTimer?.cancel();
      _locationSubscription?.cancel();
      _runningPathCoordinates.clear();
      _polylines.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error during session cleanup: $e");
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _runningTimer?.cancel();
    super.dispose();
  }
}