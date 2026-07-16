import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationRouteUtils {
  LocationRouteUtils._();

  /// Max distance we attempt to preview/generate as a walk/run route.
  static const double maxRouteDistanceMeters = 80000; // 80 km

  /// Android emulator / mock default near Google HQ.
  static const LatLng kAndroidMockLocation = LatLng(37.4219983, -122.084);

  static double distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  static bool isKnownMockLocation(LatLng point, {double thresholdMeters = 500}) {
    return distanceMeters(point, kAndroidMockLocation) <= thresholdMeters;
  }

  static bool isPlausibleRoute(LatLng origin, LatLng destination) {
    return distanceMeters(origin, destination) <= maxRouteDistanceMeters;
  }

  static bool shouldUseLocalCamera(LatLng? origin, LatLng? destination) {
    if (origin == null || destination == null) return true;
    final spanLat = (origin.latitude - destination.latitude).abs();
    final spanLng = (origin.longitude - destination.longitude).abs();
    return spanLat <= 4 && spanLng <= 4;
  }

  static String? routeValidationError({
    required LatLng? origin,
    required LatLng? destination,
    String? destinationName,
  }) {
    if (destination == null) return null;

    if (origin == null) {
      return 'Waiting for your current location. Enable GPS and location permission, then try again.';
    }

    final distance = distanceMeters(origin, destination);
    if (distance > maxRouteDistanceMeters) {
      final label = destinationName ?? 'the selected destination';
      if (isKnownMockLocation(origin)) {
        return 'Your device location is set to the emulator default (USA), but $label is far away. Set a mock location near your destination or test on a real device with GPS enabled.';
      }
      return 'Your current location is too far from $label (${(distance / 1000).toStringAsFixed(0)} km away). Move closer or enable accurate GPS.';
    }

    return null;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
