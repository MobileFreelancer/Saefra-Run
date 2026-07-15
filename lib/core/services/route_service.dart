import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/utils/polyline_decoder.dart';

class LoopRouteResult {
  final String routeName;
  final int distanceMeters;
  final double distanceKm;
  final String duration;
  final String formattedDuration;
  final String travelMode;
  final String difficulty;
  final String routeType;
  final String lighting;
  final int estimatedCalories;
  final int estimatedSteps;
  final double averageSpeedKmh;
  final String encodedPolyline;
  final List<Map<String, double>> coordinates;

  LoopRouteResult({
    required this.routeName,
    required this.distanceMeters,
    required this.distanceKm,
    required this.duration,
    required this.formattedDuration,
    required this.travelMode,
    required this.difficulty,
    required this.routeType,
    required this.lighting,
    required this.estimatedCalories,
    required this.estimatedSteps,
    required this.averageSpeedKmh,
    required this.encodedPolyline,
    required this.coordinates,
  });

  String get apiRouteType =>
      routeType.toLowerCase() == 'one_way' ? 'one_way' : 'loop';

  Map<String, dynamic> toJson() {
    return {
      "routeName": routeName,
      "distanceMeters": distanceMeters,
      "distanceKm": distanceKm,
      "formattedDuration": formattedDuration,
      "travelMode": travelMode,
      "difficulty": difficulty,
      "routeType": routeType,
      "lighting": lighting,
      "estimatedCalories": estimatedCalories,
      "estimatedSteps": estimatedSteps,
      "averageSpeedKmh": averageSpeedKmh,
      "encodedPolyline": encodedPolyline,
      "coordinates": coordinates, // Output directly into the json file
    };
  }
}

class RouteService {
  String get apiKey => ApiConfig.googleRoutesApiKey;

  Future<LoopRouteResult?> createLoopRoute({
    required LatLng currentLocation,
    required double distanceKm,
    String travelMode = 'WALK',
    String difficulty = 'medium',
    String routeType = 'loop',
    String lighting = 'Well-lit',
    String? routeName,
  }) async {
    final radius = (distanceKm * 1000) / (2 * pi);
    final waypoints = generateLoopWaypoints(currentLocation, radius);

    return _computeRoute(
      origin: currentLocation,
      destination: currentLocation,
      intermediates: waypoints,
      travelMode: travelMode,
      difficulty: difficulty,
      routeType: routeType,
      lighting: lighting,
      routeName: routeName,
    );
  }

  Future<LoopRouteResult?> createOneWayRoute({
    required LatLng origin,
    required double distanceKm,
    String travelMode = 'WALK',
    String difficulty = 'medium',
    String lighting = 'Well-lit',
    String? routeName,
  }) async {
    final destination = calculatePoint(origin, distanceKm * 1000, 0);

    return _computeRoute(
      origin: origin,
      destination: destination,
      travelMode: travelMode,
      difficulty: difficulty,
      routeType: 'one_way',
      lighting: lighting,
      routeName: routeName,
    );
  }

  Future<LoopRouteResult?> _computeRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> intermediates = const [],
    String travelMode = 'WALK',
    String difficulty = 'medium',
    String routeType = 'loop',
    String lighting = 'Well-lit',
    String? routeName,
  }) async {
    final body = <String, dynamic>{
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          }
        }
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          }
        }
      },
      'travelMode': travelMode,
      'computeAlternativeRoutes': false,
    };

    if (intermediates.isNotEmpty) {
      body['intermediates'] = intermediates.map((point) {
        return {
          'location': {
            'latLng': {
              'latitude': point.latitude,
              'longitude': point.longitude,
            }
          },
          'via': true,
        };
      }).toList();
    }

    try {
      final response = await http.post(
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask':
              'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.description',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('routes') && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          final rawMeters = route['distanceMeters'] ?? 0;
          final rawDurationStr = route['duration'] ?? '0s';
          final rawSeconds = int.parse(rawDurationStr.replaceAll('s', ''));

          final calculatedKm =
              double.parse((rawMeters / 1000).toStringAsFixed(2));
          final hoursTotal = rawSeconds / 3600;

          final speed = hoursTotal > 0
              ? double.parse((calculatedKm / hoursTotal).toStringAsFixed(1))
              : 0.0;
          final steps = (rawMeters / 0.76).round();
          final calories = (calculatedKm * 65).round();

          final encodedPolyline = route['polyline']['encodedPolyline'] ?? '';
          final decodedPoints = PolylineDecoder.decode(encodedPolyline);
          final coordinatesList = decodedPoints
              .map(
                (point) => {
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                },
              )
              .toList();

          return LoopRouteResult(
            routeName: routeName ??
                route['description'] as String? ??
                'Safe Route ${calculatedKm.toStringAsFixed(1)} km',
            distanceMeters: rawMeters,
            distanceKm: calculatedKm,
            duration: rawDurationStr,
            formattedDuration: formatDuration(rawSeconds),
            travelMode: travelMode,
            difficulty: difficulty,
            routeType: routeType,
            lighting: lighting,
            estimatedCalories: calories,
            estimatedSteps: steps,
            averageSpeedKmh: speed,
            encodedPolyline: encodedPolyline,
            coordinates: coordinatesList,
          );
        }
      } else {
        print('API Error: ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
    return null;
  }

  List<LatLng> generateLoopWaypoints(LatLng center, double radius) {
    List<LatLng> points = [];
    int totalPoints = 4;
    for (int i = 0; i < totalPoints; i++) {
      double angle = (2 * pi / totalPoints) * i;
      points.add(calculatePoint(center, radius, angle));
    }
    return points;
  }

  LatLng calculatePoint(LatLng center, double radius, double angle) {
    const earthRadius = 6378137.0;
    double lat = center.latitude * pi / 180;
    double lng = center.longitude * pi / 180;

    double newLat = asin(
      sin(lat) * cos(radius / earthRadius) +
          cos(lat) * sin(radius / earthRadius) * cos(angle),
    );

    double newLng = lng +
        atan2(
          sin(angle) * sin(radius / earthRadius) * cos(lat),
          cos(radius / earthRadius) - sin(lat) * sin(newLat),
        );

    return LatLng(newLat * 180 / pi, newLng * 180 / pi);
  }

  String formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;

    List<String> parts = [];
    if (hours > 0) parts.add("$hours hr");
    if (minutes > 0) parts.add("$minutes min");
    if (parts.isEmpty) parts.add("0 min");

    return parts.join(' ');
  }
}

void fetchAndShowRouteData() async {
  RouteService service = RouteService();
  LoopRouteResult? result = await service.createLoopRoute(
    currentLocation: const LatLng(21.205195, 72.775681),
    distanceKm: 7.0,
    travelMode: "WALK",
  );
  if (result != null) {
    String jsonOutput = const JsonEncoder.withIndent('  ').convert(result.toJson());
    print(jsonOutput);
  }
}