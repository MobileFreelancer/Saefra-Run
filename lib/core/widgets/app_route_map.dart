import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/dashboard_services.dart';
import 'package:saefra_run/core/utils/location_route_utils.dart';

class _AppRouteMapSnapshot {
  const _AppRouteMapSnapshot({
    required this.latitude,
    required this.longitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.routePolylinePoints,
  });

  final double? latitude;
  final double? longitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final List<LatLng> routePolylinePoints;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AppRouteMapSnapshot &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.destinationLatitude == destinationLatitude &&
        other.destinationLongitude == destinationLongitude &&
        _polylineEqual(other.routePolylinePoints, routePolylinePoints);
  }

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        destinationLatitude,
        destinationLongitude,
        routePolylinePoints.length,
        routePolylinePoints.isEmpty
            ? 0
            : routePolylinePoints.first.latitude,
      );

  static bool _polylineEqual(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    if (a.isEmpty) return true;
    return a.first.latitude == b.first.latitude &&
        a.first.longitude == b.first.longitude &&
        a.last.latitude == b.last.latitude &&
        a.last.longitude == b.last.longitude;
  }
}

/// Reusable Google Map — draws only real route polylines from API data.
class AppRouteMap extends StatefulWidget {
  const AppRouteMap({
    super.key,
    this.height,
    this.borderRadius = 16,
    this.polylinePoints,
    this.origin,
    this.destination,
    this.showRoutePolyline = true,
    this.showLocationMarker = true,
    this.fallbackToDashboardPolyline = false,
    this.fitToContent = true,
    this.preferDestinationCamera = false,
    this.zoom = 14,
  });

  final double? height;
  final double borderRadius;
  final List<LatLng>? polylinePoints;
  final LatLng? origin;
  final LatLng? destination;
  final bool showRoutePolyline;
  final bool showLocationMarker;
  final bool fallbackToDashboardPolyline;
  final bool fitToContent;
  final bool preferDestinationCamera;
  final double zoom;

  @override
  State<AppRouteMap> createState() => _AppRouteMapState();
}

class _AppRouteMapState extends State<AppRouteMap> {
  GoogleMapController? _controller;
  String? _lastCameraKey;

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardServices, _AppRouteMapSnapshot>(
      selector: (_, services) => _AppRouteMapSnapshot(
        latitude: services.latitude,
        longitude: services.longitude,
        destinationLatitude: services.destinationPositionLatitude,
        destinationLongitude: services.destinationPositionLongitude,
        routePolylinePoints: services.routePolylinePoints,
      ),
      builder: (context, snapshot, _) {
        final resolvedOrigin = widget.origin ??
            (snapshot.latitude != null && snapshot.longitude != null
                ? LatLng(snapshot.latitude!, snapshot.longitude!)
                : null);
        final resolvedDestination = widget.destination ??
            (snapshot.destinationLatitude != null &&
                    snapshot.destinationLongitude != null
                ? LatLng(
                    snapshot.destinationLatitude!,
                    snapshot.destinationLongitude!,
                  )
                : null);

        final points = _resolvePoints(
          widget.polylinePoints,
          widget.fallbackToDashboardPolyline
              ? snapshot.routePolylinePoints
              : const [],
        );

        final target = resolvedOrigin ??
            resolvedDestination ??
            (points.isNotEmpty
                ? points.first
                : const LatLng(21.1702, 72.8311));

        final useLocalCamera = !widget.preferDestinationCamera &&
            LocationRouteUtils.shouldUseLocalCamera(
              resolvedOrigin,
              resolvedDestination,
            );
        final showOriginMarker = resolvedOrigin != null &&
            (resolvedDestination == null ||
                LocationRouteUtils.isPlausibleRoute(
                  resolvedOrigin,
                  resolvedDestination,
                ));

        final markers = <Marker>{};

        if (showOriginMarker) {
          markers.add(
            Marker(
              markerId: const MarkerId('route_origin'),
              position: resolvedOrigin,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: const InfoWindow(title: 'Start'),
            ),
          );
        } else if (widget.showLocationMarker &&
            resolvedOrigin == null &&
            snapshot.latitude != null &&
            snapshot.longitude != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('map_center'),
              position: LatLng(snapshot.latitude!, snapshot.longitude!),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
              infoWindow: const InfoWindow(title: 'My Location'),
            ),
          );
        }

        if (resolvedDestination != null &&
            !_nearLatLng(resolvedOrigin, resolvedDestination)) {
          markers.add(
            Marker(
              markerId: const MarkerId('route_destination'),
              position: resolvedDestination,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: const InfoWindow(title: 'Destination'),
            ),
          );
        }

        final cameraKey = _cameraKey(markers, points, useLocalCamera);
        if (widget.fitToContent && cameraKey != _lastCameraKey) {
          _lastCameraKey = cameraKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitCamera(
              markers,
              points,
              fallbackTarget: resolvedDestination ?? target,
              useLocalCamera: useLocalCamera,
            );
          });
        }

        final map = GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: widget.zoom),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          markers: markers,
          polylines: widget.showRoutePolyline && points.length > 1
              ? {
                  Polyline(
                    polylineId: const PolylineId('app_route_polyline'),
                    points: points,
                    color: AppColors.primary,
                    width: 5,
                  ),
                }
              : {},
          onMapCreated: (controller) async {
            _controller = controller;
            await context.read<DashboardServices>().applyMapStyle(controller);
            if (widget.fitToContent) {
              _fitCamera(
                markers,
                points,
                fallbackTarget: resolvedDestination ?? target,
                useLocalCamera: useLocalCamera,
              );
            }
          },
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.height != null
              ? SizedBox(
                  height: widget.height,
                  width: double.infinity,
                  child: map,
                )
              : SizedBox.expand(child: map),
        );
      },
    );
  }

  Future<void> _fitCamera(
    Set<Marker> markers,
    List<LatLng> points, {
    required LatLng fallbackTarget,
    required bool useLocalCamera,
  }) async {
    final controller = _controller;
    if (controller == null) return;

    final allPoints = <LatLng>[
      if (useLocalCamera) ...markers.map((marker) => marker.position),
      ...points,
    ];

    if (!useLocalCamera) {
      final destinationMarker = markers.where(
        (marker) => marker.markerId.value == 'route_destination',
      );
      if (destinationMarker.isNotEmpty) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            destinationMarker.first.position,
            widget.zoom,
          ),
        );
        return;
      }
    }

    if (allPoints.isEmpty) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(fallbackTarget, widget.zoom),
      );
      return;
    }

    if (allPoints.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(allPoints.first, widget.zoom),
      );
      return;
    }

    var minLat = allPoints.first.latitude;
    var maxLat = allPoints.first.latitude;
    var minLng = allPoints.first.longitude;
    var maxLng = allPoints.first.longitude;

    for (final point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(allPoints.first, widget.zoom),
      );
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          56,
        ),
      );
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(allPoints.first, widget.zoom),
      );
    }
  }

  String _cameraKey(
    Set<Marker> markers,
    List<LatLng> points,
    bool useLocalCamera,
  ) {
    final markerKey = markers
        .map(
          (marker) =>
              '${marker.markerId.value}:${marker.position.latitude},${marker.position.longitude}',
        )
        .join('|');
    final pointKey = points.isEmpty
        ? ''
        : '${points.first.latitude},${points.first.longitude}->'
            '${points.last.latitude},${points.last.longitude}(${points.length})';
    return '$markerKey#$pointKey#$useLocalCamera';
  }

  List<LatLng> _resolvePoints(
    List<LatLng>? explicitPoints,
    List<LatLng> dashboardPoints,
  ) {
    if (explicitPoints != null && explicitPoints.length > 1) {
      return explicitPoints;
    }
    if (dashboardPoints.length > 1) {
      return dashboardPoints;
    }
    return const [];
  }

  static bool _nearLatLng(LatLng? a, LatLng? b, {double epsilon = 0.0005}) {
    if (a == null || b == null) return false;
    return (a.latitude - b.latitude).abs() < epsilon &&
        (a.longitude - b.longitude).abs() < epsilon;
  }
}
