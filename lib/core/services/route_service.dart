import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/utils/polyline_decoder.dart';
import 'package:flutter/foundation.dart';

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
  final String? warningMessage;

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
    this.warningMessage,
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
      "coordinates": coordinates,
    };
  }
}

class RouteService {
  String get apiKey => ApiConfig.googleRoutesApiKey;

  /// Fetches elevation data for sampled points along the route using the Google Elevation API
  /// and returns the total cumulative elevation gain in meters.
  Future<double?> getElevationGain(List<LatLng> points) async {
    if (points.isEmpty) return 0.0;

    // Sample up to 20 points along the path to keep request size compact
    final List<LatLng> sampledPoints = [];
    if (points.length <= 20) {
      sampledPoints.addAll(points);
    } else {
      final step = (points.length - 1) / 19;
      for (int i = 0; i < 20; i++) {
        final index = (i * step).round().clamp(0, points.length - 1);
        sampledPoints.add(points[index]);
      }
    }

    final locationsParam = sampledPoints
        .map((p) =>
            '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}')
        .join('|');

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/elevation/json',
    ).replace(
      queryParameters: {
        'locations': locationsParam,
        'key': apiKey,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          if (Platform.isIOS) 'X-Ios-Bundle-Identifier': 'com.saefra.run.saefraRun',
          if (Platform.isAndroid) 'X-Android-Package': 'com.saefra.run.saefra_run',
        },
      );
      if (response.statusCode != 200) {
        debugPrint(
            'Elevation API HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        debugPrint(
            'Elevation API status ${data['status']}: ${data['error_message']}');
        return null;
      }

      final results = data['results'] as List<dynamic>? ?? [];
      if (results.length < 2) return 0.0;

      double totalGainMeters = 0.0;
      double previousElevation =
          (results.first['elevation'] as num?)?.toDouble() ?? 0.0;

      for (int i = 1; i < results.length; i++) {
        final currentElevation =
            (results[i]['elevation'] as num?)?.toDouble() ?? previousElevation;
        final diff = currentElevation - previousElevation;
        if (diff > 0) {
          totalGainMeters += diff;
        }
        previousElevation = currentElevation;
      }

      return totalGainMeters;
    } catch (e) {
      debugPrint('Elevation API exception: $e');
      return null;
    }
  }

  /// Non-overlapping elevation bands (gain meters per km):
  /// Easy <= 15 | Medium 15–50 (exclusive of easy) | Hard > 50
  static const double _easyMaxGainPerKm = 15.0;
  static const double _mediumMaxGainPerKm = 50.0;

  /// 0 = in-band. Otherwise distance outside the target band (lower is closer).
  double _elevationMismatch(double gainPerKm, String difficulty) {
    final diffLower = difficulty.toLowerCase();
    if (diffLower == 'easy') {
      if (gainPerKm <= _easyMaxGainPerKm) return 0;
      return gainPerKm - _easyMaxGainPerKm;
    }
    if (diffLower == 'medium' || diffLower == 'moderate') {
      if (gainPerKm > _easyMaxGainPerKm && gainPerKm <= _mediumMaxGainPerKm) {
        return 0;
      }
      if (gainPerKm <= _easyMaxGainPerKm) {
        return _easyMaxGainPerKm - gainPerKm + 0.01;
      }
      return gainPerKm - _mediumMaxGainPerKm;
    }
    if (diffLower == 'hard') {
      if (gainPerKm > _mediumMaxGainPerKm) return 0;
      return _mediumMaxGainPerKm - gainPerKm + 0.01;
    }
    return 0;
  }

  /// Creates a loop route matching distance and difficulty constraints,
  /// re-sampling alternative loop geometries up to [maxRetries] times if elevation gain
  /// does not match the difficulty criteria.
  Future<LoopRouteResult?> createLoopRoute({
    required LatLng currentLocation,
    required double distanceKm,
    String travelMode = 'WALK',
    String difficulty = 'medium',
    String routeType = 'loop',
    String lighting = 'Well-lit',
    String? routeName,
    int maxRetries = 6,
  }) async {
    final baseRadius = (distanceKm * 1000) / (2 * pi);
    LoopRouteResult? bestResult;
    double bestMismatch = double.infinity;
    double? bestGainPerKm;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // Explore different directions and slightly vary radius to find hills/flats.
      final angleOffset = attempt * (pi / 5);
      final radiusScale = _radiusScaleForDifficulty(difficulty, attempt);
      final waypoints = generateLoopWaypoints(
        currentLocation,
        baseRadius * radiusScale,
        startAngleOffset: angleOffset,
        difficulty: difficulty,
        attempt: attempt,
      );

      final result = await _computeRoute(
        origin: currentLocation,
        destination: currentLocation,
        intermediates: waypoints,
        travelMode: travelMode,
        difficulty: difficulty,
        routeType: routeType,
        lighting: lighting,
        routeName: routeName,
      );

      if (result == null) continue;

      // Decode polyline points and verify elevation profile
      final points = PolylineDecoder.decode(result.encodedPolyline);
      final gainMeters = await getElevationGain(points);

      // If Elevation API is not configured or returns null, use the initial route
      if (gainMeters == null) {
        return result;
      }

      final gainPerKm =
          result.distanceKm > 0 ? gainMeters / result.distanceKm : 0.0;
      final mismatch = _elevationMismatch(gainPerKm, difficulty);

      if (mismatch < bestMismatch) {
        bestMismatch = mismatch;
        bestResult = result;
        bestGainPerKm = gainPerKm;
      }

      if (mismatch == 0) {
        debugPrint(
          '✅ Found $difficulty route on attempt ${attempt + 1}: '
          '${gainMeters.toStringAsFixed(1)}m elevation gain for ${result.distanceKm}km '
          '(${gainPerKm.toStringAsFixed(1)}m/km)',
        );
        return result;
      }

      debugPrint(
        '⚠️ Attempt ${attempt + 1} elevation (${gainPerKm.toStringAsFixed(1)}m/km) '
        'did not match criteria for "$difficulty". Retrying...',
      );
    }

    if (bestResult != null && bestMismatch == 0) {
      return bestResult;
    }

    // Do not silently accept a mismatched profile as the requested difficulty.
    if (bestResult != null) {
      final gainRatio = bestGainPerKm != null
          ? '${bestGainPerKm.toStringAsFixed(1)}m/km'
          : 'unknown';
      final warningMsg =
          'Could not match "$difficulty" elevation in this area ($gainRatio). '
          'Showing the closest available route.';

      debugPrint(
        '⚠️ WARNING: No exact elevation match for "$difficulty" '
        'after $maxRetries attempts (best=$gainRatio, mismatch=$bestMismatch).',
      );

      return LoopRouteResult(
        routeName: bestResult.routeName,
        distanceMeters: bestResult.distanceMeters,
        distanceKm: bestResult.distanceKm,
        duration: bestResult.duration,
        formattedDuration: bestResult.formattedDuration,
        travelMode: bestResult.travelMode,
        difficulty: bestResult.difficulty,
        routeType: bestResult.routeType,
        lighting: bestResult.lighting,
        estimatedCalories: bestResult.estimatedCalories,
        estimatedSteps: bestResult.estimatedSteps,
        averageSpeedKmh: bestResult.averageSpeedKmh,
        encodedPolyline: bestResult.encodedPolyline,
        coordinates: bestResult.coordinates,
        warningMessage: warningMsg,
      );
    }

    return null;
  }

  double _radiusScaleForDifficulty(String difficulty, int attempt) {
    final diffLower = difficulty.toLowerCase();
    if (diffLower == 'easy') {
      // Keep loops compact/local to favor flatter nearby streets.
      return 0.92 + (attempt % 3) * 0.03;
    }
    if (diffLower == 'hard') {
      // Stretch the search area to find more elevation change.
      return 1.08 + attempt * 0.06;
    }
    // Medium / moderate
    return 1.0 + attempt * 0.04;
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

  Future<LoopRouteResult?> createRouteToDestination({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'WALK',
    String difficulty = 'medium',
    String lighting = 'Well-lit',
    String? routeName,
  }) async {
    final routesResult = await _computeRoute(
      origin: origin,
      destination: destination,
      travelMode: travelMode,
      difficulty: difficulty,
      routeType: 'one_way',
      lighting: lighting,
      routeName: routeName,
    );
    if (routesResult != null) return routesResult;

    return _computeRouteViaDirections(
      origin: origin,
      destination: destination,
      travelMode: travelMode,
      difficulty: difficulty,
      routeType: 'one_way',
      lighting: lighting,
      routeName: routeName,
    );
  }

  Future<LoopRouteResult?> _computeRouteViaDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'WALK',
    String difficulty = 'medium',
    String routeType = 'one_way',
    String lighting = 'Well-lit',
    String? routeName,
  }) async {
    final mode = travelMode.toLowerCase() == 'walk' ? 'walking' : 'driving';
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json',
    ).replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': mode,
        'key': ApiConfig.googleDirectionsApiKey,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        debugPrint(
            'Directions API HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        debugPrint(
            'Directions API status ${data['status']}: ${data['error_message']}');
        return null;
      }

      final routes = data['routes'] as List<dynamic>? ?? [];
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>? ?? [];
      if (legs.isEmpty) return null;

      final leg = legs.first as Map<String, dynamic>;
      final distanceMeters = (leg['distance']?['value'] as num?)?.toInt() ?? 0;
      final durationSeconds =
          (leg['duration']?['value'] as num?)?.toInt() ?? 0;
      final encodedPolyline =
          route['overview_polyline']?['points'] as String? ?? '';

      if (encodedPolyline.isEmpty) return null;

      final decodedPoints = PolylineDecoder.decode(encodedPolyline);
      final coordinatesList = decodedPoints
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList();

      final calculatedKm =
          double.parse((distanceMeters / 1000).toStringAsFixed(2));
      final adjustedSeconds =
          _calculateRunningDurationSeconds(calculatedKm, durationSeconds);
      final hoursTotal = adjustedSeconds / 3600;
      final speed = hoursTotal > 0
          ? double.parse((calculatedKm / hoursTotal).toStringAsFixed(1))
          : 0.0;

      return LoopRouteResult(
        routeName: routeName ?? 'Route to destination',
        distanceMeters: distanceMeters,
        distanceKm: calculatedKm,
        duration: '${adjustedSeconds}s',
        formattedDuration: formatDuration(adjustedSeconds),
        travelMode: travelMode,
        difficulty: difficulty,
        routeType: routeType,
        lighting: lighting,
        estimatedCalories: (calculatedKm * 65).round(),
        estimatedSteps: (distanceMeters / 0.76).round(),
        averageSpeedKmh: speed,
        encodedPolyline: encodedPolyline,
        coordinates: coordinatesList,
      );
    } catch (e) {
      debugPrint('Directions API exception: $e');
      return null;
    }
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
          final adjustedSeconds =
              _calculateRunningDurationSeconds(calculatedKm, rawSeconds);
          final hoursTotal = adjustedSeconds / 3600;

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
            duration: '${adjustedSeconds}s',
            formattedDuration: formatDuration(adjustedSeconds),
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
        debugPrint('Routes API HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Routes API exception: $e');
    }
    return null;
  }

  int _calculateRunningDurationSeconds(double distanceKm, int rawSeconds) {
    if (distanceKm <= 0) return rawSeconds > 0 ? rawSeconds : 0;
    // Average running pace: ~7 minutes per km (~11 minutes per mile)
    final runningPaceSeconds = (distanceKm * 7.0 * 60).round();
    // Override if raw API duration is unrealistically high (> 1.4x running pace estimate, e.g. 4 hours for 3 km)
    if (rawSeconds <= 0 || rawSeconds > runningPaceSeconds * 1.4) {
      return runningPaceSeconds;
    }
    return rawSeconds;
  }

  List<LatLng> generateLoopWaypoints(
    LatLng center,
    double radius, {
    double startAngleOffset = 0.0,
    String difficulty = 'medium',
    int attempt = 0,
  }) {
    final points = <LatLng>[];
    const totalPoints = 4;
    final diffLower = difficulty.toLowerCase();
    // Elliptical stretch finds hillier corridors for medium/hard without
    // changing the easy (near-circular) shape much.
    final stretch = switch (diffLower) {
      'easy' => 1.0,
      'hard' => 1.25 + attempt * 0.05,
      _ => 1.1 + attempt * 0.03,
    };

    for (var i = 0; i < totalPoints; i++) {
      final angle = startAngleOffset + (2 * pi / totalPoints) * i;
      final axisScale = (i.isEven ? stretch : (1 / stretch));
      points.add(calculatePoint(center, radius * axisScale, angle));
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