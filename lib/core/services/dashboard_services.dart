import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/services/api_service.dart';

class DashboardServices extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  int _currentBottomIndex = 0;
  GoogleMapController? _mapController;

  // Blinking Live Marker Config
  Timer? _blinkTimer;
  bool _isBlinkVisible = true;
  StreamSubscription<Position>? _positionStreamSubscription;
  BitmapDescriptor? _liveLocationIcon;

  // State variables for Location Autocomplete Search
  List<dynamic> _placePredictions = [];
  bool _isSearching = false;
  final String _googleApiKey = "YOUR_GOOGLE_MAPS_API_KEY_HERE";

  // Dynamic Route Integration State
  Map<String, dynamic>? _recommendedRoute;
  List<dynamic> _recentRoutes = [];
  List<LatLng> _routePolylinePoints = [];
  bool _isRouteLoading = false;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  int get currentBottomIndex => _currentBottomIndex;
  GoogleMapController? get mapController => _mapController;
  List<dynamic> get placePredictions => _placePredictions;
  bool get isSearching => _isSearching;
  bool get isBlinkVisible => _isBlinkVisible;
  BitmapDescriptor? get liveLocationIcon => _liveLocationIcon;

  Map<String, dynamic>? get recommendedRoute => _recommendedRoute;
  List<dynamic> get recentRoutes => _recentRoutes;
  List<LatLng> get routePolylinePoints => _routePolylinePoints;
  bool get isRouteLoading => _isRouteLoading;
  String? get errorMessage => _errorMessage;

  DashboardServices() {
    _startBlinkAnimation();
  }

  void _startBlinkAnimation() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _isBlinkVisible = !_isBlinkVisible;
      notifyListeners();
    });
  }

  void setBottomIndex(int index) {
    _currentBottomIndex = index;
    notifyListeners();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  /// Create Set of custom markers dynamically rendered on the map scene graph
  /// 1. Generates the sharp center blue dot marker
  Set<Marker> getMapMarkers(BuildContext context) {
    final Set<Marker> markers = {};

    if (_latitude != null && _longitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_location_center_dot'),
          position: LatLng(_latitude!, _longitude!),
          // Native system blue/azure point matching your image perfectly
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5), // Centers the dot perfectly on coordinates
          flat: true, // Keeps it flat when rotating the map view
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );

      // Your nearby runner and waypoint mock data can safely sit here:
      markers.add(
        Marker(
          markerId: const MarkerId('nearby_runner_1'),
          position: LatLng(_latitude! + 0.002, _longitude! + 0.002),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (_recommendedRoute != null) {
      final double? startLat = _recommendedRoute!['start_latitude']?.toDouble();
      final double? startLng = _recommendedRoute!['start_longitude']?.toDouble();
      final double? endLat = _recommendedRoute!['end_latitude']?.toDouble();
      final double? endLng = _recommendedRoute!['end_longitude']?.toDouble();

      if (startLat != null && startLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('route_start'),
            position: LatLng(startLat, startLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: _recommendedRoute!['starting_point'] ?? 'Start'),
          ),
        );
      }
      if (endLat != null && endLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('route_end'),
            position: LatLng(endLat, endLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: _recommendedRoute!['ending_point'] ?? 'Destination'),
          ),
        );
      }
    }
    return markers;
  }

  /// 2. Generates the semi-transparent glowing outer blue pulse ring
  Set<Circle> getMapCircles() {
    final Set<Circle> circles = {};

    if (_latitude != null && _longitude != null) {
      circles.add(
        Circle(
          circleId: const CircleId('live_location_pulse_ring'),
          center: LatLng(_latitude!, _longitude!),
          radius: 65, // Radius size in meters. Adjust this to make the glow wider or narrower

          // Outer stroke ring color (very faint blue)
          strokeColor: const Color(0x332196F3),
          strokeWidth: 2,

          // Internal fill translucent blue color matching the screenshot's opacity
          fillColor: const Color(0x222196F3),
          zIndex: 1, // Keeps the glow beneath the solid core dot text layers
        ),
      );
    }
    return circles;
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

    if (_googleApiKey == "YOUR_GOOGLE_MAPS_API_KEY_HERE" || _googleApiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      _useMockSearch(query);
      _isSearching = false;
      notifyListeners();
      return;
    }

    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          _placePredictions = data['predictions'];
        } else {
          _useMockSearch(query);
        }
      } else {
        _useMockSearch(query);
      }
    } catch (e) {
      _useMockSearch(query);
    }
    _isSearching = false;
    notifyListeners();
  }

  void _useMockSearch(String query) {
    final allMock = [
      {
        'description': 'Dumas Beach, Surat',
        'place_id': 'mock_dumas',
        'lat': 21.0772,
        'lng': 72.7130
      },
      {
        'description': 'VR Mall Surat',
        'place_id': 'mock_vrmall',
        'lat': 21.1738,
        'lng': 72.7845
      },
      {
        'description': 'Adajan, Surat',
        'place_id': 'mock_adajan',
        'lat': 21.1895,
        'lng': 72.7951
      },
      {
        'description': 'madhi',
        'place_id': 'mock_madhi',
        'lat': 21.2035,
        'lng': 72.7997
      },
    ];
    _placePredictions = allMock
        .where((element) =>
            (element['description'] as String).toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> selectPrediction(String placeId) async {
    _placePredictions = [];
    notifyListeners();

    double? lat;
    double? lng;

    if (placeId.startsWith('mock_')) {
      final allMock = [
        {
          'description': 'Dumas Beach, Surat',
          'place_id': 'mock_dumas',
          'lat': 21.0772,
          'lng': 72.7130
        },
        {
          'description': 'VR Mall Surat',
          'place_id': 'mock_vrmall',
          'lat': 21.1738,
          'lng': 72.7845
        },
        {
          'description': 'Adajan, Surat',
          'place_id': 'mock_adajan',
          'lat': 21.1895,
          'lng': 72.7951
        },
        {
          'description': 'madhi',
          'place_id': 'mock_madhi',
          'lat': 21.2035,
          'lng': 72.7997
        },
      ];
      final matched = allMock.firstWhere((e) => e['place_id'] == placeId);
      lat = matched['lat'] as double;
      lng = matched['lng'] as double;
    } else {
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
    }

    if (lat != null && lng != null) {
      _routePolylinePoints = [];
      _recommendedRoute = null;
      notifyListeners();

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0));
      }

      final double originLat = _latitude ?? 21.2158;
      final double originLng = _longitude ?? 72.8372;

      await fetchSafeRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: lat,
        destLng: lng,
      );
    }
  }

  Future<void> fetchSafeRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    _isRouteLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.generateSafeRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (result['success'] == true && result['route'] != null) {
        final routeData = result['route'];
        _recommendedRoute = routeData['recommended_routes'];
        
        final list = routeData['recent_routes'];
        if (list is List) {
          _recentRoutes = list;
        }

        if (_recommendedRoute != null && _recommendedRoute!['route_coordinates'] != null) {
          final polylineStr = _recommendedRoute!['route_coordinates'] as String;
          _routePolylinePoints = decodePolyline(polylineStr);
          _fitMapToPoints(_routePolylinePoints);
        } else {
          _routePolylinePoints = [];
        }
      } else {
        _errorMessage = result['message'] ?? 'Failed to generate safe route.';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching safe route: $e');
    } finally {
      _isRouteLoading = false;
      notifyListeners();
    }
  }

  void _fitMapToPoints(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;
    
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
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60.0, // padding
      ),
    );
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    // Load custom asset icon image layout mapping configuration reference asset
    try {
      _liveLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(36, 36)),
        'assets/images/live_dot.png', // <-- Make sure to place your custom map marker design graphic here
      );
    } catch (_) {
      // Fallback configuration handles automatically
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      // Initialize persistent Location Coordinate stream changes dynamically
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
      ).listen((Position position) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        notifyListeners();
      });

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _latitude = pos.latitude;
      _longitude = pos.longitude;

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_latitude!, _longitude!), 15.0));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}