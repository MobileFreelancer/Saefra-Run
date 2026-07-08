import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/data/app_mock_data.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';

class _AppRouteMapSnapshot {
  const _AppRouteMapSnapshot({
    required this.latitude,
    required this.longitude,
    required this.routePolylinePoints,
  });

  final double? latitude;
  final double? longitude;
  final List<LatLng> routePolylinePoints;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AppRouteMapSnapshot &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.routePolylinePoints.length == routePolylinePoints.length;
  }

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        routePolylinePoints.length,
      );
}

/// Reusable Google Map — same style/behavior as dashboard map.
class AppRouteMap extends StatelessWidget {
  const AppRouteMap({
    super.key,
    this.height,
    this.borderRadius = 16,
    this.polylinePoints,
    this.showRoutePolyline = true,
    this.showLocationMarker = true,
    this.zoom = 14,
  });

  /// When null, expands to fill the parent.
  final double? height;
  final double borderRadius;
  final List<LatLng>? polylinePoints;
  final bool showRoutePolyline;
  final bool showLocationMarker;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardServices, _AppRouteMapSnapshot>(
      selector: (_, services) => _AppRouteMapSnapshot(
        latitude: services.latitude,
        longitude: services.longitude,
        routePolylinePoints: services.routePolylinePoints,
      ),
      builder: (context, snapshot, _) {
        final points = polylinePoints ??
            (snapshot.routePolylinePoints.isNotEmpty
                ? snapshot.routePolylinePoints
                : AppMockData.defaultPolyline);

        final target = points.isNotEmpty
            ? points.first
            : (snapshot.latitude != null && snapshot.longitude != null
                ? LatLng(snapshot.latitude!, snapshot.longitude!)
                : AppMockData.defaultMapTarget);

        final markers = <Marker>{};
        if (showLocationMarker && snapshot.latitude != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('map_center'),
              position: target,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }
        if (points.isNotEmpty) {
          markers.add(
            Marker(
              markerId: const MarkerId('route_start'),
              position: points.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
        }

        final map = GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: zoom),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          markers: markers,
          polylines: showRoutePolyline && points.length > 1
              ? {
                  Polyline(
                    polylineId: const PolylineId('app_route_polyline'),
                    points: points,
                    color: AppColors.primary,
                    width: 5,
                  ),
                }
              : {},
        );

        final clipped = ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: height != null
              ? SizedBox(height: height, width: double.infinity, child: map)
              : SizedBox.expand(child: map),
        );

        return clipped;
      },
    );
  }
}
