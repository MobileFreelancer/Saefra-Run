import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  int get currentBottomIndex => _currentBottomIndex;
  GoogleMapController? get mapController => _mapController;
  List<dynamic> get placePredictions => _placePredictions;
  bool get isSearching => _isSearching;
  bool get isBlinkVisible => _isBlinkVisible;
  BitmapDescriptor? get liveLocationIcon => _liveLocationIcon;

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

    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          _placePredictions = data['predictions'];
        } else {
          _placePredictions = [];
        }
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

    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          double lat = location['lat'];
          double lng = location['lng'];
          _latitude = lat;
          _longitude = lng;

          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0));
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
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