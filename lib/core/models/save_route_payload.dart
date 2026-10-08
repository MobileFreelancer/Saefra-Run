import 'package:saefra_run/core/services/route_service.dart';

class SaveRoutePayload {
  SaveRoutePayload._();

  static Map<String, dynamic> fromLoopResult(
    LoopRouteResult result, {
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    String? location,
  }) {
    final body = <String, dynamic>{
      'routeName': result.routeName,
      'distanceMeters': result.distanceMeters,
      'distanceKm': result.distanceKm,
      'formattedDuration': result.formattedDuration,
      'travelMode': result.travelMode,
      'difficulty': result.difficulty.toLowerCase(),
      'routeType': result.apiRouteType,
      'lighting': result.lighting,
      'estimatedCalories': result.estimatedCalories,
      'estimatedSteps': result.estimatedSteps,
      'averageSpeedKmh': result.averageSpeedKmh,
      'encodedPolyline': result.encodedPolyline,
    };

    final locationLabel = location?.trim();
    if (locationLabel != null && locationLabel.isNotEmpty) {
      // Backend Activity/community screens read this as the route place label.
      body['location'] = locationLabel;
    }

    if (startLatitude != null && startLongitude != null) {
      body['start_latitude'] = startLatitude;
      body['start_longitude'] = startLongitude;
    }
    if (endLatitude != null && endLongitude != null) {
      body['end_latitude'] = endLatitude;
      body['end_longitude'] = endLongitude;
    }

    return body;
  }
}
