import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saefra_run/core/config/api_config.dart';

class RunningProvider extends ChangeNotifier {
  Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  Completer<GoogleMapController> get mapController => _mapController;
  GoogleMapController? _activeMapController;

  static LocationSettings get _locationSettings {
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  static const double _avgStrideMeters = 0.762;
  static const double _gpsAccuracyThreshold = 35;
  static const Duration _gpsStaleAfter = Duration(seconds: 8);

  List<LatLng> _fullRoutePoints = [];
  double _trackedDistanceMeters = 0;
  int? _stepBaseline;
  DateTime? _lastMeaningfulGpsUpdateAt;
  double? _lastGpsAccuracy;

  StreamSubscription<StepCount>? _pedometerSubscription;

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

  bool _isRerouting = false;
  DateTime? _lastRerouteAt;
  static const Duration _rerouteCooldown = Duration(seconds: 12);
  static const double _offRouteThresholdMeters = 35;

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

  bool get isUsingStepTracking => _isTracking && _shouldPreferStepTracking();

  void Function({
  required double latitude,
  required double longitude,
  required double distanceKm,
  required int durationSeconds,
  required double speedKmh,
  required int steps,
  required String pace,
  })? onTrackingUpdate;

  // Custom Asset Markers
  BitmapDescriptor? _runnerIconIdle;
  BitmapDescriptor? _runnerIconActive;
  BitmapDescriptor? _destinationIcon;

  BitmapDescriptor get runnerMarkerIcon => _isTracking
      ? (_runnerIconActive ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))
      : (_runnerIconIdle ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose));

  BitmapDescriptor get destinationMarkerIcon =>
      _destinationIcon ??
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  static const double _navigationZoom = 14.0;

  /// Fresh marker set each call so GoogleMap always picks up GPS moves.
  Set<Marker> buildMarkerSet() {
    final markers = <Marker>{};
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('runner_location'),
          position: _currentPosition!,
          icon: runnerMarkerIcon,
          // Bottom-center so the person icon sits on the route point.
          anchor: const Offset(0.5, 0.9),
          zIndexInt: 2,
          flat: false,
          consumeTapEvents: false,
        ),
      );
    }
    if (_destinationPosition != null &&
        (_currentPosition == null ||
            Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  _destinationPosition!.latitude,
                  _destinationPosition!.longitude,
                ) >
                25)) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination_location'),
          position: _destinationPosition!,
          icon: destinationMarkerIcon,
          anchor: const Offset(0.5, 1.0),
          zIndexInt: 1,
        ),
      );
    }
    return markers;
  }

  void _resetMapController() {
    _activeMapController = null;
    _mapController = Completer<GoogleMapController>();
  }

  /// Loads custom marker images from app assets.
  Future<void> _ensureRunnerIcons() async {
    try {
      // Fixed logical sizes so the person marker stays clearly visible.
      const imageConfig = ImageConfiguration(devicePixelRatio: 3);
      const personMarkerSize = 64.0;
      const destinationMarkerSize = 48.0;

      // Start / runner marker: people (running person) icon.
      final personIcon = await BitmapDescriptor.asset(
        imageConfig,
        'assets/images/runicon.png',
        width: personMarkerSize,
        height: personMarkerSize,
      );
      _runnerIconIdle ??= personIcon;
      _runnerIconActive ??= personIcon;

      _destinationIcon ??= await BitmapDescriptor.asset(
        imageConfig,
        'assets/images/startrun.png',
        width: destinationMarkerSize,
        height: destinationMarkerSize,
      );
      debugPrint('✅ Person start marker + destination markers loaded');
      notifyListeners();
    } catch (e) {
      debugPrint(
        '⚠️ Could not load person marker asset, trying user.png fallback: $e',
      );
      try {
        const imageConfig = ImageConfiguration(devicePixelRatio: 3);
        final fallbackPerson = await BitmapDescriptor.asset(
          imageConfig,
          'assets/images/user.png',
          width: 56,
          height: 56,
        );
        _runnerIconIdle ??= fallbackPerson;
        _runnerIconActive ??= fallbackPerson;
      } catch (_) {
        _runnerIconIdle ??= BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRose,
        );
        _runnerIconActive ??= BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
      }
      _destinationIcon ??= BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
      notifyListeners();
    }
  }

  Future<void> initTracking() async {
    try {
      await _ensureRunnerIcons();
      final hasPermission = await _initLocationPermission();
      if (hasPermission) {
        _startLiveLocationTracking();
      }
    } catch (e) {
      debugPrint("❌ Error inside initTracking: $e");
    }
  }

  /// Clears prior run state and applies a generated/saved route for live tracking.
  void prepareForRun({
    required LatLng startPoint,
    required LatLng endPoint,
    List<LatLng>? routePolyline,
  }) {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _stopPedometerTracking();
    _runningTimer?.cancel();
    _isTracking = false;
    _isLoadingRoute = false;
    _totalDistanceKm = 0.0;
    _totalSteps = 0;
    _currentSpeedKmh = 0.0;
    _secondsElapsed = 0;
    _routeRemainingStr = "0m";
    _trackedDistanceMeters = 0;
    _fullRoutePoints = [];
    _stepBaseline = null;
    _lastMeaningfulGpsUpdateAt = null;
    _lastGpsAccuracy = null;
    _runningPathCoordinates.clear();
    _polylines.clear();
    _markers.clear();
    _resetMapController();

    selectDestination(
      startPoint: startPoint,
      endPoint: endPoint,
      routePolyline: routePolyline,
    );
  }

  void onMapReady(GoogleMapController controller) {
    _activeMapController = controller;
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
    // Prefer a route-aware overview over an extreme close-up zoom.
    _adjustCameraToFitRoute();
    notifyListeners();
  }

  Future<bool> _initLocationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint("⚠️ Location service is disabled.");
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        debugPrint('Location not granted — skipping live tracking init.');
        return false;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      _applyGpsPosition(position, followCamera: !_isTracking);
      return true;
    } catch (e) {
      debugPrint("❌ Error initializing location permissions: $e");
      return false;
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

      // Prefer live GPS; fall back to route start so the runner marker is visible.
      _currentPosition ??=
          (routePolyline != null && routePolyline.isNotEmpty)
              ? routePolyline.first
              : startPoint;

      _destinationPosition = endPoint;
      _isSafeRouteSelected = true;

      if (routePolyline != null && routePolyline.length > 1) {
        _fullRoutePoints = List<LatLng>.from(routePolyline);
        _runningPathCoordinates
          ..clear()
          ..addAll(routePolyline);
        _drawRunningPolyline(const Color(0xFFE91E63));
        _calculateRemainingDistance();
        _adjustCameraToFitRoute();
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
      final controller = _activeMapController ??
          (_mapController.isCompleted ? await _mapController.future : null);
      if (controller == null) return;

      // Fit the remaining polyline (not just start/end). Loop routes have the
      // same start & end, which previously collapsed bounds and over-zoomed.
      final points = <LatLng>[
        if (_currentPosition != null) _currentPosition!,
        ..._runningPathCoordinates,
        if (_destinationPosition != null) _destinationPosition!,
      ];

      if (points.isEmpty) return;

      if (points.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, _navigationZoom),
        );
        return;
      }

      var minLat = points.first.latitude;
      var maxLat = points.first.latitude;
      var minLng = points.first.longitude;
      var maxLng = points.first.longitude;
      for (final point in points) {
        minLat = minLat < point.latitude ? minLat : point.latitude;
        maxLat = maxLat > point.latitude ? maxLat : point.latitude;
        minLng = minLng < point.longitude ? minLng : point.longitude;
        maxLng = maxLng > point.longitude ? maxLng : point.longitude;
      }

      final latDelta = (maxLat - minLat).abs();
      final lngDelta = (maxLng - minLng).abs();
      // Very small spans (same-point loop / GPS noise) → moderate navigation zoom.
      if (latDelta < 0.003 && lngDelta < 0.003) {
        final center = _currentPosition ??
            LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(center, _navigationZoom),
        );
        return;
      }

      // Pad degenerate edges so LatLngBounds never collapses.
      if (latDelta < 0.0005) {
        minLat -= 0.001;
        maxLat += 0.001;
      }
      if (lngDelta < 0.0005) {
        minLng -= 0.001;
        maxLng += 0.001;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (e) {
      debugPrint('❌ Error moving camera bounds: $e');
      if (_currentPosition != null) {
        await _followRunnerOnMap(_currentPosition!, zoom: _navigationZoom);
      }
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

        _fullRoutePoints = List<LatLng>.from(_runningPathCoordinates);
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
      await _adjustCameraToFitRoute();
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

  Future<void> startRunSession() async {
    if (_isTracking) return;

    try {
      if (_currentPosition == null) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: _locationSettings,
          );
          _applyGpsPosition(position, followCamera: true);
        } catch (e) {
          debugPrint('startRunSession: could not read GPS: $e');
        }
      }

      _isTracking = true;
      _trackedDistanceMeters = 0;
      _stepBaseline = null;
      _startTimer();
      _startLiveLocationTracking();
      await _ensurePedometerPermission();
      _startPedometerTracking();
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
          if (_shouldPreferStepTracking()) {
            _currentSpeedKmh = _estimateSpeedKmh();
          }
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

  String get paceLabel {
    if (_totalDistanceKm <= 0) return "0'00\" /km";
    final paceSeconds = _secondsElapsed / _totalDistanceKm;
    final min = paceSeconds ~/ 60;
    final sec = (paceSeconds % 60).round().toString().padLeft(2, '0');
    return "$min'$sec\" /km";
  }

  void _notifyTrackingUpdate(LatLng position) {
    onTrackingUpdate?.call(
      latitude: position.latitude,
      longitude: position.longitude,
      distanceKm: _totalDistanceKm,
      durationSeconds: _secondsElapsed,
      speedKmh: _currentSpeedKmh,
      steps: _totalSteps,
      pace: paceLabel,
    );
  }

  void _applyGpsPosition(Position position, {bool followCamera = true}) {
    _lastGpsAccuracy = position.accuracy;
    final newPos = LatLng(position.latitude, position.longitude);
    final previous = _currentPosition;
    _lastMeaningfulGpsUpdateAt = DateTime.now();

    if (_isTracking && previous != null) {
      final distanceMovedMeters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        newPos.latitude,
        newPos.longitude,
      );

      if (distanceMovedMeters > 0.5) {
        _trackedDistanceMeters += distanceMovedMeters;
        _totalDistanceKm += distanceMovedMeters / 1000;

        _currentSpeedKmh = position.speed >= 0 ? position.speed * 3.6 : 0;
        if (_currentSpeedKmh < 0.5) {
          _currentSpeedKmh = _estimateSpeedKmh();
        }

        _currentPosition = newPos;
        if (_runningPathCoordinates.isNotEmpty) {
          _trimPassedRoutePoints(newPos);
          _checkAndTriggerReroute(newPos);
        }
        _calculateRemainingDistance();
        _notifyTrackingUpdate(newPos);

        if (followCamera) {
          _followRunnerOnMap(newPos);
        }
        notifyListeners();
        return;
      }
    }

    _currentPosition = newPos;

    if (followCamera && (_isTracking || previous == null)) {
      _followRunnerOnMap(newPos);
    }

    notifyListeners();
  }

  void _checkAndTriggerReroute(LatLng currentPos) {
    if (_destinationPosition == null || _isLoadingRoute || _isRerouting) return;
    if (_runningPathCoordinates.isEmpty) return;

    if (_lastRerouteAt != null &&
        DateTime.now().difference(_lastRerouteAt!) < _rerouteCooldown) {
      return;
    }

    double minDistance = double.infinity;
    var nearestIndex = 0;
    for (var i = 0; i < _runningPathCoordinates.length; i++) {
      final point = _runningPathCoordinates[i];
      final dist = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        point.latitude,
        point.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearestIndex = i;
      }
    }

    if (minDistance > _offRouteThresholdMeters) {
      debugPrint(
        '[Reroute] Off-route detected: ${minDistance.toStringAsFixed(1)}m '
        'from remaining path (nearestIndex=$nearestIndex, '
        'remainingPoints=${_runningPathCoordinates.length}). '
        'Reconnecting to remaining route instead of final destination.',
      );
      _rerouteReconnectingToRemainingPath(
        currentPos: currentPos,
        nearestIndex: nearestIndex,
      );
    }
  }

  /// Reconnects from the runner's current position to the nearest remaining
  /// route segment, then preserves the rest of the planned path (important for loops).
  Future<void> _rerouteReconnectingToRemainingPath({
    required LatLng currentPos,
    required int nearestIndex,
  }) async {
    if (_isLoadingRoute || _isRerouting || _runningPathCoordinates.isEmpty) {
      return;
    }

    _isRerouting = true;
    _isLoadingRoute = true;
    _lastRerouteAt = DateTime.now();
    notifyListeners();

    try {
      final reconnectIndex = _reconnectIndexAlongRemainingPath(nearestIndex);
      final reconnectPoint = _runningPathCoordinates[reconnectIndex];
      final remainingTail =
          _runningPathCoordinates.sublist(reconnectIndex);

      debugPrint(
        '[Reroute] Requesting reconnect path: '
        'current=(${currentPos.latitude},${currentPos.longitude}) → '
        'reconnect=(${reconnectPoint.latitude},${reconnectPoint.longitude}) '
        'index=$reconnectIndex/${_runningPathCoordinates.length - 1}',
      );

      final response = await _polylinePoints.getRouteBetweenCoordinatesV2(
        request: RoutesApiRequest(
          origin: PointLatLng(currentPos.latitude, currentPos.longitude),
          destination: PointLatLng(
            reconnectPoint.latitude,
            reconnectPoint.longitude,
          ),
          travelMode: TravelMode.walking,
          routingPreference: RoutingPreference.unspecified,
        ),
      );

      if (response.errorMessage != null && response.errorMessage!.isNotEmpty) {
        debugPrint('[Reroute] API error: ${response.errorMessage}');
      }

      final decoded = response.routes.isNotEmpty
          ? response.routes.first.polylinePoints
          : null;

      if (decoded == null || decoded.isEmpty) {
        debugPrint(
          '[Reroute] No reconnect polyline returned (status=${response.status}). '
          'Keeping existing remaining path.',
        );
        return;
      }

      final reconnectPath = decoded
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      final merged = <LatLng>[...reconnectPath];
      for (final point in remainingTail) {
        if (merged.isNotEmpty) {
          final last = merged.last;
          final gap = Geolocator.distanceBetween(
            last.latitude,
            last.longitude,
            point.latitude,
            point.longitude,
          );
          if (gap < 3) continue;
        }
        merged.add(point);
      }

      if (merged.length < 2) {
        debugPrint('[Reroute] Merged path too short; aborting update');
        return;
      }

      _runningPathCoordinates
        ..clear()
        ..addAll(merged);
      _fullRoutePoints = List<LatLng>.from(merged);
      _drawRunningPolyline(const Color(0xFFE91E63));
      _calculateRemainingDistance();

      debugPrint(
        '[Reroute] Success. New remaining points=${merged.length}, '
        'remaining=${_routeRemainingStr}',
      );
    } catch (e) {
      debugPrint('[Reroute] Failed: $e');
    } finally {
      _isRerouting = false;
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  /// Prefer a point slightly ahead of the nearest index so we reconnect in the
  /// intended travel direction instead of behind the runner.
  int _reconnectIndexAlongRemainingPath(int nearestIndex) {
    if (_runningPathCoordinates.isEmpty) return 0;
    if (nearestIndex >= _runningPathCoordinates.length - 1) {
      return _runningPathCoordinates.length - 1;
    }

    const lookaheadMeters = 60.0;
    var traveled = 0.0;
    var index = nearestIndex;

    for (var i = nearestIndex; i < _runningPathCoordinates.length - 1; i++) {
      final segment = Geolocator.distanceBetween(
        _runningPathCoordinates[i].latitude,
        _runningPathCoordinates[i].longitude,
        _runningPathCoordinates[i + 1].latitude,
        _runningPathCoordinates[i + 1].longitude,
      );
      traveled += segment;
      index = i + 1;
      if (traveled >= lookaheadMeters) break;
    }

    return index;
  }

  bool _shouldPreferStepTracking() {
    if (!_isTracking) return false;
    if (_lastMeaningfulGpsUpdateAt == null) return true;
    if ((_lastGpsAccuracy ?? double.infinity) > _gpsAccuracyThreshold) {
      return true;
    }
    return DateTime.now().difference(_lastMeaningfulGpsUpdateAt!) >
        _gpsStaleAfter;
  }

  double _estimateSpeedKmh() {
    if (_secondsElapsed <= 0 || _totalDistanceKm <= 0) return 0;
    return _totalDistanceKm / (_secondsElapsed / 3600);
  }

  void _applyStepProgress(int deltaSteps) {
    if (!_isTracking || deltaSteps <= 0) return;

    final deltaMeters = deltaSteps * _avgStrideMeters;
    _trackedDistanceMeters += deltaMeters;
    _totalDistanceKm = _trackedDistanceMeters / 1000;
    _currentSpeedKmh = _estimateSpeedKmh();

    if (_fullRoutePoints.length > 1) {
      final pos = _positionAtDistance(_fullRoutePoints, _trackedDistanceMeters);
      if (pos != null) {
        _currentPosition = pos;
        _trimPassedRoutePoints(pos);
        _calculateRemainingDistance();
        _followRunnerOnMap(pos);
        _notifyTrackingUpdate(pos);
      }
    } else if (_currentPosition != null) {
      _notifyTrackingUpdate(_currentPosition!);
    }

    notifyListeners();
  }

  LatLng? _positionAtDistance(List<LatLng> points, double distanceMeters) {
    if (points.isEmpty) return null;
    if (distanceMeters <= 0) return points.first;

    var remaining = distanceMeters;
    for (var i = 0; i < points.length - 1; i++) {
      final segmentMeters = Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );

      if (segmentMeters <= 0) continue;

      if (remaining <= segmentMeters) {
        final t = remaining / segmentMeters;
        return LatLng(
          points[i].latitude + (points[i + 1].latitude - points[i].latitude) * t,
          points[i].longitude + (points[i + 1].longitude - points[i].longitude) * t,
        );
      }

      remaining -= segmentMeters;
    }

    return points.last;
  }

  Future<void> _ensurePedometerPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.activityRecognition.status;
      if (!status.isGranted) {
        await Permission.activityRecognition.request();
      }
    } catch (e) {
      debugPrint('Activity recognition permission request failed: $e');
    }
  }

  void _startPedometerTracking() {
    _pedometerSubscription?.cancel();
    _stepBaseline = null;

    try {
      _pedometerSubscription = Pedometer.stepCountStream.listen(
        _onPedometerStep,
        onError: (error) => debugPrint('Pedometer stream error: $error'),
      );
    } catch (e) {
      debugPrint('Pedometer setup failed: $e');
    }
  }

  void _stopPedometerTracking() {
    _pedometerSubscription?.cancel();
    _pedometerSubscription = null;
    _stepBaseline = null;
  }

  void _onPedometerStep(StepCount event) {
    if (!_isTracking) return;

    if (_stepBaseline == null) {
      _stepBaseline = event.steps;
      return;
    }

    var sessionSteps = event.steps - _stepBaseline!;
    if (sessionSteps < 0) {
      _stepBaseline = event.steps;
      sessionSteps = 0;
    }

    if (sessionSteps <= _totalSteps) return;

    final deltaSteps = sessionSteps - _totalSteps;
    _totalSteps = sessionSteps;

    if (_shouldPreferStepTracking()) {
      _applyStepProgress(deltaSteps);
    } else {
      notifyListeners();
    }
  }

  void _trimPassedRoutePoints(LatLng newPos) {
    int closestIndex = 0;
    double shortestDistance = double.infinity;

    for (int i = 0; i < _runningPathCoordinates.length; i++) {
      final dist = Geolocator.distanceBetween(
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

  Future<void> _followRunnerOnMap(LatLng position, {double? zoom}) async {
    final controller = _activeMapController;
    if (controller == null) return;

    try {
      // Keep a professional street-level view; never snap to extreme close-up.
      final targetZoom = zoom ?? _navigationZoom;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(position, targetZoom),
      );
    } catch (e) {
      debugPrint('Camera follow failed: $e');
    }
  }

  void _startLiveLocationTracking() {
    if (_locationSubscription != null) return;

    try {
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (position) {
          try {
            _applyGpsPosition(position, followCamera: _isTracking);
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

  void togglePauseResume() {
    try {
      _isTracking = !_isTracking;
      if (!_isTracking) {
        _currentSpeedKmh = 0.0;
      } else {
        _startLiveLocationTracking();
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
      _locationSubscription = null;
      _stopPedometerTracking();
      _runningPathCoordinates.clear();
      _fullRoutePoints = [];
      _trackedDistanceMeters = 0;
      _polylines.clear();
      _destinationPosition = null;
      _currentPosition = null;
      _markers.clear();
      _resetMapController();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error during session cleanup: $e");
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _stopPedometerTracking();
    _runningTimer?.cancel();
    super.dispose();
  }
}