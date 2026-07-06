// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:saefra_run/core/services/api_service.dart';
//
// enum DashboardMapStyle {
//   darkBase('Dark base'),
//   light('Light'),
//   dark('Dark');
//
//   const DashboardMapStyle(this.label);
//   final String label;
// }
//
// class DashboardServices extends ChangeNotifier {
//   double? _latitude;
//   double? _longitude;
//   bool _isLoading = false;
//   int _currentBottomIndex = 0;
//
//
//   // Location stream
//   StreamSubscription<Position>? _positionStreamSubscription;
//   bool _locationInitStarted = false;
//   bool _locationPermissionResolved = false;
//   DateTime? _lastLocationNotifyAt;
//
//   // State variables for Location Autocomplete Search
//   List<dynamic> _placePredictions = [];
//   bool _isSearching = false;
//   final String _googleApiKey = "YOUR_GOOGLE_MAPS_API_KEY_HERE";
//
//   // Dynamic Route Integration State
//   Map<String, dynamic>? _recommendedRoute;
//   List<dynamic> _recentRoutes = [];
//   List<LatLng> _routePolylinePoints = [];
//   bool _isRouteLoading = false;
//   String? _errorMessage;
//   DashboardMapStyle _mapStyle = DashboardMapStyle.darkBase;
//
//   final ApiService _apiService = ApiService();
//
//   double? get latitude => _latitude;
//   double? get longitude => _longitude;
//   bool get isLoading => _isLoading;
//   /// True once the location permission flow has finished (granted or denied).
//   /// The dashboard map waits for this so Google Maps is not alive during the
//   /// system permission dialog — that combination causes native crashes/hangs.
//   bool get isLocationPermissionResolved => _locationPermissionResolved;
//   int get currentBottomIndex => _currentBottomIndex;
//   GoogleMapController? _mapController;
//
//   GoogleMapController? get mapController => _mapController;
//   List<dynamic> get placePredictions => _placePredictions;
//   bool get isSearching => _isSearching;
//
//   Map<String, dynamic>? get recommendedRoute => _recommendedRoute;
//   List<dynamic> get recentRoutes => _recentRoutes;
//   List<LatLng> get routePolylinePoints => _routePolylinePoints;
//   bool get isRouteLoading => _isRouteLoading;
//   String? get errorMessage => _errorMessage;
//   DashboardMapStyle get mapStyle => _mapStyle;
//
//
//
//   set mapController(GoogleMapController? controller) {
//     _mapController = controller;
//     notifyListeners();
//   }
//
//   DashboardServices() {
//     _startBlinkAnimation();
//   }
//
//   void _startBlinkAnimation() {
//     _blinkTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
//       _isBlinkVisible = !_isBlinkVisible;
//       notifyListeners();
//     });
//   }
//
//   void setBottomIndex(int index) {
//     _currentBottomIndex = index;
//     notifyListeners();
//   }
//
//   void setMapStyle(DashboardMapStyle style) {
//     _mapStyle = style;
//     notifyListeners();
//   }
//
//   void setMapController(GoogleMapController controller) {
//     _mapController = controller;
//     if (_latitude != null && _longitude != null) {
//       _animateToCurrentLocation();
//     }
//   }
//
//   void _notifyLocationListeners() {
//     final now = DateTime.now();
//     if (_lastLocationNotifyAt != null &&
//         now.difference(_lastLocationNotifyAt!) <
//             const Duration(milliseconds: 800)) {
//       return;
//     }
//     _lastLocationNotifyAt = now;
//     notifyListeners();
//   }
//
//   Future<void> searchLocation(String query) async {
//     if (query.trim().isEmpty) {
//       _placePredictions = [];
//       _isSearching = false;
//       notifyListeners();
//       return;
//     }
//     _isSearching = true;
//     notifyListeners();
//     final double originLat = _latitude ?? 21.2158;
//     final double originLng = _longitude ?? 72.8372;
//
//     await fetchSafeRoute(
//       originLat: originLat,
//       originLng: originLng,
//       destLat: originLat,
//       destLng: originLng,
//     );
//
//     if (_googleApiKey == "YOUR_GOOGLE_MAPS_API_KEY_HERE" || _googleApiKey.isEmpty) {
//       await Future.delayed(const Duration(milliseconds: 300));
//       _useMockSearch(query);
//       _isSearching = false;
//       notifyListeners();
//       return;
//     }
//     final String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googleApiKey";
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 'OK') {
//           _placePredictions = data['predictions'];
//         } else {
//           _useMockSearch(query);
//         }
//       } else {
//         _useMockSearch(query);
//       }
//     } catch (e) {
//       _useMockSearch(query);
//     }
//     _isSearching = false;
//     notifyListeners();
//   }
//
//   void _useMockSearch(String query) {
//     final allMock = [
//       {
//         'description': 'Dumas Beach, Surat',
//         'place_id': 'mock_dumas',
//         'lat': 21.0772,
//         'lng': 72.7130
//       },
//       {
//         'description': 'VR Mall Surat',
//         'place_id': 'mock_vrmall',
//         'lat': 21.1738,
//         'lng': 72.7845
//       },
//       {
//         'description': 'Adajan, Surat',
//         'place_id': 'mock_adajan',
//         'lat': 21.1895,
//         'lng': 72.7951
//       },
//       {
//         'description': 'madhi',
//         'place_id': 'mock_madhi',
//         'lat': 21.2035,
//         'lng': 72.7997
//       },
//     ];
//     _placePredictions = allMock.where((element) => (element['description'] as String).toLowerCase().contains(query.toLowerCase())).toList();
//   }
//
//   Future<void> selectPrediction(String placeId) async {
//     _placePredictions = [];
//     notifyListeners();
//     double? lat;
//     double? lng;
//     if (placeId.startsWith('mock_')) {
//       final allMock = [
//         {
//           'description': 'Dumas Beach, Surat',
//           'place_id': 'mock_dumas',
//           'lat': 21.0772,
//           'lng': 72.7130
//         },
//         {
//           'description': 'VR Mall Surat',
//           'place_id': 'mock_vrmall',
//           'lat': 21.1738,
//           'lng': 72.7845
//         },
//         {
//           'description': 'Adajan, Surat',
//           'place_id': 'mock_adajan',
//           'lat': 21.1895,
//           'lng': 72.7951
//         },
//         {
//           'description': 'madhi',
//           'place_id': 'mock_madhi',
//           'lat': 21.2035,
//           'lng': 72.7997
//         },
//       ];
//       final matched = allMock.firstWhere((e) => e['place_id'] == placeId);
//       lat = matched['lat'] as double;
//       lng = matched['lng'] as double;
//     } else {
//       final String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleApiKey";
//       try {
//         final response = await http.get(Uri.parse(url));
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           if (data['status'] == 'OK') {
//             final location = data['result']['geometry']['location'];
//             lat = location['lat'];
//             lng = location['lng'];
//           }
//         }
//       } catch (e) {
//         debugPrint(e.toString());
//       }
//     }
//     if (lat != null && lng != null) {
//       _routePolylinePoints = [];
//       _recommendedRoute = null;
//       notifyListeners();
//       if (_mapController != null) {
//         _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0));
//       }
//     }
//   }
//
//   Future<void> fetchSafeRoute({
//     required double originLat,
//     required double originLng,
//     required double destLat,
//     required double destLng,
//   }) async {
//     _isRouteLoading = true;
//     _errorMessage = null;
//     notifyListeners();
//
//     try {
//       final result = await _apiService.generateSafeRoute(
//         originLat: originLat,
//         originLng: originLng,
//         destLat: destLat,
//         destLng: destLng,
//       );
//
//       if (result['success'] == true && result['route'] != null) {
//         final routeData = result['route'];
//         _recommendedRoute = routeData['recommended_routes'];
//
//         final list = routeData['recent_routes'];
//         if (list is List) {
//           _recentRoutes = list;
//         }
//
//         if (_recommendedRoute != null && _recommendedRoute!['route_coordinates'] != null) {
//           try {
//             final polylineStr = _recommendedRoute!['route_coordinates'] as String;
//             _routePolylinePoints = decodePolyline(polylineStr);
//             _fitMapToPoints(_routePolylinePoints);
//           } catch (e) {
//             debugPrint('Polyline decode failed: $e');
//             _routePolylinePoints = [];
//           }
//         } else {
//           _routePolylinePoints = [];
//         }
//       } else {
//         _errorMessage = result['message'] ?? 'Failed to generate safe route.';
//       }
//     } catch (e) {
//       _errorMessage = e.toString();
//       debugPrint('Error fetching safe route: $e');
//     } finally {
//       _isRouteLoading = false;
//       notifyListeners();
//     }
//   }
//
//   void _fitMapToPoints(List<LatLng> points) {
//     if (_mapController == null || points.isEmpty) return;
//
//     try {
//       if (points.length == 1) {
//         _mapController!.animateCamera(
//           CameraUpdate.newLatLngZoom(points.first, 15),
//         );
//         return;
//       }
//
//       double minLat = points.first.latitude;
//       double maxLat = points.first.latitude;
//       double minLng = points.first.longitude;
//       double maxLng = points.first.longitude;
//
//       for (var point in points) {
//         if (point.latitude < minLat) minLat = point.latitude;
//         if (point.latitude > maxLat) maxLat = point.latitude;
//         if (point.longitude < minLng) minLng = point.longitude;
//         if (point.longitude > maxLng) maxLng = point.longitude;
//       }
//
//       // Google Maps crashes when bounds have zero area.
//       if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
//         _mapController!.animateCamera(
//           CameraUpdate.newLatLngZoom(points.first, 15),
//         );
//         return;
//       }
//
//       _mapController!.animateCamera(
//         CameraUpdate.newLatLngBounds(
//           LatLngBounds(
//             southwest: LatLng(minLat, minLng),
//             northeast: LatLng(maxLat, maxLng),
//           ),
//           60.0,
//         ),
//       );
//     } catch (e) {
//       debugPrint('fitMapToPoints failed: $e');
//     }
//   }
//
//   List<LatLng> decodePolyline(String encoded) {
//     List<LatLng> points = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;
//
//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lat += dlat;
//
//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lng += dlng;
//
//       points.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return points;
//   }
//
//   Future<void> getCurrentLocation() async {
//     if (_locationInitStarted) return;
//     _locationInitStarted = true;
//
//     try {
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         _locationPermissionResolved = true;
//         notifyListeners();
//         return;
//       }
//
//       var permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         // Do not notifyListeners here — avoids rebuilding GoogleMap while the
//         // system permission sheet is visible.
//         permission = await Geolocator.requestPermission();
//       }
//
//       // Mount the map as soon as the permission sheet is gone (granted or not).
//       _locationPermissionResolved = true;
//       notifyListeners();
//
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         return;
//       }
//
//       _isLoading = true;
//       notifyListeners();
//
//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription = Geolocator.getPositionStream(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.medium,
//           distanceFilter: 10,
//         ),
//       ).listen((Position position) {
//         _latitude = position.latitude;
//         _longitude = position.longitude;
//         _notifyLocationListeners();
//       });
//
//       final pos = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.medium,
//         ),
//       );
//       _latitude = pos.latitude;
//       _longitude = pos.longitude;
//
//       await _animateToCurrentLocation();
//       notifyListeners();
//     } catch (e) {
//       debugPrint('getCurrentLocation failed: $e');
//     } finally {
//       _isLoading = false;
//       _locationPermissionResolved = true;
//       notifyListeners();
//     }
//   }
//
//   Future<void> _animateToCurrentLocation() async {
//     if (_mapController == null ||
//         _latitude == null ||
//         _longitude == null) {
//       return;
//     }
//     try {
//       await _mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(
//           LatLng(_latitude!, _longitude!),
//           15,
//         ),
//       );
//     } catch (e) {
//       debugPrint('Map camera animation failed: $e');
//     }
//   }
//
//   @override
//   void dispose() {
//     _blinkTimer?.cancel();
//     _positionStreamSubscription?.cancel();
//     _mapController?.dispose();
//     super.dispose();
//   }
// }



import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/services/api_service.dart';

enum DashboardMapStyle {
  darkBase('Dark base'),
  light('Light'),
  dark('Dark');

  const DashboardMapStyle(this.label);
  final String label;
}

class DashboardServices extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  int _currentBottomIndex = 0;
  GoogleMapController? _mapController;

  // Location stream
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _locationInitStarted = false;
  bool _locationPermissionResolved = false;
  DateTime? _lastLocationNotifyAt;

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
  DashboardMapStyle _mapStyle = DashboardMapStyle.darkBase;

  final ApiService _apiService = ApiService();

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  /// True once the location permission flow has finished (granted or denied).
  /// The dashboard map waits for this so Google Maps is not alive during the
  /// system permission dialog — that combination causes native crashes/hangs.
  bool get isLocationPermissionResolved => _locationPermissionResolved;
  int get currentBottomIndex => _currentBottomIndex;
  GoogleMapController? get mapController => _mapController;
  List<dynamic> get placePredictions => _placePredictions;
  bool get isSearching => _isSearching;

  Map<String, dynamic>? get recommendedRoute => _recommendedRoute;
  List<dynamic> get recentRoutes => _recentRoutes;
  List<LatLng> get routePolylinePoints => _routePolylinePoints;
  bool get isRouteLoading => _isRouteLoading;
  String? get errorMessage => _errorMessage;
  DashboardMapStyle get mapStyle => _mapStyle;

  void setBottomIndex(int index) {
    _currentBottomIndex = index;
    notifyListeners();
  }

  void setMapStyle(DashboardMapStyle style) {
    _mapStyle = style;
    notifyListeners();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
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
    final double originLat = _latitude ?? 21.2158;
    final double originLng = _longitude ?? 72.8372;

    await fetchSafeRoute(
      originLat: originLat,
      originLng: originLng,
      destLat: originLat,
      destLng: originLng,
    );

    if (_googleApiKey == "YOUR_GOOGLE_MAPS_API_KEY_HERE" || _googleApiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      _useMockSearch(query);
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
    _placePredictions = allMock.where((element) => (element['description'] as String).toLowerCase().contains(query.toLowerCase())).toList();
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
      final String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleApiKey";
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
          try {
            final polylineStr = _recommendedRoute!['route_coordinates'] as String;
            _routePolylinePoints = decodePolyline(polylineStr);
            _fitMapToPoints(_routePolylinePoints);
          } catch (e) {
            debugPrint('Polyline decode failed: $e');
            _routePolylinePoints = [];
          }
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
    if (_locationInitStarted) return;
    _locationInitStarted = true;

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
      });

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;

      await _animateToCurrentLocation();
      notifyListeners();
    } catch (e) {
      debugPrint('getCurrentLocation failed: $e');
    } finally {
      _isLoading = false;
      _locationPermissionResolved = true;
      notifyListeners();
    }
  }

  Future<void> _animateToCurrentLocation() async {
    if (_mapController == null ||
        _latitude == null ||
        _longitude == null) {
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
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}