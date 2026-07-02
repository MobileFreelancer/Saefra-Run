import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// ==========================================
// 1. EXTENDED DATA MODEL FOR JSON RESPONSE
// ==========================================
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
  });

  /// Converts the complete object to your requested JSON structure
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
    };
  }
}

// ==========================================
// 2. ROUTE SERVICE CLASS
// ==========================================
class RouteService {
  static String apiKey = "AIzaSyCbIzUN3ij3FCD-zBBshUZdEgBXDCcYsj8";

  Future<LoopRouteResult?> createLoopRoute({
    required LatLng currentLocation,
    required double distanceKm,
    String travelMode = "WALK",
  }) async {
    double radius = (distanceKm * 1000) / (2 * pi);
    List<LatLng> waypoints = generateLoopWaypoints(currentLocation, radius);

    final body = {
      "origin": {
        "location": {
          "latLng": {
            "latitude": currentLocation.latitude,
            "longitude": currentLocation.longitude,
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": currentLocation.latitude,
            "longitude": currentLocation.longitude,
          }
        }
      },
      "intermediates": waypoints.map((e) {
        return {
          "location": {
            "latLng": {
              "latitude": e.latitude,
              "longitude": e.longitude,
            }
          },
          "via": true
        };
      }).toList(),
      "travelMode": travelMode,
      "computeAlternativeRoutes": false,
    };

    try {
      final response = await http.post(
        Uri.parse("https://routes.googleapis.com/directions/v2:computeRoutes"),
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.description",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('routes') && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          int rawMeters = route['distanceMeters'] ?? 0;
          String rawDurationStr = route['duration'] ?? "0s";
          int rawSeconds = int.parse(rawDurationStr.replaceAll('s', ''));

          // --- SMART CALCULATIONS ---
          double calculatedKm = double.parse((rawMeters / 1000).toStringAsFixed(2));
          double hoursTotal = rawSeconds / 3600;

          // Speed (km/h)
          double speed = hoursTotal > 0 ? double.parse((calculatedKm / hoursTotal).toStringAsFixed(1)) : 0.0;

          // Steps (Average step length = 0.76 meters for walk/run)
          int steps = (rawMeters / 0.76).round();

          // Calories (Roughly 65 kcal per km for walking/running)
          int calories = (calculatedKm * 65).round();

          // Difficulty based on distance
          String difficulty = "Easy";
          if (calculatedKm > 4 && calculatedKm <= 8) {
            difficulty = "Medium";
          } else if (calculatedKm > 8) {
            difficulty = "Hard";
          }

          return LoopRouteResult(
            routeName: route['description'] ?? "Pal Gam - Palanpur Jakatnaka Rd",
            distanceMeters: rawMeters,
            distanceKm: calculatedKm,
            duration: rawDurationStr,
            formattedDuration: formatDuration(rawSeconds),
            travelMode: travelMode,
            difficulty: difficulty,
            routeType: "Loop",
            lighting: "Well-lit",
            estimatedCalories: calories,
            estimatedSteps: steps,
            averageSpeedKmh: speed,
            encodedPolyline: route['polyline']['encodedPolyline'] ?? "",
          );
        }
      } else {
        print("API Error: ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
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

// ==========================================
// 3. RUN / EXECUTION TEST METHOD
// ==========================================
void fetchAndShowRouteData() async {
  RouteService service = RouteService();

  // 7.0 Km Loop around your Surat Coordinates
  LoopRouteResult? result = await service.createLoopRoute(
    currentLocation: const LatLng(21.205194905801783, 72.77568113625402),
    distanceKm: 7.0,
    travelMode: "WALK",
  );

  if (result != null) {
    // Generate clean, readable JSON format directly matching your structure
    String jsonOutput = const JsonEncoder.withIndent('  ').convert(result.toJson());

    print("--- FULL JSON DATA RECEIVED ---");
    print(jsonOutput);
    print("--------------------------------");
  } else {
    print("Data fetching failed. Verify API Key or connectivity.");
  }
}