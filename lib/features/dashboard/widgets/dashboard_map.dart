import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';

/// Map layer for the dashboard — rebuilds only when map overlays change,
/// not on unrelated [DashboardServices] updates (loading, search, etc.).
class DashboardMap extends StatelessWidget {
  const DashboardMap({
    super.key,
    required this.initialTarget,
    required this.initialZoom,
  });

  final LatLng initialTarget;
  final double initialZoom;

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardServices, bool>(
      selector: (_, services) => services.isLocationPermissionResolved,
      builder: (context, permissionResolved, _) {
        if (!permissionResolved) {
          return const ColoredBox(
            color: Color(0xFF1A1A1A),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        return Selector<DashboardServices, _DashboardMapSnapshot>(
          selector: (_, services) => _DashboardMapSnapshot.from(services),
          builder: (context, snapshot, _) {
            final services = context.read<DashboardServices>();
            final target = snapshot.hasLocation
                ? LatLng(snapshot.latitude!, snapshot.longitude!)
                : initialTarget;

            return GoogleMap(
              key: const ValueKey('dashboard_map'),
              initialCameraPosition: CameraPosition(
                target: target,
                zoom: initialZoom,
              ),
              // Location is handled by Geolocator + custom markers.
              // Enabling this fights the permission dialog and causes native crashes.
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              circles: snapshot.circles,
              markers: snapshot.markers,
              polylines: snapshot.polylines,
              onMapCreated: services.setMapController,
            );
          },
        );
      },
    );
  }
}

class _DashboardMapSnapshot {
  const _DashboardMapSnapshot({
    required this.latitude,
    required this.longitude,
    required this.markers,
    required this.circles,
    required this.polylines,
  });

  final double? latitude;
  final double? longitude;
  final Set<Marker> markers;
  final Set<Circle> circles;
  final Set<Polyline> polylines;

  bool get hasLocation => latitude != null && longitude != null;

  factory _DashboardMapSnapshot.from(DashboardServices services) {
    final markers = <Marker>{};

    if (services.latitude != null && services.longitude != null) {
      final center = LatLng(services.latitude!, services.longitude!);
      markers.add(
        Marker(
          markerId: const MarkerId('live_location_center_dot'),
          position: center,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }

    final route = services.recommendedRoute;
    if (route != null) {
      final startLat = _readCoord(route['start_latitude']);
      final startLng = _readCoord(route['start_longitude']);
      final endLat = _readCoord(route['end_latitude']);
      final endLng = _readCoord(route['end_longitude']);

      if (startLat != null && startLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('route_start'),
            position: LatLng(startLat, startLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: '${route['starting_point'] ?? 'Start'}',
            ),
          ),
        );
      }
      if (endLat != null && endLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('route_end'),
            position: LatLng(endLat, endLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: '${route['ending_point'] ?? 'Destination'}',
            ),
          ),
        );
      }
    }

    final circles = <Circle>{};
    if (services.latitude != null && services.longitude != null) {
      circles.add(
        Circle(
          circleId: const CircleId('live_location_pulse_ring'),
          center: LatLng(services.latitude!, services.longitude!),
          radius: 65,
          strokeColor: const Color(0x332196F3),
          strokeWidth: 2,
          fillColor: const Color(0x222196F3),
          zIndex: 1,
        ),
      );
    }

    final polylines = <Polyline>{};
    if (services.routePolylinePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('safe_route_polyline'),
          points: services.routePolylinePoints,
          color: AppColors.primary,
          width: 5,
        ),
      );
    }

    return _DashboardMapSnapshot(
      latitude: services.latitude,
      longitude: services.longitude,
      markers: markers,
      circles: circles,
      polylines: polylines,
    );
  }

  static double? _readCoord(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DashboardMapSnapshot &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.markers.length == markers.length &&
        other.circles.length == circles.length &&
        other.polylines.length == polylines.length &&
        _polylinePointsEqual(other.polylines, polylines);
  }

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        markers.length,
        circles.length,
        polylines.length,
        polylines.isEmpty
            ? 0
            : polylines.first.points.length,
      );

  static bool _polylinePointsEqual(Set<Polyline> a, Set<Polyline> b) {
    if (a.isEmpty && b.isEmpty) return true;
    if (a.length != b.length) return false;
    final pa = a.first.points;
    final pb = b.first.points;
    if (pa.length != pb.length) return false;
    for (var i = 0; i < pa.length; i++) {
      if (pa[i].latitude != pb[i].latitude ||
          pa[i].longitude != pb[i].longitude) {
        return false;
      }
    }
    return true;
  }
}
