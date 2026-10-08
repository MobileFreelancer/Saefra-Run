import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/models/route_model.dart';
import 'package:saefra_run/core/services/api_service.dart';
import 'package:saefra_run/core/utils/api_response_parser.dart';
import 'package:saefra_run/core/utils/map_style_service.dart';
import 'package:saefra_run/core/utils/polyline_decoder.dart';

enum DashboardMapStyle {
  darkBase('Dark base'),
  light('Light'),
  dark('Dark');

  const DashboardMapStyle(this.label);
  final String label;
}

class DashboardServices extends ChangeNotifier {
  static const double defaultLatitude = 21.205194905801783;
  static const double defaultLongitude = 72.77568113625402;

  double? _latitude;
  double? _longitude;

  double? _destinationPositionLatitude;
  double? _destinationPositionLongitude;
  String? _destinationName;

  bool _isLoading = false;
  int _currentBottomIndex = 0;
  GoogleMapController? _mapController;

  // Location stream
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _locationInitStarted = false;
  bool _locationInitInProgress = false;
  bool _locationPermissionResolved = false;
  bool _homeRoutesRequested = false;
  DateTime? _lastLocationNotifyAt;

  // State variables for Location Autocomplete Search
  List<dynamic> _placePredictions = [];
  bool _isSearching = false;
  final String _googleApiKey = ApiConfig.googlePlacesApiKey;

  // Dynamic Route Integration State
  Map<String, dynamic>? _recommendedRoute;
  List<dynamic> _recentRoutes = [];
  List<LatLng> _routePolylinePoints = [];
  bool _isRouteLoading = false;
  String? _errorMessage;
  DashboardMapStyle _mapStyle = DashboardMapStyle.darkBase;
  MapTheme _mapTheme = MapTheme.light;

  int _nearbyRunners = 0;
  int _routesVerifiedToday = 0;
  int _safetyReportsCount = 0;

  final ApiService _apiService = ApiService();
  Timer? _fetchRouteDebounce;
  int _fetchRouteGeneration = 0;

  double? get latitude => _latitude;
  double? get longitude => _longitude;

  double? get destinationPositionLatitude => _destinationPositionLatitude;
  double? get destinationPositionLongitude => _destinationPositionLongitude;
  String? get destinationName => _destinationName;
  bool get hasSelectedDestination =>
      _destinationPositionLatitude != null &&
      _destinationPositionLongitude != null;


  bool get isLoading => _isLoading;
  

  bool get isLocationPermissionResolved => _locationPermissionResolved;
  int get currentBottomIndex => _currentBottomIndex;
  GoogleMapController? get mapController => _mapController;
  List<dynamic> get placePredictions => _placePredictions;
  bool get isSearching => _isSearching;

  Map<String, dynamic>? get recommendedRoute => _recommendedRoute;
  List<dynamic> get recentRoutes => _recentRoutes;
  bool get hasHomeData => _homeRoutesRequested;

  List<RouteModel> get recentRouteModels => _recentRoutes
      .map(
        (item) => RouteModel.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList();
  List<LatLng> get routePolylinePoints => _routePolylinePoints;
  bool get isRouteLoading => _isRouteLoading;
  String? get errorMessage => _errorMessage;
  DashboardMapStyle get mapStyle => _mapStyle;
  MapTheme get mapTheme => _mapTheme;

  int get nearbyRunners => _nearbyRunners;
  int get routesVerifiedToday => _routesVerifiedToday;
  int get safetyReportsCount => _safetyReportsCount;

  void setBottomIndex(int index) {
    _currentBottomIndex = index;
    notifyListeners();
  }

  void setMapStyle(DashboardMapStyle style) {
    _mapStyle = style;
    notifyListeners();
  }

  Future<void> setMapTheme(MapTheme theme) async {
    _mapTheme = theme;
    notifyListeners();
    if (_mapController != null) {
      await MapStyleService.applyStyle(
        controller: _mapController!,
        theme: theme,
      );
    }
  }

  Future<void> applyMapStyle(GoogleMapController controller) async {
    await MapStyleService.applyStyle(
      controller: controller,
      theme: _mapTheme,
    );
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    applyMapStyle(controller);
    if (_latitude != null && _longitude != null) {
      _animateToCurrentLocation();
    }
  }

  void _notifyLocationListeners() {
    final now = DateTime.now();
    if (_lastLocationNotifyAt != null &&
        now.difference(_lastLocationNotifyAt!) <
            const Duration(milliseconds: 800)) {
      return;
    }
    _lastLocationNotifyAt = now;
    notifyListeners();
  }

  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      _placePredictions = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();

    if (_googleApiKey.isEmpty) {
      _placePredictions = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    final String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googleApiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          _placePredictions = data['predictions'];
        } else {
          _placePredictions = [];
        }
      } else {
        _placePredictions = [];
      }
    } catch (e) {
      _placePredictions = [];
    }
    _isSearching = false;
    notifyListeners();
  }

  Future<void> selectPrediction(String placeId) async {
    _placePredictions = [];
    notifyListeners();
    double? lat;
    double? lng;

    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleApiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          lat = location['lat'];
          lng = location['lng'];
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (lat != null && lng != null) {
      await focusOnLocation(lat, lng);
    }
  }

  void clearDestination() {
    _destinationPositionLatitude = null;
    _destinationPositionLongitude = null;
    _destinationName = null;
    _routePolylinePoints = [];
    _recommendedRoute = null;
    notifyListeners();
  }

  Future<void> focusOnLocation(
    double lat,
    double lng, {
    String? name,
  }) async {
    _destinationPositionLatitude = lat;
    _destinationPositionLongitude = lng;
    _destinationName = name;
    notifyListeners();

    if (_latitude != null && _longitude != null) {
      _scheduleFetchSafeRoute(
        originLat: _latitude!,
        originLng: _longitude!,
      );
    } else {
      _routePolylinePoints = [];
      _recommendedRoute = null;
      notifyListeners();
    }

    if (_mapController != null) {
      if (_routePolylinePoints.length > 1) {
        _fitMapToPoints(_routePolylinePoints);
      } else {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
        );
      }
    }
  }

  void _scheduleFetchSafeRoute({
    required double originLat,
    required double originLng,
  }) {
    _fetchRouteDebounce?.cancel();
    _fetchRouteDebounce = Timer(const Duration(milliseconds: 600), () {
      fetchSafeRoute(
        originLat: originLat,
        originLng: originLng,
      );
    });
  }

  Future<void> fetchSafeRoute({
    required double originLat,
    required double originLng,
  }) async {
    final generation = ++_fetchRouteGeneration;
    _isRouteLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.generateSafeRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: originLat, // Passing origin as placeholder if API expects it
        destLng: originLng,
      );

      if (generation != _fetchRouteGeneration) return;

      if (result['success'] == true ||
          result['status']?.toString().toLowerCase() == 'success') {
        final payload = ApiResponseParser.payload(result);
        
        final stats = payload['community_stats'];
        if (stats is Map) {
          _nearbyRunners = (stats['nearby_runners'] as num?)?.toInt() ?? 0;
          _routesVerifiedToday = (stats['routes_verified'] as num?)?.toInt() ?? 0;
          _safetyReportsCount = (stats['safety_reports'] as num?)?.toInt() ?? 0;
        }

        final activeRouteData = payload['active_route'];
        if (activeRouteData is Map) {
          _recommendedRoute = Map<String, dynamic>.from(activeRouteData);
          final routeModel = RouteModel.fromJson(_recommendedRoute!);
          _routePolylinePoints = routeModel.polylinePoints;
        }

        final recentList = payload['recent_routes'];
        if (recentList is List) {
          _recentRoutes = recentList;
        }
        
        if (_routePolylinePoints.length > 1) {
          _fitMapToPoints(_routePolylinePoints);
        }
      } else {
        _errorMessage = result['message'] ?? 'Failed to generate safe route.';
      }
    } catch (e) {
      if (generation != _fetchRouteGeneration) return;
      _errorMessage = e.toString();
      debugPrint('Error fetching safe route: $e');
    } finally {
      if (generation != _fetchRouteGeneration) return;
      _isRouteLoading = false;
      notifyListeners();
    }
  }

  void _fitMapToPoints(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    try {
      if (points.length == 1) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15),
        );
        return;
      }

      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (var point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      // Google Maps crashes when bounds have zero area.
      if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15),
        );
        return;
      }

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          60.0,
        ),
      );
    } catch (e) {
      debugPrint('fitMapToPoints failed: $e');
    }
  }

  void resetHomeRoutes() {
    _homeRoutesRequested = false;
    _recommendedRoute = null;
    _recentRoutes = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initializeDashboard() async {
    // Always try to resolve GPS when missing — home routes may already have
    // loaded with default coordinates after a previous failed location attempt.
    if (_latitude == null || _longitude == null) {
      try {
        await ensureCurrentLocation().timeout(const Duration(seconds: 12));
      } catch (e) {
        debugPrint('initializeDashboard location failed: $e');
      }
    } else if (!_locationInitStarted) {
      try {
        await getCurrentLocation().timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('getCurrentLocation timed out or failed: $e');
      }
    }
    await loadHomeRoutesIfNeeded();
  }

  /// Pull-to-refresh: re-fetch home routes from the API.
  Future<void> refreshHomeData() async {
    _homeRoutesRequested = false;
    _recommendedRoute = null;
    _recentRoutes = [];
    _errorMessage = null;
    notifyListeners();

    try {
      await refreshCurrentLocation();
    } catch (e) {
      debugPrint('refreshHomeData location failed: $e');
    }
    await loadHomeRoutesIfNeeded();
  }

  /// Loads the default safe-route feed once coordinates are available.
  Future<void> loadHomeRoutesIfNeeded() async {
    if (_homeRoutesRequested) return;

    final lat = _latitude ?? defaultLatitude;
    final lng = _longitude ?? defaultLongitude;

    _homeRoutesRequested = true;
    debugPrint('Dashboard: loading home routes at $lat, $lng');

    await fetchSafeRoute(
      originLat: lat,
      originLng: lng,
    );
  }

  Future<void> getCurrentLocation() async {
    if (_locationInitInProgress) return;

    if (_locationInitStarted &&
        _latitude != null &&
        _longitude != null) {
      return;
    }

    _locationInitInProgress = true;
    if (!_locationInitStarted) {
      _locationInitStarted = true;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationPermissionResolved = true;
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Do not notifyListeners here — avoids rebuilding GoogleMap while the
        // system permission sheet is visible.
        permission = await Geolocator.requestPermission();
      }

      // Mount the map as soon as the permission sheet is gone (granted or not).
      _locationPermissionResolved = true;
      notifyListeners();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _isLoading = true;
      notifyListeners();

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _notifyLocationListeners();
        loadHomeRoutesIfNeeded();
      });

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 6));
      _latitude = pos.latitude;
      _longitude = pos.longitude;

      await _animateToCurrentLocation();
      await loadHomeRoutesIfNeeded();
      notifyListeners();
    } catch (e) {
      debugPrint('getCurrentLocation failed: $e');
    } finally {
      _isLoading = false;
      _locationPermissionResolved = true;
      _locationInitInProgress = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentLocation() async {
    await ensureCurrentLocation(forceRefresh: true);
  }

  /// Ensures [latitude]/[longitude] are available for routing.
  ///
  /// Requests permission when needed, prompts to enable GPS if required,
  /// prefers a fresh fix, and falls back to last-known position.
  Future<bool> ensureCurrentLocation({
    bool forceRefresh = false,
    bool openSettingsIfDisabled = true,
  }) async {
    if (!forceRefresh && _latitude != null && _longitude != null) {
      return true;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      _locationPermissionResolved = true;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _errorMessage =
            'Location permission is required to generate a route.';
        debugPrint('ensureCurrentLocation: permission=$permission');
        notifyListeners();
        return false;
      }

      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
          'ensureCurrentLocation: location services reported disabled',
        );
        // Keep any existing fix usable for routing.
        if (!forceRefresh && _latitude != null && _longitude != null) {
          return true;
        }

        if (openSettingsIfDisabled) {
          try {
            await Geolocator.openLocationSettings();
          } catch (e) {
            debugPrint('openLocationSettings failed: $e');
          }
          // Give the user a moment to turn GPS on, then re-check once.
          await Future<void>.delayed(const Duration(seconds: 2));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
      }

      // Always attempt a position read when permission is granted — some OEMs
      // report services as disabled even when a fix is still available.
      final resolved = await _resolvePositionFix();
      if (resolved) {
        _errorMessage = null;
        _startPositionStreamIfNeeded();
        notifyListeners();
        return true;
      }

      if (!serviceEnabled) {
        _errorMessage =
            'Please turn on Location / GPS in Settings, then try again.';
      } else {
        _errorMessage =
            'Could not get your current location. Check GPS and try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('ensureCurrentLocation failed: $e');
      if (_latitude != null && _longitude != null) return true;
      _errorMessage =
          'Could not get your current location. Check GPS and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _resolvePositionFix() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _latitude = lastKnown.latitude;
        _longitude = lastKnown.longitude;
        debugPrint(
          'ensureCurrentLocation: using lastKnown ($_latitude, $_longitude)',
        );
      }
    } catch (e) {
      debugPrint('ensureCurrentLocation lastKnown failed: $e');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 12));
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      debugPrint(
        'ensureCurrentLocation: fresh fix ($_latitude, $_longitude)',
      );
      return true;
    } catch (e) {
      debugPrint('ensureCurrentLocation getCurrentPosition failed: $e');
      return _latitude != null && _longitude != null;
    }
  }

  void _startPositionStreamIfNeeded() {
    if (_positionStreamSubscription != null) return;
    _locationInitStarted = true;
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _notifyLocationListeners();
      loadHomeRoutesIfNeeded();
    });
  }

  Future<void> _animateToCurrentLocation() async {
    if (_mapController == null || _latitude == null || _longitude == null) {
      return;
    }
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_latitude!, _longitude!),
          15,
        ),
      );
    } catch (e) {
      debugPrint('Map camera animation failed: $e');
    }
  }

  @override
  void dispose() {
    _fetchRouteDebounce?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}